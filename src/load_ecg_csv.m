function [signal, fs, true_peak_indices] = load_ecg_csv(record_dir)
%LOAD_ECG_CSV Load one ECG record previously exported to CSV by
%   scripts/download_data.py (signal.csv, annotations.csv, meta.csv).
%
%   MIT-BIH ships in a specialized binary format (WFDB) from the 1980s.
%   Rather than reimplement a WFDB decoder from scratch in MATLAB --
%   which would be a distraction from the actual signal-processing work
%   this project is about -- the data is fetched and converted to plain
%   CSV via PhysioNet's own official Python client library (`wfdb`) in
%   scripts/download_data.py. MATLAB does all the actual analysis.
    signal_data = readmatrix(fullfile(record_dir, 'signal.csv'));
    signal = signal_data(:)';

    meta = readmatrix(fullfile(record_dir, 'meta.csv'));
    fs = meta(1);

    ann = readtable(fullfile(record_dir, 'annotations.csv'), 'TextType', 'string');
    is_beat = false(height(ann), 1);
    for i = 1:height(ann)
        is_beat(i) = is_beat_annotation(ann.symbol(i));
    end

    % PhysioNet annotation samples are 0-indexed; MATLAB arrays are 1-indexed.
    true_peak_indices = ann.sample_index(is_beat)' + 1;
end
