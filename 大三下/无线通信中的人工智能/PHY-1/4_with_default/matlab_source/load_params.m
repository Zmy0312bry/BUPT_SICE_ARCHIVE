function [N,M,P,N_features] = load_params(csvfile)
%LOAD_PARAMS 读取 const.csv 并返回 N, M, P（三个标量），忽略 K
%   [N,M,P] = LOAD_PARAMS() 会在当前文件所在目录查找 const.csv。
%   [N,M,P] = LOAD_PARAMS(csvfile) 指定 CSV 路径。

if nargin < 1 || isempty(csvfile)
    thisdir = fileparts(mfilename('fullpath'));
    csvfile = fullfile(thisdir, 'const.csv');
end

% 尝试使用 readtable 读取带列名的 CSV
try
    T = readtable(csvfile);
    vars = T.Properties.VariableNames;
    if ismember('N',vars) && ismember('M',vars) && ismember('P',vars) && ismember('N_features',vars)
        N = T.N(1);
        M = T.M(1);
        P = T.P(1);
        N_features = T.N_features(1);
        return;
    end
catch
    % ignore and fallback to numeric read
end

% 退化为数值读取（readmatrix）
data = readmatrix(csvfile);
if isempty(data) || size(data,2) < 3
    error('load_params:InvalidFormat', 'CSV must contain at least 3 columns for N, M, P');
end

N = data(1,1);
M = data(1,2);
P = data(1,3);
N_features = data(1,5);
end
