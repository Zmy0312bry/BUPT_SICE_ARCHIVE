function [x_recon, step_sizes] = adpcm_decoder(codes, alpha, M, delta_table, deltamin, deltamax, delta_init)
% ADPCM_DECODER  Jayant ADPCM 解码器（参考图 P11.30b 结构）
%
% 4-bit midtread 量化器解码: code → signed_val → dq = signed_val/8 × Δ

    N = length(codes);
    x_recon = zeros(N, 1);
    step_sizes = zeros(N, 1);

    delta = delta_init;
    x_hat_prev = 0;
    c_prev = 8;

    for n = 1:N
        % ① 步长自适应
        if n > 1
            signed_prev = c_prev - 8 * (c_prev >= 8);
            mag_idx_prev = min(abs(signed_prev), 7);
            delta = M(mag_idx_prev + 1) * delta;
            delta = max(deltamin, min(deltamax, delta));
            [~, idx] = min(abs(delta_table - delta));
            delta = delta_table(idx);
        end

        % ② 预测
        x_tilde = alpha * x_hat_prev;

        % ③ 解码器: code → signed level → dq
        level = codes(n) - 8;  % signed level [-8, +7]
        dq = (level / 8) * delta;

        % ④ 重建
        x_recon(n) = x_tilde + dq;

        % ⑤ 更新状态
        x_hat_prev = x_recon(n);
        c_prev = codes(n);
        step_sizes(n) = delta;
    end
end
