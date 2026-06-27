function [codes, x_recon, step_sizes] = adpcm_encoder(x, alpha, M, delta_table, deltamin, deltamax, delta_init)
% ADPCM_ENCODER  Jayant ADPCM 编码器（参考图 P11.30a 结构）
%
% 4-bit midtread 量化器: 16个电平 [-7/8*Δ, ..., 0, ..., +7/8*Δ]
% 编码方案: code = signed_val + 8, 其中 signed_val ∈ [-8, +7]
%   code 0~7:  正值 (0 到 +7/8*Δ)
%   code 8:    零
%   code 9~15: 负值 (-7/8*Δ 到 -1/8*Δ)

    N = length(x);
    codes = zeros(N, 1);
    x_recon = zeros(N, 1);
    step_sizes = zeros(N, 1);

    delta = delta_init;
    x_hat_prev = 0;
    c_prev = 8;  % 初始代码 = 8 (零)

    for n = 1:N
        % ① 步长自适应: Δ[n] = M[|c[n-1]|] × Δ[n-1]
        if n > 1
            signed_prev = c_prev - 8 * (c_prev >= 8);
            mag_idx_prev = min(abs(signed_prev), 7);
            delta = M(mag_idx_prev + 1) * delta;
            delta = max(deltamin, min(deltamax, delta));
            [~, idx] = min(abs(delta_table - delta));
            delta = delta_table(idx);
        end

        % ② 预测: x̃[n] = α × x̂[n-1]
        x_tilde = alpha * x_hat_prev;

        % ③ 差值: d[n] = x[n] - x̃[n]
        d = x(n) - x_tilde;

        % ④ 量化器 Q[]: 归一化 → 16级midtread量化 → 反归一化
        d_norm = d / delta;
        level = round(d_norm * 8);   % [-8, +7]
        level = max(-8, min(7, level));

        % ⑤ 编码器: level → 4-bit code
        codes(n) = level + 8;  % [0, 15]

        % ⑥ 量化差值
        dq = (level / 8) * delta;

        % ⑦ 重建: x̂[n] = x̃[n] + d̂[n]
        x_recon(n) = x_tilde + dq;

        % ⑧ 更新状态
        x_hat_prev = x_recon(n);
        c_prev = codes(n);
        step_sizes(n) = delta;
    end
end
