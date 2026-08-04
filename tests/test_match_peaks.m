classdef test_match_peaks < matlab.unittest.TestCase
    methods (Test)
        function testPerfectMatch(testCase)
            fs = 250;
            true_peaks = [100, 300, 500];
            detected = [101, 299, 502];  % all within the 50ms tolerance
            result = match_peaks(detected, true_peaks, fs);
            testCase.verifyEqual(result.true_positives, 3);
            testCase.verifyEqual(result.f1, 1.0);
        end

        function testFalsePositiveAndNegative(testCase)
            fs = 250;
            true_peaks = [100, 300, 500];
            detected = [101, 299, 900];  % misses 500, extra false detection at 900
            result = match_peaks(detected, true_peaks, fs);
            testCase.verifyEqual(result.true_positives, 2);
            testCase.verifyEqual(result.false_positives, 1);
            testCase.verifyEqual(result.false_negatives, 1);
        end

        function testDoesNotDoubleMatchOneTruePeak(testCase)
            fs = 250;
            true_peaks = 500;
            detected = [498, 502];  % both close to the same single true peak
            result = match_peaks(detected, true_peaks, fs);
            testCase.verifyEqual(result.true_positives, 1);
            testCase.verifyEqual(result.false_positives, 1);
        end

        function testEmptyDetectionsGiveZeroRecall(testCase)
            fs = 250;
            true_peaks = [100, 300];
            detected = [];
            result = match_peaks(detected, true_peaks, fs);
            testCase.verifyEqual(result.recall, 0);
            testCase.verifyEqual(result.false_negatives, 2);
        end
    end
end
