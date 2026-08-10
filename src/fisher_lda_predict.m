function [predictions, scores] = fisher_lda_predict(model, X)
%FISHER_LDA_PREDICT Classify each row of X using a MODEL from
%   FISHER_LDA_TRAIN. SCORES are the projected (standardized) values
%   before thresholding -- how far past the decision boundary each
%   point falls.
    Xz = (X - model.feature_mean) ./ model.feature_std;
    scores = Xz * model.w;

    predictions = repmat(model.class_if_below, size(scores));
    predictions(scores > model.threshold) = model.class_if_above;
end
