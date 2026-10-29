function [bacc, auc, scores, accTrain] = decodeCV(X, y, nFolds, lambda)
% decodeCV  Cross-validated logistic-regression decoder of a binary label.
%
%   [bacc, auc, scores, accTrain] = decodeCV(X, y)
%   [...] = decodeCV(X, y, nFolds, lambda)
%
%   INPUTS
%       X      - [nTrials x nFeatures] predictors (e.g. firing rates of neurons)
%       y      - [nTrials x 1] binary labels (0/1), e.g. rewarded
%       nFolds - number of cross-validation folds (default 5). Folds are
%                stratified: each keeps the proportion of 0s and 1s.
%       lambda - ridge (L2) regularisation strength (default 1/nTrials).
%                Larger lambda = simpler model, less overfitting.
%   OUTPUTS
%       bacc     - balanced accuracy on the held-out (test) trials
%                  (chance = 0.5 whatever the class proportions)
%       auc      - area under the ROC curve of the held-out scores
%       scores   - [nTrials x 1] held-out P(y = 1) of every trial
%       accTrain - mean balanced accuracy on the training trials
%
%   In each fold the features are z-scored with the mean/SD of the
%   TRAINING trials only (using the test trials would leak information).
%
%   Course: MUW 860.053

if nargin < 3 || isempty(nFolds), nFolds = 5; end
y = double(y(:));
if nargin < 4 || isempty(lambda), lambda = 1/numel(y); end
cv = cvpartition(y, 'KFold', nFolds);
scores = nan(numel(y), 1);
accTr = zeros(nFolds, 1);
for f = 1:nFolds
    tr = training(cv, f); te = test(cv, f);
    mu = mean(X(tr, :), 1); sd = std(X(tr, :), 0, 1); sd(sd == 0) = 1;
    Xtr = (X(tr, :) - mu) ./ sd;
    Xte = (X(te, :) - mu) ./ sd;
    mdl = fitclinear(Xtr, y(tr), 'Learner', 'logistic', ...
        'Regularization', 'ridge', 'Lambda', lambda, 'Solver', 'lbfgs');
    [~, sc] = predict(mdl, Xte);
    scores(te) = sc(:, 2);
    [~, scTr] = predict(mdl, Xtr);
    accTr(f) = balancedAccuracy(y(tr), scTr(:, 2) > 0.5);
end
bacc = balancedAccuracy(y, scores > 0.5);
auc  = aucFromSamples(scores(y == 1), scores(y == 0));
accTrain = mean(accTr);
end
