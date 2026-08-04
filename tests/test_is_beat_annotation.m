classdef test_is_beat_annotation < matlab.unittest.TestCase
    methods (Test)
        function testNormalBeatIsABeat(testCase)
            testCase.verifyTrue(is_beat_annotation('N'));
        end

        function testPvcIsABeat(testCase)
            testCase.verifyTrue(is_beat_annotation('V'));
        end

        function testRhythmChangeMarkerIsNotABeat(testCase)
            testCase.verifyFalse(is_beat_annotation('+'));
        end

        function testSignalQualityMarkerIsNotABeat(testCase)
            testCase.verifyFalse(is_beat_annotation('~'));
        end
    end
end
