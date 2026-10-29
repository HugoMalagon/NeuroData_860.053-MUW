function [isSig, pAdjusted] = fdr_bh(p, q)
% fdr_bh  Benjamini-Hochberg false discovery rate correction.
%
%   [isSig, pAdjusted] = fdr_bh(p)        % q = 0.05
%   [isSig, pAdjusted] = fdr_bh(p, q)
%
%   INPUTS
%       p - vector of p-values (e.g. one per neuron). NaNs are ignored.
%       q - desired false discovery rate (default 0.05)
%   OUTPUTS
%       isSig     - logical, true where the test survives the correction
%       pAdjusted - BH-adjusted p-values (compare them with q)
%
%   Idea: sort the m p-values, p(1) <= ... <= p(m). Find the largest k with
%   p(k) <= k/m * q. All tests 1..k are declared significant. On average,
%   at most a fraction q of the "discoveries" are false positives.
%
%   Course: MUW 860.053

if nargin < 2, q = 0.05; end
sz = size(p);
p = p(:);
valid = ~isnan(p);
pv = p(valid);
m = numel(pv);
[ps, order] = sort(pv);
adj = ps .* m ./ (1:m)';
adj = min(1, flipud(cummin(flipud(adj))));   % enforce monotonicity
padj = nan(m, 1); padj(order) = adj;
pAdjusted = nan(size(p)); pAdjusted(valid) = padj;
isSig = pAdjusted <= q;
isSig = reshape(isSig, sz); pAdjusted = reshape(pAdjusted, sz);
end
