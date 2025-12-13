% 画出内插之后的频域信道响应幅值图、相位图；画出时域信道响应图
% 画出PBCH中数据部分，信道补偿之前与之后的星座图

% 提取PBCH并完成DMRS基于LS的信道估计与均衡
% frame_data: 含SSB的单帧复数采样（列或行向量均可）
% ssb_start:  SSB起始子载波索引
% pss_peak_index: PSS峰值样点索引（以帧起点为参考）
% NID:        小区ID（来自SSS检测结果）
% 返回：
%   PBCH_data_eq - 均衡后的PBCH数据符号
%   H_all        - 576维的信道估计（含DMRS与插值数据）
%   H_data       - 数据子载波位置的信道估计（432维）
%   PBCH         - 解映射出的PBCH频域符号（未均衡）
%   data_index   - 数据子载波索引
%   dmrs_index   - DMRS子载波索引
function [PBCH_data_eq, H_all, H_data, PBCH, data_index, dmrs_index] = channel(frame_data, ssb_start, pss_peak_index, NID)

N_fft = 4096;
N_cp = 288;

% 保证行向量便于切片
frame_row = frame_data(:).';

% 三个PBCH符号的起点（相对帧起点）
pbch_symbol2_index = pss_peak_index + (N_fft + N_cp) * 1;  % 第2个符号
pbch_symbol3_index = pss_peak_index + (N_fft + N_cp) * 2;  % 第3个符号
pbch_symbol4_index = pss_peak_index + (N_fft + N_cp) * 3;  % 第4个符号

% 提取三个OFDM符号（时域）
pbch234 = [frame_row(pbch_symbol2_index:pbch_symbol2_index+N_fft-1); ...
		   frame_row(pbch_symbol3_index:pbch_symbol3_index+N_fft-1); ...
		   frame_row(pbch_symbol4_index:pbch_symbol4_index+N_fft-1)].';

% 频域变换
pbch234_f = zeros(N_fft, 3);
pbch234_f(:,1) = fftshift(fft(pbch234(:,1)));
pbch234_f(:,2) = fftshift(fft(pbch234(:,2)));
pbch234_f(:,3) = fftshift(fft(pbch234(:,3)));

fig1 = figure;
subplot(1,3,1); plot(log(abs(pbch234_f(:,1)))); title('PBCH Sym 1 Spectrum');
subplot(1,3,2); plot(log(abs(pbch234_f(:,2)))); title('PBCH Sym 2 Spectrum');
subplot(1,3,3); plot(log(abs(pbch234_f(:,3)))); title('PBCH Sym 3 Spectrum');
% 保存图像
saveas(fig1, 'assets/pbch_3symbols_spectrum.png');
savefig(fig1, 'assets/pbch_3symbols_spectrum.fig');
fprintf('已保存: assets/pbch_3symbols_spectrum.png\n');

% 解映射PBCH 576 个子载波
PBCH = zeros(576,1);
ssb_end = ssb_start + 240 - 1;
PBCH(1:240)   = pbch234_f(ssb_start:ssb_end, 1);
PBCH(241:288) = pbch234_f(ssb_start:ssb_start+47, 2);
PBCH(289:336) = pbch234_f(ssb_end-47:ssb_end, 2);
PBCH(337:576) = pbch234_f(ssb_start:ssb_end, 3);

fig2 = figure;
plot(real(PBCH), imag(PBCH), '.');
xlabel('In-Phase'); ylabel('Quadrature'); title('PBCH星座图'); grid on; axis equal;
% 保存图像
saveas(fig2, 'assets/pbch_constellation_before_eq.png');
savefig(fig2, 'assets/pbch_constellation_before_eq.fig');
fprintf('已保存: assets/pbch_constellation_before_eq.png\n');

% 计算数据与DMRS索引
v = mod(NID, 4);
data_index = [];
dmrs_index = [];
for i = 1:576
	if mod(i,4) ~= mod(v+1,4)
		data_index = [data_index, i];
	else
		dmrs_index = [dmrs_index, i];
	end
end

% 提取DMRS并做LS信道估计
PBCH_dmrs = PBCH(dmrs_index);
fig3 = figure;
plot(real(PBCH_dmrs), imag(PBCH_dmrs), '.');
xlabel('In-Phase'); ylabel('Quadrature'); title('DMRS星座图'); grid on; axis equal;
% 保存图像
saveas(fig3, 'assets/dmrs_constellation.png');
savefig(fig3, 'assets/dmrs_constellation.fig');
fprintf('已保存: assets/dmrs_constellation.png\n');

H_all = zeros(576,1);
% H_data = zeros(432,1);
dmrs = nrPBCHDMRS(NID,0);
H_dmrs = PBCH_dmrs ./ dmrs;
H_all(dmrs_index) = H_dmrs;

fig4 = figure; stem(abs(H_all(1:240))); title('内插之前的信道响应幅值（前240个子载波）');
xlabel('子载波索引'); ylabel('幅值');
saveas(fig4, 'assets/channel_magnitude_before_interp.png');
savefig(fig4, 'assets/channel_magnitude_before_interp.fig');
fprintf('已保存: assets/channel_magnitude_before_interp.png\n');

fig5 = figure; stem(angle(H_all(1:240))); title('内插之前的信道响应相位（前240个子载波）');
xlabel('子载波索引'); ylabel('相位 (rad)');
saveas(fig5, 'assets/channel_phase_before_interp.png');
savefig(fig5, 'assets/channel_phase_before_interp.fig');
fprintf('已保存: assets/channel_phase_before_interp.png\n');

% 插值得到数据子载波信道
H_data = interp1(dmrs_index, H_dmrs, data_index, 'linear');
H_all(data_index) = H_data;

fig6 = figure; stem(abs(H_all(1:240))); title('内插之后的信道响应幅值（前240个子载波）');
xlabel('子载波索引'); ylabel('幅值');
saveas(fig6, 'assets/channel_magnitude_after_interp.png');
savefig(fig6, 'assets/channel_magnitude_after_interp.fig');
fprintf('已保存: assets/channel_magnitude_after_interp.png\n');

fig7 = figure; stem(angle(H_all(1:240))); title('内插之后的信道响应相位（前240个子载波）');
xlabel('子载波索引'); ylabel('相位 (rad)');
saveas(fig7, 'assets/channel_phase_after_interp.png');
savefig(fig7, 'assets/channel_phase_after_interp.fig');
fprintf('已保存: assets/channel_phase_after_interp.png\n');

% 时域信道响应（通过IFFT转换）
% 先对频域信道响应归一化，以便看清时域结构
H_freq = H_all(1:240);
H_freq_normalized = H_freq / mean(abs(H_freq));  % 归一化到均值
h_time = ifft(H_freq_normalized);

% 只显示前面的抽头（信道能量主要集中在前面）
num_taps = 100;  % 显示前100个抽头
h_time_show = h_time(1:num_taps);

% 分解为I路和Q路
h_I = real(h_time_show);
h_Q = imag(h_time_show);
h_abs = abs(h_time_show);

fig_time = figure;
subplot(3,1,1);
stem(h_I, 'LineWidth', 1.2);
title('时域信道冲激响应 - I路（同相分量）');
xlabel('时延抽头');
ylabel('幅度');
grid on;
xlim([0 num_taps-1]);

subplot(3,1,2);
stem(h_Q, 'LineWidth', 1.2);
title('时域信道冲激响应 - Q路（正交分量）');
xlabel('时延抽头');
ylabel('幅度');
grid on;
xlim([0 num_taps-1]);

subplot(3,1,3);
stem(h_abs, 'LineWidth', 1.2, 'Color', [0.85 0.33 0.1]);
title('时域信道冲激响应 - 幅度');
xlabel('时延抽头');
ylabel('幅度');
grid on;
xlim([0 num_taps-1]);

saveas(fig_time, 'assets/channel_time_domain_response.png');
savefig(fig_time, 'assets/channel_time_domain_response.fig');
fprintf('已保存: assets/channel_time_domain_response.png\n');

% 功率延迟分布（dB刻度）
fig_pdp = figure;
power_db = 20*log10(h_abs + eps);  % 转为dB，eps避免log(0)
stem(0:num_taps-1, power_db, 'LineWidth', 1.5, 'Color', [0 0.45 0.74]);
grid on;
title('时域信道功率延迟分布 (Power Delay Profile)');
xlabel('时延抽头');
ylabel('功率 (dB)');
xlim([0 num_taps-1]);

saveas(fig_pdp, 'assets/channel_power_delay_profile.png');
savefig(fig_pdp, 'assets/channel_power_delay_profile.fig');
fprintf('已保存: assets/channel_power_delay_profile.png\n');

% 均衡PBCH数据
PBCH_data_eq = PBCH(data_index) ./ H_data.';

fig8 = figure;
hold on;
% 绘制坐标轴参考线（通过原点）
plot([-5 5], [0 0], 'k-', 'LineWidth', 0.5);  % x轴
plot([0 0], [-5 5], 'k-', 'LineWidth', 0.5);  % y轴
% 绘制星座点
plot(real(PBCH_data_eq), imag(PBCH_data_eq), 'b.', 'MarkerSize', 8);
xlim([-1 1]);
ylim([-1 1]);
axis square;  % 使用 axis square 保持坐标轴范围并确保正方形显示
grid on;
xlabel('In-Phase');
ylabel('Quadrature');
title('信道均衡之后的PBCH数据星座图');
hold off;
% 保存图像
saveas(fig8, 'assets/pbch_constellation_after_eq.png');
savefig(fig8, 'assets/pbch_constellation_after_eq.fig');
fprintf('已保存: assets/pbch_constellation_after_eq.png\n');

end
