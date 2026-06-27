import torch
import torch.nn as nn

def get_activation(activation):
    """获取激活函数"""
    if activation == 'relu':
        return nn.ReLU()
    elif activation == 'sigmoid':
        return nn.Sigmoid()
    elif activation == 'tanh':
        return nn.Tanh()
    elif activation == 'leaky_relu':
        return nn.LeakyReLU()
    else:
        return nn.Identity()

def build_Conv(in_channels, out_channels, kernel_size, padding, activation, use_bias, use_list=False):
    """
    构建单个卷积层（包括卷积+激活）
    
    参数：
        in_channels: 输入通道数
        out_channels: 输出通道数
        kernel_size: 卷积核大小 (tuple)
        padding: 填充大小 (tuple)
        activation: 激活函数名称
        use_bias: 是否使用偏置
        use_list: 是否返回列表形式（便于在Sequential中展开）
    
    返回：
        list 或 nn.Sequential
    """
    layers = [
        nn.Conv2d(in_channels, out_channels, kernel_size, padding=padding, bias=use_bias),
        get_activation(activation)
    ]
    
    if use_list:
        return layers
    else:
        return nn.Sequential(*layers)

def build_Conv1x1(in_channels, activation, use_bias, out_channels=None, use_list=False):
    """
    构建1x1卷积层
    
    参数：
        in_channels: 输入通道数（如果未指定out_channels，则输出通道数相同）
        activation: 激活函数名称
        use_bias: 是否使用偏置
        out_channels: 输出通道数（默认与in_channels相同）
        use_list: 是否返回列表形式
    
    返回：
        list 或 nn.Sequential
    """
    if out_channels is None:
        out_channels = in_channels
    
    layers = [
        nn.Conv2d(in_channels, out_channels, kernel_size=1, stride=1, padding=0, bias=use_bias),
        get_activation(activation)
    ]
    
    if use_list:
        return layers
    else:
        return nn.Sequential(*layers)


class MiniDeepST(nn.Module):
    def __init__(self, filters, kernel_size, activation, use_bias):
        super().__init__()
        # 处理不同 kernel_size 类型
        if isinstance(kernel_size, int):
            kernel_size = (kernel_size, kernel_size)
        padding = (kernel_size[0] // 2, kernel_size[1] // 2)

        # 动态计算 1x1 卷积的 padding
        self.conv1x1_padding = (0, 0)  # 1x1 卷积无需 padding

        # 分支定义
        self.closeness = self._build_branch(3, filters, kernel_size, padding, activation, use_bias)
        self.period = self._build_branch(3, filters, kernel_size, padding, activation, use_bias)
        self.trend = self._build_branch(1, filters, kernel_size, padding, activation, use_bias)

        # 融合部分修正
        self.fusion = nn.Sequential(
            *build_Conv(filters, filters, kernel_size, padding, activation, use_bias, use_list=True),
            *build_Conv(filters, filters, kernel_size, padding, activation, use_bias, use_list=True),
            *build_Conv(filters, filters, kernel_size, padding, activation, use_bias, use_list=True),
            nn.Conv2d(filters, 1, kernel_size, padding=padding, bias=use_bias),  # 移除最后多余的激活函数
            nn.Flatten()
        )

    def _build_branch(self, in_channels, out_channels, kernel_size, padding, activation, use_bias):
        return nn.Sequential(
            *build_Conv(in_channels, out_channels, kernel_size, padding, activation, use_bias, use_list=True),
            *build_Conv(out_channels, out_channels, kernel_size, padding, activation, use_bias, use_list=True),
            *build_Conv1x1(out_channels, activation, use_bias, use_list=True)
        )

    def forward(self, c, p, t):
        # 从keras迁移到pytorch时，需要手动转换数据维度，模型层结构不需要改变，只需修改数据维度转换即可
        # 数据维度转换（channels_last -> channels_first）
        c = c.permute(0, 3, 1, 2).float()
        p = p.permute(0, 3, 1, 2).float()
        t = t.permute(0, 3, 1, 2).float()

        c = self.closeness(c)
        p = self.period(p)
        t = self.trend(t)

        fusion = c + p + t
        return self.fusion(fusion)


class ResUnit(nn.Module):
    def __init__(self, filters, kernel_size, use_bias=True):
        super().__init__()
        if isinstance(kernel_size, int):
            kernel_size = (kernel_size, kernel_size)
        padding = (kernel_size[0] // 2, kernel_size[1] // 2)

        self.relu0 = nn.ReLU()
        self.conv1 = nn.Conv2d(filters, filters, kernel_size, padding=padding, bias=use_bias)
        self.relu1 = nn.ReLU()
        self.conv2 = nn.Conv2d(filters, filters, kernel_size, padding=padding, bias=use_bias)

    def forward(self, x):
        identity = x
        out = self.relu0(x)
        out = self.conv1(out)
        out = self.relu1(out)
        out = self.conv2(out)
        return out + identity


class MiniSTResNet(nn.Module):
    def __init__(self, filters, kernel_size, activation, use_bias):
        super().__init__()
        if isinstance(kernel_size, int):
            kernel_size = (kernel_size, kernel_size)
        padding = (kernel_size[0] // 2, kernel_size[1] // 2)

        # 初始化分支卷积
        self.closeness_initial = self._build_initial(3, filters, kernel_size, padding, activation, use_bias)
        self.period_initial = self._build_initial(3, filters, kernel_size, padding, activation, use_bias)
        self.trend_initial = self._build_initial(1, filters, kernel_size, padding, activation, use_bias)

        # 残差单元
        self.closeness_res = nn.Sequential(*[ResUnit(filters, kernel_size, use_bias) for _ in range(2)])
        self.period_res = nn.Sequential(*[ResUnit(filters, kernel_size, use_bias) for _ in range(2)])
        self.trend_res = nn.Sequential(*[ResUnit(filters, kernel_size, use_bias) for _ in range(2)])

        # 1x1卷积
        self.closeness_1x1 = build_Conv1x1(filters, activation, use_bias)
        self.period_1x1 = build_Conv1x1(filters, activation, use_bias)
        self.trend_1x1 = build_Conv1x1(filters, activation, use_bias)

        # 融合层
        self.fusion = nn.Sequential(
            nn.Conv2d(filters, 1, (1, 1), padding=0, bias=use_bias),
            get_activation(activation),
            nn.Flatten()
        )

    def _build_initial(self, in_channels, filters, kernel_size, padding, activation, use_bias):
        return nn.Sequential(
            nn.Conv2d(in_channels, filters, kernel_size, padding=padding, bias=use_bias),
            get_activation(activation)
        )

    def forward(self, c, p, t):
        # 维度转换 (B,H,W,C) -> (B,C,H,W)
        c = c.permute(0, 3, 1, 2).float()
        p = p.permute(0, 3, 1, 2).float()
        t = t.permute(0, 3, 1, 2).float()

        # 处理各分支
        c = self.closeness_initial(c)
        c = self.closeness_res(c)
        c = self.closeness_1x1(c)

        p = self.period_initial(p)
        p = self.period_res(p)
        p = self.period_1x1(p)

        t = self.trend_initial(t)
        t = self.trend_res(t)
        t = self.trend_1x1(t)

        # 融合输出
        fusion = c + p + t
        return self.fusion(fusion)


class ConvLSTM2DCell(nn.Module):
    def __init__(self, input_dim, hidden_dim, kernel_size, bias=True):
        super().__init__()
        self.hidden_dim = hidden_dim

        if isinstance(kernel_size, int):
            kernel_size = (kernel_size, kernel_size)
        padding = (kernel_size[0] // 2, kernel_size[1] // 2)

        self.conv = nn.Conv2d(
            in_channels=input_dim + hidden_dim,
            out_channels=4 * hidden_dim,
            kernel_size=kernel_size,
            padding=padding,
            bias=bias
        )

    def forward(self, x, hidden):
        h_cur, c_cur = hidden
        combined = torch.cat([x, h_cur], dim=1)
        combined_conv = self.conv(combined)
        cc_i, cc_f, cc_o, cc_g = torch.split(combined_conv, self.hidden_dim, dim=1)

        i = torch.sigmoid(cc_i)
        f = torch.sigmoid(cc_f)
        o = torch.sigmoid(cc_o)
        g = torch.tanh(cc_g)

        c_next = f * c_cur + i * g
        h_next = o * torch.tanh(c_next)
        return h_next, c_next


class ConvLSTM2D(nn.Module):
    def __init__(self, input_dim, hidden_dim, kernel_size, num_layers=1, batch_first=True, bias=True):
        super().__init__()
        self.input_dim = input_dim
        self.hidden_dim = hidden_dim
        self.kernel_size = kernel_size
        self.num_layers = num_layers
        self.batch_first = batch_first

        cell_list = []
        for _ in range(num_layers):
            cell_list.append(ConvLSTM2DCell(input_dim, hidden_dim, kernel_size, bias))
            input_dim = hidden_dim  # 后续层的输入维度等于前一层的隐藏维度
        self.cell_list = nn.ModuleList(cell_list)

    def forward(self, x, hidden_states=None):
        if self.batch_first:
            x = x.permute(0, 2, 1, 3, 4)  # (B,T,C,H,W) -> (T,B,C,H,W)

        seq_len = x.size(0)
        batch_size = x.size(1)

        if hidden_states is None:
            h0 = torch.zeros(self.num_layers, batch_size, self.hidden_dim, x.size(3), x.size(4)).to(x.device)
            c0 = torch.zeros_like(h0)
            hidden_states = [(h0[l], c0[l]) for l in range(self.num_layers)]

        output = []
        for t in range(seq_len):
            layer_input = x[t]
            new_hidden = []
            for l, (cell, (h_prev, c_prev)) in enumerate(zip(self.cell_list, hidden_states)):
                h, c = cell(layer_input, (h_prev, c_prev))
                new_hidden.append((h, c))
                layer_input = h  # 下一层的输入是前一层的输出
            hidden_states = new_hidden
            output.append(h)

        if self.batch_first:
            output = torch.stack(output).permute(1, 0, 2, 3, 4)  # (T,B,C,H,W) -> (B,T,C,H,W)
        else:
            output = torch.stack(output)

        return output, hidden_states


class ConvLSTMCell(nn.Module):
    def __init__(self, in_channels, filters, kernel_size, use_bias=True):
        super().__init__()
        if isinstance(kernel_size, int):
            kernel_size = (kernel_size, kernel_size)
        padding = (kernel_size[0] // 2, kernel_size[1] // 2)
        # 卷积路径
        self.conv_path = nn.Sequential(
            nn.Conv2d(in_channels, filters, kernel_size, padding=padding, bias=use_bias),
            nn.ReLU(),
            ResUnit(filters, kernel_size, use_bias),
            ResUnit(filters, kernel_size, use_bias)
        )

        # LSTM路径
        self.lstm = ConvLSTM2D(
            input_dim=in_channels,
            hidden_dim=filters,
            kernel_size=kernel_size,
            num_layers=1,
            batch_first=True,
            bias=use_bias
        )
        self.lstm_conv = nn.Sequential(
            nn.Conv2d(filters, filters, 1, bias=use_bias),
            nn.ReLU()
        )

        # 融合路径
        self.fusion_conv = nn.Sequential(
            nn.Conv2d(filters, filters, 1, bias=use_bias),
            nn.ReLU()
        )

    def forward(self, x):
        # 卷积路径
        conv_out = self.conv_path(x)

        # LSTM路径（修正时间维度处理）
        # batch, C, H, W = x.shape
        lstm_input = x.unsqueeze(2)  # 添加时间维度 (B,C,1,H,W)
        lstm_output, _ = self.lstm(lstm_input)
        lstm_output = lstm_output[:, :, -1]  # 取最后一个时间步 (B,C,H,W)
        lstm_out = self.lstm_conv(lstm_output)

        # 特征融合
        fused = self.fusion_conv(conv_out) + lstm_out
        return fused


class ConvLSTM(nn.Module):
    def __init__(self, filters, kernel_size, use_bias=True):
        super().__init__()
        # 各分支处理
        self.branch_c = nn.Sequential(
            ConvLSTMCell(3, filters, kernel_size, use_bias),
            nn.Conv2d(filters, filters, 1, bias=use_bias),
            nn.ReLU()
        )
        self.branch_p = nn.Sequential(
            ConvLSTMCell(3, filters, kernel_size, use_bias),
            nn.Conv2d(filters, filters, 1, bias=use_bias),
            nn.ReLU()
        )
        self.branch_t = nn.Sequential(
            ConvLSTMCell(1, filters, kernel_size, use_bias),
            nn.Conv2d(filters, filters, 1, bias=use_bias),
            nn.ReLU()
        )

        # 最终输出
        self.fusion = nn.Sequential(
            nn.Conv2d(filters, 1, 1, bias=use_bias),
            nn.ReLU(),
            nn.Flatten()
        )

    def forward(self, c, p, t):
        # 维度转换 (B,H,W,C) -> (B,C,H,W)
        c = c.permute(0, 3, 1, 2).float()
        p = p.permute(0, 3, 1, 2).float()
        t = t.permute(0, 3, 1, 2).float()

        # 处理各分支
        c_out = self.branch_c(c)
        p_out = self.branch_p(p)
        t_out = self.branch_t(t)

        # 特征融合
        fusion = c_out + p_out + t_out
        return self.fusion(fusion)

import math
import torch
import torch.nn as nn
import torch.nn.functional as F


class TimeBlock(nn.Module):
    """
    Neural network block that applies a temporal convolution to each node of
    a graph in isolation.
    """

    def __init__(self, in_channels, out_channels, kernel_size=3):
        """
        :param in_channels: Number of input features at each node in each time
        step.
        :param out_channels: Desired number of output channels at each node in
        each time step.
        :param kernel_size: Size of the 1D temporal kernel.
        """
        super(TimeBlock, self).__init__()
        self.conv1 = nn.Conv2d(in_channels, out_channels, (1, kernel_size))
        self.conv2 = nn.Conv2d(in_channels, out_channels, (1, kernel_size))
        self.conv3 = nn.Conv2d(in_channels, out_channels, (1, kernel_size))

    def forward(self, X):
        """
        :param X: Input data of shape (batch_size, num_nodes, num_timesteps,
        num_features=in_channels)
        :return: Output data of shape (batch_size, num_nodes,
        num_timesteps_out, num_features_out=out_channels)
        """
        # Convert into NCHW format for pytorch to perform convolutions.
        X = X.permute(0, 3, 1, 2)
        temp = self.conv1(X) + torch.sigmoid(self.conv2(X))
        out = F.relu(temp + self.conv3(X))
        # Convert back from NCHW to NHWC
        out = out.permute(0, 2, 3, 1)
        return out


class STGCNBlock(nn.Module):
    """
    Neural network block that applies a temporal convolution on each node in
    isolation, followed by a graph convolution, followed by another temporal
    convolution on each node.
    """

    def __init__(self, in_channels, spatial_channels, out_channels,
                 num_nodes):
        """
        :param in_channels: Number of input features at each node in each time
        step.
        :param spatial_channels: Number of output channels of the graph
        convolutional, spatial sub-block.
        :param out_channels: Desired number of output features at each node in
        each time step.
        :param num_nodes: Number of nodes in the graph.
        """
        super(STGCNBlock, self).__init__()
        self.temporal1 = TimeBlock(in_channels=in_channels,
                                   out_channels=out_channels)
        self.Theta1 = nn.Parameter(torch.FloatTensor(out_channels,
                                                     spatial_channels))
        self.temporal2 = TimeBlock(in_channels=spatial_channels,
                                   out_channels=out_channels)
        self.batch_norm = nn.BatchNorm2d(num_nodes)
        self.reset_parameters()

    def reset_parameters(self):
        stdv = 1. / math.sqrt(self.Theta1.shape[1])
        self.Theta1.data.uniform_(-stdv, stdv)

    def forward(self, X, A_hat):
        """
        :param X: Input data of shape (batch_size, num_nodes, num_timesteps,
        num_features=in_channels).
        :param A_hat: Normalized adjacency matrix.
        :return: Output data of shape (batch_size, num_nodes,
        num_timesteps_out, num_features=out_channels).
        """
        t = self.temporal1(X)
        lfs = torch.einsum("ij,jklm->kilm", [A_hat, t.permute(1, 0, 2, 3)])
        # t2 = F.relu(torch.einsum("ijkl,lp->ijkp", [lfs, self.Theta1]))
        t2 = F.relu(torch.matmul(lfs, self.Theta1))
        t3 = self.temporal2(t2)
        return self.batch_norm(t3)
        # return t3


class STGCN(nn.Module):
    """
    Spatio-temporal graph convolutional network as described in
    https://arxiv.org/abs/1709.04875v3 by Yu et al.
    Input should have shape (batch_size, num_nodes, num_input_time_steps,
    num_features).
    """

    def __init__(self, num_nodes, num_features, num_timesteps_input,
                 num_timesteps_output):
        """
        :param num_nodes: Number of nodes in the graph.
        :param num_features: Number of features at each node in each time step.
        :param num_timesteps_input: Number of past time steps fed into the
        network.
        :param num_timesteps_output: Desired number of future time steps
        output by the network.
        """
        super(STGCN, self).__init__()
        self.block1 = STGCNBlock(in_channels=num_features, out_channels=64,
                                 spatial_channels=16, num_nodes=num_nodes)
        self.block2 = STGCNBlock(in_channels=64, out_channels=64,
                                 spatial_channels=16, num_nodes=num_nodes)
        self.last_temporal = TimeBlock(in_channels=64, out_channels=64)
        self.fully = nn.Linear((num_timesteps_input - 2 * 5) * 64,
                               num_timesteps_output)

    def forward(self, A_hat, X):
        """
        :param X: Input data of shape (batch_size, num_nodes, num_timesteps,
        num_features=in_channels).
        :param A_hat: Normalized adjacency matrix.
        """
        out1 = self.block1(X, A_hat)
        out2 = self.block2(out1, A_hat)
        out3 = self.last_temporal(out2)
        out4 = self.fully(out3.reshape((out3.shape[0], out3.shape[1], -1)))
        return out4


import torch
import torch.nn as nn


class SpatioTemporalTransformer(nn.Module):
    def __init__(self, d_model=16, num_layers=3, nhead=4, dim_feedforward=128, dropout=0.1):
        super(SpatioTemporalTransformer, self).__init__()

        if d_model % nhead != 0:
            raise ValueError(f"d_model ({d_model}) must be divisible by nhead ({nhead})")

        self.d_model = d_model
        self.grid_h = 20
        self.grid_w = 20
        self.num_grids = self.grid_h * self.grid_w

        self.input_proj = nn.Linear(7, d_model)

        self.spatial_pos_embed = nn.Parameter(torch.randn(self.num_grids, d_model) * 0.02)

        encoder_layer = nn.TransformerEncoderLayer(
            d_model=d_model,
            nhead=nhead,
            dim_feedforward=dim_feedforward,
            dropout=dropout,
            activation='gelu',
            batch_first=True
        )
        self.encoder = nn.TransformerEncoder(encoder_layer, num_layers=num_layers)

        self.output_proj = nn.Sequential(
            nn.Linear(d_model, d_model),
            nn.GELU(),
            nn.Dropout(dropout),
            nn.Linear(d_model, 1)
        )

        self._init_weights()

    def _init_weights(self):
        for p in self.parameters():
            if p.dim() > 1:
                nn.init.xavier_uniform_(p)

    def forward(self, c, p, t):
        B = c.shape[0]

        x = torch.cat([c, p, t], dim=-1)

        x = self.input_proj(x)

        x = x.view(B, self.num_grids, self.d_model)

        x = x + self.spatial_pos_embed.unsqueeze(0)

        x = self.encoder(x)

        x = self.output_proj(x)

        return x.squeeze(-1)
