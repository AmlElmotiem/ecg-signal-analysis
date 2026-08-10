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
pred_test = fisher_lda_predict(model, X_test);

accuracy = mean(pred_test == y_test);

tp_v = sum(pred_test == 2 & y_test == 2);
fp_v = sum(pred_test == 2 & y_test == 1);
fn_v = sum(pred_test == 1 & y_test == 2);
precision_v = tp_v / (tp_v + fp_v);
recall_v = tp_v / (tp_v + fn_v);
f1_v = 2 * precision_v * recall_v / (precision_v + recall_v);

fprintf('\nOverall accuracy: %.4f\n', accuracy);
fprintf('PVC (V) detection -- precision: %.4f  recall: %.4f  F1: %.4f\n', ...
    precision_v, recall_v, f1_v);

fprintf('\nConfusion matrix (rows=true, cols=predicted):\n');
fprintf('%12s %8s %8s\n', '', 'Pred N', 'Pred V');
fprintf('%12s %8d %8d\n', 'True N', sum(y_test == 1 & pred_test == 1), sum(y_test == 1 & pred_test == 2));
fprintf('%12s %8d %8d\n', 'True V', sum(y_test == 2 & pred_test == 1), sum(y_test == 2 & pred_test == 2));

results_dir = fullfile(project_root, 'results');
if ~exist(results_dir, 'dir')
    mkdir(results_dir);
end

fig = figure('Color', 'w');
scores_n = (X_test(y_test == 1, :) - model.feature_mean) ./ model.feature_std * model.w;
scores_v = (X_test(y_test == 2, :) - model.feature_mean) ./ model.feature_std * model.w;
histogram(scores_n, 30, 'FaceAlpha', 0.6, 'DisplayName', 'True N');
hold on;
histogram(scores_v, 30, 'FaceAlpha', 0.6, 'DisplayName', 'True V');
xline(model.threshold, 'k--', 'DisplayName', 'Decision threshold');
xlabel('LDA projection score');
ylabel('Count');
title('Beat classifier: LDA projection on held-out test records');
legend('Location', 'best');
saveas(fig, fullfile(results_dir, 'beat_classifier_scores.png'));
fprintf('\nWrote %s\n', fullfile(results_dir, 'beat_classifier_scores.png'));
