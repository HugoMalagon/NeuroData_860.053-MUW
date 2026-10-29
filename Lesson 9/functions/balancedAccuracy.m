function bacc = balancedAccuracy(yTrue, yPred)
% balancedAccuracy  Mean of the per-class accuracies (recall).
%
%   bacc = balancedAccuracy(yTrue, yPred)
%
%   With unbalanced classes (e.g. 70 % rewarded trials) plain accuracy is
%   misleading: always answering "rewarded" already gives 70 %. Balanced
%   accuracy averages the hit rate of each class, so chance is always 0.5
%   for two classes, whatever the class proportions.
%
%   Course: MUW 860.053

yTrue = yTrue(:); yPred = yPred(:);
classes = unique(yTrue);
acc = zeros(numel(classes), 1);
for c = 1:numel(classes)
    m = yTrue == classes(c);
    acc(c) = mean(yPred(m) == classes(c));
end
bacc = mean(acc);
end
