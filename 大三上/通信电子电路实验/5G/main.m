clear all;
close all;

% 创建assets目录（如果不存在）
if ~exist('assets', 'dir')
    mkdir('assets');
end

% 设置图形不显示（用于命令行运行）
set(0, 'DefaultFigureVisible', 'off');

fprintf('\n========================================\n');
fprintf('5G NR SSB信号解析实验\n');
fprintf('========================================\n\n');

fid = fopen('fp_iq_640008.hex','r');
frame_length = 1228800; % 以样点计，每帧长度。这是当前5G配置所决定的。
total_frame = 8;

IQ_data_array_int16 = fread(fid,frame_length *total_frame * 2,'int16'); % 以int16类型将数据读入IQ_data_arry_int16中。
% IQ_data_array的格式为： | I0(16bit) | Q0(16bit)| I1(16bit) | Q1(16bit)| I2(16bit) | Q2(16bit)|

%将IQ_data_array_int16转换为复数序列
Rx_data = IQ_data_array_int16(1:2:end)+IQ_data_array_int16(2:2:end)*1i;
fclose(fid);

% 计算SSB起始子载波索引（基于参考频点）
pointA = 640008;                  % 参考点（整数）
dl_offset_to_carrier = 0;         % 下行载波偏移（Hz）
bandwidth = 100e6;                % 工作带宽 100 MHz
subcarrier_spacing = 30e3;        % 子载波间隔 30 kHz
% 下面两个部分二选一
% ---- block1 ----
ssb_start_val = ssb_start_func(Rx_data, pointA, dl_offset_to_carrier, bandwidth, subcarrier_spacing);
disp(['计算得到的SSB起始子载波索引：', num2str(ssb_start_val)]);
% ---- end block1 ----

% ---- block2 ----
% 中心SSB接收情况下的ssb_start_val
%ssb_start_val = 2048 - 120 + 1;
% ---- end block2 ----


fprintf('\n--- 开始PSS同步检测 ---\n');
[~, pss_peak_index, best_frame] = pss(Rx_data, total_frame, ssb_start_val);

fprintf('\n--- 开始SSS同步检测 ---\n');
frame_data = Rx_data((best_frame-1)*frame_length + 1 : best_frame*frame_length);
[NID1, NID2, NID] = sss(frame_data, ssb_start_val, pss_peak_index);

fprintf('\n--- 开始信道估计与均衡 ---\n');
% PBCH信道估计与均衡
[PBCH_data_eq, H_all, H_data, PBCH, data_index, dmrs_index] = channel(frame_data, ssb_start_val, pss_peak_index, NID);

fprintf('\n--- 开始PBCH解码 ---\n');
% 解码所有帧的帧号
frame_numbers = decode(Rx_data, frame_length, total_frame, pss_peak_index, ssb_start_val, NID);
disp("Frame Numbers: " + mat2str(frame_numbers));

% 保存解码结果到文本文件
result_file = fopen('assets/decode_results.txt', 'w');
fprintf(result_file, '5G NR SSB解析结果\n');
fprintf(result_file, '==================\n\n');
fprintf(result_file, 'SSB起始子载波索引: %d\n', ssb_start_val);
fprintf(result_file, 'NID2: %d\n', NID2);
fprintf(result_file, 'NID1: %d\n', NID1);
fprintf(result_file, 'NID: %d\n', NID);
fprintf(result_file, 'PSS峰值位置: %d (帧%d)\n', pss_peak_index, best_frame);
fprintf(result_file, '\n系统帧号序列:\n');
for i = 1:length(frame_numbers)
    if isnan(frame_numbers(i))
        fprintf(result_file, '帧%d: CRC失败\n', i);
    else
        fprintf(result_file, '帧%d: SFN = %d\n', i, frame_numbers(i));
    end
end
fclose(result_file);
fprintf('已保存解码结果: assets/decode_results.txt\n');

fprintf('\n========================================\n');
fprintf('实验完成！所有图像已保存到assets/目录\n');
fprintf('========================================\n\n');
