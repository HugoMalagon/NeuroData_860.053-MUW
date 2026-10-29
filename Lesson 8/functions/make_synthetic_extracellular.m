function S = make_synthetic_extracellular(unitSpikeTimes, duration, fs, seed)
% make_synthetic_extracellular  Simulated raw extracellular recording.
%
%   S = make_synthetic_extracellular(unitSpikeTimes, duration, fs, seed)
%
%   Builds a "raw" wide-band signal from one electrode, like the one an
%   amplifier (Intan, Neuropixels...) stores BEFORE spike sorting:
%       raw = LFP (slow waves + theta) + 50 Hz line noise
%           + spikes of a few nearby neurons (known waveforms, known times)
%           + background activity of many far-away neurons + amplifier noise
%   Because the true spike times are known (the "ground truth"), students
%   can measure how well their spike detection / sorting works.
%
%   INPUTS
%       unitSpikeTimes - {1 x nUnits} cell of spike times (s). Real spike
%                        times can be used (e.g. from STMtx) - only the
%                        spikes inside [0, duration] are used.
%       duration       - length of the recording (s), default 20
%       fs             - sampling rate (Hz), default 20000
%       seed           - random seed, default 1
%   OUTPUT (struct)
%       raw        - [1 x N] wide-band signal (microvolts)
%       t          - [1 x N] time (s)
%       fs         - sampling rate
%       gtSpikes   - {1 x nUnits} true spike times (s) of each unit
%       templates  - [nUnits x L] true average waveform of each unit (uV)
%       templateT  - [1 x L] time axis of the templates (ms)
%
%   Course: MUW 860.053

if nargin < 2 || isempty(duration), duration = 20;    end
if nargin < 3 || isempty(fs),       fs = 20000;       end
if nargin < 4 || isempty(seed),     seed = 1;         end
rng(seed);
N = round(duration*fs);
t = (0:N-1)/fs;
nU = numel(unitSpikeTimes);

% --- waveform templates: negative trough + positive rebound -------------
tw = (-0.6e-3):(1/fs):(1.4e-3);                   % 2 ms window
L  = numel(tw);
amps    = [-140 -90 -60 -45];                      % trough amplitude (uV)
widthsN = [0.10 0.13 0.18 0.12]*1e-3;              % trough width (s)
repol   = [0.25 0.45 0.55 0.35]*1e-3;              % time of rebound peak (s)
reb     = [0.35 0.25 0.20 0.30];                   % rebound size (fraction)
templates = zeros(nU, L);
for u = 1:nU
    k = mod(u-1, numel(amps)) + 1;
    trough = exp(-tw.^2/(2*widthsN(k)^2));
    rebound = reb(k) * exp(-(tw - repol(k)).^2/(2*(2.2*widthsN(k))^2));
    templates(u,:) = amps(k) * (trough - rebound);
end

raw = zeros(1, N);
gtSpikes = cell(1, nU);
i0 = find(tw >= 0, 1);
for u = 1:nU
    s = unitSpikeTimes{u}(:);
    s = s(s > 0.002 & s < duration - 0.002);
    gtSpikes{u} = s;
    for k = 1:numel(s)
        idx = round(s(k)*fs) + (1:L) - i0;
        a = 1 + 0.08*randn;                          % small amplitude jitter
        raw(idx) = raw(idx) + a*templates(u,:);
    end
end

% --- background: many small far-away units --------------------------------
for b = 1:40
    rate = 3 + 7*rand;
    sb = cumsum(-log(rand(ceil(rate*duration*1.5),1))/rate);
    sb = sb(sb > 0.002 & sb < duration - 0.002);
    tpl = (6 + 8*rand) * templates(mod(b,2)+1,:) / abs(min(templates(mod(b,2)+1,:)));
    for k = 1:numel(sb)
        idx = round(sb(k)*fs) + (1:L) - i0;
        raw(idx) = raw(idx) + tpl;
    end
end

% --- amplifier noise (white) ---------------------------------------------
raw = raw + 8*randn(1, N);

% --- LFP: slow 1/f waves + theta ----------------------------------------
w = randn(1, N); W = fft(w);
f = [0:floor(N/2), -ceil(N/2)+1:-1] * fs / N;
lf = real(ifft(W ./ max(abs(f), 0.5).^0.9 .* (abs(f) < 300)));
lf = 150 * lf / std(lf);
raw = raw + lf + 100*sin(2*pi*7*t) + 30*sin(2*pi*50*t);

S.raw = raw;
S.t = t;
S.fs = fs;
S.gtSpikes = gtSpikes;
S.templates = templates;
S.templateT = tw*1000;
end
