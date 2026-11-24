% Lesson7_Students_plain.m
% Plain-script version of the live script Lesson7_Students.mlx, for
% computers on which the live script does not open. The text, code and
% exercises are the same; only the layout is different.
%
% How to use this file
% * Open it in the MATLAB Editor and set the Current Folder to the folder
%   "Lesson 7" (the folder that contains this file).
% * Run it one section at a time: click inside a section (each section
%   starts at a line that begins with %%) and press Ctrl+Enter (macOS:
%   Cmd+Enter), or click Run Section in the Editor tab.
% * Results appear in the Command Window, figures in figure windows.
% * The lesson text is in the comments. Marks such as *bold*, _italic_
%   and |code| are the formatting of the live script.
% * Write your answers where it says "% >>> YOUR CODE HERE <<<".

%% Lesson 7 - Spikes and Statistics
% *Processing and Interpretation of Neuroscience Data (860.053-MUW)* -
% Vered Kellner and Hugo Malagon Vina. Data property of V. Kellner and
% H. Malagon Vina.
%
% We return to the prelimbic-cortex session of Lesson 6 (141 neurons,
% gambling task) and ask the central questions of systems neuroscience:
% *how do single neurons fire, and does their activity relate to what the
% animal senses, decides and obtains?* And: *how do we know that an effect
% is real?*
%
% *Learning goals*
%
% * Describe the firing of single neurons: rate, ISI, regularity (CV,
% LvR), bursts, autocorrelograms, unit quality
% * Detect interactions between neurons with cross-correlograms
% * Align spikes to task events: raster plots, PSTHs, smoothing,
% population heat maps
% * Choose the right statistical test: paired vs unpaired, parametric vs
% non-parametric, permutation tests, ROC/AUC, multiple comparisons,
% pseudoreplication
%
% *The task (reminder)*: the mouse stops a wheel for 1 s (trial start), a
% cue appears, it turns the wheel to the Gamble or the Safe side and gets
% the outcome ("reward period"). Safe = 1 drop with 90 %; Gamble = 4 drops
% with 75 % (block 1), 22.5 % (block 2) or 12.5 % (block 3).
%
% The spike times we use are the *output* of spike sorting. Lesson 8
% shows where they come from (raw signal -> filter -> detect -> sort), and
% Lesson 9 analyses the behaviour of the mouse and builds models of it.
%
% Toolboxes: Statistics and Machine Learning, Signal Processing.

%% 0. Setup and data
clear; close all; clc
assert(isfolder('data'), ['Data folder not found. Set the Current Folder ' ...
    'to the "Lesson 7" folder and run again.'])
addpath('functions')
rng(1)
load(fullfile('data', 'SpikeTimes.mat'))       % spikeTimes (cell), sessionInfo
load(fullfile('data', 'Trials_Table.mat'))     % Trials_Table (event times in s)
load(fullfile('data', 'STMtx.mat'))            % same spikes as a matrix
T = Trials_Table;
V = T(T.Valid, :);                             % responded trials of blocks 1-3
nNeurons = numel(spikeTimes);
sessionDur = sessionInfo.recordingEnd_s - sessionInfo.recordingStart_s;
fprintf('%d neurons, %d trials (%d valid), %.0f s\n', nNeurons, height(T), height(V), sessionDur);

%% 1. How do single neurons fire?
% We summarise each neuron with a few numbers (open |neuronFiringStats.m|):
%
% * *firing rate* (Hz)
% * *CV* of the inter-spike intervals (ISI) = SD(ISI) / mean(ISI): 1 for a
% Poisson process (spikes at random, independent times - the null model of
% spiking), < 1 more regular, > 1 more irregular
% * *CV2*: an improved, *local* CV. It compares each ISI only with the next
% one (|2*abs(a-b)/(a+b)| for neighbouring ISIs |a| and |b|, averaged over
% all pairs), so slow changes of the rate during the session do not inflate it.
% * *LvR*: a refined local measure that also corrects for the refractory
% period. This is the one we use: LvR < 0.5 regular, ~1 random (Poisson),
% > 1 bursty (Shinomoto et al. 2009).
% * *burst index*: fraction of ISIs < 10 ms
% * *refractory violations*: % of ISIs < 2 ms - a well-isolated neuron has
% almost none.
stats = neuronFiringStats(spikeTimes, sessionDur);
head(stats)
groupcounts(stats, 'Classification')

figure('Position', [100 100 1000 330])
tiledlayout(1, 3, 'TileSpacing', 'compact')
nexttile
histogram(log10(stats.FiringRate_Hz), 25)
xlabel('log_{10} firing rate (Hz)'); ylabel('Neurons'); title('Firing rates')
nexttile
gscatter(stats.FiringRate_Hz, stats.LvR, stats.Classification)
set(gca, 'XScale', 'log'); xlabel('Firing rate (Hz)'); ylabel('LvR')   % gca = the current axes
yline([0.5 1], ':', 'HandleVisibility', 'off'); title('Regularity')
nexttile
scatter(stats.CV, stats.LvR, 15, 'filled')
xlabel('CV'); ylabel('LvR'); set(gca, 'XScale', 'log'); title('Global vs local variability')

%% 1.1 ISI histograms and autocorrelograms
% A *bursty* neuron (86) and a *regular* one (78). The autocorrelogram
% (ACG) shows how likely another spike is at each time lag after a spike.
examples = [86 78];
figure('Position', [100 100 900 550])
tiledlayout(2, 2, 'TileSpacing', 'compact')
for n = examples                 % n takes each value of the vector in turn
    isi = diff(spikeTimes{n});
    nexttile
    histogram(isi*1000, 0:2:300)
    xlabel('ISI (ms)'); ylabel('Count')
    title(sprintf('Neuron %d (%s): ISI', n, stats.Classification{n}))
    nexttile
    plotACG(spikeTimes{n}, 0.002, 0.3);
    title(sprintf('Neuron %d: ACG, LvR = %.2f', n, stats.LvR(n)))
end

%% FOR YOU!! - L7-E.1
% # Which neurons have more than 1 % refractory violations? Plot the ACG
% of the worst one with 1-ms bins and a +/- 20 ms window. What do you see
% around 0 ms, and what does that mean for the quality of this unit?
% # Neuron 78 has a CV of ~14 but an LvR of ~0.3. Plot its firing rate in
% 10-s bins over the whole session. Why is the global CV so high? What
% does it tell you about the stability of the recording?
%
% Hint for 1: no new computation needed. The |stats| table from section 1
% has one row per neuron and one column per measure. Look at the output of
% |head(stats)| (or double-click |stats| in the Workspace): which column
% holds the refractory violations? Then use a logical mask on that column
% (Lesson 6) and |find| to get the neuron numbers. |max| gives the worst
% one (its second output is the position).
%
% Hint for 2: |histcounts(x, edges)| counts how many values of |x| fall
% between consecutive edges. N+1 edges give N counts, so plot the counts
% against the bin starts:
% |edges = 0:10:sessionDur; c = histcounts(spikeTimes{78}, edges); plot(edges(1:end-1), c/10)|
% (|c/10|: spikes per 10 s -> Hz)

% >>> YOUR CODE HERE <<<

%% 1.2 Do neurons talk to each other? Cross-correlograms (demo)
% *Demo:* run this section and look at the result; the teacher explains it.
%
% A cross-correlogram (CCG) counts the spikes of neuron B at each lag
% after the spikes of neuron A. A sharp peak 1-5 ms after zero suggests a
% monosynaptic excitatory connection A -> B; a sharp trough, inhibition;
% a broad peak centred on 0, common input. Red dots mark lags with
% significantly more spikes than slow co-modulation alone would produce,
% blue dots significantly fewer (Stark and Abeles 2009).
% note: this helper takes the matrix STMtx and two COLUMN numbers (neurons),
% not spikeTimes{n} like the other helpers
plotCrossCorrelogram(STMtx, 24, 26, 0.001, 0.1);   % compute +/-100 ms ...
xlim([-30 30])                                      % ... but show +/-30 ms

%%
% *Careful*: a CCG peak can also come from a shared stimulus or behaviour
% (both neurons respond to the reward), or from the spike-sorting of one
% neuron into two units. Short-latency (1-4 ms), narrow peaks are the most
% convincing evidence of a real connection.
%
% Apply these criteria to the pair above. Its excess runs from about -1 ms
% to +2 ms, so it is centred near 0 rather than 1-4 ms after it, and
% neuron 24 is the contaminated unit of L7-E.1. This pair more likely
% shows synchrony (common input) or a sorting effect than a monosynaptic
% connection. Compare with the pair 121 -> 122 (both units well
% isolated): an excess 2-6 ms after zero and nothing at 0. This is what a
% _putative_ excitatory connection looks like; a CCG alone cannot prove a
% synapse.
plotCrossCorrelogram(STMtx, 121, 122, 0.001, 0.1);
xlim([-30 30])

%% 2. Aligning spikes to events: raster and PSTH
% To see if a neuron responds to a task event we align its spikes to the
% event in every trial (|alignSpikes|), show them as a *raster* (one row
% per trial) and average them into a *peri-stimulus time histogram* (PSTH).
n = 61;
pre = 2; post = 3;
aligned = alignSpikes(spikeTimes{n}, V.Cue_s, pre, post);
[rate, tb, trialRates] = computePSTH(aligned, pre, post, 0.05);
figure('Position', [100 100 600 600])
tiledlayout(2, 1, 'TileSpacing', 'compact')
nexttile; plotRaster(aligned); title(sprintf('Neuron %d aligned to the cue', n))
nexttile
bar(tb, rate, 1, 'EdgeColor', 'none'); xline(0, 'r--')
xlabel('Time from cue (s)'); ylabel('Firing rate (Hz)'); title('PSTH, 50-ms bins')

%% 2.1 Bin size and smoothing (demo)
% *Demo:* run this section and look at the result; the teacher explains it.
%
% Small bins are noisy, big bins blur the timing. Smoothing with a Gaussian
% kernel gives a *spike density function*. Always report the bin size /
% kernel width you used.
figure; hold on
for sg = [0 0.02 0.1]
    [r_s, tb_s] = computePSTH(aligned, pre, post, 0.01, sg);
    plot(tb_s, r_s, 'LineWidth', 1.2)
end
xline(0, 'r--', 'HandleVisibility', 'off')
legend('10-ms bins, no smoothing', 'sigma = 20 ms', 'sigma = 100 ms')
xlabel('Time from cue (s)'); ylabel('Firing rate (Hz)')

%% 2.2 Comparing conditions
% Align to the reward period and split trials by outcome. The shaded band
% is the SEM across trials.
n = 60;
alR = alignSpikes(spikeTimes{n}, V.Reward_s, pre, post);
cols = [0.85 0.3 0.3; 0.2 0.6 0.2];      % not rewarded, rewarded
figure('Position', [100 100 600 650])
tiledlayout(2, 1, 'TileSpacing', 'compact')
nexttile; plotRaster(alR, V.Rewarded, cols)
title(sprintf('Neuron %d aligned to outcome (green = rewarded)', n))
nexttile; hold on
for c = [0 1]
    [r_c, tb_c, tr_c] = computePSTH(alR(V.Rewarded == c), pre, post, 0.02, 0.05);
    sem = std(tr_c) / sqrt(size(tr_c, 1));
    % shaded band: fill draws a polygon. Its outline goes along the upper
    % edge (left to right) and back along the lower edge (right to left),
    % hence the time axis followed by the flipped time axis (fliplr).
    fill([tb_c fliplr(tb_c)], [r_c - sem, fliplr(r_c + sem)], cols(c+1, :), ...
        'FaceAlpha', 0.25, 'EdgeColor', 'none')
    plot(tb_c, r_c, 'Color', cols(c+1, :), 'LineWidth', 1.5)
end
xline(0, 'k--'); xlabel('Time from outcome (s)'); ylabel('Firing rate (Hz)')

%% 2.3 The whole population at once
% For every neuron: PSTH aligned to the cue, then *z-scored* with its own
% baseline (-1.5 to -0.5 s before the cue), so neurons with different
% rates become comparable. Sorting by the time of the peak reveals the
% sequence of activity across the trial. The baseline of every neuron is
% stored (|baseMean|, |baseSD|) so that we can reuse it later.
%
% *Careful:* sorting by the peak always produces a diagonal, even for pure
% noise, because the order comes from the same data. To test whether a
% sequence is real, sort with half of the trials and plot the other half
% (cross-validation, Lesson 9).
binW = 0.05;
Z = [];                                   % filled row by row (one row per neuron)
baseMean = zeros(nNeurons, 1);
baseSD   = zeros(nNeurons, 1);
for k = 1:nNeurons
    a = alignSpikes(spikeTimes{k}, V.Cue_s, pre, post);
    [r_k, tb] = computePSTH(a, pre, post, binW, 0.05);
    base = r_k(tb >= -1.5 & tb < -0.5);   % 1.5 to 0.5 s before the cue
    baseMean(k) = mean(base);
    baseSD(k)   = std(base) + eps;        % eps (tiny number): no division by 0 for silent neurons
    Z(k, :) = (r_k - baseMean(k)) / baseSD(k);
end
% Sort the neurons by the time of their peak:
% max(X, [], 2) takes the maximum of every ROW (dimension 2; the [] only
% fills the place of an unused input). Its 2nd output is the POSITION of
% the maximum, i.e. the bin of the peak.
[~, peakBin] = max(Z(:, tb > -0.5), [], 2);
% sort with two outputs: order = the neuron numbers, sorted by peak time
[~, order] = sort(peakBin);
figure('Position', [100 100 600 600])
imagesc(tb, 1:nNeurons, Z(order, :)); clim([-3 3])
colormap(gca, redblue_cmap()); cb = colorbar; cb.Label.String = 'z-score';   % redblue_cmap: helper in functions/
xline(0, 'k--'); xline(median(V.Reward_s - V.Cue_s), 'k:')
xlabel('Time from cue (s)'); ylabel('Neuron (sorted by peak time)')
title('Population activity (dotted = median outcome time)')

%% FOR YOU!! - L7-E.2
% # Make a raster + PSTH of neuron 75 aligned to the *outcome*, splitting the
% trials by the chosen arm (gamble vs safe). Look at the time *before*
% the outcome: does the neuron "know" the choice?
% # (Optional) Make the population heat map aligned to the *outcome* for
% rewarded and for unrewarded trials (same neuron order in both!). What
% changes?
%
% Hints for 2:
%
% * A skeleton is in the code block below, commented out. Select its lines,
% uncomment them (*Live Editor* tab > *Uncomment*, or Ctrl+T on Windows)
% and fill in the |___|.
% * Align to |V.Reward_s| instead of |V.Cue_s|, once with the rewarded
% trials and once with the unrewarded ones (e.g. |V.Reward_s(isRew)|).
% * Use the baseline of 2.3 for the z-score: |(r - baseMean(k)) / baseSD(k)|.
% * The neuron order is computed only ONCE (from the rewarded trials, peak
% *after* the outcome) and used in both panels.

% % --- skeleton for part 2 ---
% isRew = V.Rewarded == 1;
% Zrew = []; Zunrew = [];
% for k = 1:nNeurons
%     a1 = alignSpikes(spikeTimes{k}, ___, pre, post);   % rewarded trials
%     a0 = alignSpikes(spikeTimes{k}, ___, pre, post);   % unrewarded trials
%     [r1, tb] = computePSTH(a1, pre, post, binW, 0.05);
%     r0 = computePSTH(a0, pre, post, binW, 0.05);
%     Zrew(k, :)   = ___;      % z-score with baseMean(k), baseSD(k) of 2.3
%     Zunrew(k, :) = ___;
% end
% [~, pk] = max(Zrew(:, tb > 0), [], 2);    % peak AFTER the outcome
% [~, ord] = sort(pk);                      % ONE order for both panels
% figure; tiledlayout(1, 2)
% nexttile; imagesc(tb, 1:nNeurons, Zrew(ord, :)); clim([-3 3]); title('rewarded')
% nexttile; imagesc(tb, 1:nNeurons, ___); clim([-3 3]); title('unrewarded')

% >>> YOUR CODE HERE <<<

%% 3. Statistics: is the effect real?
% *Recap* (you may know the t-test and the Wilcoxon test from Lessons 1-4):
%
% * The *null hypothesis* (H0) says "there is no effect", e.g. the neuron
% fires the same in both conditions.
% * The *p-value* is the probability of data at least as extreme as ours
% IF H0 were true. It is NOT the probability that H0 is true, and it does
% not say how big the effect is.
% * A result is called significant if p < *alpha* (usually 0.05). So 5 %
% of the tests where nothing is going on come out "significant" by chance.
% * The *effect size* (difference in Hz, Cohen's d, AUC) says how big the
% effect is. With many trials even a tiny effect gets a tiny p-value:
% always report both.
%
% Every test answers a precise question. Before choosing one, ask:
%
% * *What is my unit of observation?* (trials, neurons, animals)
% * *Are the samples paired?* (the same trials measured twice)
% * *Can I assume normality?* Spike counts are skewed and often zero -> use
% non-parametric tests or permutations when in doubt.
% * *How many tests am I doing?* -> correct for multiple comparisons.

%% 3.1 Does neuron 61 respond to the cue? (paired design)
% Baseline (1 s before the cue) and response (0.5 s after the cue) come
% from the *same trials*: paired test. Firing rates in Hz.
base_r = countSpikesInWindows(spikeTimes{61}, V.Cue_s - 1, V.Cue_s);
resp_r = countSpikesInWindows(spikeTimes{61}, V.Cue_s, V.Cue_s + 0.5);
dlt = resp_r - base_r;
[~, p_t]  = ttest(resp_r, base_r);             % paired t-test
p_sr      = signrank(resp_r, base_r);          % Wilcoxon signed-rank (non-parametric)
cohen_dz  = mean(dlt) / std(dlt);              % effect size for paired data
fprintf('Neuron 61: %.1f -> %.1f Hz, paired t p = %.2g, signed-rank p = %.2g, dz = %.2f\n', ...
    mean(base_r), mean(resp_r), p_t, p_sr, cohen_dz);
figure
tiledlayout(1, 2)
nexttile
plot([1 2], [base_r resp_r]', 'Color', [0.7 0.7 0.7]); hold on
plot([1 2], [mean(base_r) mean(resp_r)], 'k-o', 'LineWidth', 2)
xlim([0.5 2.5]); xticks([1 2]); xticklabels({'baseline', 'cue'}); ylabel('Hz')
title('Paired data: one line per trial')
nexttile
histogram(dlt, 20); xline(0, 'r--'); xlabel('Response - baseline (Hz)')
title(sprintf('p = %.2g (signed-rank)', p_sr))

%%
% *A common mistake*: comparing two different neurons with |ttest2|
% ("neuron 1 fires more than neuron 2") answers no interesting question,
% and ignores that both were measured in the same trials. Compare
% conditions *within* a neuron, or neurons *as a population*.

%% 3.2 Two conditions, unpaired: rewarded vs unrewarded trials
% Different trials -> unpaired. Parametric: |ttest2|. Non-parametric:
% |ranksum| (Mann-Whitney). And a *permutation test*, which needs no
% distributional assumption at all: if the outcome did not matter, the
% labels "rewarded / unrewarded" could be shuffled without changing the
% difference. Repeating the shuffle builds the *null distribution*.
% (Lesson 9 comes back to this: what to shuffle, and bootstrapping.)
n = 60;
rOut = countSpikesInWindows(spikeTimes{n}, V.Reward_s, V.Reward_s + 1);
lab  = V.Rewarded == 1;
obsDiff = mean(rOut(lab)) - mean(rOut(~lab));
nPerm = 2000;
nullDiff = zeros(nPerm, 1);
for i = 1:nPerm
    sh = lab(randperm(numel(lab)));      % randperm(n): 1..n in random order -> shuffled labels
    nullDiff(i) = mean(rOut(sh)) - mean(rOut(~sh));
end
% p = fraction of shuffles at least as extreme as the real difference.
% abs(): two-sided (an increase or a decrease both count).
% +1 above and below: the real labelling is one of the possible shuffles,
% so p can never be exactly 0.
p_perm = (sum(abs(nullDiff) >= abs(obsDiff)) + 1) / (nPerm + 1);
[~, p_t2] = ttest2(rOut(lab), rOut(~lab));
p_rs = ranksum(rOut(lab), rOut(~lab));
auc  = aucFromSamples(rOut(lab), rOut(~lab));
fprintf('Neuron %d: diff = %.2f Hz, t-test p = %.2g, rank-sum p = %.2g, permutation p = %.2g, AUC = %.2f\n', ...
    n, obsDiff, p_t2, p_rs, p_perm, auc);
figure
histogram(nullDiff, 40); xline(obsDiff, 'r', 'LineWidth', 2)
xlabel('Difference in mean rate (Hz), shuffled labels'); ylabel('Count')
title('Permutation null distribution (red = observed)')

%%
% *ROC / AUC*: the probability that a random rewarded trial has a higher
% rate than a random unrewarded trial. 0.5 = no information, 1 or 0 =
% perfect separation. It is an *effect size* that does not depend on the
% number of trials, unlike the p-value.

%% 3.3 Testing 141 neurons: multiple comparisons
% If we test 141 neurons at alpha = 0.05 and NOTHING is going on, we still
% expect ~7 "significant" neurons. Demonstration with shuffled labels:
pShuffled = zeros(nNeurons, 1);
rAll = countSpikesInWindows(spikeTimes, V.Reward_s, V.Reward_s + 1);   % trials x neurons
fakeLab = lab(randperm(numel(lab)));
for k = 1:nNeurons
    pShuffled(k) = ranksum(rAll(fakeLab, k), rAll(~fakeLab, k));
end
fprintf('Shuffled labels: %d of %d neurons "significant" at p < 0.05\n', sum(pShuffled < 0.05), nNeurons);

%%
% Corrections:
%
% * *Bonferroni*: use alpha / m (m = number of tests). Very strict.
% * *False discovery rate* (Benjamini-Hochberg, |fdr_bh|): controls the
% expected fraction of false positives among the significant results.
% The standard for many neurons / voxels / genes.
[sigFDR, pAdj] = fdr_bh(pShuffled, 0.05);
fprintf('After Bonferroni: %d, after FDR: %d\n', sum(pShuffled < 0.05/nNeurons), sum(sigFDR));

%% FOR YOU!! - L7-E.3
% # For every neuron, test whether its rate in the 1 s after the outcome
% differs between rewarded and unrewarded trials (|ranksum|, real labels).
% How many neurons are significant without correction, with Bonferroni
% and with FDR?
% # Compute the AUC of every neuron and plot the histogram of AUC values,
% highlighting the FDR-significant neurons in another colour.
%
% *L7-Q.1* Is it better to report "N neurons were significant" or the
% distribution of AUC values? Why?

% >>> YOUR CODE HERE <<<

%% 3.4 Block effects and the "unit of observation" (demo)
% *Demo:* run this section and look at the result; the teacher explains it.
% The two warnings below are the important part.
%
% Does neuron 60 change its rate across the three blocks? Three groups ->
% one-way ANOVA (|anova1|) or its non-parametric version (|kruskalwallis|).
rTrial = countSpikesInWindows(spikeTimes{60}, V.TrialStart_s, V.TrialStart_s + 1);
p_kw = kruskalwallis(rTrial, V.Block, 'off');
p_an = anova1(rTrial, V.Block, 'off');
fprintf('Neuron 60 across blocks: ANOVA p = %.2g, Kruskal-Wallis p = %.2g\n', p_an, p_kw);
figure; boxchart(V.Block, rTrial); hold on
swarmchart(V.Block, rTrial, 10, 'filled', 'MarkerFaceAlpha', 0.4)
xlabel('Block'); ylabel('Rate 0-1 s after trial start (Hz)')

%%
% *Two warnings*
%
% # Blocks are also *time*: block 3 always comes last. A change across
% blocks may be drift of the recording or satiety, not "value". Controls:
% compare with neighbouring trials, or use designs where conditions alternate.
% # *Pseudoreplication*: here trials are the unit, so the result is about
% THIS neuron. A claim about "prelimbic neurons" needs neurons as the unit;
% a claim about "mice" needs several animals. With nested data (trials in
% neurons in animals) use *mixed-effects models* (|fitlme| in MATLAB).
% They let every neuron (or animal) have its own
% baseline and its own effect, and test the effect at the right level.
% We do not use them in this course, but you should know they exist.

%% HOMEWORK (optional)
% # *Another session*: |data/OtherSession| contains a second session (47
% neurons). Convert it with |trialsSync2table| and |stmtx2cell|, and find the
% neurons that respond to reward (raster + PSTH + FDR-corrected test).
% # *Response latency*: find the neurons that respond to the cue (the
% paired test of section 3.1 for every neuron, FDR-corrected). For them,
% estimate the latency as the first bin after the cue where the z-scored
% PSTH (|Z| of section 2.3) exceeds 3 for at least 3 consecutive bins.
% Plot the latency distribution. Hint: |movsum(z > 3, [0 2]) == 3| is true
% at every bin that starts 3 bins in a row above 3.
% # *CCG survey*: compute the CCG for all pairs among the 20 neurons with
% the highest firing rate. How many pairs have significant bins between 1
% and 4 ms? Are they neighbours in the list (same electrode?) Hint:
% |[~, lags, ccgRaw, ~, ~, ciHigh] = plotCrossCorrelogram(STMtx, a, b, 0.001, 0.1, 0);|
% (last input 0 = no plot); significant excess = |ccgRaw > ciHigh|, |lags| in s.
% # *Cell types*: compare firing rate, LvR and burst index between neurons
% that increase and neurons that decrease their rate after the reward.
% # *Permutation test for the ANOVA*: write a permutation version of the
% block test of section 3.4 (shuffle the block labels). As the statistic
% use the difference between the highest and the lowest block mean (or
% the F value: |[~, tbl] = anova1(r, g, 'off'); F = tbl{2,5};|).
