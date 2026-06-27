import numpy as np
import matplotlib.pyplot as plt
import scipy.io.wavfile as wav

plt.rcParams['font.family'] = 'Maple Mono NF CN'

# 读取语音文件
fs, y = wav.read('speech.wav')  # 假设语音文件名为 speech.wav

# 如果语音是双声道，取单声道
if len(y.shape) > 1:
    y = y[:, 0]

# 归一化到 [-1, 1] 范围（如果是整数类型）
if y.dtype != np.float32 and y.dtype != np.float64:
    y = y / np.max(np.abs(y))

# 参数设置
frame_len = 256  # 帧长
frame_shift = 128  # 帧移

# 计算帧数
N = len(y)
num_frames = (N - frame_len) // frame_shift + 1

# 初始化短时能量、短时幅度和短时过零率
E = np.zeros(num_frames)
M = np.zeros(num_frames)
Z = np.zeros(num_frames)

# 分帧计算
for i in range(num_frames):
    start_idx = i * frame_shift
    end_idx = start_idx + frame_len
    frame = y[start_idx:end_idx]

    # 短时能量
    E[i] = np.sum(frame ** 2)

    # 短时幅度
    M[i] = np.sum(np.abs(frame))

    # 短时过零率
    Z[i] = np.sum(np.abs(np.sign(frame[1:]) - np.sign(frame[:-1]))) / 2

# 计算时间轴
time_axis = np.arange(N) / fs
frame_time = (np.arange(num_frames) * frame_shift + frame_len / 2) / fs

# 绘图
fig, axes = plt.subplots(4, 1, figsize=(12, 10))

# 子图1：原始语音波形
axes[0].plot(time_axis, y, 'b')
axes[0].set_xlabel('时间 (s)')
axes[0].set_ylabel('幅度')
axes[0].set_title('原始语音波形')
axes[0].grid(True)

# 子图2：短时能量
axes[1].plot(frame_time, E, 'r')
axes[1].set_xlabel('时间 (s)')
axes[1].set_ylabel('能量')
axes[1].set_title('短时能量 E_n')
axes[1].grid(True)

# 子图3：短时幅度
axes[2].plot(frame_time, M, 'g')
axes[2].set_xlabel('时间 (s)')
axes[2].set_ylabel('幅度')
axes[2].set_title('短时幅度 M_n')
axes[2].grid(True)

# 子图4：短时过零率
axes[3].plot(frame_time, Z, 'm')
axes[3].set_xlabel('时间 (s)')
axes[3].set_ylabel('过零率')
axes[3].set_title('短时过零率 Z_n')
axes[3].grid(True)

plt.suptitle('语音信号分析结果')
plt.tight_layout()
plt.show()
