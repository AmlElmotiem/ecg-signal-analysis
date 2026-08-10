% Train a from-scratch Fisher LDA classifier to distinguish Normal (N)
% beats from PVCs (V) using simple morphological/timing features, and
% evaluate it honestly on records that were NOT used for training --
% the same across-patient evaluation philosophy as bci-arm-control's
% GroupKFold (a classifier that only ever saw one patient's beat shapes
% could look artificially good tested on more of that same patient).
%
% Run (after scripts/download_data.py): scripts/train_beat_classifier
project_root = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(project_root));
data_root = fullfile(project_root, 'data');

% Split by RECORD, not by individual beat -- so no patient appears in
% both sets. Chosen so both sets have a meaningful number of the rare
% class (V); see README for the exact counts.
train_records = {'100', '101', '103', '105', '111', '122', '205', '119'};
test_records = {'213', '223'};
target_symbols = {'N', 'V'};

[X_train, y_train] = build_beat_dataset(data_root, train_records, target_symbols);
[X_test, y_test] = build_beat_dataset(data_root, test_records, target_symbols);

fprintf('Train: %d beats (%d N, %d V) from %d records\n', ...
    numel(y_train), sum(y_train == 1), sum(y_train == 2), numel(train_records));
fprintf('Test:  %d beats (%d N, %d V) from %d records (NOT seen during training)\n', ...
    numel(y_test), sum(y_test == 1), sum(y_test == 2), numel(test_records));

model = fisher_lda_train(X_train, y_train);

% Baseline: the default midpoint-of-means threshold.
pred_default = fisher_lda_predict(model, X_test);
report_metrics('Default (midpoint) threshold', pred_default, y_test);

% Alternative: sweep thresholds on TRAINING scores only (never on
% test) to find the one maximizing F1 for the minority class, then
% apply that fixed threshold to the untouched test set.
Xz_train = (X_train - model.feature_mean) ./ model.feature_std;
train_scores = Xz_train * model.w;
tuned_threshold = find_best_threshold(train_scores, y_train, 2, 1);

model_tuned = model;
model_tuned.threshold = tuned_threshold;
pred_tuned = fisher_lda_predict(model_tuned, X_test);
report_metrics('F1-tuned threshold (chosen on train only)', pred_tuned, y_test);

function report_metrics(label, pred, y_true)
    accuracy = mean(pred == y_true);
    tp_v = sum(pred == 2 & y_true == 2);
    fp_v = sum(pred == 2 & y_true == 1);
    fn_v = sum(pred == 1 & y_true == 2);
    precision_v = tp_v / (tp_v + fp_v);
    recall_v = tp_v / (tp_v + fn_v);
    f1_v = 2 * precision_v * recall_v / (precision_v + recall_v);

    fprintf('\n== %s ==\n', label);
    fprintf('Overall accuracy: %.4f\n', accuracy);
    fprintf('PVC (V) detection -- precision: %.4f  recall: %.4f  F1: %.4f\n', ...
        precision_v, recall_v, f1_v);
    fprintf('Confusion matrix (rows=true, cols=predicted):\n');
    fprintf('%12s %8s %8s\n', '', 'Pred N', 'Pred V');
    fprintf('%12s %8d %8d\n', 'True N', sum(y_true == 1 & pred == 1), sum(y_true == 1 & pred == 2));
    fprintf('%12s %8d %8d\n', 'True V', sum(y_true == 2 & pred == 1), sum(y_true == 2 & pred == 2));
end
