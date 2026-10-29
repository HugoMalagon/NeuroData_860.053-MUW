function auc = aucFromSamples(x1, x0)
% aucFromSamples  Area under the ROC curve comparing two samples.
%
%   auc = aucFromSamples(x1, x0)
%
%   AUC = probability that a random value of x1 is larger than a random
%   value of x0 (ties count 1/2). 0.5 = no difference, 1 = every x1 is
%   larger, 0 = every x1 is smaller. In neuroscience: how well an ideal
%   observer could tell the two conditions apart from the firing rate of
%   one neuron ("choice probability", "ROC selectivity").
%
%   Computed from the ranks (Mann-Whitney U statistic), which is fast
%   enough to run inside permutation tests.
%
%   EXAMPLE
%       auc = aucFromSamples(rateRewarded, rateUnrewarded);
%
%   Course: MUW 860.053

x1 = x1(:); x0 = x0(:);
x1 = x1(~isnan(x1)); x0 = x0(~isnan(x0));
n1 = numel(x1); n0 = numel(x0);
r = tiedrank([x1; x0]);
auc = (sum(r(1:n1)) - n1*(n1+1)/2) / (n1*n0);
end
