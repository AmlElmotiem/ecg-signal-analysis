% Run the Pan-Tompkins QRS detector on one real, downloaded MIT-BIH
% record, plot the result, and print heart-rate/HRV summary stats.
%
% Run (after scripts/download_data.py): scripts/run_demo
addpath(genpath(fileparts(fileparts(mfilename('fullpath')))));

record_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data', '100');
[signal, fs, true_peaks] = load_ecg_csv(record_dir);

% First 30 seconds only, so the plot stays readable
window_end = min(round(30 * fs), numel(signal));
signal_w = signal(1:window_end);
true_peaks_w = true_peaks(true_peaks <= window_end);

detected = pan_tompkins_detector(signal_w, fs);
result = match_peaks(detected, true_peaks_w, fs);

fprintf('Record 100, first 30s: %d detected, %d annotated beats\n', ...
    numel(detected), numel(true_peaks_w));
fprintf('Precision=%.3f  Recall=%.3f  F1=%.3f\n', result.precision, result.recall, result.f1);

hrv = compute_hrv(detected, fs);
fprintf('Mean HR: %.1f bpm | SDNN: %.1f ms | RMSSD: %.1f ms\n', ...
    hrv.mean_hr_bpm, hrv.sdnn_ms, hrv.rmssd_ms);

results_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'results');
if ~exist(results_dir, 'dir')
    mkdir(results_dir);
end

fig1 = plot_ecg_detection(signal_w, fs, detected, true_peaks_w);
saveas(fig1, fullfile(results_dir, 'ecg_detection_demo.png'));

fig2 = plot_hrv(hrv);
saveas(fig2, fullfile(results_dir, 'hrv_poincare_demo.png'));

fprintf('Wrote %s\n', fullfile(results_dir, 'ecg_detection_demo.png'));
fprintf('Wrote %s\n', fullfile(results_dir, 'hrv_poincare_demo.png'));
