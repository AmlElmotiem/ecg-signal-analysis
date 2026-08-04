function hrv = compute_hrv(peak_indices, fs)
%COMPUTE_HRV Heart rate variability metrics from detected R-peak indices.
%
%   hrv = COMPUTE_HRV(peak_indices, fs) returns a struct with:
%     rr_intervals_ms - successive RR intervals, in milliseconds
%     mean_hr_bpm     - mean heart rate, beats per minute
%     sdnn_ms         - standard deviation of RR intervals (overall variability)
%     rmssd_ms        - root mean square of successive RR differences
%                       (short-term, parasympathetically-driven variability)
    peak_indices = sort(peak_indices(:)');
    rr_samples = diff(peak_indices);
    rr_ms = (rr_samples / fs) * 1000;

    hrv.rr_intervals_ms = rr_ms;
    hrv.mean_hr_bpm = 60000 / mean(rr_ms);
    hrv.sdnn_ms = std(rr_ms);
    if numel(rr_ms) >= 2
        hrv.rmssd_ms = sqrt(mean(diff(rr_ms) .^ 2));
    else
        hrv.rmssd_ms = NaN;
    end
end
