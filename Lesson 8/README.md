# Lesson 8 - Signals: Sampling, Spectra, Filters, LFP and Spikes

From the same electrode we can extract slow field potentials (LFP, oscillations) and fast action potentials (spikes). This lesson covers the tools that produce spike times and those needed to analyse the slow part of the signal.

Topics: sampling and aliasing, thresholds, digital filters and their pitfalls, the frequency domain, power spectra and spectrograms, the Hilbert transform, a mini spike sorter.

Requires the **Signal Processing Toolbox**.

## How to start

1. Download the whole repository (see the main README).
2. In MATLAB, set this folder (`Lesson 8`) as the **Current Folder**.
3. Open `Lesson8_Students.mlx` and run section 0 (Setup).

## Contents

- `Lesson8_Students.mlx` - the lesson notebook (Live Script)
- `data/` - an intracellular recording, a synthetic LFP and a synthetic extracellular recording
- `functions/` - helper functions, including the scripts that generated the synthetic data
