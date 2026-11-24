% Lesson10_Students_plain.m
% Plain-script version of the live script Lesson10_Students.mlx, for
% computers on which the live script does not open. The text, code and
% exercises are the same; only the layout is different.
%
% How to use this file
% * Open it in the MATLAB Editor and set the Current Folder to the folder
%   "Lesson 10" (the folder that contains this file).
% * Run it one section at a time: click inside a section (each section
%   starts at a line that begins with %%) and press Ctrl+Enter (macOS:
%   Cmd+Enter), or click Run Section in the Editor tab.
% * Results appear in the Command Window, figures in figure windows.
% * The lesson text is in the comments. Marks such as *bold*, _italic_
%   and |code| are the formatting of the live script, and equations
%   are written in LaTeX between $$ signs.
% * Write your answers where it says "% >>> YOUR CODE HERE <<<".

%% Lesson 10 - Calcium Imaging: a Group Mini-Project
% *Processing and Interpretation of Neuroscience Data (860.053-MUW)* -
% Vered Kellner and Hugo Malagon Vina.
%
% In Lessons 6-9 you learned to handle spike trains, statistics, signals
% and models. Today you *apply* these tools, in groups, to a data type you
% have not analysed yet: *two-photon calcium imaging*. There is little new
% theory. The first part (sections 0-2, about 20 min) is done together;
% then each group works on the project (sections A-F) and presents its
% answers at the end of the lesson.
%
% *The scientific questions*
%
% # Is there a pattern in the activity of the neurons?
% # Are the neurons synchronised?
% # How many neurons respond to the sounds?
% # Do individual neurons respond differently to different frequencies?
% # Do individual neurons respond differently across repeats?
%
% *Data*
%
% * |Calcium_Imaging.mat| - |dFF| (300 frames x 20 neurons): dF/F of 20
% excitatory neurons expressing the red calcium indicator jRGECO1a, imaged
% with a two-photon microscope at |fs| = *2 Hz* in the auditory cortex of an
% awake mouse (150 s). |t| = time of each frame (s).
% * |Stimuli.mat| - table |Stim|, one row per tone (28 tones): 7 pure tones
% (6-24 kHz, half-octave steps) played in 4 blocks (= 4 repeats). Onsets
% are given in frames *and* seconds.
% * |original/| - the files as they were given in the old course
% (|roisNeur|, |stimMat|). Careful: there, onset and end are *frame
% numbers*, not seconds.
%
% Toolboxes: Signal Processing (|findpeaks|), Statistics and Machine
% Learning (tests, |fitlm|, |pca|).

%% 0. Setup
clear; close all; clc
assert(isfolder('data'), ['Data folder not found. Set the Current Folder ' ...
    'to the "Lesson 10" folder and run again.'])
addpath('functions')
rng(1)

%% How the group work is organised
% * Groups of *3-4 students*. Sections 0-2 are done together in class.
% * Sections A-E each answer part of the questions. *Split them*: every
% member owns one or two sections (suggestion below), then the group
% puts the answers together. Section F is optional.
% * In every section, do the *core* parts first (about 30 min per
% section). Parts marked (Optional) are for when the core is done.
% * Sections A and C contain a code *skeleton* (commented out): select
% its lines, uncomment them (Live Editor tab > Uncomment, or Ctrl+T on
% Windows) and fill in the |___|.
% * Every section only needs the variables created in sections 1-2, so
% the sections can be solved in parallel and in any order.
% * Roles: one *coordinator* (keeps time, collects figures), one
% *presenter*, and everybody codes.
% * *Deliverable*: a 5-minute presentation (about 5 slides): one figure
% per question, the answer in one sentence, and one thing that
% surprised you or that you do not trust. See section G.
%
% Suggested split for 4 students: (1) A, (2) B + D, (3) C, (4) E (+ F).
% For 3 students: (1) A, (2) B + C, (3) D + E.
%
% If time is short, the teacher may ask each group to present only two or
% three of the questions.

%% 1. The data
load(fullfile('data', 'Calcium_Imaging.mat'))     % dFF, t, fs, description
load(fullfile('data', 'Stimuli.mat'))             % Stim (table)
disp(description)
[nFrames, nN] = size(dFF);
nT = height(Stim);
freqs = unique(Stim.Frequency_kHz)';
fprintf('%d frames (%.0f s at %g Hz), %d neurons, %d tones, frequencies (kHz): %s\n', ...
    nFrames, nFrames/fs, fs, nN, nT, mat2str(freqs));
disp(head(Stim, 8))

%%
% Each tone period lasts 10 frames (5 s, including the silence after the
% tone). Look at the |Frequency_kHz| column block by block:
disp(reshape(Stim.Frequency_kHz, 7, 4))      % columns = blocks

%% FOR YOU!! - L10-Q.1
% Look at the table above (one column per block). How is the order of the
% frequencies chosen? Is anything *not* random? Keep your answer in mind
% for section D.

%% 1.1 Always look at the data first
% A heat map shows all neurons at once; the vertical lines mark the tone
% onsets.
figure('Position', [100 100 1000 550])
tiledlayout(3, 1, 'TileSpacing', 'compact')
nexttile([2 1])
imagesc(t, 1:nN, dFF'); clim([0 5])
ylabel('Neuron'); cb = colorbar; cb.Label.String = 'dF/F';
title('Calcium activity of 20 neurons (white lines = tone onsets)')
xline(Stim.Onset_s, 'w', 'LineWidth', 0.5)
set(gca, 'XTickLabel', [])
nexttile
plot(t, mean(dFF, 2), 'k'); hold on
xline(Stim.Onset_s, 'r:')
xlim([t(1) t(end)]); xlabel('Time (s)'); ylabel('mean dF/F')
title('Population mean')

%% 1.2 What does the calcium signal measure? (demo)
% *Demo:* the teacher explains this section and the simulation below.
%
% A calcium indicator reports *intracellular calcium*, which rises after
% every action potential and decays slowly. The signal is normalised as
%
% $$\Delta F/F = \frac{F - F_0}{F_0}$$
%
% where |F0| is the baseline fluorescence (often a low percentile of |F|
% in a sliding window). Three consequences:
%
% * The calcium signal is a *low-pass filtered* version of the spike
% train: one spike gives a transient that lasts about a second.
% * At |fs| = 2 Hz (Nyquist = 1 Hz, Lesson 8) single spikes in a burst
% cannot be separated: we see *bursts*, not spikes.
% * The amplitude depends on the number of spikes, but also on the
% indicator, the expression level and the noise. Comparing dF/F between
% neurons is risky; comparing a neuron with *itself* (baseline vs
% response) is safer.
%
% The simulation below converts a Poisson spike train into a calcium-like
% signal and samples it at 30 Hz and at 2 Hz.
dt = 0.001; tt = 0:dt:20;
spk = rand(size(tt)) < 2*dt;                          % ~2 Hz Poisson spikes
spk(tt > 8 & tt < 9) = rand(1, sum(tt > 8 & tt < 9)) < 30*dt;   % a 1-s burst
kern = (1 - exp(-(0:dt:3)/0.05)) .* exp(-(0:dt:3)/0.7);         % rise 50 ms, decay 0.7 s
ca = conv(double(spk), kern); ca = ca(1:numel(tt));
figure('Position', [100 100 1000 400])
plot(tt, ca, 'Color', [0.6 0.6 0.6]); hold on
i30 = 1:round(1/(30*dt)):numel(tt); i2 = 1:round(1/(2*dt)):numel(tt);
plot(tt(i30), ca(i30), 'b.-', tt(i2), ca(i2), 'ro-', 'LineWidth', 1.2)
plot(tt(spk), -0.5*ones(1, sum(spk)), 'k|', 'MarkerSize', 10)
xlabel('Time (s)'); ylabel('Calcium (a.u.)')
legend('calcium', 'sampled at 30 Hz', 'sampled at 2 Hz (our data)', 'spikes', 'Location', 'northeast')
title('From spikes to a calcium signal')

%%
% Recovering spike times from calcium traces is called *deconvolution*
% (e.g. OASIS, MLspike, CASCADE). In this project we work directly on
% dF/F, and treat large transients as "events", not as spikes.

%% 2. Responses to the tones: the peri-stimulus array
% As for the PSTH of Lesson 7, we cut a window around every tone onset:
% from 4 frames before (-2 s) to 9 frames after (+4.5 s). The function
% |periStimulus| returns an array |P| of size tones x lags x neurons.
lags = -4:9;
[P, tLag] = periStimulus(dFF, Stim.OnsetFrame, lags, fs);
size(P)

figure('Position', [100 100 1000 380])
tiledlayout(1, 2)
nexttile
plot(tLag, squeeze(mean(P, 1)), 'Color', [0.6 0.6 0.6]); hold on
plot(tLag, mean(P, [1 3]), 'k', 'LineWidth', 2.5)
xline(0, 'r--'); xlabel('Time from tone onset (s)'); ylabel('dF/F')
title('Mean response of each neuron (black = all)')
nexttile
imagesc(tLag, 1:nN, squeeze(mean(P, 1))'); xline(0, 'w--')
xlabel('Time from tone onset (s)'); ylabel('Neuron'); colorbar
title('Mean response, all tones')

%%
% The response peaks 0.5-1 s after the onset and is back to baseline after
% about 3 s. We therefore define, for every tone and neuron:
%
% * *baseline* = mean dF/F in the 2 frames before the onset (-1 to 0 s)
% * *response* = mean dF/F in the first 4 frames from the onset (0 to 2 s)
% * |R = response - baseline| (the evoked response)
%
% These three tones x neurons matrices are the starting point of all
% group sections.
isBase = lags >= -2 & lags <= -1;
isResp = lags >= 0  & lags <= 3;
base = squeeze(mean(P(:, isBase, :), 2));     % nT x nN
resp = squeeze(mean(P(:, isResp, :), 2));     % nT x nN
R    = resp - base;                           % nT x nN
fprintf('Evoked response, mean over all tones and neurons: %.2f dF/F\n', mean(R, 'all'));

%% FOR YOU!! - L10-Q.2
% Why do we subtract the baseline of *each tone* instead of one baseline
% for the whole recording? (Hint: look at the population mean in 1.1 -
% does the signal always come back to the same level before a tone?)

%% A. Events and synchrony (questions 1 and 2)
% Lesson 8 detected spikes with a robust threshold. Do the same with the
% calcium transients. Here a *threshold per neuron* is needed, because
% dF/F scales differ between neurons.

%% FOR YOUR GROUP!! - L10-E.1
% # For every neuron, set a threshold |median + 3 x MAD/0.6745| (Lesson 8)
% and detect the transients with |findpeaks| (|MinPeakHeight|; use
% |MinPeakDistance| of 2 frames). Store the event frames of neuron |n| in
% a cell array |ev{n}|. A skeleton is in the code block below.
% # Plot an *event raster* (one row per neuron, a dot per event) with the
% tone onsets as vertical lines, and compute the *event rate* (events per
% minute) of every neuron.
% # *Synchrony*: plot the correlation matrix of the traces,
% |C = corr(dFF)|, with |imagesc|, and compute the mean correlation over
% all pairs of neurons: |mean(C(triu(true(nN), 1)))| (the upper triangle
% without the diagonal contains every pair once).
% # (Optional) What fraction of all events falls in the response window
% (0-2 s after an onset)? Chance would be 4 of every 10 frames = 0.4 of
% the tone periods.
% # (Optional) Count, for every frame, how many neurons have an event (a
% population event count) and plot it.
%
% *L10-Q.3* Is a calcium "event" the same as a spike? What can a 2 Hz
% signal not tell you?
%
% *L10-Q.4* Are the neurons synchronised? Is the synchrony a property of
% the network, or could the stimulus alone explain it? (Section E
% separates the two.)

% % --- skeleton for part 1 ---
% ev = cell(1, nN);                        % one cell per neuron
% for n = 1:nN
%     x = dFF(:, n);                       % trace of neuron n
%     thr = ___;                           % median + 3 x MAD/0.6745 of x
%     [~, ev{n}] = findpeaks(x, 'MinPeakHeight', ___, 'MinPeakDistance', 2);
% end
% evRate = cellfun(@numel, ev) / (nFrames/fs/60);   % events per minute

% >>> YOUR CODE HERE <<<

%% B. Who responds? (question 3)
% A neuron "responds" if its activity after the tone is higher than
% before it. Baseline and response are measured on the *same* tones, so
% the test must be *paired* (Lesson 7).

%% FOR YOUR GROUP!! - L10-E.2
% # For every neuron, compare |resp| with |base| over the 28 tones with a
% paired test (|signrank|). Store the p-values in |pResp| (1 x nN).
% # Correct for testing 20 neurons with |fdr_bh| (Lesson 7). How many
% neurons respond?
% # (Optional) An effect size: for every neuron compute the fraction of
% tones whose response |R| is larger than 2 SD of that neuron's baseline
% values (|std(base(:, n))|). Plot it as a bar plot, sorted.
%
% *L10-Q.5* All (or almost all) neurons are "responsive". Does that mean
% they are *auditory* neurons that encode the sound? What else could
% produce a response to every sound (think of an awake mouse)?

% >>> YOUR CODE HERE <<<

%% C. Tuning to frequency (question 4)
% A *tuning curve* is the mean response as a function of the stimulus
% (here: frequency). The frequency with the largest response is the
% *best frequency* (BF). Auditory cortex is organised tonotopically, so we
% might expect different neurons to prefer different frequencies.

%% FOR YOUR GROUP!! - L10-E.3
% # Build the tuning matrix |tuning| (nN x 7): mean |R| of each neuron for
% each frequency, and the SEM over the 4 repeats. Plot the tuning curves
% (|errorbar|, log frequency axis) of 4 neurons of your choice. A skeleton
% is in the code block below.
% # Find the best frequency of every neuron (|[~, bfIdx] = max(tuning, [], 2)|)
% and plot a histogram of the BFs.
% # Is the frequency effect *significant*? For every neuron, test |R|
% across the 7 frequencies with |kruskalwallis(R(:, n), Stim.Frequency_kHz, 'off')|,
% then correct with |fdr_bh|.
% # (Optional) Plot the tuning matrix as a heat map with each row
% normalised to its maximum, neurons sorted by BF.
% # (Optional) *Reliability*: compute the tuning curve from blocks 1-2 and
% from blocks 3-4 separately and correlate them for every neuron. A
% reliable tuning curve should look the same in both halves.
%
% *L10-Q.6* With 4 repeats per frequency, how much would you trust a
% best frequency? Which BF appears most often, and do you believe it?

% % --- skeleton for part 1 ---
% tuning = zeros(nN, numel(freqs)); tSEM = tuning;
% for q = 1:numel(freqs)
%     sel = ___;                                    % the tones of frequency freqs(q)
%     tuning(:, q) = mean(R(sel, :), 1)';           % mean over those tones
%     tSEM(:, q)   = (std(R(sel, :), 0, 1) / sqrt(sum(sel)))';
% end
% errorbar(freqs, tuning(1, :), tSEM(1, :), 'o-'); set(gca, 'XScale', 'log')

% >>> YOUR CODE HERE <<<

%% D. A hidden confound: the order of the tones
% Remember L10-Q.1: within each block the first six frequencies are
% shuffled, but *24 kHz is always played last*. Any effect of the
% *position in the block* (adaptation, arousal building up, the response
% to the previous tone not yet decayed...) is therefore mixed with the
% effect of 24 kHz. This is a *confound* (Lesson 9).

%% FOR YOUR GROUP!! - L10-E.4
% # Average |R| over neurons for every tone (|popR = mean(R, 2)|). Plot
% |popR| against |Stim.PositionInBlock| and, in a second panel, against
% |Stim.Frequency_kHz|. Which variable seems to matter more?
% # Fit a linear model that includes both:
% |tbl = table(popR, Stim.PositionInBlock, categorical(Stim.Frequency_kHz), 'VariableNames', {'R', 'Pos', 'Freq'});|
% |mdl = fitlm(tbl, 'R ~ Pos + Freq')| and look at |anova(mdl)|. Is there
% a frequency effect once position is in the model?
% # (Optional) The baseline before a tone is not always the same. Plot
% |popR| against the mean baseline |mean(base, 2)|. What happens when the
% previous response has not decayed yet?
%
% *L10-Q.7* How should the experiment have been designed so that
% frequency and position can be separated? Can you rescue the 24 kHz
% question with these data?

% >>> YOUR CODE HERE <<<

%% E. Repeats and the population (questions 2 and 5)
% Do the neurons respond the same way every time a tone is repeated?
% And are the neurons correlated only because they all respond to the
% same tones (*signal correlation*), or also from trial to trial
% (*noise correlation*)?
%
% * *Signal correlation* of two neurons: correlation of their tuning
% curves (mean response per stimulus).
% * *Noise correlation*: correlation of their trial-to-trial
% fluctuations around the mean, i.e. of |R| after subtracting, for
% every tone, the mean response to that frequency.

%% FOR YOUR GROUP!! - L10-E.5
% # Plot |R'| as a heat map (neurons x tones, tones in the order they were
% played) with lines between the blocks. Then compute the mean |R| of
% every neuron in each block and test for a block effect
% (|friedman| on the nN x 4 matrix: neurons are the "subjects").
% # Run |pca| on |R| (tones x neurons). How much variance does PC1
% explain? Plot the PC1 loadings (|coeff(:, 1)|): do all neurons load with
% the same sign? What does that mean?
% # (Optional) Compute the noise residuals |Rres|: subtract from each row
% of |R| the mean of the rows with the same frequency. Compute the signal
% correlation (|corr(tuning')|, needs section C - or recompute the tuning
% matrix here) and the noise correlation (|corr(Rres)|) of every pair of
% neurons, and compare their distributions.
%
% *L10-Q.8* If PC1 is a "everybody up together" component, what could it
% reflect in an awake mouse?

% >>> YOUR CODE HERE <<<

%% F. (optional) Can the population decode the frequency?
% Use the decoder of Lesson 9 (|decodeCV|: cross-validated logistic
% regression, balanced accuracy) and a shuffle null distribution.

%% FOR YOUR GROUP!! - L10-E.6
% # Leave out 12 and 24 kHz. Label the remaining tones *low* (6, 7.56,
% 9.52 kHz, |y = 0|) or *high* (15.12, 19.05 kHz, |y = 1|). Decode |y|
% from |R| with |decodeCV(X, y, 4)| and build a null distribution by
% shuffling |y| 200 times.
% # Do the same for the *position* instead: early (positions 1-3) vs late
% (positions 4-6) tones. Which one can be decoded?
%
% *L10-Q.9* With 20 trials and 20 neurons, why are cross-validation and a
% null distribution essential?

% >>> YOUR CODE HERE <<<

%% G. Putting it together: the group presentation
% Prepare about 5 slides (5 minutes):
%
% # One slide per question (1-5): *one* figure, and the answer in one
% sentence. Say how sure you are and why.
% # One slide "What we do not trust": a confound, a small sample, an
% arbitrary choice (threshold, windows) that could change the answer.
%
% Good figures: labelled axes with units, a title that states the
% result, the number of neurons and tones in the legend or caption.
% |exportgraphics(gcf, 'Q3_responsive.png', 'Resolution', 200)| saves a
% figure for the slides.
%
% Questions the other groups (and the teachers) may ask you:
%
% * How did you choose the baseline and response windows? Does the answer
% change with other windows?
% * Did you correct for multiple comparisons?
% * What is the unit of your statistics: neuron, tone, or tone x neuron?
% * Could movement or arousal explain your result?

%% HOMEWORK (optional)
% # *Windows*: repeat section B with a response window of 0.5-1.5 s and
% with a baseline of 2 s. How robust is the number of responsive neurons?
% # *Deconvolution light*: |diff(dFF)| is large when calcium rises. Set
% negative values to 0 and use the result as an "activity" estimate.
% Repeat the tuning analysis (section C). Does the confound disappear?
% # *Position-matched comparison*: compare the response to 24 kHz
% (position 7) with the response to the tone at position 6 of the same
% block. What does this comparison control for, and what not?
% # *Bootstrap*: compute a 95% bootstrap confidence interval (Lesson 9) of
% the best frequency of neuron 1 by resampling the 4 repeats.
% # *Think about the pipeline*: the data you got were already dF/F of
% manually selected neurons. List the steps that happened before
% (motion correction, ROI detection, neuropil subtraction, F0 estimation)
% and how each could bias the results. Tools: Suite2p, CaImAn.
