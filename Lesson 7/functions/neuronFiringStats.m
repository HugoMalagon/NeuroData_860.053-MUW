function stats = neuronFiringStats(spikeTimes, sessionDuration)
% neuronFiringStats  Firing statistics of every neuron in a session.
%
%   stats = neuronFiringStats(spikeTimes, sessionDuration)
%
%   INPUTS
%       spikeTimes      - {1 x nNeurons} cell of spike times (s)
%       sessionDuration - recording duration (s) used for the mean rate
%   OUTPUT
%       stats - table, one row per neuron, with:
%         NeuronID       column index in STMtx
%         nSpikes        number of spikes
%         FiringRate_Hz  nSpikes / sessionDuration
%         CV             SD(ISI) / mean(ISI)         (1 = Poisson-like)
%         CV2            local CV: mean 2|a-b|/(a+b) of consecutive ISIs
%         LvR            revised local variation (Shinomoto et al. 2009),
%                        R = 5 ms. <0.5 regular, ~1 Poisson, >1 bursty
%         BurstIndex     fraction of ISIs < 10 ms
%         RefViol_pct    % of ISIs < 2 ms (refractory period violations;
%                        high values suggest contamination / multi-unit)
%         Classification 'Bursty' | 'Regular' | 'Irregular' (as in
%                        Compute_Neuron_Stats.m of the Flexi-Gambling repo)
%
%   Neurons with fewer than 50 spikes get NaN statistics and class 'TooFew'.
%
%   Course: MUW 860.053 (based on Compute_Neuron_Stats.m, H. Malagon)

R = 0.005; MIN_SPIKES = 50;
nN = numel(spikeTimes);
[nSpikes, FiringRate_Hz, CV, CV2, LvR, BurstIndex, RefViol_pct] = deal(nan(nN,1));
Classification = repmat({'TooFew'}, nN, 1);

for n = 1:nN
    s = sort(spikeTimes{n}(:));
    nSpikes(n) = numel(s);
    FiringRate_Hz(n) = numel(s) / sessionDuration;
    if numel(s) < MIN_SPIKES, continue; end
    isi = diff(s);
    a = isi(1:end-1); b = isi(2:end); ab = a + b;
    ok = ab > 0;
    CV(n)   = std(isi) / mean(isi);
    CV2(n)  = mean(2*abs(a(ok) - b(ok)) ./ ab(ok));
    LvR(n)  = 3/(numel(isi)-1) * sum((1 - 4*a(ok).*b(ok)./ab(ok).^2) .* (1 + 4*R./ab(ok)));
    BurstIndex(n)  = mean(isi < 0.010);
    RefViol_pct(n) = 100 * mean(isi < 0.002);
    if LvR(n) > 1 && BurstIndex(n) > 0.1
        Classification{n} = 'Bursty';
    elseif LvR(n) < 0.5
        Classification{n} = 'Regular';
    else
        Classification{n} = 'Irregular';
    end
end
NeuronID = (1:nN)';
stats = table(NeuronID, nSpikes, FiringRate_Hz, CV, CV2, LvR, BurstIndex, ...
    RefViol_pct, Classification);
end
