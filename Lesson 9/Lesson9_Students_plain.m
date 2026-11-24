% Lesson9_Students_plain.m
% Plain-script version of the live script Lesson9_Students.mlx, for
% computers on which the live script does not open. The text, code and
% exercises are the same; only the layout is different.
%
% How to use this file
% * Open it in the MATLAB Editor and set the Current Folder to the folder
%   "Lesson 9" (the folder that contains this file).
% * Run it one section at a time: click inside a section (each section
%   starts at a line that begins with %%) and press Ctrl+Enter (macOS:
%   Cmd+Enter), or click Run Section in the Editor tab.
% * Results appear in the Command Window, figures in figure windows.
% * The lesson text is in the comments. Marks such as *bold*, _italic_
%   and |code| are the formatting of the live script, and equations
%   are written in LaTeX between $$ signs.
% * Write your answers where it says "% >>> YOUR CODE HERE <<<".

%% Lesson 9 - Models: Behaviour, Encoding, Decoding and Population Dynamics
% *Processing and Interpretation of Neuroscience Data (860.053-MUW)* -
% Vered Kellner and Hugo Malagon Vina. Data property of V. Kellner and
% H. Malagon Vina.
%
% Lesson 7 asked "does this neuron respond?". Now we build *models*:
%
% # A model of the *animal*: what does it choose, and how does it learn
% the value of each option from rewards? (behaviour, reinforcement learning)
% # *Encoding* models: which task variables explain the firing of each
% neuron? (generalised linear models)
% # *Decoding* models: can we read out the outcome or the choice from the
% activity of the population? When in the trial? (cross-validated classifiers)
% # *Null distributions*: how do we know that a model found something
% real? (shuffling and bootstrapping)
% # *Population dynamics*: how does the activity of all neurons together
% evolve during a trial? (principal component analysis, PCA)
%
% *Learning goals*
%
% * Quantify behaviour (choices, win-stay/lose-shift) and fit a learning
% model to it
% * Fit and interpret a Poisson GLM of spike counts
% * Build decoders correctly: cross-validation, balanced accuracy,
% overfitting and confounds
% * Build the right null distribution (what to shuffle, and why) and
% estimate uncertainty with the bootstrap
% * Visualise population activity with PCA
%
% *The task (reminder)*: the mouse stops a wheel for 1 s (trial start), a
% cue appears, it turns the wheel to the Gamble or the Safe side and gets
% the outcome ("reward period"). Safe = 1 drop with 90 %; Gamble = 4 drops
% with 75 % (block 1), 22.5 % (block 2) or 12.5 % (block 3).
%
% Toolboxes: Statistics and Machine Learning.

%% 0. Setup and data
% *Which trials?* This lesson uses three sets of trials:
%
% * |T|: all 179 trials (the full sequence, needed when we look at
% consecutive trials, section 1.1);
% * |hasChoice|: the 177 trials with a choice, used to fit the learning
% model (section 2);
% * |V| = |T(T.Valid, :)|: the 176 responded trials of blocks 1-3, used for
% all neural analyses.
%
% The model values (|RL.Qg|, |RL.Qs|, |RL.Pg|) have one entry per row of
% |T|; use |RL.Qg(T.Valid)| to match the rows of |V|.
clear; close all; clc
assert(isfolder('data'), ['Data folder not found. Set the Current Folder ' ...
    'to the "Lesson 9" folder and run again.'])
addpath('functions')
rng(1)
load(fullfile('data', 'SpikeTimes.mat'))       % spikeTimes (cell), sessionInfo
load(fullfile('data', 'Trials_Table.mat'))     % Trials_Table (event times in s)
T = Trials_Table;
V = T(T.Valid, :);                             % responded trials of blocks 1-3
nNeurons = numel(spikeTimes);
fprintf('%d neurons, %d trials (%d valid)\n', nNeurons, height(T), height(V));

%% 1. Behaviour first
% Neural data only make sense in the light of behaviour, and any model of
% the animal starts by describing what it does. Did the mouse follow the
% changes in reward probability?
blockChange = V.Trial(find(diff(V.Block)) + 1);
figure('Position', [100 100 1000 350])
tiledlayout(1, 3, 'TileSpacing', 'compact')
nexttile
plot(V.Trial, movmean(V.ChoseGamble, 10), 'k', 'LineWidth', 1.5); hold on
plot(V.Trial(V.Rewarded == 1), 1.05, 'g|')
plot(V.Trial(V.Rewarded == 0), -0.05, 'r|')
xline(blockChange, '--', 'HandleVisibility', 'off')
ylim([-0.1 1.1]); xlabel('Trial'); ylabel('P(gamble), 10-trial mean')
title('Choices')
nexttile
G = groupsummary(V, 'Block', 'mean', 'ChoseGamble');
bar(G.Block, G.mean_ChoseGamble); ylim([0 1])
xlabel('Block'); ylabel('P(gamble)'); title('Preference')
nexttile
G2 = groupsummary(V, {'Block', 'ChoseGamble'}, 'mean', 'Rewarded');
G2 = G2(G2.GroupCount >= 3, :);                       % ignore tiny groups
bar(categorical(compose('B%d %s', G2.Block, string(G2.ChoseGamble))), G2.mean_Rewarded)
ylabel('P(reward)'); title('Reward (1 = gamble)')

%% 1.1 Win-stay / lose-shift
% Classic readout of reinforcement learning: after a reward, does the
% animal repeat its choice? After no reward, does it switch?
% We use T (all trials in their real order): consecutive trials must be
% neighbours in time.
arm = T.ChoseGamble; rew = T.Rewarded;
% arm(1:end-1) = trial t, arm(2:end) = trial t+1: pairs where BOTH have a choice
pairT    = find(~isnan(arm(1:end-1)) & ~isnan(arm(2:end)));   % first trial of each pair
% stay and afterWin have ONE ENTRY PER PAIR (not per trial)
stay     = arm(pairT + 1) == arm(pairT);
afterWin = rew(pairT) == 1;
winStay   = mean(stay(afterWin));
loseShift = mean(~stay(~afterWin));
fprintf('Win-stay %.0f%%, lose-shift %.0f%%\n', 100*winStay, 100*loseShift);

%% FOR YOU!! - L9-E.1
% # Compute win-stay and lose-shift separately for gamble and safe choices.
% Hint: |stay| and |afterWin| have one entry per pair of trials, and
% |armT = arm(pairT)| is the arm chosen in the first trial of each pair.
% Combine the masks: |stay(afterWin & armT == 1)| are the "stays" after a
% rewarded gamble choice.
% # (Optional) The time between the cue and the reward period
% (|Reward_s - Cue_s|) is the time the mouse needed to choose. Compare it
% between gamble and safe choices (plot the two distributions).
%
% *L9-Q.1* Is the mouse an outcome-driven learner? Is there a difference
% between the two arms after a loss? Win-stay/lose-shift only looks one
% trial back - the model of section 2 integrates the whole reward history.

% >>> YOUR CODE HERE <<<

%% 2. A model of learning: Rescorla-Wagner / Q-learning
% The mouse does not know the reward probabilities; it must *learn* them.
% A simple and very successful model keeps a value |Q| for each arm and
% updates it after every outcome with a *prediction error*:
%
% $$Q \leftarrow Q + \alpha\,(R - Q)$$
%
% |alpha| (0-1) is the learning rate. The choice is probabilistic
% ("softmax"): the bigger the value difference, the more likely the better arm,
%
% $$P(\mathrm{gamble}) = \frac{1}{1 + e^{-\beta (Q_g - Q_s)}}$$
%
% where |beta| is the inverse temperature (low = random, high = greedy).
% Here the gamble reward can also be scaled by a factor |rRatio| (big vs
% small reward).
%
% *Likelihood.* How good is a set of parameters? The model gives, before
% every trial, a probability P(gamble). The *likelihood* is the probability
% that the model gives to the choices the mouse ACTUALLY made: on a trial
% where the mouse chose gamble it is P(gamble), on a safe trial 1 - P(gamble).
% Over all trials these probabilities are multiplied; in practice we sum
% their logarithms (the *log-likelihood*, always negative; closer to 0 =
% better). Example: a model that always says P(gamble) = 0.5 has a
% log-likelihood of |n*log(0.5)| for n choices. |fitRLmodel| tries a grid
% of parameter values and keeps the combination with the highest
% log-likelihood (open |fitRLmodel.m|).
RL = fitRLmodel(T.ChoseGamble, T.Rewarded);       % RL.Qg, RL.Qs, RL.Pg: one value per row of T
fprintf('alpha = %.2f, beta = %.1f, rRatio = %.1f, log-likelihood = %.1f\n', ...
    RL.alpha, RL.beta, RL.rRatio, RL.logLik);

hasChoice = ~isnan(T.ChoseGamble);               % the 177 trials the model was fitted on
figure('Position', [100 100 1000 550])
tiledlayout(2, 1, 'TileSpacing', 'compact')
nexttile
plot(T.Trial(hasChoice), movmean(T.ChoseGamble(hasChoice), 10), 'k'); hold on
plot(T.Trial, RL.Pg, 'r', 'LineWidth', 1.5)
xline(T.Trial(find(diff(T.Block)) + 1), '--')
ylabel('P(gamble)'); legend('animal (10-trial mean)', 'model', 'Location', 'best')
title('The model follows the behaviour')
nexttile
plot(T.Trial, RL.Qg, T.Trial, RL.Qs, 'LineWidth', 1.5)
xline(T.Trial(find(diff(T.Block)) + 1), '--')
xlabel('Trial'); ylabel('Value Q'); legend('Q gamble', 'Q safe')

%% 2.1 The likelihood landscape (demo)
% *Demo:* the teacher explains this figure.
%
% The likelihood landscape shows how well each parameter combination
% explains the choices (at the best |rRatio|). A sharp peak means the
% parameters are well constrained by the data.
[~, iR] = min(abs(RL.grid.rRatios - RL.rRatio));
figure
imagesc(RL.grid.betas, RL.grid.alphas, RL.logLikGrid(:, :, iR)); axis xy
xlabel('\beta (inverse temperature)'); ylabel('\alpha (learning rate)')
cb = colorbar; cb.Label.String = 'log-likelihood';
clim(RL.logLik + [-30 0]); ylim([0 0.3]); hold on
plot(RL.beta, RL.alpha, 'rp', 'MarkerSize', 14, 'MarkerFaceColor', 'r')

%% FOR YOU!! - L9-E.2
% Is learning needed to explain the behaviour? Compare the RL model with
% two simpler models using the *Bayesian information criterion*,
% |BIC = k*log(n) - 2*logLik| (k = number of free parameters, n = number
% of choices; lower BIC = better):
%
% # a "random" model: P(gamble) = 0.5 on every trial (k = 0) - computed
% for you in the code below;
% # a "bias" model: P(gamble) = the overall fraction of gamble choices (k = 1);
% # the RL model (k = 3), whose log-likelihood is |RL.logLik|.
%
% Compute the log-likelihood of the bias model and the three BICs. Hint:
% the log-likelihood of a model that gives the same P(gamble) = p on every
% trial is |sum(c*log(p) + (1-c)*log(1-p))| (for a gamble choice, c = 1,
% this adds log(p); for a safe choice log(1-p)).
c = T.ChoseGamble(hasChoice); nC = numel(c);   % the 177 choices of the RL fit
LL_rand  = nC * log(0.5);                      % random model: log(0.5) per choice
BIC_rand = 0*log(nC) - 2*LL_rand;

% >>> YOUR CODE HERE <<<

%% 3. Encoding: what drives the firing of a neuron?
% A *generalised linear model* (GLM) explains a neuron's spike count on
% each trial from task variables. Spike counts are non-negative integers,
% so we use a *Poisson* GLM with a log link:
%
% $$\log E[\mathrm{count}] = b_0 + b_1\,\mathrm{Rewarded} + b_2\,\mathrm{Gamble} + b_3\,(Q_g - Q_s) + b_4\,\mathrm{Trial}$$
%
% This is a *regression*: every coefficient |b| says how much the log of the
% expected count changes when its predictor increases by 1 (all others
% fixed). |exp(b)| is a *rate ratio*: exp(b1) = 2 means twice as many
% spikes after a reward. |b0| is the baseline.
%
% We add the trial number as a *nuisance* predictor: firing rates often
% drift slowly during a session (electrode drift, satiety, arousal). Any
% slowly changing task variable (the block, the value dQ) would otherwise
% "explain" that drift.
%
% The continuous predictors are z-scored (mean 0, SD 1), so their
% coefficients are comparable: "change per 1 SD of the predictor". In
% |fitglm| the model is written as a formula: |'Count ~ Rewarded + Gamble'|
% means "explain the column Count from the columns Rewarded and Gamble"
% (the intercept b0 is added automatically).
dQ = RL.Qg(T.Valid) - RL.Qs(T.Valid);             % value difference before the choice (rows of V)
tWin = [0 1];                                      % time window: 0-1 s after the outcome
% A Poisson GLM needs spike COUNTS: the 2nd output of countSpikesInWindows
[~, cnt] = countSpikesInWindows(spikeTimes, V.Reward_s + tWin(1), V.Reward_s + tWin(2));
X = table(V.Rewarded, V.ChoseGamble, zscore(dQ), zscore(V.Trial), ...
    'VariableNames', {'Rewarded', 'Gamble', 'dQ', 'TrialNum'});

n = 60;
tblN = X; tblN.Count = cnt(:, n);
glm = fitglm(tblN, 'Count ~ Rewarded + Gamble + dQ + TrialNum', 'Distribution', 'poisson');
disp(glm.Coefficients)
fprintf('Rate ratio for reward: %.2f\n', exp(glm.Coefficients.Estimate(2)));

%% 3.1 Reading the output
% |glm.Coefficients| has one row per predictor (plus the intercept):
%
% * |Estimate|: the coefficient b, on the *log* scale; |exp(b)| is the
% rate ratio.
% * |SE|: its standard error - how uncertain the estimate is.
% * |tStat| = Estimate / SE.
% * |pValue|: the test of b = 0 *with all the other predictors in the
% model*.
%
% For neuron 60 this reads:
%
% * *Rewarded*: b = 1.79, exp(b) = 6.0 - about 6 times more spikes after a
% reward, with choice, value and trial number held fixed.
% * *Gamble*: b close to 0 (p = 0.34) - the chosen arm itself does not
% matter.
% * *TrialNum*: b = -0.54, exp(b) = 0.58 - the neuron fires less as the
% session goes on (per 1 SD of trial number, about 50 trials).
% * *dQ*: b = -0.37, p < 1e-6 - value coding? Careful: dQ and TrialNum
% are strongly correlated (printed below), so the model can hardly tell
% them apart. Correlated (*collinear*) predictors share explained variance
% and their coefficients become unstable. Section 5.2 tests value coding
% properly, with the right null distribution.
fprintf('Correlation dQ vs TrialNum: r = %.2f\n', corr(X.dQ, X.TrialNum));

%%
% *What can a GLM tell you that a t-test (Lesson 7) cannot?*
%
% * The effect of each variable *controlling for the others*: the reward
% effect of neuron 60 is not explained by the choice or by slow drift.
% * An effect size in meaningful units: a rate ratio ("6 times more
% spikes").
% * Fitted to every neuron (see the homework): which variables each neuron
% encodes - often several at once.

%% 4. Decoding: reading the outcome from neurons
% Decoding asks the reverse question: given the activity, can we predict
% the label (rewarded or not) of a trial we have *not* used to train the model?
%
% *First, a trap.* 70 % of the trials are rewarded. A "decoder" that
% always answers "rewarded" is right 70 % of the time without looking at
% any neuron! Plain accuracy is misleading with unbalanced classes; use
% *balanced accuracy* (mean accuracy of each class, chance = 0.5) or the
% *AUC* (chance = 0.5).
isRewarded = V.Rewarded;                 % the labels we decode (1 = rewarded)
fprintf('Fraction rewarded: %.2f\n', mean(isRewarded));
alwaysYes = ones(size(isRewarded));
fprintf('"Always rewarded": accuracy %.2f, balanced accuracy %.2f\n', ...
    mean(alwaysYes == isRewarded), balancedAccuracy(isRewarded, alwaysYes));

%% 4.1 A single neuron, done right
% Logistic regression (a GLM for binary labels) with 5-fold
% cross-validation: train on 4/5 of the trials, test on the remaining 1/5,
% rotate. The decoder computes a weighted sum of the firing rates and
% passes it through the same S-shaped function as the softmax of section
% 2, which gives P(rewarded). Training = finding the weights (open
% |decodeCV.m|). Then build a *null distribution* by shuffling the labels: what
% accuracy do we get when there is nothing to find? (Section 5 looks at
% null distributions in detail.)
ratesPost = countSpikesInWindows(spikeTimes, V.Reward_s, V.Reward_s + 1);   % rates 0-1 s after the outcome, trials x neurons
[bacc60, auc60] = decodeCV(ratesPost(:, 60), isRewarded, 5);
nShuf = 200; nullB = zeros(nShuf, 1);
for i = 1:nShuf
    nullB(i) = decodeCV(ratesPost(:, 60), isRewarded(randperm(numel(isRewarded))), 5);
end
pDec = (sum(nullB >= bacc60) + 1) / (nShuf + 1);
fprintf('Neuron 60: balanced accuracy %.2f, AUC %.2f, p = %.3f\n', bacc60, auc60, pDec);
figure; histogram(nullB, 20); xline(bacc60, 'r', 'LineWidth', 2)
xlabel('Balanced accuracy'); title('Shuffled-label null distribution (red = real)')

%% 4.2 The population: more neurons, more information... and overfitting
% With 141 neurons and ~140 training trials a model can memorise the
% training data perfectly (training accuracy = 1) - the gap between
% training and test performance is *overfitting*. To make it obvious we
% add 300 fake "neurons" that are pure noise: they carry no information,
% but the model still uses them to fit the training trials.
%
% *Ridge regularisation* (|lambda|) penalises large weights. Too little:
% the model fits noise (overfitting). Too much: the model becomes too
% simple and misses real structure (underfitting). The sweep below shows
% both ends.
noise = randn(numel(isRewarded), 300);
lambdas = logspace(-6, 1, 8);                       % 8 values from 1e-6 to 1e1, equally spaced on a log scale
[trA, teA, trN, teN] = deal(zeros(size(lambdas)));  % deal: give the same value to several variables
for i = 1:numel(lambdas)
    [teA(i), ~, ~, trA(i)] = decodeCV(ratesPost, isRewarded, 5, lambdas(i));
    [teN(i), ~, ~, trN(i)] = decodeCV([ratesPost noise], isRewarded, 5, lambdas(i));
end
figure
semilogx(lambdas, trA, 'b--', lambdas, teA, 'b-', lambdas, trN, 'r--', lambdas, teN, 'r-', ...
    'LineWidth', 1.5)
yline(0.5, 'k:'); ylim([0.4 1.02])
xlabel('\lambda (ridge)'); ylabel('Balanced accuracy')
legend('141 neurons: train', '141 neurons: test', '+300 noise: train', '+300 noise: test', ...
    'Location', 'southwest')
title('Overfitting (left) and underfitting (right)')
% Only the TEST performance tells us what the population encodes. The
% training performance is always optimistic. The best lambda must itself
% be chosen by cross-validation on the training data (nested CV).

%% 4.3 Neuron-dropping curve (demo)
% *Demo:* run it and look at the result (it takes a few seconds).
%
% *Neuron-dropping curve*: how does performance grow with the number of
% neurons? Neurons are drawn at random many times (the order of the
% columns in |STMtx| means nothing).
sizes = [1 2 5 10 20 40 80 141];
nDraw = 20;
accN = nan(numel(sizes), nDraw);
for s = 1:numel(sizes)
    for d = 1:nDraw
        pick = randperm(nNeurons, sizes(s));
        accN(s, d) = decodeCV(ratesPost(:, pick), isRewarded, 5, 1e-2);   % lambda = 1e-2: a reasonable (not tuned) value, see the sweep above
    end
end
figure
errorbar(sizes, mean(accN, 2), std(accN, 0, 2), 'o-', 'LineWidth', 1.5)
set(gca, 'XScale', 'log'); yline(0.5, 'k--', 'chance')
xlabel('Number of neurons'); ylabel('Balanced accuracy (test)')
title('Decoding the outcome: neuron-dropping curve')

%% FOR YOU!! - L9-E.3
% Decode the *choice* (|V.ChoseGamble|) from the population in the 0.6 s
% *before* the outcome. Use NEW variable names (e.g. |ratesPre|): do not
% overwrite |ratesPost| or |isRewarded|, the next sections use them.
%
% # Use all valid trials. What balanced accuracy do you get?
% # Now use only trials of block 2 (where the mouse chose both arms about
% equally often). Does the accuracy drop?
%
% *L9-Q.2* Choice is strongly correlated with the block (gamble in block
% 1, safe in block 3). Why can this *confound* inflate the decoding of
% choice in (1)? How does (2) control for it?
b2 = V.Block == 2;       % block-2 trials (also used in L9-X.1)

% >>> YOUR CODE HERE <<<

%% 5. Null distributions: shuffling and bootstrapping
% Every number in this lesson (a balanced accuracy of 0.84, an AUC of
% 0.89, a correlation of 0.4) is meaningless without a reference: *what
% would we get if there were nothing to find?* That reference is the
% *null distribution*. The theoretical chance level (0.5) is NOT enough:
%
% * with a finite number of trials, chance results scatter around 0.5;
% * the analysis itself can be biased, so its chance level is not 0.5;
% * the data have structure (blocks, slow drift, autocorrelation) that
% creates relationships nobody is interested in.
%
% A *surrogate* data set is built by shuffling the data so that it destroys
% *exactly* the relationship we test and keeps everything else. Two rules:
%
% # The surrogate data go through the WHOLE analysis, exactly like the
% real data.
% # The null hypothesis decides WHAT you shuffle.

%% 5.1 Rule 1: shuffle the whole pipeline (double dipping)
% A tempting shortcut: pick the 10 neurons that best separate rewarded
% from unrewarded trials (AUC on ALL trials), then cross-validate a decoder
% on those 10. The test trials were already used to choose the neurons, so
% the decoder has seen them: this is *double dipping* (circular analysis).
% Running the same pipeline on shuffled labels shows how big the bias is.
nBest = 10;
% maxk(x, n): the n largest values (2nd output: their positions = neurons)
[~, best] = maxk(abs(aucColumns(ratesPost, isRewarded) - 0.5), nBest);
baccDip = decodeCV(ratesPost(:, best), isRewarded, 5, 1e-2);
nShuf = 100;
nullDip = zeros(nShuf, 1);
for i = 1:nShuf
    ySh = isRewarded(randperm(numel(isRewarded)));                            % no information left...
    [~, bestSh] = maxk(abs(aucColumns(ratesPost, ySh) - 0.5), nBest);   % ...same selection
    nullDip(i) = decodeCV(ratesPost(:, bestSh), ySh, 5, 1e-2);  % ...same decoder
end
fprintf('Double dipping: real %.2f, shuffled labels %.2f on average (not 0.50!)\n', ...
    baccDip, mean(nullDip));
figure
histogram(nullDip, 0.3:0.02:1); hold on
xline(0.5, '--', 'theoretical chance', 'LabelVerticalAlignment', 'middle')
xline(mean(nullDip), 'b', 'chance of THIS pipeline', 'LabelVerticalAlignment', 'middle')
xline(baccDip, 'r', 'real', 'LineWidth', 2)
xlabel('Balanced accuracy'); ylabel('Shuffles')
title('Selection + decoding on shuffled labels')

%%
% Two lessons: (1) the accuracy of a double-dipped decoder is inflated
% and cannot be reported; (2) a null built by running the *whole*
% pipeline on shuffled data has the same bias, so the p-value stays
% honest. A null built from a shortcut (e.g. "chance = 0.5") does not.
% The honest decoder selects neurons inside each training fold (homework).

%% 5.2 Rule 2: what to shuffle? Trials are not independent (demo)
% *Demo:* the teacher explains section 5.2. Read the conclusion (the text
% below the figure) carefully.
%
% Question: does the firing of each neuron *before the cue* correlate with
% the value difference |dQ| of the RL model (section 2)? |dQ| changes
% slowly across the session (blocks!), and firing rates drift slowly too.
% Three nulls, from naive to strict:
%
% * *Trial permutation*: shuffle the order of |dQ|. Destroys its slow
% structure, so it assumes independent trials. Too permissive here.
% * *Circular shift*: rotate |dQ| by a random number of trials. Keeps its
% autocorrelation, breaks the alignment with the neurons.
% * *Pseudo-sessions* (Harris 2020, "Nonsense correlations in
% neuroscience"): simulate new sessions of the RL agent in the SAME task
% (same blocks, same reward probabilities) and compute |dQ| from them. It
% keeps everything the task imposes on |dQ| - only the link to what the
% mouse actually experienced is gone.
rPre = countSpikesInWindows(spikeTimes, V.Cue_s - 1, V.Cue_s);   % trials x neurons
rObs = corr(dQ, rPre);                                  % dQ from section 3; 1 x neurons
nT = numel(dQ); nNull = 500;
[dQperm, dQcirc] = deal(zeros(nT, nNull));
for i = 1:nNull
    dQperm(:, i) = dQ(randperm(nT));
    dQcirc(:, i) = circshift(dQ, randi(round([0.1 0.9]*nT)));   % circshift: rotate the vector (end wraps to the start)
end
dQpseudo = simulateSessions(RL, T, nNull);              % helper: functions/simulateSessions.m
nulls = {corr(dQperm, rPre), corr(dQcirc, rPre), corr(dQpseudo, rPre)};   % nNull x neurons
nullNames = {'trial permutation', 'circular shift', 'pseudo-sessions'};
pNull = zeros(nNeurons, 3); nSig = zeros(1, 3);
for j = 1:3
    pNull(:, j) = (sum(abs(nulls{j}) >= abs(rObs)) + 1) / (nNull + 1);
    pNull(isnan(rObs), j) = NaN;                        % silent neurons: no test
    nSig(j) = sum(fdr_bh(pNull(:, j), 0.05));
    fprintf('%-18s: %3d of %d neurons correlate with dQ (FDR)\n', nullNames{j}, nSig(j), nNeurons);
end

%%
% Neuron 78 has the strongest correlation. In Lesson 7 we saw why: it stops
% firing at ~850 s (the unit is lost), just when |dQ| drops in block 3.
n = 78;
figure('Position', [100 100 800 650])
tiledlayout(2, 1, 'TileSpacing', 'compact')
nexttile
yyaxis left;  plot(V.Trial, dQ, 'LineWidth', 1.5); ylabel('dQ (real)')    % yyaxis: two y axes in one plot
yyaxis right; plot(V.Trial, rPre(:, n)); ylabel(sprintf('Neuron %d rate (Hz)', n))
xlabel('Trial'); title(sprintf('r = %.2f', rObs(n)))
nexttile; hold on
for j = 1:3
    histogram(nulls{j}(:, n), -1:0.05:1, 'Normalization', 'probability', 'DisplayStyle', 'stairs', 'LineWidth', 1.5)
end
xline(rObs(n), 'r', 'LineWidth', 2)
yl = ylim; ylim([0 1.7*yl(2)])                          % room for the legend
legend([nullNames, {'real'}], 'Location', 'north', 'NumColumns', 2)
xlabel('Correlation with dQ'); ylabel('Fraction'); title('Three null distributions')

%%
% Same data, same statistic, three answers: from most neurons "encode
% value" to almost none. Pseudo-session |dQ| also follows the blocks, so a
% neuron that just drifts across the session correlates with them too.
% *The null must keep every structure that is not part of your
% hypothesis.* Other common shuffles:
%
% * *Stratified / within-block permutation*: shuffle labels only inside
% each block (or session, animal) - controls for that grouping.
% * *Spike-time jitter* (e.g. +/- 5 ms): keeps the slow firing rate,
% destroys fine timing - the null for synchrony and CCG peaks (Lesson 7).
% * *ISI shuffle*: keeps the ISI distribution, destroys their order -
% tests bursts and rhythms.
% * *Shuffling trials of one neuron against another* (keeping conditions):
% destroys noise correlations, keeps tuning.
%
% How many shuffles? The smallest p-value you can get is |1/(nShuf + 1)|:
% 100 shuffles give at best p = 1/101, about 0.01. To survive a correction over 141
% neurons you need thousands.

%% 5.3 Bootstrap: how precise is my estimate?
% A permutation test asks: *could this result come from a world without an
% effect?* The *bootstrap* asks a different question: *how much would my
% estimate change if I repeated the experiment?* We resample the trials
% WITH replacement (same number of trials), recompute the statistic, and
% repeat. The spread of the bootstrap values gives a *confidence
% interval*. The permutation null is centred on "no effect", the bootstrap
% distribution on the observed value.
r60 = ratesPost(:, 60);
i1 = find(isRewarded == 1); i0 = find(isRewarded == 0);
aucObs = aucFromSamples(r60(i1), r60(i0));
nBoot = 2000;
[bootAUC, permAUC] = deal(zeros(nBoot, 1));
for b = 1:nBoot
    s1 = i1(randi(numel(i1), numel(i1), 1));     % resample each class separately
    s0 = i0(randi(numel(i0), numel(i0), 1));     % (keeps the 70/30 proportion)
    bootAUC(b) = aucFromSamples(r60(s1), r60(s0));
    ySh = isRewarded(randperm(numel(isRewarded)));
    permAUC(b) = aucFromSamples(r60(ySh == 1), r60(ySh == 0));
end
ci95 = prctile(bootAUC, [2.5 97.5]);     % prctile: the values below which 2.5 % and 97.5 % of the data lie
pPerm = (sum(abs(permAUC - 0.5) >= abs(aucObs - 0.5)) + 1) / (nBoot + 1);
fprintf('Neuron 60: AUC = %.2f, 95%% bootstrap CI [%.2f %.2f], permutation p = %.4f\n', ...
    aucObs, ci95, pPerm);
figure; hold on
histogram(permAUC, 0:0.01:1, 'FaceColor', [0.6 0.6 0.6])
histogram(bootAUC, 0:0.01:1, 'FaceColor', [0.9 0.4 0.2])
xline(aucObs, 'r', 'LineWidth', 2); xline(ci95, 'r--')
legend('permutation null (is there an effect?)', 'bootstrap (how precise?)', ...
    'observed', '95% CI', 'Location', 'northwest')
xlabel('AUC rewarded vs unrewarded'); ylabel('Count')

%%
% * *Resample the right unit.* Here trials, because the claim is about
% neuron 60. For a claim about the population, resample *neurons*; for
% mice, resample *animals* (hierarchical bootstrap). Resampling trials
% pooled across animals is pseudoreplication (Lesson 7).
% * MATLAB's |bootci| does this in one line (homework); its default is a refined interval called 'bca'.

%% FOR YOU!! - L9-E.4
% # *Bootstrap*: compute 95 % confidence intervals for the win-stay and
% lose-shift rates of section 1.1 by resampling the trial pairs with
% replacement 2000 times. Is lose-shift different from 50 %? Hint: in each
% repetition |s = randi(nP, nP, 1)| (nP = number of pairs) picks pairs with
% replacement; then compute win-stay from |stay(s)| and |afterWin(s)|.
% # (Optional) *Within-block shuffle*: decode the choice (|V.ChoseGamble|)
% from the firing rates in the 0.6 s before the outcome, using all valid
% trials (as in L9-E.3). Build two nulls with 30 shuffles each: (a)
% shuffle the choices across all trials; (b) shuffle the choices only
% *within* each block. Plot both nulls and the real value. Code for one
% within-block shuffle:
%
%   chW = ch;                                 % ch = V.ChoseGamble
%   for bk = 1:3
%       ix = find(V.Block == bk);             % the trials of this block
%       chW(ix) = ch(ix(randperm(numel(ix))));    % shuffled among themselves
%   end
%
% *L9-Q.3* Why is null (b) above 0.5? What does it mean if the real value
% is above null (a) but inside null (b)? Which question does a permutation
% p-value answer, and which one a bootstrap confidence interval?

% >>> YOUR CODE HERE <<<

%% 6. Population dynamics with PCA (demo)
% *Demo:* run sections 6 and 6.1 while the teacher explains; your task is
% L9-E.5.
%
% Each moment of the trial is a point in a 141-dimensional space (one axis
% per neuron). PCA finds the few directions that capture most of the
% variance, so we can *see* the population state move through the trial:
% a *neural trajectory*.
%
% First we count the spikes of every neuron in 100-ms bins around the
% outcome, in every trial. The counts go into a *3-D array*
% |cntBins(trial, bin, neuron)|: a stack of trials x bins matrices, one
% per neuron. Then we average the trials of four conditions, z-score each
% neuron, and run PCA on the (conditions x time) by neurons matrix.
pre = 2; post = 2.5; step = 0.1;
aligned = cell(height(V), nNeurons);
for k = 1:nNeurons
    aligned(:, k) = alignSpikes(spikeTimes{k}, V.Reward_s, pre, post);
end
edges = -pre:step:post;
cntBins = zeros(height(V), numel(edges) - 1, nNeurons);
for k = 1:nNeurons
    for tr = 1:height(V)
        cntBins(tr, :, k) = histcounts(aligned{tr, k}, edges);
    end
end
conds = {V.ChoseGamble == 1 & V.Rewarded == 1, V.ChoseGamble == 1 & V.Rewarded == 0, ...
         V.ChoseGamble == 0 & V.Rewarded == 1, V.ChoseGamble == 0 & V.Rewarded == 0};
condNames = {'gamble rewarded', 'gamble unrewarded', 'safe rewarded', 'safe unrewarded'};
rateBins = cntBins / step;                                    % trials x bins x neurons
tb = edges(1:end-1) + step/2;
nBins = numel(tb);
M = zeros(4*nBins, nNeurons);
for c = 1:4
    m = squeeze(mean(rateBins(conds{c}, :, :), 1));          % mean over trials -> bins x neurons
    % stack the 4 conditions below each other: rows (c-1)*nBins+1 ... c*nBins
    M((c-1)*nBins + (1:nBins), :) = movmean(m, 3, 1);        % light smoothing along time
end
Mz = (M - mean(M)) ./ (std(M) + eps);
[coeff, score, ~, ~, explained] = pca(Mz);
fprintf('Variance explained by PC1-3: %.0f%%, %.0f%%, %.0f%%\n', explained(1:3));
cols = [0.9 0.5 0.1; 0.6 0.3 0.1; 0.2 0.6 0.9; 0.1 0.3 0.5];
figure('Position', [100 100 1000 400])
tiledlayout(1, 2)
nexttile; hold on
for c = 1:4
    sc = score((c-1)*nBins + (1:nBins), :);                  % the rows of condition c
    plot(tb, sc(:, 1), 'Color', cols(c, :), 'LineWidth', 1.5)
end
xline(0, 'k--'); xlabel('Time from outcome (s)'); ylabel('PC1'); legend(condNames, 'Location', 'best')
nexttile; hold on
for c = 1:4
    sc = score((c-1)*nBins + (1:nBins), :);
    plot(sc(:, 1), sc(:, 2), 'Color', cols(c, :), 'LineWidth', 1.5)
    [~, iT0] = min(abs(tb));                                  % bin closest to the outcome (t = 0)
    plot(sc(iT0, 1), sc(iT0, 2), 'o', 'MarkerFaceColor', cols(c, :), 'MarkerEdgeColor', 'k')
    plot(sc(1, 1), sc(1, 2), 's', 'Color', cols(c, :))
end
xlabel('PC1'); ylabel('PC2'); title('Square = -2 s, circle = outcome')

%%
% *Look carefully*: PC1 separates gamble from safe trials at ALL times,
% even 2 s before the outcome. It also separates rewarded from unrewarded
% *gamble* trials before the outcome: rewarded gambles come mostly from
% block 1, unrewarded ones from block 2. Gamble trials happen mostly early
% in the session, so PC1 probably reflects slow drift or the block, not
% the choice or the outcome (compare L9-E.3). Where is the outcome? You
% will find it in L9-E.5.

%% 6.1 What is behind a PC? Loadings and contributions (demo)
% |pca| returns more than the scores:
%
% * |coeff| (neurons x PCs): the *loadings*. Column k holds one weight per
% neuron: PCk is a weighted sum of the z-scored neurons,
% |score(:, k) = Mz * coeff(:, k)| (|Mz| is already centred).
% * |score| (rows x PCs): the *projections* - the trajectories we plotted.
% * |explained|: % of the variance captured by each PC.
%
% The *contribution* of neuron i to PCk is its squared loading,
% |100 * coeff(i, k)^2| %. For each PC they sum to 100 % (the columns of
% |coeff| have length 1). The *sign* gives the direction: neurons with the
% same sign go up and down together along the PC. The overall sign of a PC
% is arbitrary (PC1 and -PC1 are the same axis).
contribPC1 = 100 * coeff(:, 1).^2;             % % contribution of each neuron to PC1
[~, orderPC1] = sort(contribPC1, 'descend');   % neuron numbers, largest contribution first
topN = orderPC1(1:10);
disp(table(topN, coeff(topN, 1), contribPC1(topN), ...
    'VariableNames', {'Neuron', 'LoadingPC1', 'ContributionPct'}))
fprintf('The top 10 neurons make up %.0f%% of PC1\n', sum(contribPC1(topN)));
figure('Position', [100 100 900 330])
stem(1:nNeurons, coeff(:, 1), 'filled', 'MarkerSize', 3)
xlabel('Neuron'); ylabel('Loading on PC1'); title('What PC1 is made of: one weight per neuron')

%%
% Two things to notice:
%
% * PC1 is spread over many neurons: the top 10 have almost the same
% weight (~2 % each) and together make up only about a fifth of PC1. A PC
% is usually a pattern shared by many neurons, not a handful of "PC1
% neurons".
% * Among the top neurons is *78*, the unit that stops firing at ~850 s
% (Lesson 7, L7-E.1). Together with the gamble/safe split at all times,
% this fits the idea that PC1 largely captures slow changes over the
% session (drift), not the outcome.

%% FOR YOU!! - L9-E.5
% # Plot the trajectories in 3D (PC1-PC3) and rotate the figure. Which PC
% separates rewarded from unrewarded trials after the outcome? Hint: copy
% the second loop of section 6 and replace the |plot(...)| of the
% trajectory by |plot3(sc(:, 1), sc(:, 2), sc(:, 3), ...)|; then |view(3)|
% and the rotate button of the figure.
% # Plot the variance explained by the first 10 PCs (|explained|). How
% many dimensions does this population activity need?
% # (Optional) Repeat 6.1 for the PC that separates rewarded from
% unrewarded trials (part 1). Which neurons contribute most? Where does neuron 60 (the
% strong reward neuron of Lesson 7) rank on this PC, and where on PC1?
% Hint: |find(orderPC1 == 60)| gives the rank of neuron 60 on PC1.

% >>> YOUR CODE HERE <<<

%% HOMEWORK (optional)
% # *Encoding across the population*: fit the GLM of section 3 to every
% neuron (loop over the neurons, skip those with fewer than 20 spikes),
% correct the p-values of Rewarded, Gamble and dQ with |fdr_bh| and plot
% the % of neurons encoding each. Then repeat for the window *before* the
% outcome (-0.6 to 0 s). Is |Rewarded| still "encoded"? What would it
% mean if it were?
% # *Other session*: fit the RL model to |data/OtherSession| and compare the
% learning rate with this session.
% # *Two learning rates*: modify |fitRLmodel| so that gamble and safe values
% have different learning rates. Does BIC improve?
% # *Value neurons, honestly*: repeat section 5.2 for the window 0.6 s
% before the OUTCOME (instead of before the cue), with Spearman
% correlations (|corr(..., 'Type', 'Spearman')|). Use |dQ| (one value per
% row of |V|; |RL.Qg - RL.Qs| has one per row of |T|). How many neurons
% survive with the pseudo-session null?
% # *bootci*: re-plot the PSTH of neuron 60 aligned to the outcome (Lesson 7,
% section 2.2) with 95 % bootstrap confidence intervals instead of the SEM:
% |ci = bootci(1000, @mean, trialRates)| gives a 2 x nBins matrix.
% # *Other decoders*: replace logistic regression with an SVM (|fitcsvm|) or
% LDA (|fitcdiscr|). Does it matter?
% # *Nested cross-validation*: choosing the "best 10 neurons" on all trials
% and then cross-validating the decoder is cheating. Why? Implement the
% honest version (select neurons inside each training fold).
% # *Pseudo-sessions for decoding*: decode the choice before the outcome
% (L9-E.3) and build the null with |simulateSessions|-like simulated
% choices instead of shuffled ones. Compare with the within-block null of
% L9-E.4.
% # *Spike-time jitter*: for the pair 24 -> 26 of Lesson 7, count the
% spikes of 26 that fall 1-4 ms after a spike of 24. Build a null by
% jittering the spikes of 26 by +/- 5 ms (500 times). Is the peak real?
% Hint: |s26j = s26 + (rand(size(s26))*2 - 1) * 0.005|.
% # *Bootstrap a curve*: 95 % bootstrap CI of the neuron-dropping curve
% (section 4.3) at 10 neurons, resampling trials. Why is resampling
% trials inside a cross-validation tricky? (the same trial may end up in
% the training and in the test set)
% # *Decode the block* (3 classes) with |fitcecoc|. What is chance level?
% # *PCA on single trials*: project single trials onto the PCs of section 6
% (see "PCA by hand" in Going further). Are rewarded and unrewarded trials
% separable trial by trial?

%% GOING FURTHER (optional)
% Extra material for those who want more, or to practise at home. Nothing
% here is needed for the next lesson. Run section 6 first: these sections
% use its binned spike counts and its PCA.

%% When is the information there? Time-resolved decoding (optional)
% Slide a 200-ms window along the trial (aligned to the outcome) and
% decode in each window. The shaded band is the 95 % range of a
% shuffled-label null. (Only 10 shuffles per window to keep it fast: enough
% to sketch the null, not for a p-value. Testing every window also needs a
% correction across time, e.g. a cluster-based permutation test.)
%
% It uses the binned counts |cntBins(trial, bin, neuron)| of section 6.
% |winCnt(:, b, :)| takes one time window for all trials and neurons;
% |squeeze| removes the dimension of size 1, giving a trials x neurons
% matrix again. This takes about a minute.
winCnt = cntBins(:, 1:end-1, :) + cntBins(:, 2:end, :);     % 200-ms windows, 100-ms steps
tCenters = edges(2:end-1);
nT = numel(tCenters);
accT = zeros(1, nT); nullT = zeros(10, nT);
for b = 1:nT
    Xb = squeeze(winCnt(:, b, :));
    accT(b) = decodeCV(Xb, isRewarded, 5, 1e-2);
    for i = 1:10
        nullT(i, b) = decodeCV(Xb, isRewarded(randperm(numel(isRewarded))), 5, 1e-2);
    end
end
figure; hold on
fill([tCenters fliplr(tCenters)], [prctile(nullT, 2.5) fliplr(prctile(nullT, 97.5))], ...
    [0.8 0.8 0.8], 'EdgeColor', 'none')
plot(tCenters, accT, 'r', 'LineWidth', 2)
xline(0, 'k--', 'outcome'); yline(0.5, 'k:')
xlabel('Time from outcome (s)'); ylabel('Balanced accuracy')
title('Decoding reward over time')

%% FOR YOU!! - L9-X.1 (optional): choice versus reward over time
% Using |winCnt|, decode the *choice* over time (block-2 trials only, |b2|
% as in L9-E.3). Plot it together with the reward curve. Which information
% appears first, and does that make sense? Hint: copy the loop above and
% use |squeeze(winCnt(b2, b, :))| and |V.ChoseGamble(b2)| (new names - do
% not overwrite |isRewarded|).

% >>> YOUR CODE HERE <<<

%% PCA by hand (optional)
% The outputs of |pca| (section 6.1) are linked by simple matrix
% operations:
%
% * The scores are the centred data times the loadings:
% |score = Mz * coeff| (|Mz| is already centred).
% * Keeping only the first k PCs and multiplying back,
% |score(:, 1:k) * coeff(:, 1:k)'|, *reconstructs* the data approximately.
% The reconstructed variance is |sum(explained(1:k))|.
% * New data (for example single trials, see the homework) are projected
% onto the same PCs with the same formula, after the same centring and
% scaling.
scoreByHand = Mz * coeff;
fprintf('score by hand vs pca: largest difference %.1e\n', max(abs(scoreByHand(:) - score(:))));
kList = [1 2 3 5 10 20];
recVar = zeros(size(kList));
for i = 1:numel(kList)
    Mrec = score(:, 1:kList(i)) * coeff(:, 1:kList(i))';   % reconstruction from kList(i) PCs
    recVar(i) = 100 * (1 - sum((Mz(:) - Mrec(:)).^2) / sum(Mz(:).^2));
end
figure
plot(kList, recVar, 'o', 'MarkerSize', 8, 'LineWidth', 1.5); hold on
plot(1:20, cumsum(explained(1:20)), 'k-')
xlabel('Number of PCs kept'); ylabel('% variance'); ylim([0 100])
legend('reconstructed from k PCs', 'cumsum(explained)', 'Location', 'southeast')
title('A few PCs reconstruct most of the population activity')
