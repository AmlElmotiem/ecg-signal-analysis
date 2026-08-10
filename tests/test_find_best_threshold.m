classdef test_find_best_threshold < matlab.unittest.TestCase
    methods (Test)
        function testFindsThresholdThatPerfectlySeparatesClasses(testCase)
            scores = [-2 -1.5 -1 -0.5 0.5 1 1.5 2]';
            y = [1 1 1 1 2 2 2 2]';
            th = find_best_threshold(scores, y, 2, 1);

            pred = repmat(1, size(scores));
            pred(scores > th) = 2;
            testCase.verifyEqual(pred, y);
        end

        function testHandlesImbalancedData(testCase)
            % Mostly class 1, with the few class-2 points near the top.
            % Check behavior (does it perfectly separate the classes?)
            % rather than an exact threshold value, since any threshold
            % in (2, 8) is an equally valid perfect separator.
            scores = [-3 -2 -1 0 1 2 8 9]';
            y = [1 1 1 1 1 1 2 2]';
            th = find_best_threshold(scores, y, 2, 1);

            pred = repmat(1, size(scores));
            pred(scores > th) = 2;
            testCase.verifyEqual(pred, y);
        end
    end
end
