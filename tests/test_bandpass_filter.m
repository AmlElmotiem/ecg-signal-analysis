classdef test_bandpass_filter < matlab.unittest.TestCase
    methods (Test)
        function testAttenuatesOutOfBandFrequency(testCase)
            fs = 250;
            t = (0:1 / fs:2)';
            low_freq_drift = sin(2 * pi * 0.1 * t);  % baseline wander, well below the band
            in_band = sin(2 * pi * 10 * t);          % inside the 5-15 Hz QRS band

            signal = low_freq_drift + in_band;
            filtered = bandpass_filter(signal, fs, 5, 15);

            testCase.verifyLessThan(std(filtered - in_band), 0.1);
        end

        function testPreservesSignalLength(testCase)
            fs = 250;
            signal = randn(1, 500);
            filtered = bandpass_filter(signal, fs, 5, 15);
            testCase.verifyEqual(numel(filtered), numel(signal));
        end
    end
end
