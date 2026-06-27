% LPC_analysis_NMSE.m
% 对语音进行LPC分析，画出平均归一化均方误差随阶数(1~16)的变化曲线
% 需要 Signal Processing Toolbox (buffer, hamming, lpc)

clear; clc; close all;

%% ========== 参数设置 ==========
frameLen   = 256;          % 帧长（样本点），如8kHz下为32ms
frameShift = 128;          % 帧移（样本点），帧重叠50%
preemph    = true;         % 是否进行预加重
alpha      = 0.97;         % 预加重系数
pMax       = 16;           % 最大 LPC 阶数
energyThresh = 0.01;       % 能量阈值，用于剔除静音帧（相对于最大帧能量的比例）

%% ========== 语音文件列表（请修改为实际路径）==========
fileNames = {'speech1.wav', 'speech2.wav', 'speech3.wav'};
numFiles  = length(fileNames);
allNMSE_dB = zeros(numFiles, pMax);   % 保存各文件各阶数的平均NMSE(dB)

%% ========== 对每个文件处理 ==========
for idxFile = 1:numFiles
    % --- 1. 读入语音 ---
    [x, fs] = audioread(fileNames{idxFile});
    if size(x,2) > 1
        x = x(:,1);                     % 立体声 -> 单声道
    end
    
    % --- 2. 预加重（可选）---
    if preemph
        x = filter([1, -alpha], 1, x);
    end
    
    % --- 3. 分帧与加窗 ---
    % buffer 在 Signal Processing Toolbox 中，若无该函数可自编分帧
    frames = buffer(x, frameLen, frameLen - frameShift, 'nodelay');
    win = hamming(frameLen);
    framesWin = frames .* win;          % 逐帧加窗
    
    % --- 4. 去除静音帧 ---
    energy = sum(framesWin.^2, 1);      % 每帧能量
    threshold = max(energy) * energyThresh;
    validFrames = framesWin(:, energy > threshold);
    numFrames = size(validFrames, 2);
    
    if numFrames == 0
        error(['文件 ' fileNames{idxFile} ' 中没有足够能量的语音帧，请调整阈值。']);
    end
    
    % --- 5. 对不同阶数计算平均 NMSE ---
    avgNMSE_dB = zeros(1, pMax);
    for p = 1:pMax
        nmse_sum = 0;
        for i = 1:numFrames
            frame = validFrames(:, i);
            [a, g] = lpc(frame, p);     % g 是预测误差的均方根 sqrt(E_pred)
            E_pred = g^2;               % 预测误差能量
            E_frame = sum(frame.^2);    % 帧能量
            nmse = E_pred / E_frame;    % 归一化均方误差
            nmse_sum = nmse_sum + nmse;
        end
        avgNMSE = nmse_sum / numFrames;
        avgNMSE_dB(p) = 10 * log10(avgNMSE);
    end
    
    allNMSE_dB(idxFile, :) = avgNMSE_dB;
    
    % --- 6. 绘制单文件曲线 ---
    figure;
    plot(1:pMax, avgNMSE_dB, 'b-o', 'LineWidth', 1.5);
    xlabel('LPC 阶数 p'); ylabel('平均归一化均方误差 (dB)');
    title(['文件: ' fileNames{idxFile}]);
    grid on;
end

%% ========== 所有文件对比图 ==========
figure;
hold on;
colorOrder = lines(numFiles);
for idxFile = 1:numFiles
    plot(1:pMax, allNMSE_dB(idxFile, :), 'o-', ...
        'Color', colorOrder(idxFile,:), ...
        'DisplayName', fileNames{idxFile}, 'LineWidth', 1.5);
end
xlabel('LPC 阶数 p'); ylabel('平均归一化均方误差 (dB)');
title('不同语音文件的平均NMSE随LPC阶数变化');
legend('show'); grid on; hold off;