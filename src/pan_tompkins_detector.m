function [peak_indices, info] = pan_tompkins_detector(signal, fs)
%PAN_TOMPKINS_DETECTOR QRS complex (R-peak) detection via the
%   Pan-Tompkins algorithm, implemented from its five classic stages
%   rather than called from a toolbox.
%
%   [peak_indices, info] = PAN_TOMPKINS_DETECTOR(signal, fs) detects
%   R-peaks in an ECG SIGNAL sampled at FS Hz:
%     1. Bandpass filter   -- isolate QRS energy (5-15 Hz)
%     2. Derivative        -- emphasize the steep QRS slope
%     3. Squaring           -- make everything positive, amplify large slopes
%     4. Moving-window integration -- smear each QRS into one wide pulse
%     5. Adaptive thresholding + refractory period -- find the pulses
%
%   Reference: Pan J, Tompkins WJ. "A Real-Time QRS Detection
%   Algorithm." IEEE Trans Biomed Eng. 1985.
    signal = signal(:)';  % row vector

    % 1. Bandpass filter
    filtered = bandpass_filter(signal, fs, 5, 15);

    % 2. Derivative filter: y(n) = (1/8T)[-x(n-2) -2x(n-1) +2x(n+1) +x(n+2)]
    deriv_kernel = [-1, -2, 0, 2, 1] * (fs / 8);
    deriv = conv(filtered, deriv_kernel, 'same');

    % 3. Squaring
    squared = deriv .^ 2;

    % 4. Moving-window integration (~150ms, roughly one QRS width)
    window_samples = max(1, round(0.150 * fs));
    integrated = movmean(squared, [window_samples - 1, 0]);

    % 5. Adaptive threshold + refractory period
    [candidate_indices, threshold_info] = adaptive_threshold_peaks(integrated, fs);

    % The integration stage delays/smears the pulse; snap each candidate
    % back to the true local maximum in the filtered signal.
    search_radius = max(1, round(0.075 * fs));
    peak_indices = refine_peaks(candidate_indices, filtered, search_radius);

    info = threshold_info;
    info.n_after_refine = numel(peak_indices);
end
