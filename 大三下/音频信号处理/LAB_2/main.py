import numpy as np
import matplotlib.pyplot as plt
from scipy.io import wavfile
from scipy import signal

def plot_spectrograms(wav_path, target_sr=None,
                      wideband_window_ms=20, narrowband_window_ms=200,
                      wideband_nfft=512, narrowband_nfft=4096,
                      log_scale=True, dyn_range_db=80, use_colormap=True):
    """
    绘制语音文件的窄带和宽带声谱图

    参数:
        wav_path: 语音文件路径
        target_sr: 目标采样率(Hz)，如8000，None表示不降采样
        wideband_window_ms: 宽带窗长(ms)
        narrowband_window_ms: 窄带窗长(ms)
        wideband_nfft: 宽带FFT长度
        narrowband_nfft: 窄带FFT长度
        log_scale: True表示对数幅度，False表示线性幅度
        dyn_range_db: 声谱图动态范围(dB)
        use_colormap: True表示彩色，False表示灰度
    """
    # 读取音频文件
    sr, audio = wavfile.read(wav_path)
    if audio.dtype == np.int16:
        audio = audio / 32768.0
    elif audio.dtype == np.int32:
        audio = audio / 2147483648.0
    elif np.issubdtype(audio.dtype, np.integer):
        audio = audio.astype(np.float64) / np.iinfo(audio.dtype).max
    else:
        audio = audio.astype(np.float64)

    # 转换为单声道
    if len(audio.shape) > 1:
        audio = np.mean(audio, axis=1)

    # 降采样
    if target_sr and target_sr < sr:
        audio = signal.resample_poly(audio, target_sr, sr)
        sr = target_sr

    # 计算窗口样本数
    wideband_nperseg = max(1, round(wideband_window_ms * sr / 1000))
    narrowband_nperseg = max(1, round(narrowband_window_ms * sr / 1000))

    # 确保窗口长度为奇数
    if wideband_nperseg % 2 == 0:
        wideband_nperseg += 1
    if narrowband_nperseg % 2 == 0:
        narrowband_nperseg += 1

    wideband_window = signal.windows.hamming(wideband_nperseg, sym=True)
    narrowband_window = signal.windows.hamming(narrowband_nperseg, sym=True)

    # 计算宽带声谱图
    f_wide, t_wide, Sxx_wide = signal.spectrogram(
        audio, sr, window=wideband_window, nperseg=wideband_nperseg,
        noverlap=wideband_nperseg // 2, nfft=wideband_nfft,
        detrend=False, scaling='spectrum', mode='complex'
    )

    # 计算窄带声谱图
    f_narrow, t_narrow, Sxx_narrow = signal.spectrogram(
        audio, sr, window=narrowband_window, nperseg=narrowband_nperseg,
        noverlap=narrowband_nperseg // 2, nfft=narrowband_nfft,
        detrend=False, scaling='spectrum', mode='complex'
    )

    Sxx_wide_mag = np.abs(Sxx_wide)
    Sxx_narrow_mag = np.abs(Sxx_narrow)

    cmap = 'jet' if use_colormap else 'gray'

    # 幅度转换与显示范围
    if log_scale:
        Sxx_wide_plot = 20 * np.log10(Sxx_wide_mag + np.finfo(float).eps)
        Sxx_narrow_plot = 20 * np.log10(Sxx_narrow_mag + np.finfo(float).eps)

        wide_vmax = np.max(Sxx_wide_plot)
        wide_vmin = wide_vmax - dyn_range_db
        narrow_vmax = np.max(Sxx_narrow_plot)
        narrow_vmin = narrow_vmax - dyn_range_db

        Sxx_wide_plot = np.maximum(Sxx_wide_plot, wide_vmin)
        Sxx_narrow_plot = np.maximum(Sxx_narrow_plot, narrow_vmin)
    else:
        Sxx_wide_plot = Sxx_wide_mag
        Sxx_narrow_plot = Sxx_narrow_mag
        wide_vmin = 0.0
        narrow_vmin = 0.0
        wide_vmax = np.max(Sxx_wide_plot)
        narrow_vmax = np.max(Sxx_narrow_plot)

    # 绘制
    plt.rcParams['font.family'] = 'Maple Mono NF CN'
    fig, axes = plt.subplots(2, 1, figsize=(14, 8), sharex=False)

    # 宽带声谱图
    ax = axes[0]
    im = ax.pcolormesh(
        t_wide, f_wide, Sxx_wide_plot, shading='gouraud', cmap=cmap,
        vmin=wide_vmin, vmax=wide_vmax
    )
    ax.set_ylabel('Frequency (Hz)')
    ax.set_title(f'Broadband Spectrogram (Window: {wideband_window_ms} ms, FFT: {wideband_nfft})')
    ax.set_ylim(0, sr / 2)

    # 窄带声谱图
    ax = axes[1]
    im = ax.pcolormesh(
        t_narrow, f_narrow, Sxx_narrow_plot, shading='gouraud', cmap=cmap,
        vmin=narrow_vmin, vmax=narrow_vmax
    )
    ax.set_xlabel('Time (s)')
    ax.set_ylabel('Frequency (Hz)')
    ax.set_title(f'Narrowband Spectrogram (Window: {narrowband_window_ms} ms, FFT: {narrowband_nfft})')
    ax.set_ylim(0, sr / 2)

    fig.suptitle(f'Spectrograms - {wav_path}')
    fig.tight_layout()
    plt.show()


# 使用样例
if __name__ == "__main__":
    # 示例调用
    plot_spectrograms(
        wav_path='speech.wav',           # 语音文件路径
        target_sr=8000,                   # 降采样到8kHz
        wideband_window_ms=20,            # 宽带窗长20ms
        narrowband_window_ms=200,         # 窄带窗长200ms
        wideband_nfft=512,                # 宽带FFT长度
        narrowband_nfft=4096,             # 窄带FFT长度
        log_scale=False,                   # 对数幅度
        dyn_range_db=80,                  # 动态范围80dB
        use_colormap=False                # True为彩色，False为灰度
    )
