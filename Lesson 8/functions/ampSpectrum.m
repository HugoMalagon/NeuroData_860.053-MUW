function [amp, f] = ampSpectrum(x, fs)
% ampSpectrum  One-sided amplitude spectrum of a signal (with fft).
%
%   [amp, f] = ampSpectrum(x, fs)
%
%   INPUT
%       x   - signal (vector), sampled at fs
%       fs  - sampling rate (Hz)
%   OUTPUT
%       amp - amplitude of every frequency from 0 Hz to fs/2 (Nyquist).
%             A sine of amplitude A gives a peak of height A if its
%             frequency falls exactly on a frequency bin (a multiple of
%             1/T); otherwise the peak is lower and spreads to the
%             neighbouring bins (leakage, see L8-E.4).
%       f   - frequency axis (Hz). Its resolution is fs/N = 1/T, with
%             N samples and T the length of the signal in s.
%
%   EXAMPLE
%       [amp, f] = ampSpectrum(xSim, fsSim);
%       plot(f, amp); xlabel('Frequency (Hz)'); ylabel('Amplitude')
%
%   Course: Processing and Interpretation of Neuroscience Data (MUW)

x   = x(:)';                       % row vector
N   = numel(x);
X   = fft(x);                      % complex: abs = amplitude, angle = phase
amp = abs(X)/N;                    % two-sided amplitude
amp = amp(1:floor(N/2)+1);         % keep 0 ... Nyquist
amp(2:end-1) = 2*amp(2:end-1);     % one-sided: double the non-DC bins
f   = (0:floor(N/2)) * fs/N;       % frequency axis
end
