function SimParams = sdruqpskreceiver_init(useCodegen)
%   Copyright 2012-2020 The MathWorks, Inc.

%% General simulation parameters
SimParams.Rsym = 0.3e6;         % Symbol rate in Hertz


SimParams.ModulationOrder = 4;      % QPSK alphabet size
SimParams.Interpolation = 2;        % Interpolation factor
SimParams.Decimation = 1;           % Decimation factor
SimParams.Tsym = 1/SimParams.Rsym;  % Symbol time in sec
SimParams.Fs   = SimParams.Rsym * SimParams.Interpolation; % Sample rate

%% Frame Specifications
% [BarkerCode*2 | 'Hello world 000\n' | 'Hello world 001\n' ... | 'Hello world 099\n'];
SimParams.BarkerCode      = [+1 +1 +1 +1 +1 -1 -1 +1 +1 -1 +1 -1 +1];     % Bipolar Barker Code
SimParams.BarkerLength    = length(SimParams.BarkerCode);
SimParams.HeaderLength    = SimParams.BarkerLength * 2;                   % Duplicate 2 Barker codes to be as a header
SimParams.Message         = 'BUPT1955-2026';
SimParams.MessageLength   = length(SimParams.Message) + 5;                % 'Hello world 000\n'...
SimParams.NumberOfMessage = 30;                                          % Number of messages in a frame
SimParams.PayloadLength   = SimParams.NumberOfMessage * SimParams.MessageLength * 7; % 7 bits per characters
SimParams.FrameSize       = (SimParams.HeaderLength + SimParams.PayloadLength) ...
    / log2(SimParams.ModulationOrder);                                    % Frame size in symbols
SimParams.FrameTime       = SimParams.Tsym*SimParams.FrameSize;

%% Rx parameters
SimParams.RolloffFactor     = 0.5;                      % Rolloff Factor of Raised Cosine Filter
SimParams.ScramblerBase     = 2;
SimParams.ScramblerPolynomial           = [1 1 1 0 1];
SimParams.ScramblerInitialConditions    = [0 0 0 0];
SimParams.RaisedCosineFilterSpan = 10;                  % Filter span of Raised Cosine Tx Rx filters (in symbols)
SimParams.DesiredPower                  = 1;            % AGC desired output power (in watts)
SimParams.AveragingLength               = 50;           % AGC averaging length
SimParams.MaxPowerGain                  = 60;           % AGC maximum output power gain
SimParams.MaximumFrequencyOffset        = 6e3;
% Look into model for details for details of PLL parameter choice. 
% Refer equation 7.30 of "Digital Communications - A Discrete-Time Approach" by Michael Rice.
K = 1;
A = 1/sqrt(2);
SimParams.PhaseRecoveryLoopBandwidth    = 0.01;         % Normalized loop bandwidth for fine frequency compensation
SimParams.PhaseRecoveryDampingFactor    = 1;            % Damping Factor for fine frequency compensation
SimParams.TimingRecoveryLoopBandwidth   = 0.01;         % Normalized loop bandwidth for timing recovery
SimParams.TimingRecoveryDampingFactor   = 1;            % Damping Factor for timing recovery
% K_p for Timing Recovery PLL, determined by 2KA^2*2.7 (for binary PAM),
% QPSK could be treated as two individual binary PAM,
% 2.7 is for raised cosine filter with roll-off factor 0.5
SimParams.TimingErrorDetectorGain       = 2.7*2*K*A^2+2.7*2*K*A^2;
SimParams.PreambleDetectorThreshold     = 0.8;

%% Message generation and BER calculation parameters
msgSet = zeros(100 * SimParams.MessageLength, 1);
for msgCnt = 0 : 99
    msgSet(msgCnt * SimParams.MessageLength + (1 : SimParams.MessageLength)) = ...
        sprintf('%s %03d\n', SimParams.Message, msgCnt);
end
bits = de2bi(msgSet, 7, 'left-msb')';
SimParams.MessageBits = bits(:);

% For BER calculation masks
SimParams.BerMask = zeros(SimParams.NumberOfMessage * length(SimParams.Message) * 7, 1);
for i = 1 : SimParams.NumberOfMessage
    SimParams.BerMask( (i-1) * length(SimParams.Message) * 7 + ( 1: length(SimParams.Message) * 7) ) = ...
        (i-1) * SimParams.MessageLength * 7 + (1: length(SimParams.Message) * 7);
end

%% SDR receiver parameters
SimParams.SDRCenterFrequency           = 325e6;
SimParams.SDRGain                      = 20;
SimParams.SDRFrontEndSampleRate        = SimParams.Rsym * 2; % Nyquist sampling theorem
SimParams.SDRFrameLength               = SimParams.Interpolation * SimParams.FrameSize;

% Experiment parameters
SimParams.SDRFrameTime                 = SimParams.SDRFrameLength/SimParams.SDRFrontEndSampleRate;
SimParams.StopTime                      = 10;
