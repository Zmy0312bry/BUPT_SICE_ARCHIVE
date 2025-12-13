% 计算得到NID，画出检测的SSS相关峰图、SSS星座图
% 输入：
%   frame_data      - 单帧复数采样（PSS检测出的那一帧）
%   ssb_start       - SSB起始子载波索引（与PSS/PBCH一致）
%   pss_peak_index  - PSS相关峰所在的样点索引，参考点为帧起点
% 输出：
%   NID1, NID2, NID - 检测得到的小区ID分量与完整NID
function [NID1, NID2, NID] = sss(frame_data, ssb_start, pss_peak_index)

N_fft = 4096;
N_cp = 288;

% 计算SSS符号的起止位置：PSS之后两个OFDM符号为SSS
sss_symbol_start_idx = pss_peak_index + (N_fft + N_cp) * 2;
sss_symbol_end_idx = sss_symbol_start_idx + N_fft - 1;

% 提取SSS所在OFDM符号（时域）
sss_symbol_t = frame_data(sss_symbol_start_idx:sss_symbol_end_idx);

% 频域符号并画频谱
sss_symbol_f = fftshift(fft(sss_symbol_t));
fig1 = figure;
plot(log(abs(sss_symbol_f)));
title('SSS OFDM Symbol Spectrum');
xlabel('Subcarrier index');
ylabel('log|X(k)|');
grid on;
% 保存图像
saveas(fig1, 'assets/sss_spectrum.png');
savefig(fig1, 'assets/sss_spectrum.fig');
fprintf('已保存: assets/sss_spectrum.png\n');

% 提取SSS子载波（127个），并画星座
sss_start = ssb_start + 56;
sss_end = sss_start + 127 - 1;
sss_f = sss_symbol_f(sss_start:sss_end);
fig2 = figure;
plot(real(sss_f), imag(sss_f), 'b.', 'MarkerSize', 10);
title('Received SSS Constellation');
xlabel('In-Phase');
ylabel('Quadrature');
grid on;
axis equal;
% 保存图像
saveas(fig2, 'assets/sss_constellation.png');
savefig(fig2, 'assets/sss_constellation.fig');
fprintf('已保存: assets/sss_constellation.png\n');

% 穷举NID1(0..335)、NID2(0..2)寻找最大相关
peak_sss = 0;
NID1 = 0;
NID2 = 0;
NID = 0;
best_corr = [];

for nid2 = 0:2
	for nid1 = 0:335
		nid = nid1 * 3 + nid2;
		sss_gen = nrSSS(nid);

		[corr_val, ~] = xcorr(sss_f, sss_gen, 'none');
		curr_peak = max(abs(corr_val));

		if curr_peak > peak_sss
			peak_sss = curr_peak;
			NID1 = nid1;
			NID2 = nid2;
			NID = nid;
			best_corr = corr_val;
		end
	end
end

% 画出最佳相关曲线并标记峰值
fig3 = figure;
plot(abs(best_corr));
grid on;
title(sprintf('SSS Correlation (NID1=%d, NID2=%d, NID=%d)', NID1, NID2, NID));
xlabel('Lag index');
ylabel('|Correlation|');
hold on;
[max_val, max_idx] = max(abs(best_corr));
plot(max_idx, max_val, 'ro', 'MarkerSize', 8, 'LineWidth', 2);
text(max_idx, max_val, sprintf('  Peak: %.2f @ %d', max_val, max_idx), 'FontSize', 10);
hold off;
% 保存图像
saveas(fig3, 'assets/sss_correlation.png');
savefig(fig3, 'assets/sss_correlation.fig');
fprintf('已保存: assets/sss_correlation.png\n');

disp(['检测到的NID1：', num2str(NID1), '，NID2：', num2str(NID2), ...
	  '，NID：', num2str(NID)]);
