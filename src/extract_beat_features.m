function features = extract_beat_features(signal, fs, peak_indices)
%EXTRACT_BEAT_FEATURES Simple morphological + timing features per beat,
%   for classifying beat type (e.g. normal vs. PVC). Columns:
%     1. RR interval to the previous beat (s) -- PVCs are classically
%        premature, i.e. preceded by an unusually short RR interval
%     2. RR interval to the next beat (s) -- classically followed by a
%        compensatory pause, i.e. an unusually long one
%     3. Peak amplitude at the beat
%     4. QRS width (s) -- the span around the peak where the signal
%        stays above half the peak's amplitude. PVCs classically have
%        a wider QRS than normal beats (the depolarization doesn't
%        travel through the normal fast conduction pathway).
    peak_indices = peak_indices(:)';
    n_beats = numel(peak_indices);
    features = zeros(n_beats, 4);

    if n_beats > 1
        rr = diff(peak_indices) / fs;
        median_rr = median(rr);
    else
        median_rr = NaN;
    end

    for k = 1:n_beats
        if k == 1
            features(k, 1) = median_rr;
        else
            features(k, 1) = (peak_indices(k) - peak_indices(k - 1)) / fs;
        end
        if k == n_beats
            features(k, 2) = median_rr;
        else
            features(k, 2) = (peak_indices(k + 1) - peak_indices(k)) / fs;
        end

        idx = peak_indices(k);
        features(k, 3) = signal(idx);
        features(k, 4) = qrs_width_at_beat(signal, fs, idx);
    end
end

function width_s = qrs_width_at_beat(signal, fs, idx)
    half_amp = signal(idx) / 2;
    n = numel(signal);
    search_radius = round(0.1 * fs);  % 100ms: generously wider than a real QRS
    ref_sign = sign(signal(idx) - half_amp);
    if ref_sign == 0
        ref_sign = 1;
    end

    lo = idx;
    while lo > max(1, idx - search_radius) && sign(signal(lo) - half_amp) == ref_sign
        lo = lo - 1;
    end
    hi = idx;
    while hi < min(n, idx + search_radius) && sign(signal(hi) - half_amp) == ref_sign
        hi = hi + 1;
    end
    width_s = (hi - lo) / fs;
end
