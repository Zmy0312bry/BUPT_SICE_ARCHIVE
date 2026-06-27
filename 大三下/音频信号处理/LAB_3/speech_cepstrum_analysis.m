% 读取语音文件
[signal, fs] = audioread('test_16k.wav');
signal = signal(:, 1); % 取单声道

% 参数设置
N = 400;                        % 帧长（样本数）
window = hamming(N);            % 汉明窗

% 提取浊音段（始于第13000个样本）
voiced_start = 13000;
voiced_signal = signal(voiced_start:voiced_start+N-1) .* window;

% 提取清音段（始于第3400个样本）
unvoiced_start = 3400;
unvoiced_signal = signal(unvoiced_start:unvoiced_start+N-1) .* window;

%% 计算并绘制浊音信号的倒谱
figure('Name', '浊音信号分析', 'Position', [100, 100, 1200, 800]);

% 时域波形
subplot(3,2,1);
t = (0:N-1)/fs;
plot(t, voiced_signal, 'b', 'LineWidth', 1);
title('浊音段时域波形');
xlabel('时间 (s)');
ylabel('幅度');
grid on;

% 对数幅度谱
subplot(3,2,2);
X_voiced = fft(voiced_signal);
mag_spec = abs(X_voiced(1:N/2));
log_mag = log(mag_spec + eps);
f_axis = (0:N/2-1) * fs / N;
plot(f_axis, log_mag, 'b', 'LineWidth', 1);
title('对数幅度谱');
xlabel('频率 (Hz)');
ylabel('幅度 (dB)');
grid on;

% 实倒谱（使用 rceps 函数）
subplot(3,2,3);
rcep_voiced = rceps(voiced_signal);
plot(t, rcep_voiced, 'r', 'LineWidth', 1);
title('实倒谱 (rceps)');
xlabel('倒频时间 (s)');
ylabel('幅度');
grid on;

% 复倒谱（使用 cceps 函数）
subplot(3,2,4);
ccep_voiced = cceps(voiced_signal);
plot(t, ccep_voiced, 'r', 'LineWidth', 1);
title('复倒谱 (cceps)');
xlabel('倒频时间 (s)');
ylabel('幅度');
grid on;

% 从倒谱中估计基音周期（手动方法，替代 pitch 函数）
subplot(3,2,5);
% 寻找实倒谱中的峰值（排除前几个样本，对应频谱包络）
[peaks, peak_locs] = findpeaks(rcep_voiced, 'MinPeakHeight', max(rcep_voiced(50:end))*0.3);
peak_locs = peak_locs(peak_locs > 20); % 排除过低倒频
if ~isempty(peak_locs)
    f0_est = fs / peak_locs(1);
    % fprintf('浊音段估计基频（从倒谱峰值）: %.2f Hz (周期约 %.2f ms)\n', f0_est, 1000/f0_est);
    plot(t, rcep_voiced, 'b', 'LineWidth', 1);
    hold on;
    plot(t(peak_locs(1)), rcep_voiced(peak_locs(1)), 'ro', 'MarkerSize', 10, 'LineWidth', 2);
    title(['浊音实倒谱（基频: ', num2str(f0_est, '%.1f'), ' Hz）']);
else
    plot(t, rcep_voiced, 'b', 'LineWidth', 1);
    title('浊音实倒谱（未检测到明显峰值）');
end
xlabel('倒频时间 (s)');
ylabel('幅度');
grid on;

% 低倒频滤波后的对数幅度谱（平滑谱包络）
subplot(3,2,6);
% 对实倒谱进行低通滤波（保留前20个倒频系数）
quefrency_domain = rcep_voiced;
quefrency_domain(21:end) = 0;  % 保留低倒频部分
smoothed_log_spec = real(fft(quefrency_domain));
smoothed_log_spec = smoothed_log_spec(1:N/2);
plot(f_axis, log_mag, 'b', 'LineWidth', 1);
hold on;
plot(f_axis, smoothed_log_spec, 'r', 'LineWidth', 2);
title('低倒频滤波后的对数幅度谱');
xlabel('频率 (Hz)');
ylabel('幅度 (dB)');
legend('原始', '平滑后', 'Location', 'best');
grid on;
hold off;

%% 清音信号分析
figure('Name', '清音信号分析', 'Position', [100, 100, 1200, 800]);

subplot(3,2,1);
plot(t, unvoiced_signal, 'b', 'LineWidth', 1);
title('清音段时域波形');
xlabel('时间 (s)');
ylabel('幅度');
grid on;

subplot(3,2,2);
X_unvoiced = fft(unvoiced_signal);
mag_spec_unv = abs(X_unvoiced(1:N/2));
log_mag_unv = log(mag_spec_unv + eps);
plot(f_axis, log_mag_unv, 'b', 'LineWidth', 1);
title('对数幅度谱');
xlabel('频率 (Hz)');
ylabel('幅度 (dB)');
grid on;

subplot(3,2,3);
rcep_unvoiced = rceps(unvoiced_signal);
plot(t, rcep_unvoiced, 'r', 'LineWidth', 1);
title('实倒谱 (rceps) - 清音');
xlabel('倒频时间 (s)');
ylabel('幅度');
grid on;

subplot(3,2,4);
ccep_unvoiced = cceps(unvoiced_signal);
plot(t, ccep_unvoiced, 'r', 'LineWidth', 1);
title('复倒谱 (cceps) - 清音');
xlabel('倒频时间 (s)');
ylabel('幅度');
grid on;

% 清音倒谱分析（应该没有明显峰值）
subplot(3,2,5);
plot(t, rcep_unvoiced, 'b', 'LineWidth', 1);
title('清音实倒谱（无明显峰值，无周期性结构）');
xlabel('倒频时间 (s)');
ylabel('幅度');
grid on;

% 清音低倒频滤波
subplot(3,2,6);
quefrency_domain_unv = rcep_unvoiced;
quefrency_domain_unv(21:end) = 0;
smoothed_log_spec_unv = real(fft(quefrency_domain_unv));
smoothed_log_spec_unv = smoothed_log_spec_unv(1:N/2);
plot(f_axis, log_mag_unv, 'b', 'LineWidth', 1);
hold on;
plot(f_axis, smoothed_log_spec_unv, 'r', 'LineWidth', 2);
title('低倒频滤波后的对数幅度谱');
xlabel('频率 (Hz)');
ylabel('幅度 (dB)');
legend('原始', '平滑后', 'Location', 'best');
grid on;
hold off;

%% 对比分析：浊音 vs 清音
figure('Name', '浊音与清音倒谱对比', 'Position', [100, 100, 1000, 500]);

subplot(2,2,1);
plot(t, rcep_voiced, 'b', 'LineWidth', 1);
title('浊音 - 实倒谱（有明显峰值）');
xlabel('倒频时间 (s)');
ylabel('幅度');
grid on;

subplot(2,2,2);
plot(t, rcep_unvoiced, 'r', 'LineWidth', 1);
title('清音 - 实倒谱（无峰值）');
xlabel('倒频时间 (s)');
ylabel('幅度');
grid on;

subplot(2,2,3);
plot(t, ccep_voiced, 'b', 'LineWidth', 1);
title('浊音 - 复倒谱');
xlabel('倒频时间 (s)');
ylabel('幅度');
grid on;

subplot(2,2,4);
plot(t, ccep_unvoiced, 'r', 'LineWidth', 1);
title('清音 - 复倒谱');
xlabel('倒频时间 (s)');
ylabel('幅度');
grid on;
