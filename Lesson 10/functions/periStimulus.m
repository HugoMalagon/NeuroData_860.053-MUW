function [P, tLag] = periStimulus(traces, onsetFrames, lags, fs)
% periStimulus  Cut peri-stimulus windows out of continuous traces.
%
%   [P, tLag] = periStimulus(traces, onsetFrames, lags, fs)
%
%   INPUTS
%       traces      - [nFrames x nNeurons] continuous signals (e.g. dF/F),
%                     one column per neuron
%       onsetFrames - [nTrials x 1] frame index of each stimulus onset
%       lags        - [1 x nLags] frames relative to the onset to keep,
%                     e.g. -4:9 (negative = before the onset)
%       fs          - sampling rate in Hz (frames per second)
%   OUTPUTS
%       P    - [nTrials x nLags x nNeurons] peri-stimulus array:
%              P(i, j, n) = traces(onsetFrames(i) + lags(j), n)
%              Windows that fall outside the recording are NaN.
%       tLag - [1 x nLags] time of each lag relative to the onset (s)
%
%   EXAMPLE (mean response of neuron 3 to all stimuli)
%       [P, tLag] = periStimulus(dFF, Stim.OnsetFrame, -4:9, 2);
%       plot(tLag, mean(P(:, :, 3), 1))
%
%   Course: MUW 860.053

onsetFrames = onsetFrames(:);
lags = lags(:)';
[nF, nN] = size(traces);
nT = numel(onsetFrames);
P = nan(nT, numel(lags), nN);
for i = 1:nT
    idx = onsetFrames(i) + lags;
    ok = idx >= 1 & idx <= nF;
    P(i, ok, :) = reshape(traces(idx(ok), :), 1, sum(ok), nN);
end
tLag = lags / fs;
end
