function filtered = bandpass_filter(signal, fs, low_hz, high_hz)
%BANDPASS_FILTER Zero-phase bandpass filter, built from scratch as a
%   single 2nd-order IIR biquad (no Signal Processing Toolbox required
%   -- BUTTER/FILTFILT are not available without it).
%
%   Uses the standard "constant 0dB peak gain" bandpass biquad design
%   (the widely-used Audio EQ Cookbook formulas), centered at the
%   geometric mean of low_hz/high_hz with Q chosen from the requested
%   bandwidth, so the passband has unity gain at its center rather than
%   scaling with Q. Applied forward, then backward on the
%   time-reversed result and reversed again -- the same zero-phase
%   trick FILTFILT uses internally, implemented with only the base
%   FILTER function.
    f0 = sqrt(low_hz * high_hz);
    bandwidth_hz = high_hz - low_hz;
    q_factor = f0 / bandwidth_hz;

    w0 = 2 * pi * f0 / fs;
    alpha = sin(w0) / (2 * q_factor);
    cos_w0 = cos(w0);

    b0 = alpha;
    b1 = 0;
    b2 = -alpha;
    a0 = 1 + alpha;
    a1 = -2 * cos_w0;
    a2 = 1 - alpha;

    b = [b0, b1, b2] / a0;
    a = [1, a1 / a0, a2 / a0];

    is_column = iscolumn(signal);
    row_signal = signal(:)';
    forward = filter(b, a, row_signal);
    backward = filter(b, a, fliplr(forward));
    filtered = fliplr(backward);

    if is_column
        filtered = filtered(:);  % match the caller's input orientation
    end
end
