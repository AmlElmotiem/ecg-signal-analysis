function filtered = bandpass_filter(signal, fs, low_hz, high_hz)
%BANDPASS_FILTER Zero-phase Butterworth bandpass filter.
%   filtered = BANDPASS_FILTER(signal, fs, low_hz, high_hz) filters SIGNAL
%   (sampled at FS Hz) to the [low_hz, high_hz] band using a 2nd-order
%   Butterworth filter applied forward and backward via FILTFILT, so the
%   result has zero phase shift -- important here because QRS timing
%   accuracy is the whole point of the pipeline.
    nyquist = fs / 2;
    [b, a] = butter(2, [low_hz, high_hz] / nyquist, 'bandpass');
    filtered = filtfilt(b, a, signal);
end
