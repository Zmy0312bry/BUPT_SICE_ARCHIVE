function [out] = BPSKModulator(in)
persistent Modulator   
if isempty(Modulator)
    Modulator=comm.BPSKModulator;
    %Modulator=comm.PSKModulator(2,'BitInput',true);
end
out = Modulator(in);
end