function ssb_start_idx = ssb_start_func(Rx_data, pointA, dl_offsetToCarrier, ~, subcarrier_spacing)

% 固定参数
N_fft = 4096;                % FFT大小
ssb_width = 240;             % SSB占用240个子载波
center_idx = N_fft/2 + 1;    % fftshift后DC中心位置 = 2049
ssb_raster = 1.44e6;         % SSB频点栅格间隔 1.44MHz
base_freq = 3e9;             % 基准频率 3GHz
num_prb = 273;               % 100MHz @ 30kHz SCS 对应 273个PRB
frame_length = 1228800;      % 每帧采样点数

% 步骤1：计算PointA对应的频率
% 公式：f_pointA = (PointA - 600000) × 15kHz + 3GHz
f_pointA = (pointA - 600000) * 15e3 + base_freq;  % Hz

% 步骤2：计算接收机中心频率
% 接收机中心频率 = PointA + 载波偏移 + 载波带宽的一半
f_rx_center = f_pointA + dl_offsetToCarrier + (num_prb * 12 / 2) * subcarrier_spacing;

% 步骤3：计算SSB位置的搜索范围
% 限制：ssb_start位于410~2048之间
ssb_start_min = 410;
ssb_start_max = 2048;
ssb_center_min = ssb_start_min + 120;  % 530
ssb_center_max = ssb_start_max + 120;  % 2168

% 将FFT索引范围转换为频率范围
f_ssb_min = f_rx_center + (ssb_center_min - center_idx) * subcarrier_spacing;
f_ssb_max = f_rx_center + (ssb_center_max - center_idx) * subcarrier_spacing;

% 步骤4：爬格子遍历SSB同步频点栅格
k_min = ceil((f_ssb_min - base_freq) / ssb_raster);
k_max = floor((f_ssb_max - base_freq) / ssb_raster);

fprintf('\n===== SSB起始子载波计算（爬格子法+PSS相关检测） =====\n');
fprintf('pointA: %d\n', pointA);
fprintf('f_pointA: %.6f MHz\n', f_pointA/1e6);
fprintf('接收机中心频率 f_rx_center: %.6f MHz\n', f_rx_center/1e6);
fprintf('搜索频率范围: %.6f ~ %.6f MHz\n', f_ssb_min/1e6, f_ssb_max/1e6);
fprintf('栅格索引范围: k = %d ~ %d\n', k_min, k_max);
fprintf('\n开始PSS相关检测...\n');

% 步骤5：对每个候选位置进行PSS相关检测
% 计算总帧数
total_frames = floor(length(Rx_data) / frame_length);
if total_frames < 1
    error('接收数据长度不足一帧');
end

% 遍历所有候选的SSB位置和所有可能的NID2
max_corr_peak = 0;
best_ssb_start = -1;
best_k = -1;
best_NID2 = -1;
best_frame = -1;

for k = k_min:k_max
    % 计算该栅格点对应的SSB频率
    f_ssb = base_freq + k * ssb_raster;

    % 验证是否满足栅格要求
    if mod(f_ssb - base_freq, ssb_raster) ~= 0
        continue;
    end

    % 计算SSB在FFT中的位置
    freq_offset = f_ssb - f_rx_center;
    subcarrier_offset = round(freq_offset / subcarrier_spacing);
    ssb_center_idx = center_idx + subcarrier_offset;
    ssb_start = ssb_center_idx - 120;
    ssb_end = ssb_center_idx + 119;

    % 检查是否在有效范围内
    if ssb_start < ssb_start_min || ssb_start > ssb_start_max
        continue;
    end

    % 确保SSB范围在FFT范围内
    if ssb_start < 1 || ssb_end > N_fft
        continue;
    end

    % 对该SSB位置，尝试所有3个可能的NID2（0, 1, 2）
    for NID2 = 0:2
        % 生成PSS序列
        pss_seq = nrPSS(NID2);

        % 构造频域PSS符号（放置在SSB子载波上）
        % PSS占用127个子载波，位于SSB的56~182位置
        A = zeros(1, N_fft);
        pss_len = length(pss_seq);
        A(ssb_start + 56 : ssb_start + 56 + pss_len - 1) = pss_seq;

        % 生成时域PSS OFDM符号
        pss_time = ifft(ifftshift(A), N_fft);

        % 与每一帧进行互相关
        for frm = 1:total_frames
            frm_start = 1 + (frm - 1) * frame_length;
            frm_stop = frm * frame_length;
            frame = Rx_data(frm_start:frm_stop);

            % 与接收帧做互相关，寻找峰值
            [corr_val, ~] = xcorr(frame, pss_time, 'none');
            [curr_peak, ~] = max(abs(corr_val));

            % 更新最大相关峰
            if curr_peak > max_corr_peak
                max_corr_peak = curr_peak;
                best_ssb_start = ssb_start;
                best_k = k;
                best_NID2 = NID2;
                best_frame = frm;
            end
        end
    end

    % 输出当前候选位置的检测进度
    fprintf('  k=%d: f_ssb=%.6f MHz, ssb_start=%d\n', ...
        k, f_ssb/1e6, ssb_start);
end

% 检查是否找到有效的SSB位置
if best_ssb_start == -1
    error('未找到有效的SSB位置！');
end

ssb_start_idx = best_ssb_start;

fprintf('\n===== PSS相关检测结果 =====\n');
fprintf('最大相关峰位置: k=%d\n', best_k);
fprintf('最大相关峰值: %.2e\n', max_corr_peak);
fprintf('检测到的NID2: %d\n', best_NID2);
fprintf('检测到的帧号: %d\n', best_frame);
fprintf('SSB起始索引: %d\n', ssb_start_idx);
fprintf('SSB子载波范围: [%d, %d]\n', ssb_start_idx, ssb_start_idx+ssb_width-1);
f_ssb_detected = base_freq + best_k * ssb_raster;
fprintf('检测到的SSB频率: %.6f MHz\n', f_ssb_detected/1e6);

end
