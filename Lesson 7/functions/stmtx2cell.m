function spikeTimes = stmtx2cell(STMtx)
% stmtx2cell  Convert a NaN-padded spike time matrix into a cell array.
%
%   spikeTimes = stmtx2cell(STMtx)
%
%   INPUT
%       STMtx      - [nSpikesMax x nNeurons] matrix. Each column holds the
%                    spike times (s) of one neuron, padded with NaN.
%   OUTPUT
%       spikeTimes - {1 x nNeurons} cell. spikeTimes{n} is a sorted column
%                    vector with the spike times (s) of neuron n.
%
%   EXAMPLE
%       spikeTimes = stmtx2cell(STMtx);
%       numel(spikeTimes{5})      % number of spikes of neuron 5
%
%   Course: Processing and Interpretation of Neuroscience Data (MUW)

nNeurons   = size(STMtx, 2);
spikeTimes = cell(1, nNeurons);
for n = 1:nNeurons
    s = STMtx(:, n);
    spikeTimes{n} = sort(s(~isnan(s)));
end
end
