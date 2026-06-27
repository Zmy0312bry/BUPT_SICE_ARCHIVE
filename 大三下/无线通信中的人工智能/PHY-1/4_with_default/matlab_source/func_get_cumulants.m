function [cumulants] = func_get_cumulants(signalData)

shape = size(signalData);
H = shape(1);
L = shape(2);
cumulants = zeros(H, L);

for row = 1:H
    M20 = sum(signalData(row,:).^2)/L;
    M21 = sum(abs(signalData(row,:)).^2)/L;
    M40 = sum(signalData(row,:).^4)/L;
    M41 = sum(abs(signalData(row,:)).^2.*signalData(row,:).^2)/L;
    M42 = sum(abs(signalData(row,:)).^4)/L;    

    C20 = M20;
    C21 = M21;
    C40 = M40 - 3*M20^2;
    C41 = M41 - 3*M20*M21;
    C42 = M42 - abs(M20)^2 - 2*M21^2;

    C21_modify = C21;
    C20_norm = C20/(C21_modify^2);
    C21_norm = C21/(C21_modify^2);
    C40_norm = C40/(C21_modify^2);
    C41_norm = C41/(C21_modify^2);
    C42_norm = C42/(C21_modify^2);

    cumulants(row, 1) = abs(C20_norm);
    cumulants(row, 2) = abs(C21_norm);
    cumulants(row, 3) = abs(C40_norm);
    cumulants(row, 4) = abs(C41_norm);
    cumulants(row, 5) = abs(C42_norm);

end