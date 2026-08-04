function fig = plot_ecg_detection(signal, fs, detected_indices, true_indices)
%PLOT_ECG_DETECTION Plot an ECG trace with detected R-peaks (green) and
%   annotated ground-truth beats (red) overlaid, for visual sanity-checking.
    t = (0:numel(signal) - 1) / fs;
    fig = figure('Color', 'w');
    plot(t, signal, 'k');
    hold on;
    plot(t(detected_indices), signal(detected_indices), 'go', 'MarkerSize', 8, 'LineWidth', 1.5);

    if nargin >= 4 && ~isempty(true_indices)
        plot(t(true_indices), signal(true_indices), 'r+', 'MarkerSize', 10, 'LineWidth', 1.5);
        legend('ECG signal', 'Detected R-peaks', 'Annotated ground truth', 'Location', 'best');
    else
        legend('ECG signal', 'Detected R-peaks', 'Location', 'best');
    end

    xlabel('Time (s)');
    ylabel('Amplitude (mV)');
    title('QRS Detection: Pan-Tompkins Algorithm');
    grid on;
end
