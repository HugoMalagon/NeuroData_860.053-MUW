function [rates, counts] = countSpikesInWindows(spikeTimes, tStart, tEnd)
% countSpikesInWindows  Spike counts and firing rates inside time windows.
%
%   [rates, counts] = countSpikesInWindows(spikeTimes, tStart, tEnd)
%
%   INPUTS
%       spikeTimes - vector of spike times (s) of ONE neuron, or a cell
%                    array {1 x nNeurons} with one vector per neuron.
%       tStart     - [nWindows x 1] window start times (s)
%       tEnd       - [nWindows x 1] window end times (s). Same size as tStart.
%   OUTPUTS
%       rates      - [nWindows x nNeurons] firing rate (Hz) = counts / duration
%       counts     - [nWindows x nNeurons] number of spikes in [tStart, tEnd)
%
%   Windows with NaN start or end give NaN.
%
%   EXAMPLE (firing rate of all neurons in the 1 s after each reward)
%       rates = countSpikesInWindows(spikeTimes, T.Reward_s, T.Reward_s + 1);
%
%   Based on FR_Neurons.m (Flexi-Gambling). Course: MUW 860.053

if ~iscell(spikeTimes), spikeTimes = {spikeTimes}; end
tStart = tStart(:); tEnd = tEnd(:);
nW = numel(tStart); nN = numel(spikeTimes);
counts = nan(nW, nN);
for n = 1:nN
    s = spikeTimes{n}(:);
    for w = 1:nW
        if ~isnan(tStart(w)) && ~isnan(tEnd(w))
            counts(w, n) = sum(s >= tStart(w) & s < tEnd(w));
        end
    end
end
rates = counts ./ (tEnd - tStart);
end
