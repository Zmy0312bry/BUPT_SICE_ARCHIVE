import torch
import numpy as np
from torch.utils.data import TensorDataset, DataLoader
from torch_utils.TrainModel import MakeDataset

# 原始数据加载部分保持不变
total_data_path = 'data/generated/total.vocab'
train_data, test_data = MakeDataset(total_data_path)


def process_input(data):
    """处理输入数据的维度顺序和类型转换"""
    data = np.asarray(data)  # Ensure conversion to proper numpy array
    c = torch.from_numpy(data[:, :, :, 0:3]).float()
    p = torch.from_numpy(data[:, :, :, 3:6]).float()
    t = torch.from_numpy(data[:, :, :, 6:7]).float()
    return c, p, t


def process_label(data):
    """处理标签数据的格式转换"""
    data = np.asarray(data)  # Ensure conversion to proper numpy array
    label = torch.from_numpy(data[:, :, :, -1]).float()
    return label.view(label.shape[0], -1)  # 展平为 [B, 400]


def create_dataset():
    # 处理训练数据
    c_train, p_train, t_train = process_input(train_data)
    train_label = process_label(train_data)

    # 处理测试数据
    c_test, p_test, t_test = process_input(test_data)
    test_label = process_label(test_data)

    # 创建TensorDataset（注意输入的顺序对应模型的前向参数）
    train_dataset = TensorDataset(c_train, p_train, t_train, train_label)
    test_dataset = TensorDataset(c_test, p_test, t_test, test_label)

    return train_dataset, test_dataset
