function plotAutocorrelogram(STMtx, Neuron_ID, binSize, maxLag)
% plotAutocorrelogram  Plot the autocorrelogram of a single neuron.
%
%   plotAutocorrelogram(STMtx, Neuron_ID, binSize, maxLag)
%
%   INPUTS:
%       STMtx      - Matrix where each column contains spike times (in seconds)
%                    for one neuron, padded with NaNs.
%       Neuron_ID  - Index (column number) of the neuron to analyze.
%       binSize    - Bin size in seconds (e.g., 0.001 for 1 ms).
%       maxLag     - Maximum lag in seconds for the autocorrelogram (half window).
%
%   The function builds a binary spike train, computes the autocorrelation
%   using convolution (xcorr), removes the zero-lag bin, and plots the
%   normalized autocorrelogram.
%
%   EXAMPLE:
%       plotAutocorrelogram(STMtx, 2, 0.001, 0.05)
%
%   This plots the autocorrelogram of neuron 2 with 1 ms bins and ±50 ms lag.
%
%   --------------------------------------------------------------------
%   Author: Hugo Malagon - (Commented and organised by ChatGPT)
%   Course: Introduction to Data Analysis in Neuroscience
%   --------------------------------------------------------------------

    % --- Extract spike times for selected neuron ---
    spikeTimes = STMtx(~isnan(STMtx(:, Neuron_ID)), Neuron_ID);
    spikeTimes = sort(spikeTimes(:));

    % --- Build binary spike train ---
    tEdges = 0:binSize:(spikeTimes(end) + maxLag);
    spikeTrain = histcounts(spikeTimes, tEdges);

    % --- Compute autocorrelation ---
    acorr = xcorr(spikeTrain, round(maxLag/binSize), 'coeff');

    % --- Create lag axis ---
    lags = (-round(maxLag/binSize):round(maxLag/binSize)) * binSize;

    % --- Remove zero-lag bin ---
    zeroIdx = find(lags == 0);
    acorr(zeroIdx) = 0;


    %bar(lags * 1000, acorr, 'BarWidth', 1, 'FaceColor', [0.2 0.2 0.2]);
    bar(lags*1000, acorr, 'BarWidth', 1)
    xlabel('Lag (ms)');
    ylabel('Normalized count');
    title(sprintf('Autocorrelogram - Neuron %d', Neuron_ID));
    set(gca, 'Box', 'off', 'FontSize', 12);

end