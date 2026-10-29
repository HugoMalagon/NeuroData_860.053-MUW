function [ccorr, lags, CCG_raw, CCG_pred, CI_low, CI_high] = plotCrossCorrelogram(STMtx, Neuron_A, Neuron_B, binSize, maxLag, Plot, Significance)
% plotCrossCorrelogram  Cross-correlogram between two neurons with hollow
%                       Gaussian predictor and Poisson significance bounds.
%
%   [ccorr, lags, CCG_raw, CCG_pred, CI_low, CI_high] = ...
%       plotCrossCorrelogram(STMtx, Neuron_A, Neuron_B, binSize, maxLag, Plot)
%
%   INPUTS:
%       STMtx      - Spike time matrix (NaN-padded, columns = neurons, seconds).
%       Neuron_A   - Column index of the reference neuron.
%       Neuron_B   - Column index of the target neuron.
%       binSize    - Bin size in seconds (e.g., 0.001 for 1 ms).
%       maxLag     - Half-window in seconds (e.g., 0.05 for ±50 ms).
%       Plot         - (optional, default 1) 1 = plot, 0 = compute only.
%       Significance - (optional, default 1) 1 = compute hollow Gaussian
%                      predictor and Poisson CI, 0 = skip (CCG_pred,
%                      CI_low, CI_high returned as empty).
%                      Method: Stark & Abeles (2009) J Neurosci Methods.
%
%   OUTPUTS:
%       ccorr      - Normalised CCG ('coeff'), 1 x (2*nLagBins+1).
%       lags       - Lag vector in seconds.
%       CCG_raw    - Raw spike-count CCG (used for Poisson model).
%       CCG_pred   - Hollow Gaussian predictor (expected counts under null).
%       CI_low     - 1st percentile Poisson CI per bin.
%       CI_high    - 99th percentile Poisson CI per bin.
%
%   Positive lags: Neuron B fires AFTER Neuron A.
%   Negative lags: Neuron B fires BEFORE Neuron A.
%
%   SIGNIFICANCE:
%       Excitation: bins where CCG_raw > CI_high  (marked in red)
%       Inhibition: bins where CCG_raw < CI_low   (marked in blue)
%       Only bins within the ±maxLag window are marked.
%       Each bin is tested on its own (1 % per side), so in a ±30 ms window
%       about one bin per pair crosses a band by chance.
%
%   EXAMPLE:
%       plotCrossCorrelogram(STMtx, 3, 7, 0.001, 0.05)
%       [cc, lags] = plotCrossCorrelogram(STMtx, 3, 7, 0.001, 0.05, 0)

if nargin < 6; Plot         = 1; end
if nargin < 7; Significance = 1; end

% --- Extract spike times ---
spikeTimes_A = STMtx(~isnan(STMtx(:, Neuron_A)), Neuron_A);
spikeTimes_A = sort(spikeTimes_A(:));

spikeTimes_B = STMtx(~isnan(STMtx(:, Neuron_B)), Neuron_B);
spikeTimes_B = sort(spikeTimes_B(:));

% --- Build common time axis ---
tEnd   = max(spikeTimes_A(end), spikeTimes_B(end)) + maxLag;
tEdges = 0:binSize:tEnd;

% --- Build spike trains ---
trainA = histcounts(spikeTimes_A, tEdges);
trainB = histcounts(spikeTimes_B, tEdges);

% --- Step 4: Compute CCG ---
nLagBins = round(maxLag / binSize);

% Raw counts (needed for Poisson model — do NOT normalise)
CCG_raw = xcorr(trainB, trainA, nLagBins);

% Normalised version for output / display
ccorr = xcorr(trainB, trainA, nLagBins, 'coeff');

% --- Lag axis ---
lags = (-nLagBins:nLagBins) * binSize;

% --- Steps 5–7: Hollow Gaussian predictor + Poisson CI (optional) ---
CCG_pred = [];
CI_low   = [];
CI_high  = [];
excitation_bins = false(size(CCG_raw));
inhibition_bins = false(size(CCG_raw));

if Significance == 1
    sigma_ms   = 10;                               % sigma in ms
    sigma_bins = sigma_ms / (binSize * 1000);      % sigma in bins
    hw         = ceil(6 * sigma_bins);             % kernel half-width (~6 sigma)
    k_lags     = -hw:hw;
    kernel     = exp(-0.5 * (k_lags / sigma_bins).^2);

    % Partially hollow center: scale the zero-lag bin by 0.4 (Stark & Abeles 2009)
    % Rather than zeroing ±N bins, only the center bin is attenuated by (1 - 0.6)
    center_idx = hw + 1;
    kernel(center_idx) = kernel(center_idx) * 0.4;
    kernel = kernel / sum(kernel);                 % normalise to sum = 1

    % Convolve raw CCG with partially hollowed Gaussian kernel. The ends of
    % the CCG are mirrored first, so that the smoothing does not run into
    % zeros at ±maxLag (that would lower the predictor near the edges and
    % create false "excitation" there). Dividing by the smoothed ones keeps
    % it correct even when the window is shorter than the kernel.
    nPad     = min(hw, numel(CCG_raw) - 1);
    padded   = [fliplr(CCG_raw(2:nPad+1)), CCG_raw, fliplr(CCG_raw(end-nPad:end-1))];
    smoothed = conv(padded, kernel, 'same') ./ conv(ones(size(padded)), kernel, 'same');
    CCG_pred = smoothed(nPad + (1:numel(CCG_raw)));

    % CI bounds (for plotting — deterministic, based on poissinv)
    CI_low  = poissinv(0.01, CCG_pred);
    CI_high = poissinv(0.99, CCG_pred);

    excitation_bins = CCG_raw > CI_high;
    inhibition_bins = CCG_raw < CI_low;
end

% --- Step 8: Plot ---
if Plot == 1
    figure; hold on

    % Raw CCG bar chart
    bar(lags * 1000, CCG_raw, 'BarWidth', 1, 'FaceColor', [0.2 0.5 0.8], 'EdgeColor', 'none')

    % Predictor and CI (only if significance was computed)
    if Significance == 1
        plot(lags * 1000, CCG_pred,  '-k',  'LineWidth', 1.5)
        plot(lags * 1000, CI_high,   '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1)
        plot(lags * 1000, CI_low,    '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1)

        if any(excitation_bins)
            plot(lags(excitation_bins) * 1000, CCG_raw(excitation_bins), ...
                'o', 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r', 'MarkerSize', 6)
        end
        if any(inhibition_bins)
            plot(lags(inhibition_bins) * 1000, CCG_raw(inhibition_bins), ...
                'o', 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'b', 'MarkerSize', 6)
        end
    end

    % Zero-lag line
    xline(0, '--r', 'LineWidth', 1.2)

    xlabel('Lag (ms)')
    ylabel('Spike counts')
    title(sprintf('CCG — Neuron %d (ref) vs Neuron %d', Neuron_A, Neuron_B))
    set(gca, 'Box', 'off', 'FontSize', 12)
end

end
