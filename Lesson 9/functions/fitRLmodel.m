function model = fitRLmodel(choices, rewards, alphas, betas, rRatios)
% fitRLmodel  Fit a Rescorla-Wagner (Q-learning) model to gamble/safe choices.
%
%   model = fitRLmodel(choices, rewards)
%   model = fitRLmodel(choices, rewards, alphas, betas, rRatios)
%
%   The model (same as RL_Gambling_Basic_ver2026.m, Flexi-Gambling repo):
%       P(gamble on trial t) = 1 / (1 + exp(-beta * (Qg - Qs)))
%       after the choice:
%         gamble chosen:  Qg <- Qg + alpha * (R * rRatio - Qg)
%         safe chosen:    Qs <- Qs + alpha * (R - Qs)
%       (rRatio = how much bigger the gamble reward is "felt" to be)
%   Parameters are found by grid search: the combination that maximises
%   the log-likelihood of the observed choices.
%
%   INPUTS
%       choices - [nTrials x 1] 1 = gamble, 0 = safe, NaN = no response
%       rewards - [nTrials x 1] 1 = rewarded, 0 = not rewarded
%       alphas, betas, rRatios - (optional) grids of values to test
%   OUTPUT
%       model - struct with fields
%           alpha, beta, rRatio : best parameters
%           logLik              : best log-likelihood
%           Qg, Qs              : [nTrials x 1] values BEFORE each choice
%           Pg                  : [nTrials x 1] model P(gamble) before each choice
%           RPE                 : [nTrials x 1] reward prediction error of the
%                                 chosen option (NaN on missed trials)
%           logLikGrid          : log-likelihood for every grid point
%
%   Course: MUW 860.053 (simplified from the Flexi-Gambling RL scripts)

if nargin < 3 || isempty(alphas),  alphas  = 0.01:0.01:1;  end
if nargin < 4 || isempty(betas),   betas   = 0.5:0.5:20;   end
if nargin < 5 || isempty(rRatios), rRatios = 1:0.5:6;      end

choices = choices(:); rewards = rewards(:);
[A, B, RR] = ndgrid(alphas, betas, rRatios);
A = A(:)'; B = B(:)'; RR = RR(:)';
nP = numel(A); nT = numel(choices);

Qg = zeros(1, nP); Qs = zeros(1, nP); LL = zeros(1, nP);
for t = 1:nT
    c = choices(t);
    if isnan(c), continue; end
    pg = 1 ./ (1 + exp(-B .* (Qg - Qs)));
    pg = min(max(pg, 1e-10), 1 - 1e-10);
    if c == 1
        LL = LL + log(pg);
        Qg = Qg + A .* (rewards(t) .* RR - Qg);
    else
        LL = LL + log(1 - pg);
        Qs = Qs + A .* (rewards(t) - Qs);
    end
end

[bestLL, best] = max(LL);
model.alpha  = A(best);
model.beta   = B(best);
model.rRatio = RR(best);
model.logLik = bestLL;
model.logLikGrid = reshape(LL, numel(alphas), numel(betas), numel(rRatios));
model.grid = struct('alphas', alphas, 'betas', betas, 'rRatios', rRatios);

% replay the best model to store trial-by-trial values
[model.Qg, model.Qs, model.Pg, model.RPE] = deal(nan(nT, 1));
qg = 0; qs = 0;
for t = 1:nT
    model.Qg(t) = qg; model.Qs(t) = qs;
    model.Pg(t) = 1 / (1 + exp(-model.beta * (qg - qs)));
    c = choices(t);
    if isnan(c), continue; end
    if c == 1
        model.RPE(t) = rewards(t) * model.rRatio - qg;
        qg = qg + model.alpha * model.RPE(t);
    else
        model.RPE(t) = rewards(t) - qs;
        qs = qs + model.alpha * model.RPE(t);
    end
end
end
