function [counts, lags] = plotACG(spikeTimes, binSize, maxLag, doPlot)
% plotACG  Autocorrelogram of one neuron (drawn in the current axes).
%
%   [counts, lags] = plotACG(spikeTimes, binSize, maxLag)
%   [counts, lags] = plotACG(spikeTimes, binSize, maxLag, false)  % no plot
%
%   INPUTS
%       spikeTimes - vector of spike times (s) of one neuron
%       binSize    - bin width (s), e.g. 0.001 (1 ms)
%       maxLag     - half window (s), e.g. 0.05 (+/- 50 ms)
%       doPlot     - (optional, default true)
%   OUTPUTS
%       counts - number of spike pairs at each lag (zero-lag bin removed)
%       lags   - lag of each bin centre (s)
%
%   How it works: the spike train is binned (1 = spike in that bin) and
%   correlated with itself (xcorr). This is the same as counting, for
%   every spike, how many other spikes occur at each time lag.
%
%   Adapted from plotAutocorrelogram.m (H. Malagon). Course: MUW 860.053

if nargin < 4, doPlot = true; end
s = sort(spikeTimes(:));
edges = (s(1) - maxLag):binSize:(s(end) + maxLag + binSize);
train = histcounts(s, edges);
nLag  = round(maxLag / binSize);
counts = xcorr(train, nLag);            % raw pair counts
lags   = (-nLag:nLag) * binSize;
counts(nLag + 1) = 0;                   % remove the trivial zero-lag peak

if doPlot
    bar(lags * 1000, counts, 'BarWidth', 1, 'EdgeColor', 'none')
    xlabel('Lag (ms)')
    ylabel('Spike pairs')
    set(gca, 'Box', 'off')
end
end
