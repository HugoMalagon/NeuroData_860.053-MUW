% Lesson8_Students_plain.m
% Plain-script version of the live script Lesson8_Students.mlx, for
% computers on which the live script does not open. The text, code and
% exercises are the same; only the layout is different.
%
% How to use this file
% * Open it in the MATLAB Editor and set the Current Folder to the folder
%   "Lesson 8" (the folder that contains this file).
% * Run it one section at a time: click inside a section (each section
%   starts at a line that begins with %%) and press Ctrl+Enter (macOS:
%   Cmd+Enter), or click Run Section in the Editor tab.
% * Results appear in the Command Window, figures in figure windows.
% * The lesson text is in the comments. Marks such as *bold*, _italic_
%   and |code| are the formatting of the live script.
% * Write your answers where it says "% >>> YOUR CODE HERE <<<".

%% Lesson 8 - Signals: Sampling, Spectra, Filters, LFP and Spikes
% *Processing and Interpretation of Neuroscience Data (860.053-MUW)* -
% Vered Kellner and Hugo Malagon Vina. Parts inspired by W. van Drongelen,
% _Signal Processing for Neuroscientists_, and M. X Cohen, _Analyzing
% Neural Time Series Data_.
%
% Electrophysiology gives us *continuous signals*: voltage sampled many
% thousand times per second. From the same electrode we can extract slow
% field potentials (LFP, oscillations) and fast action potentials
% (spikes). In Lesson 7 we started from spike times that were already
% sorted; in this lesson you learn the tools that produce them, and those
% needed to analyse the slow part of the signal.
%
% *Learning goals*
%
% * Understand sampling, the Nyquist frequency and aliasing
% * Detect events with robust thresholds (median / MAD)
% * Design and apply digital filters, and know their pitfalls
% * Move between time and frequency domain (FFT, power spectrum)
% * Analyse an LFP: its components, spectrum, spectrogram, band power and
% phase
% * See (demo) how spikes are obtained from a raw extracellular recording:
% filter, detect, extract waveforms, cluster, and evaluate
%
% *Data*
%
% * |Intracellular_Recording.mat| - 20 s of an *intracellular* recording
% (membrane potential |Vm| in mV, time |tVm| in s, sampling rate |fs|, 10 kHz;
% renamed |fsVm| after loading, because this lesson uses several sampling rates)
% * |Synthetic_LFP.mat| - 120 s of a simulated LFP (1 kHz) with known
% ingredients (see |make_synthetic_LFP.m|)
% * |Synthetic_Extracellular.mat| - 20 s of a simulated raw extracellular
% recording (20 kHz). The spikes of its 3 units are *real spike times*
% from the prelimbic neurons of Lessons 6 and 7, so we know the ground truth.
%
% Toolboxes: Signal Processing (required), Wavelet (homework only, optional),
% Statistics and Machine Learning (section 7.4).

%% 0. Setup
clear; close all; clc
assert(isfolder('data'), ['Data folder not found. Set the Current Folder ' ...
    'to the "Lesson 8" folder and run again.'])
addpath('functions')
rng(1)

%% 1. Sampling and aliasing
% A computer can only store a signal at discrete time points: it
% *samples* it at a sampling rate |fs| (Hz). If we sample too slowly, fast
% oscillations are not only lost - they appear as *slower* oscillations
% that do not exist. This is called *aliasing*.
%
% Below, a 20 Hz sine (black, "continuous") is sampled at decreasing rates (red).
f  = 20;                          % Hz
tc = 0:1e-4:0.5;                  % "continuous" time (10 kHz)
xc = sin(2*pi*f*tc);
fsList = [500 200 80 50 40 30 25 21];    % sampling rates to try; note 40 Hz = exactly 2f!
figure('Position', [100 100 1000 550])
tiledlayout(2, 4, 'TileSpacing', 'compact')
for fsi = fsList
    nexttile
    ts = 0:1/fsi:0.5;                    % sample times at this rate
    plot(tc, xc, 'Color', [0.6 0.6 0.6]); hold on
    plot(ts, sin(2*pi*f*ts), 'r.-', 'MarkerSize', 10)
    title(sprintf('fs = %d Hz', fsi)); xlim([0 0.5]); ylim([-1.2 1.2])
end
xlabel('Time (s)')

%%
% *The Nyquist theorem*: to represent a frequency |f| we need |fs > 2f|.
% The highest frequency we can see, |fs/2|, is the *Nyquist frequency*.
% Components above it fold back and appear at |abs(f - k*fs)|.
%
% Typical sampling rates: spikes 20-30 kHz, LFP 1-2.5 kHz, EEG 250-1000 Hz,
% two-photon calcium imaging 2-30 Hz (Lesson 10!). Before sampling, the
% amplifier removes frequencies above Nyquist with an analogue
% *anti-aliasing filter*. The same must be done when you *downsample*
% data in MATLAB: use |decimate| or |resample|, never |x(1:10:end)|.

%% FOR YOU!! - L8-E.1
% # *L8-Q.1* At what sampling rate does the red signal start to look
% distorted? At what rate is its frequency no longer 20 Hz? Why is the
% signal flat at exactly 40 Hz (= 2 x 20 Hz)?
% # Predict the apparent frequency when a 70 Hz sine is sampled at 100 Hz
% (use the rule above). Then check it with a plot. Hint: reuse the lines
% inside the loop above, with a 70 Hz sine and a sampling rate of 100 Hz.
% # (Optional) Generate a sine with a random frequency between 5 and 100
% Hz (|randi([5 100])|). Sample it at 1.2, 2.5 and 10 times its frequency
% and plot the three versions.

% >>> YOUR CODE HERE <<<

%% 2. Always look at your data: an intracellular recording
% Before any analysis, *plot the raw data*. This is a whole-cell
% recording of the membrane potential of one neuron.
load(fullfile('data', 'Intracellular_Recording.mat'))    % Vm, tVm, fs
fsVm = fs; clear fs      % rename: this lesson has several sampling rates
fprintf('fsVm = %d Hz, duration = %.1f s\n', fsVm, tVm(end));
figure
plot(tVm, Vm)
xlabel('Time (s)'); ylabel('Membrane potential (mV)')
title('Intracellular recording')

%% FOR YOU!! - L8-Q.2
% Describe the signal. What is the resting potential? What are the
% sharp upward events? What else could carry information?

%% 2.1 Thresholds: mean/SD versus median/MAD
% To detect action potentials we set a threshold. The spikes themselves
% inflate the mean and especially the SD; the *median* and the *median
% absolute deviation (MAD)* are almost insensitive to them (robust statistics).
% Here we only *draw* the two thresholds; the detection itself uses 0 mV
% (see the text below the code).
%
% For Gaussian noise the MAD is 0.6745 x SD, so |mad(x,1)/0.6745| turns
% the MAD into a robust estimate of the SD (Lesson 6 used |mad| without
% this factor).
thrSD  = mean(Vm)   + 3*std(Vm);
thrMAD = median(Vm) + 3*mad(Vm, 1)/0.6745;   % MAD scaled to an SD
hold on
yline(thrSD,  'm--', 'mean + 3 SD')
yline(thrMAD, 'r--', 'median + 3 MAD')
% locs = sample numbers (indices) of the peaks, not times: times = tVm(locs)
[pks, locs] = findpeaks(Vm, 'MinPeakHeight', 0, 'MinPeakDistance', round(0.002*fsVm));
plot(tVm(locs), pks, 'go')
fprintf('%d action potentials (peaks above 0 mV)\n', numel(pks));

%%
% A threshold at 0 mV works here because intracellular spikes are huge.
% Note that the two thresholds differ, and the median + 3 MAD line even
% lies *above* the mean + 3 SD line. This recording is not "noise + a few
% spikes": the membrane potential switches between down states (about -71
% mV) and up states (about -52 mV), and for such a two-level signal
% median/MAD and mean/SD give different answers. The spikes themselves do
% move the SD more than the MAD (the larger and the more numerous the
% events, as long as they stay rare, the bigger that effect), but here the
% two levels matter more. Robust statistics are made for "Gaussian noise +
% rare large events": exactly the extracellular signal of section 7, where
% spikes are ~1000 times smaller and buried in noise, and the choice of
% threshold becomes critical.

%% FOR YOU!! - L8-E.2
% Add noise: |noisyVm = Vm + 15*randn(size(Vm));|
%
% # Plot it. Detect the spikes with |findpeaks| (copy the call of 2.1) and
% a threshold of your choice. How many events do you detect, compared with
% the 48 true spikes (|numel(locs)|)? Look at the plot: which spikes are
% missed, and which detections are false?
% # (Optional) Use the options |MinPeakDistance| and |MinPeakProminence|
% of |findpeaks| (see |doc findpeaks|) to improve the detection.

% >>> YOUR CODE HERE <<<

%% 3. The local field potential (LFP): what is in it?
% The LFP is the low-frequency part (< ~300 Hz) of the extracellular
% signal. It reflects mainly synaptic currents of many neurons and
% contains *oscillations* (delta, theta, beta, gamma...) linked to
% behaviour. Here we analyse a *simulated* LFP whose ingredients we know
% (open |make_synthetic_LFP.m|): a 1/f background, theta and gamma
% oscillations only while the animal runs, and 50 Hz line noise.
%
% Before any analysis: *look at it*.
L = load(fullfile('data', 'Synthetic_LFP.mat'));    % load into a struct L: L.lfp, L.t, L.fs ...
lfp = L.lfp; tL = L.t; fsL = L.fs;
isRunning = L.running;                   % logical: true while the animal runs
tRun = tL(find(isRunning, 1));           % start of the first running bout

figure('Position', [100 100 1000 600])
tiledlayout(3, 1)
nexttile
plot(tL, lfp); xlim([0 60]); ylabel('LFP (\muV)')
title('Synthetic LFP')
nexttile
area(tL, L.speed, 'FaceColor', [0.5 0.7 0.9]); xlim([0 60])
xlabel('Time (s)'); ylabel('Speed (cm/s)')
nexttile
plot(tL, lfp); xlim(tRun + [-2 2]); xline(tRun, 'k--', 'running starts')
xlabel('Time (s)'); ylabel('LFP (\muV)'); title('Zoom: 4 s around the start of running')

%%
% What can we see by eye?
%
% * a slow, irregular background all the time
% * while the animal runs, a *regular rhythm* of about 8 cycles per second
% (8 Hz) on top of it
% * a fine, fast "hum" all the time (the small wiggles in the zoom): 50 Hz
% mains noise
%
% How do we separate these components and measure how strong each one is?
% Two tools: *filters* keep the frequencies we choose (section 4), and the
% *Fourier transform* tells us which frequencies a signal contains
% (section 5). In section 6 we come back to this LFP with both.

%% 4. Digital filters
% A filter keeps some frequencies and attenuates others (frequency =
% cycles per second, in Hz: an 8 Hz theta wave goes up and down 8 times
% per second):
%
% * *low-pass*: keeps slow components (e.g. LFP < 300 Hz)
% * *high-pass*: removes slow drifts (e.g. spikes > 300 Hz)
% * *band-pass*: keeps a band (e.g. theta 4-12 Hz)
% * *band-stop / notch*: removes a band (e.g. 50 Hz mains noise)
%
% |designfilt| designs the filter, |freqz| shows what it does, |filtfilt|
% applies it. Butterworth (IIR) filters are common in LFP analysis.
% Two parameters matter:
%
% * |'FilterOrder'| = steepness (higher = steeper, but more ringing);
% 4 is a good default.
% * |'HalfPowerFrequency1/2'| = the cut-offs (in Hz).
bp = designfilt('bandpassiir', 'FilterOrder', 4, ...
    'HalfPowerFrequency1', 4, 'HalfPowerFrequency2', 12, 'SampleRate', fsL);
[h, fh] = freqz(bp, 4096, fsL);
figure
plot(fh, abs(h), 'LineWidth', 1.5)
xlim([0 50]); xlabel('Frequency (Hz)'); ylabel('Gain')
title('Band-pass 4-12 Hz: frequency response')

%% 4.1 Filtering the LFP: theta appears
% Apply the band-pass to the LFP with |filtfilt|: only the 4-12 Hz part of
% the signal is left.
lfpTheta = filtfilt(bp, lfp);
figure('Position', [100 100 1000 350])
plot(tL, lfp, 'Color', [0.7 0.7 0.7]); hold on
plot(tL, lfpTheta, 'b', 'LineWidth', 1.2)
xline(tRun, 'k--', 'running starts', 'HandleVisibility', 'off')
xlim(tRun + [-2 2]); xlabel('Time (s)'); ylabel('\muV')
legend('LFP', '4-12 Hz band-pass')
title('Band-pass filtered LFP: theta appears when the animal runs')
% note: even before running the filtered trace wiggles a little. A
% band-pass filter makes ANY background look wave-like (see 4.3)

%% 4.2 Pitfall 1: phase distortion
% To see the pitfalls we need a signal where we know the true answer: a
% *toy signal* made of three sines (5, 12 and 40 Hz) plus noise. We use it
% again in section 5.
%
% |filter| runs the filter forward in time: the output is *delayed*, and
% the delay differs between frequencies. |filtfilt| runs it forward and
% backward: zero phase shift. Always use |filtfilt| (or a linear-phase
% FIR filter with its delay corrected) when timing or phase matter.
fsSim = 1000; durSim = 2;          % toy signal: 1 kHz (= fsL, so bp works here too), 2 s
tSim = (0:durSim*fsSim-1)/fsSim;
xSim = 1.0*sin(2*pi*5*tSim) + 0.5*sin(2*pi*12*tSim) + 0.3*sin(2*pi*40*tSim) + 0.5*randn(size(tSim));

yFwd  = filter(bp, xSim);
yZero = filtfilt(bp, xSim);
figure
plot(tSim, sin(2*pi*5*tSim), 'k', tSim, yFwd, 'r', tSim, yZero, 'b--', 'LineWidth', 1.2)
xlim([0.5 1.5]); xlabel('Time (s)')
legend('true 5 Hz component', 'filter (shifted!)', 'filtfilt (zero phase)')

%% 4.3 Pitfall 2: edge effects and ringing (demo)
% *Demo:* run this section and look at the result; the teacher explains it.
%
% Filters need "run-in" time: the first and last samples are distorted,
% and sharp events (a spike, an artefact) produce oscillations
% ("ringing") in narrow-band filters. Filter long stretches of data, then
% cut the epochs you need - never filter short epochs.
impulse = zeros(1, 2*fsSim); impulse(fsSim) = 1;
figure
plot((0:2*fsSim-1)/fsSim, filtfilt(bp, impulse))
xlabel('Time (s)'); title('A single sharp event after a 4-12 Hz filter: ringing')

%% FOR YOU!! - L8-E.3
% # Design a *notch* (band-stop) filter for 49-51 Hz and a *low-pass* filter
% at 100 Hz for data sampled at 1 kHz. Plot both frequency responses.
% Hints: copy the |designfilt| call of section 4. A band-stop is
% |'bandstopiir'| (same parameters as the band-pass). A low-pass is
% |'lowpassiir'| and has only ONE cut-off: |'HalfPowerFrequency', 100|.
% The sampling rate is |'SampleRate', fsSim| (1 kHz) - not |fsVm|.
% # Add a 50 Hz sine of amplitude 1 to |xSim|, remove it with your notch
% filter (|filtfilt|), and plot 0.2 s of the signal before and after,
% together with the original |xSim|. Does the cleaned signal match |xSim|?
%
% *L8-Q.3* Why is a narrow band-pass filter dangerous when you want to
% claim that "there is an oscillation" in your data?

% >>> YOUR CODE HERE <<<

%% 5. The frequency domain
% Filters keep or remove the bands *we* choose. But which frequencies does
% a signal contain in the first place? Every signal can be described as a
% sum of sines of different frequencies, amplitudes and phases (Fourier).
% The *Fourier transform* (|fft|) tells us how much of each frequency is
% in the signal. We try it on the toy signal of section 4.2, where we know
% the answer: 5, 12 and 40 Hz.
%
% |fft| returns *complex* numbers: their absolute value (|abs|) is the
% amplitude of each frequency, their angle the phase. The course helper
% |ampSpectrum| does the bookkeeping for you and returns the amplitude of
% every frequency from 0 Hz up to the Nyquist frequency (open
% |ampSpectrum.m| to see the 4 lines that do it).
[amp, fAx] = ampSpectrum(xSim, fsSim);     % amplitude and frequency axis (Hz)

figure('Position', [100 100 900 350])
tiledlayout(1, 2)
nexttile; plot(tSim, xSim); xlim([0 1]); xlabel('Time (s)'); title('Time domain')
nexttile; plot(fAx, amp); xlim([0 60]); xlabel('Frequency (Hz)'); ylabel('Amplitude')
title('Frequency domain (FFT)')

%%
% Two rules:
%
% * The *frequency resolution* is |1/T| (T = signal length in s): a 2-s
% signal gives 0.5 Hz steps.
% * The highest frequency is the Nyquist frequency |fs/2|.
%
% Real signals are noisy, so we average spectra of many short windows:
% *Welch's method* (|pwelch|) returns the *power spectral density* (PSD):
% power (amplitude squared) per Hz. Power is often shown in *decibels*,
% |10*log10(power)|: +10 dB = 10 times more power, +3 dB = about 2 times.
%
% |pwelch(x, window, overlap, nfft, fs)|: window and overlap are in
% SAMPLES (|fs| samples = 1 s); |[]| = use the default for that input.
[pxx, fw] = pwelch(xSim, fsSim, fsSim/2, [], fsSim);       % 1-s windows, 50 % overlap
figure
plot(fw, 10*log10(pxx))
xlim([0 60]); xlabel('Frequency (Hz)'); ylabel('Power (dB/Hz)')
title('Welch power spectral density')

%% FOR YOU!! - L8-E.4
% # Compute the amplitude spectrum of only the first 0.25 s of |xSim| with
% |ampSpectrum| (select the samples with |tSim < 0.25|) and plot it with
% |stem| (one line per frequency). What is the frequency resolution now?
% At which frequency does the 5 Hz component appear, and why? Could you
% still separate two components at 10 and 12 Hz?
% # Compute the PSD of the intracellular signal |Vm| with |pwelch|
% (1-s windows) and plot it with log axes (|loglog|). Where is most of the
% power? Careful: |Vm| is sampled at |fsVm| (10 kHz), so window, overlap
% and sampling rate must all use |fsVm|.

% >>> YOUR CODE HERE <<<

%% 6. Back to the LFP: spectra, oscillations and behaviour
% Now we have both tools: the spectrum tells us which rhythms the LFP
% contains, and filters isolate them.

%% 6.1 Power spectrum: 1/f, peaks and artefacts
[pL, fLw] = pwelch(lfp, 2*fsL, fsL, [], fsL);
figure
loglog(fLw, pL)
xlim([1 200]); xlabel('Frequency (Hz)'); ylabel('PSD (\muV^2/Hz)')
title('LFP power spectrum (log-log)')
% note the straight line (1/f), the theta bump and the sharp 50 Hz line

%% 6.2 Remove line noise, then compare running and resting
% A notch filter like the one of E.3 (a bit wider: 48-52 Hz) removes the
% 50 Hz line noise.
notch50 = designfilt('bandstopiir', 'FilterOrder', 4, ...
    'HalfPowerFrequency1', 48, 'HalfPowerFrequency2', 52, 'SampleRate', fsL);
lfpClean = filtfilt(notch50, lfp);

% Note: lfpClean(isRunning) glues all running bouts together. Every
% junction is a small artificial jump; on real data, compute the spectrum
% of each bout separately and average them.
[pRun,  fr1] = pwelch(lfpClean(isRunning),  2*fsL, fsL, [], fsL);
[pRest, fr2] = pwelch(lfpClean(~isRunning), 2*fsL, fsL, [], fsL);
figure
loglog(fr1, pRun, fr2, pRest, 'LineWidth', 1.2)
xlim([1 150]); legend('running', 'resting')
xlabel('Frequency (Hz)'); ylabel('PSD (\muV^2/Hz)')
title('Behavioural state changes the spectrum')

%% 6.3 Time-frequency: spectrogram
% A spectrogram computes the spectrum in short sliding windows: power as a
% function of time AND frequency.
winS = 1;                                  % 1-s windows
[sp, fsp, tsp] = spectrogram(lfpClean, hann(winS*fsL), round(0.9*winS*fsL), ...
    2^nextpow2(winS*fsL), fsL);
figure('Position', [100 100 1000 350])
imagesc(tsp, fsp, 10*log10(abs(sp).^2)); axis xy     % axis xy: low frequencies at the bottom (imagesc flips by default)
ylim([1 100]); xlabel('Time (s)'); ylabel('Frequency (Hz)')
cb = colorbar; cb.Label.String = 'Power (dB)';
hold on
plot(tL, 90*L.running + 2, 'w', 'LineWidth', 1.5)    % white line = running
title('Spectrogram (white = running)')

%% 6.4 Band power and phase with the Hilbert transform
% The spectrogram tells us *that* theta and gamma appear during running,
% but only in 1-s windows. Many questions need the oscillation at *every
% moment*:
%
% * *How strong is the rhythm right now?* (its *amplitude*) - e.g. to
% relate theta to running speed moment by moment.
% * *Where in the cycle does something happen?* (its *phase*) - e.g. do
% the spikes of a neuron come at a preferred phase of theta (spike-LFP
% phase locking)? Is gamma stronger at one particular phase of theta
% (phase-amplitude coupling, E.5)? Timing within the slow cycle is thought
% to organise neural activity, so these are common questions in
% hippocampus and prefrontal cortex.
%
% Recipe: band-pass the LFP in one band (here theta), then the Hilbert
% transform gives, at every sample, the *amplitude envelope* and the
% *phase* of the oscillation. It only makes sense for a narrow-band
% signal, so always filter first.
thetaF = designfilt('bandpassiir', 'FilterOrder', 4, ...
    'HalfPowerFrequency1', 6, 'HalfPowerFrequency2', 10, 'SampleRate', fsL);
theta = filtfilt(thetaF, lfpClean);
analytic   = hilbert(theta);
thetaAmp   = abs(analytic);
thetaPhase = angle(analytic);          % radians, -pi..pi (0 = peak)

figure('Position', [100 100 1000 450])
tiledlayout(3, 1)
nexttile; plot(tL, lfpClean, 'Color', [0.7 0.7 0.7]); hold on
plot(tL, theta, 'b'); plot(tL, thetaAmp, 'r', 'LineWidth', 1.5)
xlim([10 14]); legend('LFP', 'theta', 'envelope'); ylabel('\muV')
nexttile; plot(tL, thetaPhase); xlim([10 14]); ylabel('Phase (rad)')
nexttile; plot(tL, movmean(thetaAmp, fsL), tL, L.speed*5)
xlim([0 120]); legend('theta envelope (1-s mean)', 'speed x 5'); xlabel('Time (s)')

r = corr(movmean(thetaAmp, fsL)', L.speed');
fprintf('Correlation between theta amplitude and speed: r = %.2f\n', r);

% The same recipe for gamma (55-75 Hz), the fast rhythm of running:
% band-pass, Hilbert, absolute value = amplitude envelope.
gF = designfilt('bandpassiir', 'FilterOrder', 4, ...
    'HalfPowerFrequency1', 55, 'HalfPowerFrequency2', 75, 'SampleRate', fsL);
gammaAmp = abs(hilbert(filtfilt(gF, lfpClean)));
fprintf('Gamma amplitude: running %.1f uV, resting %.1f uV\n', ...
    mean(gammaAmp(isRunning)), mean(gammaAmp(~isRunning)));

%% FOR YOU!! - L8-E.5
% *Phase-amplitude coupling* (PAC): does the amplitude of the fast rhythm
% (gamma, |gammaAmp|) depend on the phase of the slow one (theta,
% |thetaPhase|)? Both were computed in section 6.4.
%
% # Bin the theta phase in 18 bins of 20 degrees:
% |bins = discretize(thetaPhase, linspace(-pi, pi, 19));|
% # Compute the mean gamma amplitude in each bin, during running only.
% Hint: |for b = 1:18, ampByPhase(b) = mean(gammaAmp(isRunning & bins == b)); end|
% # Plot it with |bar(ampByPhase)|. Bins 9 and 10 lie around phase 0 (the
% theta peak), bins 1 and 18 around the trough.
%
% At which theta phase is gamma strongest? What would the plot look like if
% there were no coupling?

% >>> YOUR CODE HERE <<<

%% 7. From a raw extracellular recording to spikes (demo)
% *Demo:* run sections 7 to 7.6 one by one while the teacher explains; read
% the details at home. Your task comes after it (L8-E.6).
%
% An electrode in the brain records the LFP *plus* the spikes of the
% neurons close to it, plus noise. Getting single neurons out of this is
% called *spike sorting*. Here we do a simplified version on a
% simulated recording where the true spike times are known.
E = load(fullfile('data', 'Synthetic_Extracellular.mat'));
raw = E.raw; tE = E.t; fsE = E.fs;
disp(E.description)
figure('Position', [100 100 1000 300])
plot(tE, raw); xlim([2 2.5])
xlabel('Time (s)'); ylabel('\muV'); title('Raw wide-band signal (0.5 s)')

%% 7.1 Band-pass for spikes (300-6000 Hz) (demo)
spkF = designfilt('bandpassiir', 'FilterOrder', 4, ...
    'HalfPowerFrequency1', 300, 'HalfPowerFrequency2', 6000, 'SampleRate', fsE);
xf = filtfilt(spkF, raw);
figure('Position', [100 100 1000 300])
plot(tE, xf); xlim([2 2.5])
xlabel('Time (s)'); ylabel('\muV'); title('Spike band (300-6000 Hz)')

%% 7.2 Robust threshold and detection (demo)
% Extracellular spikes are mostly *negative*. The noise level is estimated
% robustly as |sigma = median(abs(x))/0.6745| (Quiroga et al. 2004,
% Neural Computation) and the threshold set at about -4 to -5 sigma. A
% "dead time" of 1 ms avoids counting one spike twice.
% (Same idea as median/MAD in section 2.1: the filtered signal is centred
% on 0, so median(abs(x)) is its MAD.)
sigmaN = median(abs(xf)) / 0.6745;
thr = 4.5 * sigmaN;     % SIZE of the threshold; spikes are negative, so we look for peaks of -xf
[~, spkIdx] = findpeaks(-xf, 'MinPeakHeight', thr, 'MinPeakDistance', round(0.001*fsE));
spkIdx = spkIdx(spkIdx > 20 & spkIdx < numel(xf) - 40);   % keep full waveforms
detected = tE(spkIdx);
fprintf('noise sigma = %.1f uV, threshold = -%.1f uV, %d spikes detected\n', ...
    sigmaN, thr, numel(detected));
hold on; plot(detected, xf(spkIdx), 'r.'); yline(-thr, 'r--')

%% 7.3 Waveforms (demo)
% Cut a window around every detected spike: -0.6 ms to +1.4 ms.
wIdx = -12:28;                                  % samples at 20 kHz
% spkIdx(:) (column) + wIdx (row) = a matrix of indices, one row per spike
% (implicit expansion)
waves = xf(spkIdx(:) + wIdx);                   % nSpikes x 41
tW = wIdx / fsE * 1000;                         % ms
figure
plot(tW, waves(1:min(300, end), :)', 'Color', [0 0 0 0.1]); hold on   % 4th colour value = transparency
plot(tW, mean(waves), 'r', 'LineWidth', 2)
xlabel('Time (ms)'); ylabel('\muV'); title('Detected waveforms and their mean')

%% 7.4 Features and clustering (a mini spike sorter) (demo)
% Different neurons have different waveforms (amplitude, width). PCA
% (explained in Lesson 9) finds the directions in which the waveforms
% differ most; we use the first 3 as features and group the spikes with
% k-means.
[~, score, ~, ~, explained] = pca(waves);
nClust = 3;                               % number of clusters
rng(2)
idx = kmeans(score(:, 1:3), nClust, 'Replicates', 10);   % idx = cluster of every spike
cols = lines(nClust);                     % one colour per cluster; cols(idx, :) = colour of every spike
figure('Position', [100 100 900 350])
tiledlayout(1, 2)
nexttile
scatter(score(:,1), score(:,2), 8, cols(idx, :), 'filled')
xlabel(sprintf('PC1 (%.0f%%)', explained(1))); ylabel(sprintf('PC2 (%.0f%%)', explained(2)))
title('Waveform features')
nexttile; hold on
for c = 1:nClust
    plot(tW, mean(waves(idx == c, :)), 'Color', cols(c, :), 'LineWidth', 2)
end
xlabel('Time (ms)'); ylabel('\muV'); title('Mean waveform per cluster')

%% 7.5 How good is our sorting? Compare with the ground truth (demo)
% A detected spike is a *hit* for unit u if a true spike of u occurred
% within 0.5 ms.
tol_s = 0.0005;                    % 0.5 ms in SECONDS (detected and gtSpikes are times)
nU = numel(E.gtSpikes);
hitMatrix = zeros(nClust, nU);     % clusters x true units
for c = 1:nClust
    dc = detected(idx == c);
    for u = 1:nU
        gt = E.gtSpikes{u};
        hitMatrix(c, u) = sum(arrayfun(@(s) any(abs(gt - s) < tol_s), dc));   % arrayfun: cellfun for vectors
    end
end
disp('Rows = clusters, columns = true units (number of matching spikes):')
disp(hitMatrix)
nTrue = cellfun(@numel, E.gtSpikes);
[~, bestUnit] = max(hitMatrix, [], 2);
for c = 1:nClust
    u = bestUnit(c);
    fprintf('cluster %d -> unit %d: %d/%d true spikes found (%.0f%%), %d spikes in cluster\n', ...
        c, u, hitMatrix(c, u), nTrue(u), 100*hitMatrix(c, u)/nTrue(u), sum(idx == c));
end

%% 7.6 A quality check: refractory period violations (demo)
% A real neuron cannot fire twice within ~2 ms. Many ISIs below 2 ms mean
% that a cluster contains spikes of more than one neuron.
for c = 1:nClust
    isiC = diff(detected(idx == c));
    fprintf('cluster %d: %.2f%% ISIs < 2 ms\n', c, 100*mean(isiC < 0.002));
end

%%
% *In real life* spike sorting is done with dedicated software on many
% channels at once (Kilosort, MountainSort, SpikeInterface) and checked
% manually (Phy). Quality metrics like ISI violations, amplitude cut-off,
% isolation distance and firing-rate stability decide which units are
% "good". The |STMtx| matrices of Lessons 6, 7 and 9 are the *output* of
% such a pipeline.

%% FOR YOU!! - L8-E.6
% # Try 2 and 4 clusters: change |nClust = 3| in section 7.4 and run
% sections 7.4 to 7.6 again. Which number matches the ground truth best?
% (Set it back to 3 afterwards.)
% # (Optional) Repeat the detection with thresholds of 3, 3.5, 4, 4.5, 5
% and 6 sigma. For each threshold compute the total number of hits (any
% unit) and of false detections (no true spike within 0.5 ms). Plot hits
% against false detections. What is the trade-off? Hints: copy the
% |findpeaks| call of 7.2 and the matching line of 7.5. All true spikes in
% one vector: |allGT = vertcat(E.gtSpikes{:});|. Note: "false" detections
% include the real spikes of the 40 small background units, which are not
% in the ground truth.
%
% *L8-Q.4* Unit 3 has the smallest spikes. Why is it the hardest to detect?

% >>> YOUR CODE HERE <<<

%% HOMEWORK (optional)
% # *Downsampling*: take |raw| (20 kHz) and downsample it to 1 kHz twice:
% with |raw(1:20:end)| and with |decimate(raw, 20)|. Compare their
% spectra. Where does the high-frequency power of the first version go?
% # *IIR vs FIR*: design a 4-12 Hz FIR band-pass (|designfilt('bandpassfir',
% ...)|). Compare its order and frequency response with the IIR filter.
% # *Line-noise harmonics*: add 100 Hz and 150 Hz components to the LFP and
% remove them.
% # *Spike-LFP*: the raw extracellular signal contains a 7 Hz theta wave.
% Compute its phase at every detected spike and plot the distribution of
% spike phases (|histogram| or |polarhistogram|). Are these spikes locked
% to theta? (In this simulation they should NOT be - why?) Hint: filter
% |raw| (not |xf|) with a 6-8 Hz band-pass designed with
% |'SampleRate', fsE|, then |angle(hilbert(...))| at |spkIdx|.
% # *Wavelets* (Wavelet Toolbox): the continuous wavelet transform (|cwt|)
% adapts its window to each frequency - long windows at low frequencies
% (good frequency resolution), short ones at high frequencies (good time
% resolution). Compute |[wt, fwt] = cwt(x, fsL, 'FrequencyLimits', [2 120])|
% for 20 s of |lfpClean| and show |abs(wt)| with |imagesc| (log frequency
% axis). Then generate a chirp (|chirp|) from 1 to 100 Hz and look at it
% with |spectrogram| and |cwt|. Which one shows the fast part better?
% # *What does a PC measure in a spike?* In section 7.4 keep the loadings
% too (|[coeff, score, ~, ~, explained] = pca(waves)|) and plot
% |coeff(:, 1:2)| against |tW|. Which part of the waveform does PC1 weigh
% most? And PC2? (Each PC is a weighted mix of the 41 time samples.)
% # *Calcium imaging preview*: a two-photon microscope samples at 2 Hz. Which
% frequencies can it represent? Could it resolve individual spikes of a
% neuron firing at 10 Hz?
