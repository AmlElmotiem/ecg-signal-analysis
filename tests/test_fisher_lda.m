classdef test_fisher_lda < matlab.unittest.TestCase
    methods (Test)
        function testSeparatesTwoWellSeparatedClusters(testCase)
            X0 = [0 0; 0.5 0.2; -0.3 0.1; 0.2 -0.4];
            X1 = [10 10; 9.5 10.2; 10.3 9.8; 9.8 10.4];
            X = [X0; X1];
            y = [ones(4, 1); 2 * ones(4, 1)];

            model = fisher_lda_train(X, y);
            pred = fisher_lda_predict(model, X);

            testCase.verifyEqual(pred, y);
        end

        function testGeneralizesToNewPoints(testCase)
            X0 = [0 0; 0.5 0.2; -0.3 0.1; 0.2 -0.4; 0.1 0.3];
            X1 = [10 10; 9.5 10.2; 10.3 9.8; 9.8 10.4; 10.1 9.9];
            X = [X0; X1];
            y = [ones(5, 1); 2 * ones(5, 1)];
            model = fisher_lda_train(X, y);

            new_points = [0.05, 0.05; 9.9, 10.05];
            pred = fisher_lda_predict(model, new_points);

            testCase.verifyEqual(pred, [1; 2]);
        end

        function testErrorsOnNonBinaryLabels(testCase)
            X = [0 0; 1 1; 2 2];
            y = [1; 2; 3];
            testCase.verifyError(@() fisher_lda_train(X, y), 'fisher_lda_train:notBinary');
        end

        function testRobustToWildlyDifferentFeatureScales(testCase)
            % One feature in the 0-1 range, another in the thousands --
            % without standardization the large-scale feature could
            % dominate the discriminant for the wrong reason.
            X0 = [0.1 1000; 0.2 1010; 0.15 995; 0.12 1005];
            X1 = [0.9 1000; 0.8 1010; 0.85 995; 0.88 1005];
            X = [X0; X1];
            y = [ones(4, 1); 2 * ones(4, 1)];

            model = fisher_lda_train(X, y);
            pred = fisher_lda_predict(model, X);

            testCase.verifyEqual(pred, y);
        end
    end
end
