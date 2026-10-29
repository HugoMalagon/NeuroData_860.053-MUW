function aligned = alignSpikes(spikeTimes, eventTimes, pre, post)
% alignSpikes  Spike times of one neuron relative to a list of events.
%
%   aligned = alignSpikes(spikeTimes, eventTimes, pre, post)
%
%   INPUTS
%       spikeTimes - vector of spike times (s) of one neuron
%       eventTimes - [nTrials x 1] event times (s), e.g. cue or reward onset.
%                    NaN events give an empty trial.
%       pre, post  - time (s) to keep before and after each event (both > 0)
%   OUTPUT
%       aligned    - {nTrials x 1} cell. aligned{k} contains the spike times
%                    relative to event k (so 0 = event), in [-pre, post].
%
%   EXAMPLE
%       aligned = alignSpikes(spikeTimes{60}, T.Reward_s, 2, 3);
%       plotRaster(aligned)
%
%   Course: MUW 860.053

s = spikeTimes(:);
eventTimes = eventTimes(:);
aligned = cell(numel(eventTimes), 1);
for k = 1:numel(eventTimes)
    if isnan(eventTimes(k)), aligned{k} = zeros(0,1); continue; end
    rel = s - eventTimes(k);
    aligned{k} = rel(rel >= -pre & rel <= post);
end
end
