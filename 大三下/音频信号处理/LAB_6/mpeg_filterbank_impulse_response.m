% MPEG Analysis Filter Bank - Impulse Response Visualization
% h_k[n] = 2 * h[n] * cos(pi*(2*k+1)*(n-16)/64), k = 0,1,...,31

clear; clc; close all;

%% Define the prototype filter coefficients (ff_mpa_enwindow from MPEG standard)
enwindow = [
     0,    -1,    -1,    -1,    -1,    -1,    -1,    -2, ...
    -2,    -2,    -2,    -3,    -3,    -4,    -4,    -5, ...
    -5,    -6,    -7,    -7,    -8,    -9,   -10,   -11, ...
   -13,   -14,   -16,   -17,   -19,   -21,   -24,   -26, ...
   -29,   -31,   -35,   -38,   -41,   -45,   -49,   -53, ...
   -58,   -63,   -68,   -73,   -79,   -85,   -91,   -97, ...
  -104,  -111,  -117,  -125,  -132,  -139,  -147,  -154, ...
  -161,  -169,  -176,  -183,  -190,  -196,  -202,  -208, ...
   213,   218,   222,   225,   227,   228,   228,   227, ...
   224,   221,   215,   208,   200,   189,   177,   163, ...
   146,   127,   106,    83,    57,    29,    -2,   -36, ...
   -72,  -111,  -153,  -197,  -244,  -294,  -347,  -401, ...
  -459,  -519,  -581,  -645,  -711,  -779,  -848,  -919, ...
  -991, -1064, -1137, -1210, -1283, -1356, -1428, -1498, ...
 -1567, -1634, -1698, -1759, -1817, -1870, -1919, -1962, ...
 -2001, -2032, -2057, -2075, -2085, -2087, -2080, -2063, ...
  2037,  2000,  1952,  1893,  1822,  1739,  1644,  1535, ...
  1414,  1280,  1131,   970,   794,   605,   402,   185, ...
   -45,  -288,  -545,  -814, -1095, -1388, -1692, -2006, ...
 -2330, -2663, -3004, -3351, -3705, -4063, -4425, -4788, ...
 -5153, -5517, -5879, -6237, -6589, -6935, -7271, -7597, ...
 -7910, -8209, -8491, -8755, -8998, -9219, -9416, -9585, ...
 -9727, -9838, -9916, -9959, -9966, -9935, -9863, -9750, ...
 -9592, -9389, -9139, -8840, -8492, -8092, -7640, -7134, ...
  6574,  5959,  5288,  4561,  3776,  2935,  2037,  1082, ...
    70,  -998, -2122, -3300, -4533, -5818, -7154, -8540, ...
 -9975,-11455,-12980,-14548,-16155,-17799,-19478,-21189, ...
-22929,-24694,-26482,-28289,-30112,-31947,-33791,-35640, ...
-37489,-39336,-41176,-43006,-44821,-46617,-48390,-50137, ...
-51853,-53534,-55178,-56778,-58333,-59838,-61289,-62684, ...
-64019,-65290,-66494,-67629,-68692,-69679,-70590,-71420, ...
-72169,-72835,-73415,-73908,-74313,-74630,-74856,-74992, ...
 75038
];

%% Generate full 512-tap prototype filter h[n]
h = zeros(1, 512);
for i = 0:256
    v = enwindow(i + 1);
    h(i + 1) = v;
    if mod(i, 64) ~= 0
        v = -v;
    end
    if i ~= 0
        h(512 - i + 1) = v;
    end
end

%% Normalize the prototype filter
h = h / max(abs(h));

%% Parameters
N = 512;                    % Filter length
numbands = 32;              % Number of subbands
n = 0:N-1;                  % Sample index

%% Generate 32 analysis filter impulse responses
hk = zeros(numbands, N);
for k = 0:numbands-1
    hk(k+1, :) = 2 * h .* cos(pi * (2*k+1) * (n - 16) / 64);
end

%% Plot all 32 impulse responses
figure('Position', [50, 50, 1200, 900], 'Name', 'MPEG Analysis Filter Bank Impulse Responses');

for k = 0:numbands-1
    subplot(8, 4, k+1);
    stem(n, hk(k+1, :), 'MarkerSize', 1, 'LineWidth', 0.5);
    title(['h_{', num2str(k), '}[n]'], 'FontSize', 9);
    xlabel('n', 'FontSize', 8);
    ylabel('Amplitude', 'FontSize', 8);
    xlim([0 N-1]);
    grid on;
    set(gca, 'FontSize', 7);
end

sgtitle('MPEG Analysis Filter Bank: All 32 Impulse Responses h_k[n]', 'FontSize', 14, 'FontWeight', 'bold');
saveas(gcf, 'all_32_impulse_responses.png');

%% Plot prototype filter
figure('Position', [100, 100, 800, 400], 'Name', 'Prototype Lowpass Filter');
stem(n, h, 'MarkerSize', 2, 'LineWidth', 0.8);
title('Prototype Lowpass Filter h[n] (512 taps)');
xlabel('n');
ylabel('Normalized Amplitude');
xlim([0 N-1]);
grid on;
saveas(gcf, 'prototype_filter.png');

%% Plot frequency responses of all 32 filters
figure('Position', [150, 150, 1000, 600], 'Name', 'Frequency Responses');

Nfft = 4096;
freq = linspace(-1, 1, Nfft);  % Normalized frequency

hold on;
for k = 0:numbands-1
    H = fftshift(fft(hk(k+1, :), Nfft));
    plot(freq, 20*log10(abs(H) / max(abs(H)) + 1e-10), 'LineWidth', 0.8);
end
hold off;

title('Frequency Responses of All 32 Analysis Filters');
xlabel('Normalized Frequency (\times\pi rad/sample)');
ylabel('Magnitude (dB)');
xlim([-1, 1]);
ylim([-100, 5]);
grid on;
legend(arrayfun(@(k) ['k=' num2str(k)], 0:31, 'UniformOutput', false), ...
    'Location', 'eastoutside', 'FontSize', 6);
saveas(gcf, 'frequency_responses.png');
