classdef test_extract_beat_features < matlab.unittest.TestCase
    methods (Test)
        function testRRIntervalsMatchKnownSpacing(testCase)
            fs = 250;
            peak_indices = [100, 350, 600];  % 250-sample spacing -> 1.0s RR
            signal = zeros(1, 700);
            signal(peak_indices) = 1;

            features = extract_beat_features(signal, fs, peak_indices);

            testCase.verifyEqual(features(2, 1), 1.0, 'AbsTol', 1e-9);  % RR to previous
            testCase.verifyEqual(features(2, 2), 1.0, 'AbsTol', 1e-9);  % RR to next
        end

        function testPeakAmplitudeMatchesSignalValue(testCase)
            fs = 250;
            signal = zeros(1, 500);
            signal(200) = 2.5;
            signal(300) = -1.5;

            features = extract_beat_features(signal, fs, [200, 300]);

            testCase.verifyEqual(features(1, 3), 2.5, 'AbsTol', 1e-9);
            testCase.verifyEqual(features(2, 3), -1.5, 'AbsTol', 1e-9);
        end

        function testWiderPulseGivesLargerQrsWidth(testCase)
            fs = 250;
            t = (0:499) / fs;
            narrow = exp(-((t - 0.4) .^ 2) / (2 * 0.005 ^ 2));
            wide = exp(-((t - 0.4) .^ 2) / (2 * 0.03 ^ 2));

            f_narrow = extract_beat_features(narrow, fs, round(0.4 * fs));
            f_wide = extract_beat_features(wide, fs, round(0.4 * fs));

            testCase.verifyGreaterThan(f_wide(1, 4), f_narrow(1, 4));
        end
    end
end
