function cmap = redblue_cmap()
% redblue_cmap  Blue - white - red colormap for z-scores (256 colours).
%
%   colormap(gca, redblue_cmap())
%
%   Negative values blue, 0 white, positive values red.
%
%   Course: MUW 860.053
n = 128;
up = linspace(0, 1, n)';
cmap = [[up; ones(n, 1)], [up; flipud(up)], [ones(n, 1); flipud(up)]];
end
