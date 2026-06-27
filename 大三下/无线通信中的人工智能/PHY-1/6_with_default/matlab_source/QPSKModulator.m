function [out] = QPSKModulator(in)
persistent Modulator   
if isempty(Modulator)
    Modulator=comm.QPSKModulator('BitInput',true);
    %demodLLR=comm.QPSKDemodulator('BitOutput',true,'DecisionMethod','Log-likelihood ratio','VarianceSource','Input port');
end
out = Modulator(in);
end