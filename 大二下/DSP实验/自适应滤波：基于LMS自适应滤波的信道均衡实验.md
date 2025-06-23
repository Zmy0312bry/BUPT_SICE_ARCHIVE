# 题目概述
## 1. 实验目的

- 了解码间干扰的产生原理；
- 学习自适应滤波的基本原理；
- 掌握基于LMS自适应滤波器的设计方法与MATLAB实现方式；
- 掌握使用MATLAB模拟通信过程的仿真方法；
- 学习眼图和误码率两种评判通信系统性能的指标。

## 2. 实验内容

### 实验基本原理

设有信号长度为 $N$ 的比特序列通过通信系统进行传输，如图1所示。首先将比特序列映射为双极性不归零码，映射关系为比特0映射为-1电平，比特1映射为1电平。然后，将映射后的符号通过信道进行传输。最后接收端通过接收到的信号进行判决，小于0的信号将被判决为比特0，大于0的信号将被判决为比特1。
<center><img src="https://i-blog.csdnimg.cn/direct/33b27b0b732b4a43850196d0f83e887a.png"/></center>
<center>图1 通信过程</center>

信道存在两种干扰，码间干扰和加性高斯白噪声干扰。所谓码间干扰，是指数字基带信号通过基带传输系统时，由于系统（主要是信道）传输特性不理想，或者由于信道中加性噪声的影响，使收端脉冲展宽，延伸到邻近码元中去，从而造成对邻近码元的干扰。图2给出了码间干扰的示意。

<center><img src="https://i-blog.csdnimg.cn/direct/89d5872f4f2540d585a68f362f77c812.png"/></center>
<center>图2 码间干扰示意图</center>

码间干扰讲解视频：[通信原理 - 北京邮电大学 - 学堂在线](https://www.xuetangx.com/learn/BUPT08071000042/BUPT08071000042/1075933/video/642939?channel=i.area.manual_search)

由于存在码间干扰，导致通信的误符号率较大，因此使用自适应均衡来减少码间干扰对系统性能的影响，如图3所示。利用可调滤波器去补偿基带系统的传输特性，使包括可调滤波器在内的基带系统的总传输特性满定实际性能的要求，这种起补偿作用的滤波器被称为均衡器。自适应均衡也是一种均衡器，本次实验使用基于LMS的自适应均衡器，有关基于LMS的自适应均衡器可以查阅资料。

<center><img src="https://i-blog.csdnimg.cn/direct/90c33f3a059141a5986a61ca1d637c2f.png"/></center>
<center>图3 自适应均衡</center>

时域均衡讲解视频：[【通信原理】第5章 数字基带传输系统-27.均衡技术](https://www.bilibili.com/video/BV1k54y1f79T/?spm_id_from=333.337.search-card.all.click&vd_source=ed1ddd615368036da617ce020366429a)

眼图可以用来评判通信系统的性能，用示波器观察接收滤波器后的信号，可以得到眼图。由于示波器荧光屏光迹暂留，可以观察到类似人眼的波形图，即所谓的眼图，如图4所示。

<center><img src="https://i-blog.csdnimg.cn/direct/03b3625c5d2e40e5b0511e56836d2b31.png"/></center>
<center>图4 眼图形成示意</center>

通过观察眼图，如图5所示，可以得到以下系统性能信息：
- 眼图的眼睛张开的大小反映码间干扰的强弱；
- 最佳抽样时刻：张开最大时刻；
- 最佳判决门限电平：中央横轴；
- 定时误差的灵敏度：斜边的斜率。越陡越灵敏，对定时要求越高；
- 信号畸变范围：垂直高度；
- 过零点畸变范围：水平宽度；
- 噪声容限：抽样时刻眼睛张开高度的一半，噪声超过此值即出错。

<center><img src="https://i-blog.csdnimg.cn/direct/1e66bc25cbed4f59b2f0ec2b05ab2454.png"/></center>
<center>图5 眼图</center>
### 实验步骤

首先，使用MATLAB设计图1不含自适应滤波的通信系统，规定信号长度为10000，码间干扰信道参数为：**\[0.05 -0.063 0.088 -0.126 -0.25 0.9047 0.25 0 0.126 0.038 0.088\]**。

在信噪比为8到18dB的情况下仿真得到模型的误符率，并绘制没有自适应滤波的眼图。然后，设计图3含自适应滤波的通信系统，设计基于LMS的自适应滤波器，除滤波器外的其它参数与图1不含自适应滤波的通信系统相同。在信噪比为8到18dB的情况下仿真得到模型的误符率，并绘制自适应滤波后的眼图。

## 3. 实验要求

- 不含自适应滤波与含自适应滤波的误符率曲线对比图；
- 没有自适应滤波的眼图；
- 自适应滤波后的眼图。
## 4. 验收标准

- 实验代码的独立性与完整性；
- 找到合适的自适应均衡器的步长$delta$；
- 画出效果较好的眼图（清晰，开口明显，像眼睛一样）

可以参考：[【通信原理】第5章 数字基带传输系统-26.眼图](https://www.bilibili.com/video/BV1ja411J7S8/?spm_id_from=333.337.search-card.all.click&vd_source=ed1ddd615368036da617ce020366429a)

例如：
<center><img src="https://i-blog.csdnimg.cn/direct/1b8b75caf23b4028afc9c81da785b23c.png"/></center>

# 代码部分

## `Matlab`代码

```matlab
clear;clc;echo off;close all;
%% gngauss.m
function [ gsrv1,gsrv2 ] = gngauss( m,sgma )
%产生高斯白噪声
if nargin ==0       %如果没有输入实参，则均方为0，标准差为1
    m=0; sgma=1;
elseif nargin ==1   %如果输入实参为1个参数，则标准差为输入实参，均值为0
    sgma=m; m=0;
end
u=rand;
z=sgma*(sqrt(2*log(1/(1-u))));
u=rand;
gsrv1=m+z*cos(2*pi*u);
gsrv2=m+z*sin(2*pi*u);
end

%% channel.m
function [ y,len ] = channel( x,snr_in_dB )
%模拟既有码间干扰又有高斯白噪声的信道
SNR=exp(snr_in_dB*log(10)/10);   %信噪比真值转换
sigma=1/sqrt(2*SNR);             %高斯白噪声的标准差
%指定信道的ISI参数，可以看出此信道质量还是比较差的
actual_isi=[0.05 -0.063 0.088 -0.126 -0.25 0.9047 0.25 0 0.126 0.038 0.088];
len_actual_isi=(length(actual_isi)-1)/2;
len=len_actual_isi;
y=conv(actual_isi,x);             %信号通过信道，相当于信号序列与信道模型序列作卷积
%需要指出，此时码元序列长度变为N+L=N+2len+1-1，译码时我们从第len个码元开始到N+len个结束
for i=1:2:size(y,2)
    [noise(i),noise(i+1)]=gngauss(sigma); %产生噪声
end
y=y+noise;                                %叠加噪声
%也可直接用y = awgn(y,SNR)
end

%% random_binary.m
function [ info ] = random_binary( N )

if nargin == 0      %nargin表示所引用的函数的输入参数的个数
    N=10000;         %如果没有输入参数，则指定信息序列为10000个码元
end
info=zeros(1,N);   %初始化信息序列
for i=1:N
    temp=rand;
    if(temp<0.5)
        info(i)=-1;  %1/2的概率
    else
        info(i)=1;
    end
end
end

%% lms_equalizer.m
function [ z ] = lms_equalizer( y,info,delta )
%LMS算法自适应滤波器实现
estimated_c=[0 0 0 0 0 1 0 0 0 0 0]; %初始抽头系数(长度应该是和channel中信道阶数相同=11)
K=5;                                 %K=（length（estimated_c）-1）/2
for k=1:size(y,2)-2*K                %channel中返回参数len的长度也是5，K的选择便是基于len，需要K=len
     y_k=y(k:k+2*K);                 %获取码元，一次11个
     z_k=estimated_c*y_k';           %各抽头系数与码元相乘后求和
     e_k=info(k)-z_k;                %误差估计
     estimated_c=estimated_c+delta * e_k * y_k;   %计算校正抽头系数
     z(k)=z_k;                       %均衡后输出的码元序列
end
%误差e=d-y，（y指经过信道后的输出信号）这里期望信号d使用的是输入信号info
%比较误码率都是只比较info的长度N
%size(y,2)返回y的列数=N+L-1（L=2len+1）,则size(y,2)-2*K=N+L-(2K+1)=N+2(len-K)
%这里将会有个弊端：如果len>K，则k=1：N+2(len-K)会超过info的长度N.
end

%% main.m

N=10000;                 %指定信号序列长度

info=random_binary(N);   %产生双极性不归零基带信号序列

SNR_in_dB=8:1:18;        %AWGN信道信噪比

Pe=zeros(1,length(SNR_in_dB)); %初始化误码率
Pee=zeros(1,length(SNR_in_dB)); %初始化误码率

for j=1:length(SNR_in_dB)
    [y,len]=channel(info,SNR_in_dB(j));  %通过既有码间干扰又有高斯白噪声信道
    numoferr=0;                          %初始误码统计数
    for i=len+1:N+len                    %从第len个码元开始为真实信号码元
        if (y(i)<0)                      %判决译码
            decis=-1;
        else
            decis=1;
        end
        if(decis~=info(i-len))          %判断是否误码，统计误码码元个数
            numoferr=numoferr+1;
        end
    end
    Pe(j)=numoferr/N;                    %未经均衡器均衡，得到的误码率
end
semilogy(SNR_in_dB,Pe,'red*-');          %未经均衡器，误码率结果图
hold on;                             %semilogy表示y坐标轴是对数坐标系
%%%%%
delta=0.01;     %自己指定自适应均衡器的步长1
% delta_2=0.2;     %指定自适应均衡器的步长2
% delta_3=0.5;     %指定自适应均衡器的步长3

for j=1:length(SNR_in_dB)
    y=channel(info,SNR_in_dB(j));        %通过信道
    z=lms_equalizer(y,info,delta);     %通过自适应均衡器，并设置步长
    numoferr=0;
    for i=1:N
        if (z(i)<0)
            decis=-1;
        else
            decis=1;
        end
        if (decis~=info(i))
            numoferr=numoferr+1;
        end
    end
    Pee(j)=numoferr/N;                   %经自适应均衡器均衡后，得到的误码率
end
semilogy(SNR_in_dB,Pee,'black*-');       %自适应均衡器均衡之后，误码率结果图
hold on;
xlabel('SNR in dB');
ylabel('Pe');
title('ISI信道自适应均衡系统仿真');
%%%%%填写你尝试的步长
str = sprintf('经自适应均衡器均衡，步长detla= %f',delta);
legend('未经均衡器均衡',str);
eyediagram(y(500:1000),10);             %均衡前眼图
eyediagram(z(500:1000),10);             %均衡后眼图
```
## 运行结果

> 以下结果是使用`GNU Octave`运行的
>
> 使用前需要导入`communications`
> ```bash
> pkg load communications
> ```
> `GNU Octave`的中文存在问题，自行忽略吧😅

<center><img src="https://i-blog.csdnimg.cn/direct/2f765bf014ca426c99e4d84e37e0d1d7.png"/></center>

<center><img src="https://i-blog.csdnimg.cn/direct/39770937a6544232b3878d5f574187a3.png"/></center>

<center><img src="https://i-blog.csdnimg.cn/direct/abf2575e4ac54ec2a90de52586148f3c.png"/></center>
