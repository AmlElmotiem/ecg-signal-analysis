function [signal, fs, peak_indices, symbols] = load_ecg_annotations(record_dir)
%LOAD_ECG_ANNOTATIONS Load a record's signal plus every annotated beat's
%   index AND its symbol (unlike LOAD_ECG_CSV, which only returns
%   indices). Needed for beat classification, where RR-interval
%   features must reflect the true neighboring beats regardless of
%   their type, even when only a subset of beat types is used for
%   training.
    signal_data = readmatrix(fullfile(record_dir, 'signal.csv'));
    signal = signal_data(:)';

    meta = readmatrix(fullfile(record_dir, 'meta.csv'));
    fs = meta(1);

    ann = readtable(fullfile(record_dir, 'annotations.csv'), 'TextType', 'string');
    is_beat = false(height(ann), 1);
    for i = 1:height(ann)
        is_beat(i) = is_beat_annotation(ann.symbol(i));
    end

    peak_indices = ann.sample_index(is_beat)' + 1;  % 0-indexed -> 1-indexed
    symbols = ann.symbol(is_beat)';
end
