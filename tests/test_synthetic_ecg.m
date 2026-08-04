classdef test_synthetic_ecg < matlab.unittest.TestCase
    methods (Test)
        function testPeakCountMatchesHeartRate(testCase)
            [~, ~, peaks] = synthetic_ecg(60, 60, 250, 0);  % 60s at 60bpm -> ~60 beats
            testCase.verifyEqual(numel(peaks), 60, 'AbsTol', 1);
        end

        function testPeaksAreActuallyLocalMaximaOfTheSignal(testCase)
            [signal, ~, peaks] = synthetic_ecg(5, 75, 250, 0);
            for k = 2:numel(peaks) - 1
                idx = peaks(k);
                testCase.verifyGreaterThanOrEqual(signal(idx), signal(idx - 1));
                testCase.verifyGreaterThanOrEqual(signal(idx), signal(idx + 1));
            end
        end
    end
end
