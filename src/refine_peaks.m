function refined = refine_peaks(peak_indices, signal, search_radius)
%REFINE_PEAKS Snap each candidate index to the true local maximum of
%   SIGNAL within +/- SEARCH_RADIUS samples.
%
%   The moving-window integration stage in the Pan-Tompkins pipeline
%   smears and delays the QRS pulse, so a peak detected in the
%   integrated signal does not sit exactly on the true R-peak in the
%   original (filtered) signal. This corrects for that by searching a
%   small window around each candidate for the actual local maximum.
    n = numel(signal);
    refined = zeros(size(peak_indices));
    for k = 1:numel(peak_indices)
        idx = peak_indices(k);
        lo = max(1, idx - search_radius);
        hi = min(n, idx + search_radius);
        [~, local_max] = max(signal(lo:hi));
        refined(k) = lo + local_max - 1;
    end
    refined = unique(refined);
end
