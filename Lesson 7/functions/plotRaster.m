function plotRaster(aligned, groups, colors)
% plotRaster  Raster plot of event-aligned spikes (one row per trial).
%
%   plotRaster(aligned)
%   plotRaster(aligned, groups)          % trials sorted and coloured by group
%   plotRaster(aligned, groups, colors)  % colors: [nGroups x 3] RGB
%
%   INPUTS
%       aligned - {nTrials x 1} cell from alignSpikes (relative times, s)
%       groups  - (optional) [nTrials x 1] numeric labels (e.g. rewarded 0/1).
%                 Trials are drawn grouped, in the order of unique(groups).
%       colors  - (optional) one RGB row per group
%
%   Draws in the current axes. A vertical line marks time 0 (the event).
%
%   Course: MUW 860.053 (inspired by Raster_PSTH_SDF.m, F. Schneider)

nTr = numel(aligned);
if nargin < 2 || isempty(groups), groups = ones(nTr, 1); end
groups = groups(:);
g = unique(groups(~isnan(groups)));
if nargin < 3 || isempty(colors), colors = lines(max(numel(g), 1)); end
if numel(g) == 1, colors = [0 0.45 0.74]; end   % visible in light and dark themes

hold on
row = 0;
for gi = 1:numel(g)
    idx = find(groups == g(gi));
    for k = idx'
        row = row + 1;
        t = aligned{k}(:)';
        if isempty(t), continue; end
        x = [t; t; nan(size(t))];
        y = [row-0.4 + zeros(size(t)); row+0.4 + zeros(size(t)); nan(size(t))];
        plot(x(:), y(:), 'Color', colors(gi, :), 'LineWidth', 1)
    end
end
xline(0, 'r--', 'LineWidth', 1, 'HandleVisibility', 'off')
ylim([0 row+1])
xlabel('Time from event (s)')
ylabel('Trial')
set(gca, 'Box', 'off', 'YDir', 'reverse')
end
