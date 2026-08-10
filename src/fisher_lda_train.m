function model = fisher_lda_train(X, y)
%FISHER_LDA_TRAIN Two-class Fisher Linear Discriminant Analysis, built
%   from scratch (mean/covariance/linear-solve only -- no Statistics
%   and Machine Learning Toolbox required).
%
%   model = FISHER_LDA_TRAIN(X, y) with X an NxD feature matrix and Y
%   an Nx1 vector containing exactly two distinct class labels.
%   Features are standardized (zero mean, unit variance) before
%   fitting, since the raw features here have very different natural
%   scales (seconds vs. millivolts) that would otherwise dominate the
%   discriminant direction for the wrong reason.
    classes = unique(y);
    if numel(classes) ~= 2
        error('fisher_lda_train:notBinary', 'Exactly two classes are required.');
    end

    mu = mean(X, 1);
    sigma = std(X, 0, 1);
    sigma(sigma == 0) = 1;
    Xz = (X - mu) ./ sigma;

    X0 = Xz(y == classes(1), :);
    X1 = Xz(y == classes(2), :);

    mu0 = mean(X0, 1);
    mu1 = mean(X1, 1);

    % Within-class scatter: how spread out each class is around its own
    % mean. The discriminant direction w maximizes the separation
    % between the projected class means relative to this spread.
    Sw = (X0 - mu0)' * (X0 - mu0) + (X1 - mu1)' * (X1 - mu1);
    w = Sw \ (mu1 - mu0)';

    proj0 = X0 * w;
    proj1 = X1 * w;
    mean_proj0 = mean(proj0);
    mean_proj1 = mean(proj1);

    model.feature_mean = mu;
    model.feature_std = sigma;
    model.w = w;
    model.threshold = (mean_proj0 + mean_proj1) / 2;

    if mean_proj1 >= mean_proj0
        model.class_if_above = classes(2);
        model.class_if_below = classes(1);
    else
        model.class_if_above = classes(1);
        model.class_if_below = classes(2);
    end
end
