%% main_adpcm.m  Jayant ADPCM 语音编解码器主脚本
%  读取 speech.wav → ADPCM 编码 → 解码 → 计算 SNR → 绘制波形图

clear; clc; close all;

%% 1. 读取语音文件
[x_raw, fs] = audioread('speech.wav');
if size(x_raw, 2) > 1
    x_raw = x_raw(:, 1);  % 取单声道
end
N = length(x_raw);
fprintf('语音文件: speech.wav\n');
fprintf('采样率: %d Hz, 采样点数: %d, 时长: %.2f s\n', fs, N, N/fs);

%% 2. 设置参数
alpha = 0.6;                                    % 一阶预测器系数
M = [0.9, 0.9, 0.9, 0.9, 1.2, 1.6, 2.0, 2.4]; % 步长自适应乘数表 (DPCM, B=4)
deltamin = 16;                                   % 步长最小值
deltamax = 1600;                                 % 步长最大值
delta_table = linspace(deltamin, deltamax, 100); % 步长查找表 (100 级)

%% 3. 信号缩放与初始步长
% 量化器最大输出 = 7/8 * deltamax = 1400
% 信号峰值应落入量化器覆盖范围
scale_factor = 2000;
x = x_raw * scale_factor;
fprintf('信号范围: [%.1f, %.1f] (缩放后)\n', min(x), max(x));

% 根据信号峰值自动选择初始步长
peak = max(abs(x));
delta_init = max(deltamin, min(deltamax, peak));
[~, init_idx] = min(abs(delta_table - delta_init));
delta_init = delta_table(init_idx);
fprintf('初始步长: %.1f (基于信号峰值 %.1f)\n', delta_init, peak);

fprintf('参数: alpha=%.1f, deltamin=%d, deltamax=%d, 步长级数=%d\n', ...
    alpha, deltamin, deltamax, length(delta_table));
fprintf('乘数表 M = [%.1f %.1f %.1f %.1f %.1f %.1f %.1f %.1f]\n', M);

%% 3. ADPCM 编码
fprintf('\n正在编码...\n');
tic;
[codes, x_recon_enc, step_sizes_enc] = adpcm_encoder(x, alpha, M, delta_table, deltamin, deltamax, delta_init);
t_enc = toc;
fprintf('编码完成，耗时 %.3f s\n', t_enc);

%% 4. ADPCM 解码
fprintf('正在解码...\n');
tic;
[x_recon_dec, step_sizes_dec] = adpcm_decoder(codes, alpha, M, delta_table, deltamin, deltamax, delta_init);
t_dec = toc;
fprintf('解码完成，耗时 %.3f s\n', t_dec);

%% 5. 验证编解码一致性
recon_diff = max(abs(x_recon_enc - x_recon_dec));
fprintf('\n编码器与解码器重建信号最大差异: %.2e\n', recon_diff);

%% 6. 计算 SNR（在原始信号尺度上比较）
x_recon_dec_orig = x_recon_dec / scale_factor;  % 缩放回原始范围
error = x_raw - x_recon_dec_orig;
signal_power = sum(x_raw.^2);
noise_power = sum(error.^2);

if noise_power > 0
    SNR = 10 * log10(signal_power / noise_power);
else
    SNR = Inf;
end

fprintf('\n========== 结果 ==========\n');
fprintf('信号功率: %.4f\n', signal_power);
fprintf('噪声功率: %.4f\n', noise_power);
fprintf('SNR = %.2f dB\n', SNR);
fprintf('===========================\n');

%% 7. 绘制波形图
t = (0:N-1) / fs;  % 时间轴 (秒)

figure('Name', 'Jayant ADPCM 语音编解码结果', 'Position', [100 100 900 700]);

% 子图1: 原始语音
subplot(3, 1, 1);
plot(t, x_raw, 'b', 'LineWidth', 0.5);
xlabel('时间 (s)');
ylabel('幅度');
title('原始语音信号');
xlim([0, t(end)]);
grid on;

% 子图2: 解码语音
subplot(3, 1, 2);
plot(t, x_recon_dec_orig, 'r', 'LineWidth', 0.5);
xlabel('时间 (s)');
ylabel('幅度');
title(sprintf('ADPCM 解码语音 (SNR = %.2f dB)', SNR));
xlim([0, t(end)]);
grid on;

% 子图3: 误差信号
subplot(3, 1, 3);
plot(t, error, 'k', 'LineWidth', 0.3);
xlabel('时间 (s)');
ylabel('幅度');
title('误差信号 (原始 - 解码)');
xlim([0, t(end)]);
grid on;

sgtitle(sprintf('Jayant ADPCM (B=4, \\alpha=%.1f)', alpha));
