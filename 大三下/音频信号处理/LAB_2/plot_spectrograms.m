function plot_spectrograms(wav_path, target_sr, wideband_window_ms, ...
    narrowband_window_ms, wideband_nfft, narrowband_nfft, ...
    log_scale, dyn_range_db, use_colormap)
% 绘制语音文件的窄带和宽带声谱图
%
% 参数:
%   wav_path: 语音文件路径
%   target_sr: 目标采样率(Hz)，[]表示不降采样
%   wideband_window_ms: 宽带窗长(ms)
%   narrowband_window_ms: 窄带窗长(ms)
%   wideband_nfft: 宽带FFT长度
%   narrowband_nfft: 窄带FFT长度
%   log_scale: true表示对数幅度，false表示线性幅度
%   dyn_range_db: 声谱图动态范围(dB)
%   use_colormap: true表示彩色，false表示灰度

    % 读取音频文件
    [audio, sr] = audioread(wav_path);

    % 转换为单声道
    if size(audio, 2) > 1
        audio = mean(audio, 2);
    end

    % 降采样
    if ~isempty(target_sr) && target_sr < sr
        audio = resample(audio, target_sr, sr);
        sr = target_sr;
    end

    % 计算窗口样本数
    wideband_window_samples = round(wideband_window_ms * sr / 1000);
    narrowband_window_samples = round(narrowband_window_ms * sr / 1000);

    % 确保窗口长度为奇数
    if mod(wideband_window_samples, 2) == 0
        wideband_window_samples = wideband_window_samples + 1;
    end
    if mod(narrowband_window_samples, 2) == 0
        narrowband_window_samples = narrowband_window_samples + 1;
    end

    % 计算宽带声谱图
    [S_wide, f_wide, t_wide] = spectrogram(audio, hamming(wideband_window_samples), ...
        floor(wideband_window_samples/2), wideband_nfft, sr);

    % 计算窄带声谱图
    [S_narrow, f_narrow, t_narrow] = spectrogram(audio, hamming(narrowband_window_samples), ...
        floor(narrowband_window_samples/2), narrowband_nfft, sr);

    % 幅度处理
    if log_scale
        S_wide_db = 20 * log10(abs(S_wide) + eps);
        S_narrow_db = 20 * log10(abs(S_narrow) + eps);

        % 应用动态范围
        max_val_wide = max(S_wide_db(:));
        min_val_wide = max_val_wide - dyn_range_db;
        S_wide_db(S_wide_db < min_val_wide) = min_val_wide;

        max_val_narrow = max(S_narrow_db(:));
        min_val_narrow = max_val_narrow - dyn_range_db;
        S_narrow_db(S_narrow_db < min_val_narrow) = min_val_narrow;

        S_wide_plot = S_wide_db;
        S_narrow_plot = S_narrow_db;
        wide_clim = [min_val_wide, max_val_wide];
        narrow_clim = [min_val_narrow, max_val_narrow];
    else
        S_wide_plot = abs(S_wide);
        S_narrow_plot = abs(S_narrow);
        wide_clim = [0, max(S_wide_plot(:))];
        narrow_clim = [0, max(S_narrow_plot(:))];
    end

    % 创建图形
    figure('Position', [100, 100, 1200, 800]);

    % 设置颜色映射
    if use_colormap
        colormap('jet');
    else
        colormap('gray');
    end

    % 绘制宽带声谱图
    subplot(2, 1, 1);
    imagesc(t_wide, f_wide, S_wide_plot);
    axis xy;
    xlabel('Time (s)');
    ylabel('Frequency (Hz)');
    title(sprintf('Broadband Spectrogram (Window: %dms, FFT: %d)', ...
        wideband_window_ms, wideband_nfft));
    ylim([0, sr/2]);
    clim(wide_clim);

    % 绘制窄带声谱图
    subplot(2, 1, 2);
    imagesc(t_narrow, f_narrow, S_narrow_plot);
    axis xy;
    xlabel('Time (s)');
    ylabel('Frequency (Hz)');
    title(sprintf('Narrowband Spectrogram (Window: %dms, FFT: %d)', ...
        narrowband_window_ms, narrowband_nfft));
    ylim([0, sr/2]);
    clim(narrow_clim);

    % 调整布局
    sgtitle(['Spectrograms - ' wav_path]);
end

% 使用样例
% plot_spectrograms('speech.wav', 8000, 20, 200, 512, 4096, true, 80, true);
