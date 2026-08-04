function [peak_indices, info] = adaptive_threshold_peaks(integrated, fs)
%ADAPTIVE_THRESHOLD_PEAKS Locate QRS peaks in the Pan-Tompkins integrated
%   signal using running signal/noise level estimates, a physiological
%   refractory period, and a search-back step for long gaps.
%
%   The threshold tracks running estimates of the "signal level"
%   (recent confirmed-peak heights) and "noise level" (recent
%   sub-threshold heights). If no beat is confirmed for more than
%   1.66x the recent average RR interval, the algorithm searches back
%   through that gap at half the threshold to recover a beat the
%   adaptive threshold had set too high to catch on the first pass --
%   the same search-back step described in the original 1985 paper.
%   Without it, a single strong beat can raise the threshold just
%   enough to make the detector silently skip the next, slightly
%   weaker one -- on real ECG this shows up as roughly every other
%   beat being missed.
    refractory_samples = round(0.200 * fs);

    init_len = min(round(2 * fs), numel(integrated));
    signal_level = max(integrated(1:init_len)) * 0.5;
    noise_level = mean(integrated(1:init_len)) * 0.5;
    threshold = noise_level + 0.25 * (signal_level - noise_level);

    n = numel(integrated);

    candidate_idx = [];
    candidate_val = [];
    for i = 2:(n - 1)
        if integrated(i) > integrated(i - 1) && integrated(i) >= integrated(i + 1)
            candidate_idx(end + 1) = i; %#ok<AGROW>
            candidate_val(end + 1) = integrated(i); %#ok<AGROW>
        end
    end

    peak_indices = [];
    rr_history = [];
    last_peak = -inf;

    for c = 1:numel(candidate_idx)
        idx = candidate_idx(c);
        val = candidate_val(c);

        if ~isempty(rr_history) && (idx - last_peak) > 1.66 * mean(rr_history) ...
                && (idx - last_peak) > refractory_samples
            [recovered_idx, recovered_val] = search_back( ...
                candidate_idx, candidate_val, last_peak + refractory_samples, idx, 0.5 * threshold);
            if recovered_idx > 0
                peak_indices(end + 1) = recovered_idx; %#ok<AGROW>
                rr_history = update_rr_history(rr_history, recovered_idx - last_peak);
                last_peak = recovered_idx;
                signal_level = 0.125 * recovered_val + 0.875 * signal_level;
                threshold = noise_level + 0.25 * (signal_level - noise_level);
            end
        end

        if (idx - last_peak) <= refractory_samples
            noise_level = 0.125 * val + 0.875 * noise_level;
            threshold = noise_level + 0.25 * (signal_level - noise_level);
            continue
        end

        if val > threshold
            peak_indices(end + 1) = idx; %#ok<AGROW>
            if last_peak > -inf
                rr_history = update_rr_history(rr_history, idx - last_peak);
            end
            last_peak = idx;
            signal_level = 0.125 * val + 0.875 * signal_level;
        else
            noise_level = 0.125 * val + 0.875 * noise_level;
        end
        threshold = noise_level + 0.25 * (signal_level - noise_level);
    end

    info = struct('threshold_final', threshold, 'n_detected', numel(peak_indices));
end

function [best_idx, best_val] = search_back(candidate_idx, candidate_val, range_start, range_end, half_threshold)
%SEARCH_BACK Find the tallest candidate strictly between RANGE_START and
%   RANGE_END that clears HALF_THRESHOLD, or BEST_IDX=-1 if none does.
    best_idx = -1;
    best_val = -inf;
    in_range = candidate_idx > range_start & candidate_idx < range_end;
    idxs = candidate_idx(in_range);
    vals = candidate_val(in_range);
    above = vals > half_threshold;
    if any(above)
        idxs_above = idxs(above);
        vals_above = vals(above);
        [best_val, local_pos] = max(vals_above);
        best_idx = idxs_above(local_pos);
    end
end

function rr_history = update_rr_history(rr_history, new_rr)
%UPDATE_RR_HISTORY Append NEW_RR, keeping only the most recent 8
%   intervals (matches the running-average window in the original
%   Pan-Tompkins paper).
    rr_history(end + 1) = new_rr;
    if numel(rr_history) > 8
        rr_history(1) = [];
    end
end
