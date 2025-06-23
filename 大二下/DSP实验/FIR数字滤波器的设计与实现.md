---
tags:
  - DSP
  - 学习
  - Matlab
---

# 题目概述
## 实验目的

1. 了解FIR数字滤波的原理；
2. 熟悉FIR数字滤波器的设计与实现方法；
3. 对比FIR滤波器和IIR滤波器的幅频响应和相频响应。

## 实验内容
### 基础实验
产生正弦波信号，分别通过FIR滤波器和IIR滤波器。对比FIR和IIR滤波器的效果，并在时域和频域对比输出和输入信号，评估滤波效果，输出信号的特性是否满足滤波器规范？

将带通滤波器改为带阻滤波器，重复试验。

### 附加实验

输入音频信号，分别通过FIR滤波器和IIR滤波器，评估经过滤波器的音频的区别。

### 实验要求

要求使用MATLAB软件完成实验，使用窗函数法（函数名称fir1）实现FIR滤波器，使用巴特沃斯IIR滤波器。

#### 要求输出
1. FIR和IIR的幅频响应、相频响应图；
2. 绘制原始、滤波后信号的时域、频域波形图。

## 验收标准
1. 实验代码的独立性与完整性；
2. 实验设计合理，结果正确；
3. 对实验结果进行合理分析与思考。

# 代码部分

> 以下结果是使用`GNU Octave`运行的
> 
> 使用前需要导入`signal`
> ```bash
> pkg load signal
> ```
> `GNU Octave`的在`Linux`下的中文无问题，好耶！

## 基础实验
### 代码

```matlab
clear all; clc;

%% 滤波器参数计算
Fs = 8000;  % 采样频率
F = [0 1400 1700 1900 2200 4000];  % 模拟截止频率
f = 2*F/Fs;  % 数字截止频率
m = [0 0 1 1 0 0];  % 幅度

%% 窗函数法设计FIR带通滤波器,阶数为58，通带为1400Hz-2200Hz
Wn = [1400, 2200]/(Fs/2);
b1 = fir1(58, Wn, 'bandpass');

%% IIR滤波器设计 - Butterworth带通滤波器
% 计算 Butterworth 滤波器的最小阶数 n 和归一化截止频率 Wn
% 通带边界频率为1700Hz、1900Hz
% 阻带边界频率为1400Hz、2200Hz
% 通带波动（最大允许的通带衰减）3dB,阻带衰减（最小要求的阻带衰减)40dB
Wp = [1700, 1900]/(Fs/2); % 通带归一化频率
Ws = [1400, 2200]/(Fs/2); % 阻带归一化频率
[n, Wn] = buttord(Wp, Ws, 3, 40);  % 3 dB通带波动和40 dB阻带衰减
[b2, a2] = butter(n, Wn, 'bandpass');  % 带通滤波器

%% 
% 计算FIR滤波器的频率响应
[H1, w1] = freqz(b1, 1, 1024, Fs);
% 计算IIR滤波器的频率响应
[H2, w2] = freqz(b2, a2, 1024, Fs);

% 绘制FIR滤波器的幅度和相位响应
figure;
subplot(2, 1, 1);
plot(w1, 20*log10(abs(H1)));
title('FIR滤波器的幅度响应');
xlabel('频率 (Hz)');
ylabel('幅度 (dB)');

subplot(2, 1, 2);
plot(w1, unwrap(angle(H1))*180/pi);
title('FIR滤波器的相位响应');
xlabel('频率 (Hz)');
ylabel('相位 (度)');

% 绘制IIR滤波器的幅度和相位响应
figure;
subplot(2, 1, 1);
plot(w2, 20*log10(abs(H2)));
title('IIR滤波器的幅度响应');
xlabel('频率 (Hz)');
ylabel('幅度 (dB)');

subplot(2, 1, 2);
plot(w2, unwrap(angle(H2))*180/pi);
title('IIR滤波器的相位响应');
xlabel('频率 (Hz)');
ylabel('相位 (度)');

% %% 生成输入信号
% n = 0:1:1000;
% x1 = sin(2*pi*800*n/Fs);
% x2 = sin(2*pi*1800*n/Fs);
% x3 = sin(2*pi*3300*n/Fs);
% x = (x1 + x2 + x3) / 3;

%% 生成输入信号（包含方波和正弦波）
t = 0:1/Fs:0.125;  % 生成时间向量
x1 = sin(2 * pi * 800 * t);
x = x1 + 0.5 * square(2 * pi * 1800 * t) + 0.5 * sin(2 * pi * 1800 * t);  % 方波和正弦波的组合
X1=fft(x);
%% FIR滤波处理
y1 = filter(b1, 1, x);
Y1 = fft(y1);

%% IIR滤波处理
y2 = filter(b2, a2, x);
Y2 = fft(y2);

%% 画图比较
figure;
subplot(3, 2, 1);
plot(t, x);
title('原始信号 - 时域');
xlabel('时间 (s)');
ylabel('幅度');

% 计算频率向量
N = length(x);
f = Fs * (0:N-1) / N;

subplot(3, 2, 2);
plot(f, abs(X1));
title('原始信号 - 频域');
xlabel('频率 (Hz)');
ylabel('幅度');

subplot(3, 2, 3);
plot(t, y1);
title('FIR滤波后的信号 - 时域');
xlabel('时间 (s)');
ylabel('幅度');

subplot(3, 2, 4);
plot(f, abs(Y1));
title('FIR滤波后的信号 - 频域');
xlabel('频率 (Hz)');
ylabel('幅度');

subplot(3, 2, 5);
plot(t, y2);
title('IIR滤波后的信号 - 时域');
xlabel('时间 (s)');
ylabel('幅度');

subplot(3, 2, 6);
plot(f, abs(Y2));
title('IIR滤波后的信号 - 频域');
xlabel('频率 (Hz)');
ylabel('幅度');
```

### 结果
![](https://i-blog.csdnimg.cn/direct/d6d28394ec5747d59492522934acdb2a.png)
![在这里插入图片描述](https://i-blog.csdnimg.cn/direct/7595857714664f0292329aa5fb557c41.png)
![在这里插入图片描述](https://i-blog.csdnimg.cn/direct/2d03cf48834d42e691f6d1bddd42bc18.png)
## 附加实验
### 代码
> 记得自己补充音频文件
```matlab
clear all; clc;
[y, Fs] = audioread('Lights.wav');
disp(Fs);
% 加载WAV文件并截取前20秒
[y, Fs] = audioread('Lights.wav', [1, 20*Fs]);

% FIR滤波器设计：使用窗函数法设计一个低通滤波器
N = 50; % 滤波器阶数
Fpass = 10000; % 通带截止频率
FIR = fir1(N, Fpass/(Fs/2));

% IIR滤波器设计：使用巴特沃斯滤波器设计
IIR = butter(5, Fpass/(Fs/2));

% 应用FIR滤波器
yFIR = filter(FIR, 1, y);

% 应用IIR滤波器
yIIR = filter(IIR, 1, y);

% 保存原始的20秒音频为WAV格式
audiowrite('original_20sec.wav', y, Fs);

% 保存FIR滤波器处理后的音频为WAV格式
audiowrite('filtered_FIR.wav', yFIR, Fs);

% 保存IIR滤波器处理后的音频为WAV格式
audiowrite('filtered_IIR.wav', yIIR, Fs);

% 显示波形
t = linspace(0, length(y)/Fs, length(y));

figure;
subplot(3,1,1);
plot(t, y);
title('Original Audio');
xlabel('Time (seconds)');
ylabel('Amplitude');

subplot(3,1,2);
plot(t, yFIR);
title('Audio after FIR Filtering');
xlabel('Time (seconds)');
ylabel('Amplitude');

subplot(3,1,3);
plot(t, yIIR);
title('Audio after IIR Filtering');
xlabel('Time (seconds)');
ylabel('Amplitude');

```
### 结果
![在这里插入图片描述](https://i-blog.csdnimg.cn/direct/f2c889bd9dcd4f16a40c7b55086e21bb.png)

