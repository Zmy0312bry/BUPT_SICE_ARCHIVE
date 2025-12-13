% 解码所有帧的PBCH，返回帧号列表（System Frame Number）并解析完整MIB信息
% 输入：
%   Rx_data        - 多帧复数采样串接
%   frame_length   - 每帧采样点数（1228800）
%   total_frame    - 帧数
%   pss_peak_index - PSS峰值索引（相对于帧起点），用于定位PBCH符号
%   ssb_start      - SSB起始子载波索引
%   NID            - 小区ID（由SSS检测获得）
%   frames_to_check- 可选，指定解码哪些帧，默认全部
% 输出：
%   frame_numbers  - 按帧顺序的解码帧号列表（CRC失败返回NaN）
function frame_numbers = decode(Rx_data, frame_length, total_frame, pss_peak_index, ssb_start, NID, frames_to_check)

if nargin < 7
	frames_to_check = 1:total_frame;
end

N_fft = 4096;
N_cp = 288;

% 计算PBCH数据与DMRS子载波索引
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

frame_numbers = NaN(1, numel(frames_to_check));

fprintf('\n========== PBCH解码详细信息 ==========\n');

for k = 1:numel(frames_to_check)
	frm = frames_to_check(k);
	frm_start = 1 + (frm - 1) * frame_length;
	frm_stop = frm * frame_length;
	frame = Rx_data(frm_start:frm_stop);

	% 三个PBCH符号的起点（相对该帧）
	pbch_symbol2_index = pss_peak_index + (N_fft + N_cp);
	pbch_symbol3_index = pss_peak_index + (N_fft + N_cp) * 2;
	pbch_symbol4_index = pss_peak_index + (N_fft + N_cp) * 3;

	% 计算在hex文件中的位置（每个IQ样本=8字节，4字节I + 4字节Q）
	pbch_byte_offset = (frm_start - 1 + pbch_symbol2_index - 1) * 8;
	pbch_hex_start = dec2hex(pbch_byte_offset, 8);

	% 提取三个OFDM符号（时域）
	pbch234 = [frame(pbch_symbol2_index:pbch_symbol2_index+N_fft-1), ...
			   frame(pbch_symbol3_index:pbch_symbol3_index+N_fft-1), ...
			   frame(pbch_symbol4_index:pbch_symbol4_index+N_fft-1)];

	% 频域变换
	pbch234_f = zeros(N_fft, 3);
	pbch234_f(:,1) = fftshift(fft(pbch234(:,1)));
	pbch234_f(:,2) = fftshift(fft(pbch234(:,2)));
	pbch234_f(:,3) = fftshift(fft(pbch234(:,3)));

	% 解映射PBCH 576 个子载波
	PBCH = zeros(576,1);
	ssb_end = ssb_start + 240 - 1;
	PBCH(1:240)   = pbch234_f(ssb_start:ssb_end, 1);
	PBCH(241:288) = pbch234_f(ssb_start:ssb_start+47, 2);
	PBCH(289:336) = pbch234_f(ssb_end-47:ssb_end, 2);
	PBCH(337:576) = pbch234_f(ssb_start:ssb_end, 3);

	% DMRS提取与LS信道估计
	PBCH_dmrs = PBCH(dmrs_index);
	dmrs = nrPBCHDMRS(NID,0);
	H_dmrs = PBCH_dmrs ./ dmrs;
	H_data = interp1(dmrs_index', H_dmrs, data_index', 'linear', 'extrap');

	% 信道均衡
	PBCH_data_eq = PBCH(data_index) ./ H_data;

	% QPSK软解调 + BCH解码
	pbchBits = nrPBCHDecode(PBCH_data_eq, NID, 0);
	Lmax = 8;               % SSB burst最大长度
	polarListLength = 8;
	[~, crcBCH, trblk, sfn4lsb, ~, ~] = nrBCHDecode(pbchBits, polarListLength, Lmax, NID);

	fprintf('\n--- 帧 %d 的PBCH解码结果 ---\n', frm);
	fprintf('PBCH在hex文件中的起始位置: 0x%s (字节偏移)\n', pbch_hex_start);
	fprintf('对应样本索引: %d (全局), %d (帧内)\n', frm_start + pbch_symbol2_index - 1, pbch_symbol2_index);

	if crcBCH == 0
		% 提取完整的32bit payload
		% trblk是24bit的MIB，sfn4lsb是4bit的帧号LSB
		% 根据38.212，BCH payload包含：
		% - A_MIB = 24 bits (MIB内容)
		% - 4 LSB of SFN
		% - half frame bit (1 bit)
		% - 其他timing信息

		% 解析SFN (10 bits total: 6 MSB from MIB + 4 LSB)
		sfn_6msb = trblk(2:7)';  % MIB中的6位SFN
		sfn_4lsb = sfn4lsb';      % BCH额外提供的4位LSB
		frm_num_bin = [sfn_6msb, sfn_4lsb];
		sfn = bi2de(frm_num_bin, 'left-msb');
		frame_numbers(k) = sfn;

		fprintf('\n✓ CRC校验通过\n');
		fprintf('完整帧号(SFN): %d (0x%03X)\n', sfn, sfn);

		fprintf('\n========== 完整32-bit PBCH Payload ==========\n');

		% 构建完整的32-bit payload
		% Bit 0-23: MIB (24 bits)
		% Bit 24-27: SFN 4 LSB (4 bits)
		% Bit 28-31: 其他timing信息 (这里用0填充，实际值包含在BCH解码中)
		payload_32bit = [trblk', sfn4lsb', 0, 0, 0, 0];  % 32 bits total

		% 打印完整的32位二进制表示
		fprintf('\n【完整32-bit Payload (二进制)】\n');
		fprintf('  ');
		for i = 1:32
			fprintf('%d', payload_32bit(i));
			if mod(i, 8) == 0 && i < 32
				fprintf(' ');  % 每8位加一个空格
			end
		end
		fprintf('\n');

		% 打印32位分组说明
		fprintf('\n【32-bit 分组说明】\n');
		fprintf('  Bit [0-23]  : MIB (24 bits)\n');
		fprintf('  Bit [24-27] : SFN 4 LSB (4 bits)\n');
		fprintf('  Bit [28-31] : Timing info (4 bits)\n');

		% 打印十六进制表示
		hex_str = '';
		for i = 1:4
			byte_bits = payload_32bit((i-1)*8+1:i*8);
			hex_str = [hex_str, dec2hex(bi2de(byte_bits, 'left-msb'), 2)];
			if i < 4
				hex_str = [hex_str, ' '];
			end
		end
		fprintf('\n【32-bit 十六进制表示】\n');
		fprintf('  0x%s\n', strrep(hex_str, ' ', ''));
		fprintf('  (分组: %s)\n', hex_str);

		fprintf('\n========== 详细字段解析 ==========\n');

		% MIB 24 bits 解析 (38.331)
		fprintf('\n【MIB - 24 bits】\n');

		% Bit 0: spare (always 0)
		spare_bit = trblk(1);
		fprintf('  [bit 0]     spare                  : %d\n', spare_bit);

		% Bit 1-6: systemFrameNumber (6 MSB of SFN)
		sfn_6bits = trblk(2:7)';
		sfn_value = bi2de(sfn_6bits, 'left-msb');
		fprintf('  [bit 1-6]   systemFrameNumber     : %d (0b%s) - SFN的6个MSB\n', ...
			sfn_value, dec2bin(sfn_value, 6));

		% Bit 7: subCarrierSpacingCommon
		scs_common = trblk(8);
		if scs_common == 0
			scs_str = '15 kHz (for FR1 < 3GHz)';
		else
			scs_str = '30 kHz (for FR1 > 3GHz)';
		end
		fprintf('  [bit 7]     subCarrierSpacingCommon: %d (%s)\n', scs_common, scs_str);

		% Bit 8-11: ssb-SubcarrierOffset (4 bits, k_SSB)
		ssb_offset = trblk(9:12)';
		ssb_offset_val = bi2de(ssb_offset, 'left-msb');
		fprintf('  [bit 8-11]  ssb-SubcarrierOffset  : %d (k_SSB偏移)\n', ssb_offset_val);

		% Bit 12: dmrs-TypeA-Position
		dmrs_typeA = trblk(13);
		if dmrs_typeA == 0
			dmrs_str = 'pos2 (symbol 2)';
		else
			dmrs_str = 'pos3 (symbol 3)';
		end
		fprintf('  [bit 12]    dmrs-TypeA-Position   : %d (%s)\n', dmrs_typeA, dmrs_str);

		% Bit 13-20: pdcch-ConfigSIB1 (8 bits)
		pdcch_config = trblk(14:21)';
		pdcch_val = bi2de(pdcch_config, 'left-msb');
		fprintf('  [bit 13-20] pdcch-ConfigSIB1      : %d (0x%02X) - CORESET/SearchSpace配置\n', ...
			pdcch_val, pdcch_val);

		% Bit 21: cellBarred
		cell_barred = trblk(22);
		if cell_barred == 0
			barred_str = 'notBarred (允许接入)';
		else
			barred_str = 'barred (禁止接入)';
		end
		fprintf('  [bit 21]    cellBarred            : %d (%s)\n', cell_barred, barred_str);

		% Bit 22: intraFreqReselection
		intra_freq = trblk(23);
		if intra_freq == 0
			freq_str = 'notAllowed';
		else
			freq_str = 'allowed';
		end
		fprintf('  [bit 22]    intraFreqReselection  : %d (%s)\n', intra_freq, freq_str);

		% Bit 23: spare
		spare2 = trblk(24);
		fprintf('  [bit 23]    spare                 : %d\n', spare2);

		fprintf('\n【额外的8 bits (从BCH channel解码)】\n');

		% 4 LSB of SFN
		sfn_lsb_val = bi2de(sfn4lsb', 'left-msb');
		fprintf('  [bit 24-27] SFN 4 LSB             : %d (0b%s)\n', ...
			sfn_lsb_val, dec2bin(sfn_lsb_val, 4));

		fprintf('  [bit 28]    Half frame bit        : (包含在BCH解码中)\n');
		fprintf('  [bit 29-31] SSB timing info       : (包含在BCH解码中)\n');

		% 完整的32bit表示
		fprintf('\n【完整SFN (10 bits)】\n');
		fprintf('  SFN = [6 MSB from MIB] + [4 LSB from BCH] = %s + %s = %d\n', ...
			dec2bin(sfn_value, 6), dec2bin(sfn_lsb_val, 4), sfn);

	else
		fprintf('\n✗ CRC校验失败 - PBCH解码错误\n');
		frame_numbers(k) = NaN;
	end

	fprintf('\n');
end

fprintf('========================================\n\n');

end
