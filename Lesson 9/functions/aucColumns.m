function auc = aucColumns(X, lab)
% aucColumns  AUC of every column of X (e.g. every neuron) for binary labels.
%
%   auc = aucColumns(X, lab)
%
%   INPUTS
%       X   - [nTrials x nNeurons] values (e.g. firing rates)
%       lab - [nTrials x 1] labels, 1/true or 0/false
%   OUTPUT
%       auc - [1 x nNeurons] AUC per column (0.5 = no information)
%
%   Rank-based, the same as aucFromSamples but for all columns at once.
%
%   Course: MUW 860.053
lab = logical(lab(:));
n1 = sum(lab); n0 = sum(~lab);
R = tiedrank(X);
auc = (sum(R(lab, :), 1) - n1*(n1 + 1)/2) / (n1*n0);
end
