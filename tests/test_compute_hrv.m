classdef test_compute_hrv < matlab.unittest.TestCase
    methods (Test)
        function testConstantRRGivesZeroVariability(testCase)
            fs = 250;
            rr_samples = round(0.8 * fs);  % exactly 75 bpm, perfectly regular
            peaks = 1:rr_samples:(rr_samples * 10);
            hrv = compute_hrv(peaks, fs);
            testCase.verifyEqual(hrv.sdnn_ms, 0, 'AbsTol', 1e-9);
            testCase.verifyEqual(hrv.rmssd_ms, 0, 'AbsTol', 1e-9);
            testCase.verifyEqual(hrv.mean_hr_bpm, 75, 'AbsTol', 0.5);
        end

        function testKnownVariableRR(testCase)
            fs = 1000;
            peaks = [0, 800, 1650, 2400, 3300] + 1;  % RR: 800, 850, 750, 900 ms
            hrv = compute_hrv(peaks, fs);
            expected_rr = [800, 850, 750, 900];
            testCase.verifyEqual(hrv.rr_intervals_ms, expected_rr, 'AbsTol', 1);
        end

        function testHandlesUnsortedPeakIndices(testCase)
            fs = 1000;
            sorted_peaks = [0, 800, 1650, 2400, 3300] + 1;
            shuffled = sorted_peaks([3, 1, 5, 2, 4]);
            hrv_sorted = compute_hrv(sorted_peaks, fs);
            hrv_shuffled = compute_hrv(shuffled, fs);
            testCase.verifyEqual(hrv_shuffled.rr_intervals_ms, hrv_sorted.rr_intervals_ms, 'AbsTol', 1);
        end
    end
end
