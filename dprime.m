function dPrime = dprime(HIT,FA,N)
% This function calculates the d'.
% use as: dprime(HIT,FA,N)
% INPUTS
% HIT - Insert the number (not proportion) of correct trials
% FA - Insert the number of false alarm trials
% N - number of trials for Hit and FA - for calculating proportions
% OUTPUT
% dprime value

% adjustments if all correct/wrong
if HIT == N 
    HIT = N-1;   
elseif FA == N
    FA = N-1;
elseif HIT == 0
    HIT = 1/N;
elseif FA == 0
    FA = 1/N;
end

zHit = norminv(HIT/N);
zFA = norminv(FA/N);

% calculate d-prime
dPrime = zHit - zFA;

end
