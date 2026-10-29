function S = make_synthetic_LFP(duration, fs, seed)
% make_synthetic_LFP  Simulated local field potential with known ingredients.
%
%   S = make_synthetic_LFP(duration, fs, seed)
%
%   Because we know exactly what was put into this signal, we can check
%   whether our analysis tools recover it. Ingredients:
%     1. "1/f" background (pink-like noise), present in every real LFP
%     2. theta oscillation (~7-8 Hz) ONLY while the animal is running
%     3. gamma bursts (~60-70 Hz) whose amplitude follows the theta phase
%        (phase-amplitude coupling), also only while running
%     4. 50 Hz line noise from the mains (an artefact!)
%
%   INPUTS  duration (s, default 120), fs (Hz, default 1000), seed (default 1)
%   OUTPUT  struct S with fields
%       lfp      - [1 x N] signal (microvolts)
%       t        - [1 x N] time (s)
%       fs       - sampling rate (Hz)
%       running  - [1 x N] logical, true while the animal runs
%       speed    - [1 x N] running speed (cm/s), smooth
%       info     - text description of the parameters
%
%   Course: MUW 860.053

if nargin < 1 || isempty(duration), duration = 120; end
if nargin < 2 || isempty(fs),       fs = 1000;      end
if nargin < 3 || isempty(seed),     seed = 1;       end
rng(seed);

N = round(duration * fs);
t = (0:N-1) / fs;

% --- 1. aperiodic 1/f background (spectrum ~ 1/f^1.6) --------------------
w = randn(1, N);
W = fft(w);
f = [0:floor(N/2), -ceil(N/2)+1:-1] * fs / N;
scale = 1 ./ max(abs(f), 0.5).^(1.6/2);
bg = real(ifft(W .* scale));
bg = 60 * bg / std(bg);

% --- running epochs (behavioural state) ----------------------------------
running = false(1, N);
boutSpeed = zeros(1, N);   % each running bout has its own speed
tt = 5;
while tt < duration - 5
    runDur  = 6 + 8*rand;      % 6-14 s running
    restDur = 5 + 8*rand;      % 5-13 s resting
    inBout = t >= tt & t < tt + runDur;
    running(inBout) = true;
    boutSpeed(inBout) = 10 + 25*rand;
    tt = tt + runDur + restDur;
end
smoothWin = ones(1, round(0.5*fs)) / round(0.5*fs);
env = conv(double(running), smoothWin, 'same');     % smooth on/off (0-1)
speedTrace = conv(boutSpeed, smoothWin, 'same');
% slow random fluctuation of theta amplitude (not perfectly tied to speed)
slowMod = conv(randn(1, N), ones(1, 2*fs)/(2*fs), 'same');
slowMod = 1 + 0.35*slowMod/std(slowMod);
env = env .* max(slowMod, 0.2) .* (0.6 + 0.4*speedTrace/35);

% --- 2. theta (frequency drifts slightly around 7.5 Hz) ------------------
fTheta = 7.5 + 0.5*sin(2*pi*t/13);
phTheta = 2*pi*cumsum(fTheta)/fs;
theta = 120 * env .* cos(phTheta);

% --- 3. gamma nested in theta (amplitude max at theta peak) -------------
% gamma frequency wanders between ~55 and ~75 Hz (real gamma is not a pure tone)
fDrift = conv(randn(1, N), ones(1, round(0.05*fs))/round(0.05*fs), 'same');
fGamma = 65 + 8*fDrift/std(fDrift);
gammaAmp = 25 * env .* (1 + cos(phTheta)) / 2;
gamma = gammaAmp .* cos(2*pi*cumsum(fGamma)/fs);

% --- 4. line noise -------------------------------------------------------
line50 = 15 * sin(2*pi*50*t);

S.lfp = bg + theta + gamma + line50;
S.t = t;
S.fs = fs;
S.running = running;
S.speed = max(speedTrace + 1.5*randn(1, N).*(speedTrace > 1), 0);
S.info = sprintf(['Synthetic LFP, %g s at %g Hz. 1/f background (60 uV), ', ...
    'theta 7-8 Hz (120 uV) and theta-nested gamma 65 Hz (25 uV) only during running, ', ...
    '50 Hz line noise (15 uV). Seed %d.'], duration, fs, seed);
end
