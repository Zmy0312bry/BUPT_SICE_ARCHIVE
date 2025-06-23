---
tags:
  - DSP
  - 学习
  - Matlab
---

# 题目概述

## 实验目的

1. 学习IIR滤波器的基本原理；
2. 掌握IIR滤波器的设计方法与MATLAB实现方式；
3. 实现MATLAB基本的图像操作；
4. 学习IIR滤波器在图像处理上的应用。

## 实验内容

### 正弦波信号IIR数字滤波（8分）

设有三个不同频率的正弦波信号$x_1(t)=sin(2\pi f_1t)$，$x_2(t)=sin(2\pi f_2t)$，$x_3(t)=sin(2\pi f_3t)$，其中频率分别为$f_1=120Hz$，$f_2=180Hz$，$f_3=240Hz$，将三个正弦波信号叠加得到发送信号
$$
x(t)=h_1sin(2\pi f_1t)+h_2sin(2\pi f_2t)+h_3sin(2\pi f_3t)
$$
其中幅度分别为$h_1=0.8$，$h_2=2.4$，$h_3=0.5$。然后将发送信号通过加性高斯白噪声信道进行传输，设信噪比$SNR=8dB$，则信号与噪声功率关系为
$$
10lg(\frac{P_s}{P_n})=SNR=8dB
$$
接收端接收到的信号为
$$
r(t)=x(t)+noise
$$
现需设计IIR滤波器，使滤波器为带通滤波器，要求滤出频率为$f_2=180Hz$的正弦波信号，得到滤波后信号$y(t)$为
$$
y(t)=h_2sin(2\pi f_2t)+noise
$$

整体流程图如图1所示。
![](<./assets/Pasted image 20250509033152.png>)
<center>图 1 正弦波信号IIR数字滤波流程图</center>

使用MATLAB对上述过程进行仿真，设计代码并构造IIR数字滤波器，滤波器类型为Butterworth滤波器，并输出：
1. IIR数字滤波器的幅频响应图；
2. 发送信号、接收信号、滤波信号的时域波形对比图；
3. 发送信号、接收信号、滤波信号的频域频谱对比图。

### 图像的IIR数字滤波（2分）

选用一张合适大小的图像，使用MATLAB导入图像的RGB矩阵，并转化为灰度矩阵，如图2所示。
![](<./assets/Pasted image 20250509033507.png>)
<center>图 2 RGB图像与灰度图像</center>

对图像的灰度矩阵进行处理，先将灰度矩阵转化为一维数组，再在一维数组上叠加频率为$300Hz$的正弦波噪声。设计IIR滤波器对该图像一维数组滤波，要求滤除$300Hz$的正弦波噪声，即设计Butterworth带阻滤波器进行滤波。得到滤波前后的图像如图3所示。
![](<./assets/Pasted image 20250509033626.png>)
<center>图 3 滤波前后的图像</center>

要求输出：
1. IIR数字滤波器的幅频响应图；
2. RGB图像与灰度图像对比图；
3. 滤波前后图像对比图。

## 验收标准
1. 实验代码的独立性与完整性；
2. 实验设计合理，结果正确；
3. 对实验结果进行合理分析与思考。

# 代码部分
> [!important]
> 学姐提供的代码强依赖于`Matlab`且需要安装`DSP工具箱`，所以如果你使用了“绿色版”（我也被迫下载😭），在安装时**务必**选择该组件，否则你就需要重新安装`Matlab`. . . . . .
> > 因为离线的绿色版`Matlab`无法增量更新
>
> `Matlab`的`designfilt`函数生成的Butterworth滤波器和`butter`函数生成的滤波器精度相差很多，在实验二中无法使用`butter`函数实现滤掉文档中说明的`300Hz`波，因此出于通用性的考量，我在第二版代码中提升了频率到`300kHz`
>
> 由于学术诚信的考量，我不会将`Matlab`的运行结果贴在文章中，但是会将`GNU Octave`的结果贴在下面，如果你完全不在意真正的代码内容只是想水个实验，那么请参考`代码1`，如果你想使用`Syslab`或其他替代品，那么我建议你参考`代码2`
>
> 如果你使用了`GNU Octave`，需要安装`signal`包并在使用前在终端中输入`pkg load signal`，但是需要先安装`signal`包
> ```bash
> pkg install "https://downloads.sourceforge.net/project/octave/Octave%20Forge%20Packages/Individual%20Package%20Releases/signal-1.4.6.tar.gz"
> ```
> 你也可以先把包下载下来，然后在`pkg install`后输入下载后得到的本地文件路径
## 正弦波信号IIR数字滤波
### 代码1

```matlab
clear global;
%% 1. 正弦波信号IIR数字滤波
% 生成频率分别为120Hz、180Hz、240Hz正弦信号并进行叠加，其中 120Hz 正弦波幅度为 0.8，180Hz正弦波幅度为 2.4，240Hz正弦波幅度为 0.5
fs = 1000;              % 采样率
t = 0:1/fs:1;           % 时间向量
f1 = 120;               % 信号频率1
f2 = 180;               % 信号频率2
f3 = 240;               % 信号频率3
h1 = 0.8;                % 信号幅度1
h2 = 2.4;                % 信号幅度2
h3 = 0.5;             % 信号幅度3

x = h1*sin(2*pi*f1*t) + h2*sin(2*pi*f2*t) + h3*sin(2*pi*f3*t);   % 发送信号

figure(1)
plot(t,x);
xlabel('时间/s');
ylabel('幅度');
xlim([0, 0.3]);
title('发送信号');

%% 高斯噪声
% 对叠加的信号施加加性高斯白噪声，信噪比SNR=7dB
% 添加随机噪声

SNR_dB = 8;                  % 信噪比（dB）
SNR = 10^(SNR_dB/10);         % 信噪比（线性值）
P_signal = rms(x)^2;         % 信号功率
P_noise = P_signal / SNR;    % 噪声功率
noise = sqrt(P_noise) * randn(size(x));  % 生成随机噪声
rx = x + noise;               % 叠加噪声

figure(2)
plot(t,rx);
xlabel('时间/s');
ylabel('幅度');
xlim([0,0.3]);
title('接收信号');

%% IIR带通滤波器

bpFilt = designfilt('bandpassiir', ...
    'FilterOrder', 20, ...
    'HalfPowerFrequency1', 170, ...
    'HalfPowerFrequency2', 190, ...
    'DesignMethod', 'butter', ...
    'SampleRate', 1000);

fvtool(bpFilt); % 查看滤波器幅值响应
filt_rx = filter(bpFilt, rx); % 对接收信号rx进行滤波，使用上文设计的滤波器

%%
% 绘制发送信号、接受信号、滤波信号的时域波形图

figure(4);
subplot(3,1,1);
plot(t,x);
xlabel('时间/s');
ylabel('幅度');
title('发送信号');
subplot(3,1,2);
plot(t,rx);
xlabel('时间/s');
ylabel('幅度');
title('接收信号');
subplot(3,1,3);
plot(t,filt_rx);
xlabel('时间/s');
ylabel('幅度');
title('滤波信号');

%%
% 绘制发送信号、接受信号、滤波信号的频谱图

figure(5);
N = length(x); % 信号长度
f = (0:N-1)*(fs/N); % 频率向量
subplot(3,1,1);
X = fft(x)/N; % FFT变换并归一化
plot(f,abs(X))
xlabel('频率/Hz');
ylabel('幅度（归一化');
title('发送信号');

subplot(3,1,2);
RX = fft(rx)/N; % FFT变换并归一化
plot(f,abs(RX))
xlabel('频率/Hz');
ylabel('幅度（归一化');
title('接收信号');

subplot(3,1,3);
FILT_RX = fft(filt_rx)/N; % FFT变换并归一化
plot(f,abs(FILT_RX))
xlabel('频率/Hz');
ylabel('幅度（归一化');
title('滤波信号');
```

### 代码2
> 仅标记和代码1的不同之处

```diff
- bpFilt = designfilt('bandpassiir', ...
-     'FilterOrder', 20, ...
-     'HalfPowerFrequency1', 170, ...
-     'HalfPowerFrequency2', 190, ...
-     'DesignMethod', 'butter', ...
-     'SampleRate', 1000);
+ order = 10; % 阶数
+ Wn = [170 190]/(fs/2); % 归一化截止频率
+ [b,a] = butter(order, Wn, 'bandpass'); % 设计带通滤波器
- fvtool(bpFilt); % 查看滤波器幅值响应
+ figure(3);
+ freqz(b,a,fs);
- filt_rx = filter(bpFilt, rx); % 对接收信号rx进行滤波，使用上文设计的滤波器
+ filt_rx = filter(b, a, rx);
```
!![](<./assets/1.png>)
!![](<./assets/2.png>)
!![](<./assets/3.png>)
!![](<./assets/4.png>)
!![](<./assets/5.png>)

## 图像的IIR数字滤波
### 代码1
```matlab
%% 2、图像的IIR数字滤波
% 读取RGB图像，并转化为灰度图像

rawImg=imread('image.jpg');  %读取 jpg 图像
grayImg=rgb2gray(rawImg);  %生成灰度图像
[row,col]=size(grayImg);  %求图像长宽

figure(6)
subplot(1,2,1)
imshow(rawImg)
title('RGB图像')
subplot(1,2,2)
imshow(grayImg)
title('灰度图像')

%%
% 将灰度图像矩阵转化为一维数组，并加入300Hz正弦噪声干扰

normImgMartix=im2double(grayImg);  % 图像数据进行归一化
rawMartix=zeros(1,row*col);  % 初始化一维矩阵

for i=1:row
    for j=1:col
        rawMartix(col*(i-1)+j)=normImgMartix(i,j);
    end
end  %将 M*N 维矩阵变成 1 维矩阵

fs2 = row * col;  % 采样率
t2 = 0:1/fs2:1-1/fs2;  % 时间向量
f_noise = 0.5*sin(2*pi*300*t2);  % 300Hz干扰正弦噪声
rawMartixWithNoise=rawMartix + f_noise;% 加入噪声的序列
noiseMartix=zeros(row,col);

% 一维变 M*N 矩阵
for i=1:row
    for j=1:col
        noiseMartix(i,j)=rawMartixWithNoise(col*(i-1)+j);
    end
end

%% IIR带阻滤波器
bsFilt = designfilt('bandstopiir', ...
    'FilterOrder',20, ...
    'HalfPowerFrequency1',250,'HalfPowerFrequency2',350, ...
    'DesignMethod', 'butter', ...
    'SampleRate',1080*1080);

fvtool(bsFilt); % 查看滤波器幅值响应

raw_filt_Martix = filter(bsFilt, rawMartixWithNoise); % 进行滤波

filt_Martix=zeros(row,col);

% 一维变 M*N 矩阵
for i=1:row
    for j=1:col
        filt_Martix(i,j)=raw_filt_Martix(col*(i-1)+j);
    end
end

%%
% 绘制带有正弦噪声的图像和滤波后图像的对比图

figure(8)
subplot(1,2,1)
imshow(noiseMartix)
title('带有正弦噪声的图像')
subplot(1,2,2)
imshow(filt_Martix)
title('滤波后图像')
```
### 代码2
> 仅标记和代码1的不同之处
```diff
- f_noise = 0.5*sin(2*pi*300*t2);  % 300Hz干扰正弦噪声
+ f_noise = 0.5*sin(2*pi*300000*t2); % 300kHz干扰正弦噪声
- bpFilt = designfilt('bandstopiir', ...
-     'FilterOrder', 20, ...
-     'HalfPowerFrequency1', 250, ...
-     'HalfPowerFrequency2', 350, ...
-     'DesignMethod', 'butter', ...
-     'SampleRate', 1080*1080);
+ order_img = 10; % 阶数
+ Wn_img = [250000 350000]/(fs2/2); % 归一化截止频率
+ [b_img,a_img] = butter(order_img, Wn_img, 'stop'); % 设计带通滤波器
- fvtool(bpFilt); % 查看滤波器幅值响应
+ figure(7);
+ freqz(b_img,a_img,fs2);
- raw_filt_Martix = filter(bsFilt, rawMartixWithNoise); % 进行滤波
+ raw_filt_Martix = filter(b_img, a_img, rawMartixWithNoise); % 进行滤波
```
!![](<./assets/6.png>)
!![](<./assets/7.png>)
!![](<./assets/8.png>)
