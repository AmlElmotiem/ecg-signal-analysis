function [peak_indices, info] = adaptive_threshold_peaks(integrated, fs)
%ADAPTIVE_THRESHOLD_PEAKS Locate QRS peaks in the Pan-Tompkins integrated
%   signal using running signal/noise level estimates and a
%   physiological refractory period, as in the original 1985 algorithm.
%
%   The threshold is not fixed: it tracks a running estimate of the
%   "signal level" (recent peak heights) and "noise level" (recent
%   sub-threshold heights), so the detector adapts to slow changes in
%   signal amplitude instead of using one number for the whole record.
    refractory_samples = round(0.200 * fs);  % 200ms: no two real heartbeats are closer than this

    init_len = min(round(2 * fs), numel(integrated));
    signal_level = max(integrated(1:init_len)) * 0.5;
    noise_level = mean(integrated(1:init_len)) * 0.5;
    threshold = noise_level + 0.25 * (signal_level - noise_level);

    peak_indices = [];
    n = numel(integrated);
    last_peak = -inf;

    for i = 2:(n - 1)
        is_local_max = integrated(i) > integrated(i - 1) && integrated(i) >= integrated(i + 1);
        if is_local_max && integrated(i) > threshold
            if (i - last_peak) > refractory_samples
                peak_indices(end + 1) = i; %#ok<AGROW>
                last_peak = i;
                signal_level = 0.125 * integrated(i) + 0.875 * signal_level;
            else
                noise_level = 0.125 * integrated(i) + 0.875 * noise_level;
            end
            threshold = noise_level + 0.25 * (signal_level - noise_level);
        end
    end

    info = struct('threshold_final', threshold, 'n_detected', numel(peak_indices));
end
