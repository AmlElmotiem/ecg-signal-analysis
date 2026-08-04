function [signal, fs, true_peak_indices] = synthetic_ecg(duration_s, hr_bpm, fs, noise_amplitude)
%SYNTHETIC_ECG Generate a synthetic ECG-like signal with known R-peak
%   locations, for deterministic unit testing without needing to
%   download real data.
%
%   [signal, fs, true_peak_indices] = SYNTHETIC_ECG(duration_s, hr_bpm, fs, noise_amplitude)
%   places a sharp Gaussian QRS-like pulse at every beat interval implied
%   by HR_BPM, adds a smaller T-wave-like bump after each, and optional
%   Gaussian noise. Not a physiological model -- just realistic enough
%   (sharp narrow QRS + smaller broad T-wave) to exercise the detector.
    if nargin < 3 || isempty(fs), fs = 250; end
    if nargin < 4, noise_amplitude = 0; end

    n = round(duration_s * fs);
    t = (0:n - 1) / fs;
    signal = zeros(1, n);

    beat_interval_s = 60 / hr_bpm;
    beat_times = 0.3:beat_interval_s:duration_s;
    true_peak_indices = round(beat_times * fs) + 1;
    true_peak_indices = true_peak_indices(true_peak_indices <= n);

    qrs_width_s = 0.02;
    t_wave_width_s = 0.05;
    for k = 1:numel(true_peak_indices)
        center = t(true_peak_indices(k));
        signal = signal + 1.5 * exp(-((t - center) .^ 2) / (2 * qrs_width_s ^ 2));
        signal = signal + 0.3 * exp(-((t - (center + 0.16)) .^ 2) / (2 * t_wave_width_s ^ 2));
    end

    if noise_amplitude > 0
        signal = signal + noise_amplitude * randn(1, n);
    end
end
