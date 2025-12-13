% 画出PSS相关图，返回最大相关峰对应的小区ID(NID2)和峰值索引
% pss_peak_index 的参考点：以当前帧首个采样点为 0 偏移的时域索引
function [NID2, pss_peak_index, best_frame] = pss(Rx_data, total_frame, ssb_start)
frame_length = 1228800;  % 每帧采样点数
N_fft = 4096;
% N_cp = 288;

% 结果占位
peak = 0;
NID2 = 0;
pss_peak_index = 0;
best_frame = 1;
best_corr = [];
best_lag = [];

for frm = 1:total_frame
	frm_start = 1 + (frm - 1) * frame_length;
	frm_stop = frm * frame_length;
	frame = Rx_data(frm_start:frm_stop);

	for num = 0:2  % 轮询三个候选的 NID2
		pss_seq = nrPSS(num);

		% 构造频域 PSS 符号（放置在 SSB 子载波上）
		A = zeros(1, N_fft);
		pss_len = length(pss_seq);
		A(ssb_start + 56 : ssb_start + 56 + pss_len - 1) = pss_seq;

		% 生成时域 PSS OFDM 符号
		pss_time = ifft(ifftshift(A), N_fft);

		% 与接收帧做互相关，寻找峰值
		[corr_val, lag] = xcorr(frame, pss_time, 'none');
		[curr_peak, idx] = max(abs(corr_val));

		if curr_peak > peak
			peak = curr_peak;
			NID2 = num;
			best_frame = frm;
			pss_peak_index = lag(idx);  % 以当前帧起点为参考的样点偏移
			best_corr = corr_val;
			best_lag = lag;
		end
	end
end

% 可视化最佳相关结果
fig = figure;
plot(best_lag, abs(best_corr));
xlabel('Lag (samples)');
ylabel('|Correlation|');
title(sprintf('PSS correlation (frame %d, NID2 = %d)', best_frame, NID2));
grid on;
% 保存图像
saveas(fig, 'assets/pss_correlation.png');
savefig(fig, 'assets/pss_correlation.fig');
fprintf('已保存: assets/pss_correlation.png\n');

% 打印参考信息
disp(['检测到的NID2：', num2str(NID2)]);
disp(['相关峰所在帧号：', num2str(best_frame), ...
	  '，PSS起始索引（以帧起点为参考）：', num2str(pss_peak_index)]);
