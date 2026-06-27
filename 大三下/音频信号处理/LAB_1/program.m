% 语音信号分析程序
% 读取语音文件并绘制波形、短时能量、短时幅度和短时过零率

% 读取语音文件
[y, Fs] = audioread('speech.wav');  % 假设语音文件名为 speech.wav

% 如果语音是双声道，取单声道
if size(y, 2) > 1
    y = y(:, 1);
end

% 参数设置
frame_len = 256;  % 帧长
frame_shift = 128;  % 帧移

% 计算帧数
N = length(y);
num_frames = floor((N - frame_len) / frame_shift) + 1;

% 初始化短时能量、短时幅度和短时过零率
E = zeros(1, num_frames);
M = zeros(1, num_frames);
Z = zeros(1, num_frames);

% 分帧计算
for i = 1:num_frames
    start_idx = (i-1) * frame_shift + 1;
    end_idx = start_idx + frame_len - 1;
    frame = y(start_idx:end_idx);

    % 短时能量
    E(i) = sum(frame.^2);

    % 短时幅度
    M(i) = sum(abs(frame));

    % 短时过零率
    Z(i) = sum(abs(sign(frame(2:end)) - sign(frame(1:end-1))) / 2);
end

% 计算时间轴
time_axis = (0:N-1) / Fs;
frame_time = ((0:num_frames-1) * frame_shift + frame_len/2) / Fs;

% 绘图
figure('Position', [100, 100, 1200, 800]);

% 子图1：原始语音波形
subplot(4, 1, 1);
plot(time_axis, y, 'b');
xlabel('时间 (s)');
ylabel('幅度');
title('原始语音波形');
grid on;

% 子图2：短时能量
subplot(4, 1, 2);
plot(frame_time, E, 'r');
xlabel('时间 (s)');
ylabel('能量');
title('短时能量 E_n');
grid on;

% 子图3：短时幅度
subplot(4, 1, 3);
plot(frame_time, M, 'g');
xlabel('时间 (s)');
ylabel('幅度');
title('短时幅度 M_n');
grid on;

% 子图4：短时过零率
subplot(4, 1, 4);
plot(frame_time, Z, 'm');
xlabel('时间 (s)');
ylabel('过零率');
title('短时过零率 Z_n');
grid on;

% 调整子图间距
sgtitle('语音信号分析结果');
