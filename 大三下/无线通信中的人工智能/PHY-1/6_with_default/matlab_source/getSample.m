%% Clean up
clear all;
clc;

[N,M,P,N_features] = load_params();

rows = M;
length = N;
NFeatures = N_features;
sample_data = zeros(rows, NFeatures + 1);

%% Simulation parameters 

%% Simulate
    %BPSK
    % Generate random data
    data = randi([0 1], rows, length);   
    
    % QAM mapping
    [data1] = data';
    data_cell = mat2cell(data1,length,ones(1,rows));
    signalData = cellfun(@(x) BPSKModulator(x), data_cell, 'UniformOutput',false);
    %signalData = cellfun(@(x) qammod(x, 2, 'InputType', 'bit', 'UnitAveragePower', true), data_cell, 'UniformOutput',false);
    signalData1 = cell2mat(signalData);
    signalData2 = mat2cell(signalData1',ones(1,rows),length);
    
    % get cumulants
    cumulants = cellfun(@(x) func_get_cumulants(x), signalData2, 'UniformOutput',false);
    cumulantsMat = cell2mat(cumulants);
    
    for row = 1: rows
        for i = 1:NFeatures
                sample_data(row, i) = cumulantsMat(row, i);
        end
        sample_data(row, NFeatures + 1) = 2;
    end
    
    %QPSK
    % Generate random data
    data = randi([0 1], rows, 2*length);   
    
    % QAM mapping
    [data1] = data';
    data_cell = mat2cell(data1,2*length,ones(1,rows));
    signalData = cellfun(@(x) QPSKModulator(x), data_cell, 'UniformOutput',false);
    %signalData = cellfun(@(x) qammod(x, 4, 'InputType', 'bit', 'UnitAveragePower', true), data_cell, 'UniformOutput',false);
    signalData1 = cell2mat(signalData);
    signalData2 = mat2cell(signalData1',ones(1,rows),length);
    
    % get cumulants
    cumulants = cellfun(@(x) func_get_cumulants(x), signalData2, 'UniformOutput',false);
    cumulantsMat = cell2mat(cumulants);
    
    for row = 1: rows
        row_r = rows + row;
        for i = 1:NFeatures
                sample_data(row_r, i) = cumulantsMat(row, i);
        end
        sample_data(row_r, NFeatures + 1) = 4;
    end
    
 %16QAM
    % Generate random data
    data = randi([0 1], rows, 4*length);   
    
    % QAM mapping
    [data1] = data';
    data_cell = mat2cell(data1,4*length,ones(1,rows));
    signalData = cellfun(@(x) qammod(x, 16, 'InputType', 'bit', 'UnitAveragePower', true), data_cell, 'UniformOutput',false);
    signalData1 = cell2mat(signalData);
    signalData2 = mat2cell(signalData1',ones(1,rows),length);
    
    % get cumulants
    cumulants = cellfun(@(x) func_get_cumulants(x), signalData2, 'UniformOutput',false);
    cumulantsMat = cell2mat(cumulants);
    
    for row = 1: rows
        row_r = 2*rows + row;
        for i = 1:NFeatures
                sample_data(row_r, i) = cumulantsMat(row, i);
        end
        sample_data(row_r, NFeatures + 1) = 16;
    end

 %64QAM
    % Generate random data
    data = randi([0 1], rows, 6*length);       
    % QAM mapping
    [data1] = data';
    data_cell = mat2cell(data1,6*length,ones(1,rows));
    signalData = cellfun(@(x) qammod(x, 64, 'InputType', 'bit', 'UnitAveragePower', true), data_cell, 'UniformOutput',false);
    signalData1 = cell2mat(signalData);
    signalData2 = mat2cell(signalData1',ones(1,rows),length);
    
    % get cumulants
    cumulants = cellfun(@(x) func_get_cumulants(x), signalData2, 'UniformOutput',false);
    cumulantsMat = cell2mat(cumulants);
    
    for row = 1: rows
        row_r = 3*rows + row;
        for i = 1:NFeatures
                sample_data(row_r, i) = cumulantsMat(row, i);
        end
        sample_data(row_r, NFeatures + 1) = 64;
    end
    
filename='digits/sample.dat';
dlmwrite(filename,sample_data,'delimiter','\t','newline','pc');

%csvwrite('sample.txt', sample_data);
