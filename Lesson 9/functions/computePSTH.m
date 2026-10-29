function [rate, binCenters, trialRates] = computePSTH(aligned, pre, post, binSize, sigma)
% computePSTH  Peri-stimulus time histogram (firing rate over time).
%
%   [rate, binCenters, trialRates] = computePSTH(aligned, pre, post, binSize)
%   [...] = computePSTH(aligned, pre, post, binSize, sigma)   % smoothed
%
%   INPUTS
%       aligned  - {nTrials x 1} cell from alignSpikes (relative times, s)
%       pre,post - window (s) before/after the event
%       binSize  - bin width (s), e.g. 0.05
%       sigma    - (optional) SD (s) of a Gaussian kernel used to smooth
%                  each trial (spike density function). 0 or [] = no smoothing.
%                  Within ~3*sigma of the window edges the smoothed rate is
%                  too low (there is no data beyond the window): compute a
%                  wider window than the one you plot.
%   OUTPUTS
%       rate       - [1 x nBins] mean firing rate across trials (Hz)
%       binCenters - [1 x nBins] bin centres (s)
%       trialRates - [nTrials x nBins] firing rate of every trial (Hz)
%
%   EXAMPLE
%       [r, t] = computePSTH(aligned, 2, 3, 0.05, 0.1);  plot(t, r)
%
%   Course: MUW 860.053

if nargin < 5, sigma = 0; end
edges      = -pre:binSize:post;
binCenters = edges(1:end-1) + binSize/2;
nTr        = numel(aligned);
trialRates = zeros(nTr, numel(binCenters));
for k = 1:nTr
    trialRates(k, :) = histcounts(aligned{k}, edges) / binSize;
end
if ~isempty(sigma) && sigma > 0
    halfWidth = ceil(3*sigma/binSize);
    kx = (-halfWidth:halfWidth) * binSize;
    kernel = exp(-kx.^2 / (2*sigma^2));
    kernel = kernel / sum(kernel);
    for k = 1:nTr
        trialRates(k, :) = conv(trialRates(k, :), kernel, 'same');
    end
end
rate = mean(trialRates, 1);
end
