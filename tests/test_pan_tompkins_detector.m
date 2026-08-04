classdef test_pan_tompkins_detector < matlab.unittest.TestCase
    methods (Test)
        function testDetectsAllBeatsOnCleanSyntheticSignal(testCase)
            fs = 250;
            [signal, ~, true_peaks] = synthetic_ecg(10, 75, fs, 0);
            detected = pan_tompkins_detector(signal, fs);
            result = match_peaks(detected, true_peaks, fs);
            testCase.verifyGreaterThanOrEqual(result.f1, 0.95);
        end

        function testRobustToModerateNoise(testCase)
            fs = 250;
            rng(42);
            [signal, ~, true_peaks] = synthetic_ecg(10, 75, fs, 0.15);
            detected = pan_tompkins_detector(signal, fs);
            result = match_peaks(detected, true_peaks, fs);
            testCase.verifyGreaterThanOrEqual(result.f1, 0.85);
        end

        function testRespectsRefractoryPeriod(testCase)
            fs = 250;
            [signal, ~, ~] = synthetic_ecg(5, 200, fs, 0);  % 200bpm: fast but physiologically valid
            detected = pan_tompkins_detector(signal, fs);
            rr_s = diff(sort(detected)) / fs;
            testCase.verifyGreaterThan(min(rr_s), 0.15);  % never closer than 150ms apart
        end

        function testDetectsCorrectBeatCountAtKnownHeartRate(testCase)
            fs = 250;
            [signal, ~, true_peaks] = synthetic_ecg(20, 60, fs, 0);  % exactly 60bpm -> ~20 beats
            detected = pan_tompkins_detector(signal, fs);
            testCase.verifyEqual(numel(detected), numel(true_peaks), 'AbsTol', 1);
        end
    end
end
