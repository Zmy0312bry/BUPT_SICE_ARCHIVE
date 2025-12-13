# 5G NR SSB信号解析实验

本项目实现了5G NR系统中同步信号块（SSB）的完整解析流程，包括PSS/SSS同步、信道估计、PBCH解码等功能。

## 项目结构

```
.
├── main.m              # 主程序
├── ssb_start_func.m    # SSB起始位置计算（爬格子法）
├── pss.m               # PSS主同步信号检测
├── sss.m               # SSS辅同步信号检测
├── channel.m           # 信道估计与均衡
├── decode.m            # PBCH解码
├── run.sh              # 自动运行脚本
├── fp_iq_1206_06.hex   # IQ数据文件（需自行提供）
└── assets/             # 自动生成的图像和结果目录
```

## 功能特性

### 1. SSB位置检测
- 基于PointA参数计算接收机中心频率
- 采用"爬格子法"遍历1.44MHz频点栅格
- 结合PSS相关检测确定SSB精确位置

### 2. PSS主同步信号检测
- 支持NID2∈{0,1,2}的检测
- 互相关匹配滤波实现符号定时同步
- 自动绘制并保存相关峰图

### 3. SSS辅同步信号检测
- 穷举搜索NID1(0-335)和NID2(0-2)
- 计算完整小区ID：NID = NID1 × 3 + NID2
- 生成SSS频谱图和星座图

### 4. 信道估计与均衡
- 基于DMRS的LS信道估计
- 线性插值获取数据子载波信道响应
- 自动保存频域幅值/相位图和时域响应图
- 生成均衡前后的星座图对比

### 5. PBCH解码
- 提取3个PBCH OFDM符号
- QPSK解调 + 极化码译码
- 解析32bit MIB信息
- 提取系统帧号（SFN）序列

### 6. 图像自动保存
所有图像自动保存到`assets/`目录，包括：
- `pss_correlation.png` - PSS相关峰图
- `sss_spectrum.png` - SSS频谱图
- `sss_constellation.png` - SSS星座图
- `sss_correlation.png` - SSS相关峰图
- `pbch_3symbols_spectrum.png` - PBCH三符号频谱
- `pbch_constellation_before_eq.png` - 均衡前PBCH星座图
- `dmrs_constellation.png` - DMRS星座图
- `channel_magnitude_before_interp.png` - 插值前信道幅值
- `channel_phase_before_interp.png` - 插值前信道相位
- `channel_magnitude_after_interp.png` - 插值后信道幅值
- `channel_phase_after_interp.png` - 插值后信道相位
- `pbch_constellation_after_eq.png` - 均衡后PBCH星座图
- `decode_results.txt` - 解码结果文本文件

## 使用方法

### 方法1：使用Shell脚本（推荐）

```bash
# 赋予执行权限（首次运行）
chmod +x run.sh

# 运行脚本
./run.sh
```

脚本会自动：
1. 检查MATLAB环境
2. 检查数据文件
3. 创建assets目录
4. 以命令行模式运行MATLAB
5. 保存所有图像和结果
6. 生成运行日志

### 方法2：MATLAB GUI模式

在MATLAB命令窗口中直接运行：

```matlab
main
```

**注意**：GUI模式下图形会显示但仍会自动保存到assets目录。

### 方法3：MATLAB命令行模式

```bash
matlab -nodisplay -nosplash -r "run('main.m'); exit"
```

## 系统要求

### 必需软件
- MATLAB R2019b或更高版本
- 5G Toolbox（用于nrPSS, nrSSS, nrPBCHDecode等函数）
- Communications Toolbox

### 硬件要求
- 内存：建议8GB以上
- 存储：至少1GB可用空间（用于数据文件和图像）

## 参数配置

主要参数在`main.m`和`ssb_start_func.m`中配置：

```matlab
% main.m
frame_length = 1228800;      % 每帧采样点数
total_frame = 10;            % 总帧数
pointA = 620016;             % 参考频点

% ssb_start_func.m
N_fft = 4096;                % FFT大小
ssb_width = 240;             % SSB子载波数
ssb_raster = 1.44e6;         % SSB频点栅格间隔
base_freq = 3e9;             % 基准频率3GHz
subcarrier_spacing = 30e3;   % 子载波间隔30kHz
```

## 输出结果

### 终端输出
```
========================================
5G NR SSB信号解析实验
========================================

计算得到的SSB起始子载波索引：XXXX
检测到的NID2：X
检测到的NID1：XXX
NID：XXX
Frame Numbers: [XX XX XX ...]

========================================
实验完成！所有图像已保存到assets/目录
========================================
```

### 文件输出
- `assets/*.png` - 所有实验图像（PNG格式）
- `assets/*.fig` - MATLAB图形文件（可重新编辑）
- `assets/decode_results.txt` - 详细解码结果
- `matlab_output.log` - MATLAB运行日志（使用run.sh时）

## 故障排除

### 1. "未找到MATLAB命令"
**解决方案**：将MATLAB添加到系统PATH
```bash
# Linux/Mac
export PATH=$PATH:/usr/local/MATLAB/R2023a/bin

# 或添加到 ~/.bashrc 或 ~/.zshrc
```

### 2. "未找到数据文件"
**解决方案**：确保`fp_iq_1206_06.hex`文件位于项目根目录

### 3. "License checkout failed"
**解决方案**：检查MATLAB和5G Toolbox许可证是否有效

### 4. 图像未保存
**解决方案**：
- 检查assets目录是否有写权限
- 在main.m开头确保包含了目录创建代码

### 5. CRC校验失败
**可能原因**：
- 信号质量差
- 参数配置不正确
- 数据文件损坏

## 实验流程

1. **SSB位置检测** → 确定SSB在频域的位置
2. **PSS同步** → 获得符号定时和NID2
3. **SSS同步** → 获得NID1和完整NID
4. **信道估计** → 基于DMRS估计频域信道响应
5. **信道均衡** → 补偿信道影响
6. **PBCH解码** → 提取系统帧号和MIB信息

## 理论背景

### PSS序列生成
PSS基于m序列生成，由NID2(∈{0,1,2})决定，占用127个子载波。

### SSS序列生成
SSS基于两个m序列的组合，由NID1和NID2共同决定，占用127个子载波。

### PBCH结构
- 占用3个OFDM符号（符号2、3、4）
- 每4个子载波中1个DMRS，3个数据
- QPSK调制
- 极化码编码

### 信道估计
采用LS（最小二乘）算法：
```
H_dmrs = Y_dmrs / X_dmrs
```
其中Y_dmrs是接收信号，X_dmrs是已知导频。

### 信道均衡
零强迫（ZF）均衡：
```
X_eq = Y / H
```

## 参考文献

1. 3GPP TS 38.211: Physical channels and modulation
2. 3GPP TS 38.212: Multiplexing and channel coding
3. 3GPP TS 38.213: Physical layer procedures for control

## 作者

通信电路与系统实验课程

## 许可证

本项目仅用于教学实验目的。