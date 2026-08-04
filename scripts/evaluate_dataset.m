% Run the detection pipeline across every downloaded MIT-BIH record and
% report honest, per-record precision/recall/F1 -- not just one
% favorable example.
%
% Run (after scripts/download_data.py): scripts/evaluate_dataset
project_root = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(project_root));

data_root = fullfile(project_root, 'data');
entries = dir(data_root);
entries = entries([entries.isdir] & ~startsWith({entries.name}, '.'));

fprintf('%-10s %10s %10s %10s %10s %10s\n', 'Record', 'Detected', 'Annotated', 'Precision', 'Recall', 'F1');

all_f1 = [];
rows = {};
for i = 1:numel(entries)
    record_name = entries(i).name;
    record_dir = fullfile(data_root, record_name);

    [signal, fs, true_peaks] = load_ecg_csv(record_dir);
    detected = pan_tompkins_detector(signal, fs);
    result = match_peaks(detected, true_peaks, fs);

    fprintf('%-10s %10d %10d %10.3f %10.3f %10.3f\n', record_name, ...
        numel(detected), numel(true_peaks), result.precision, result.recall, result.f1);

    all_f1(end + 1) = result.f1; %#ok<AGROW>
    rows(end + 1, :) = {record_name, numel(detected), numel(true_peaks), ...
        result.precision, result.recall, result.f1}; %#ok<AGROW>
end

fprintf('\nMean F1 across %d records: %.3f\n', numel(entries), mean(all_f1));

results_dir = fullfile(project_root, 'results');
if ~exist(results_dir, 'dir')
    mkdir(results_dir);
end
results_table = cell2table(rows, 'VariableNames', ...
    {'record', 'detected', 'annotated', 'precision', 'recall', 'f1'});
writetable(results_table, fullfile(results_dir, 'evaluation.csv'));
fprintf('Wrote %s\n', fullfile(results_dir, 'evaluation.csv'));
