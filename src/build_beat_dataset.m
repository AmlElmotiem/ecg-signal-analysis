function [X, y] = build_beat_dataset(data_root, record_names, target_symbols)
%BUILD_BEAT_DATASET Extract classification features for every beat
%   whose annotation symbol is in TARGET_SYMBOLS, across RECORD_NAMES.
%
%   RR-interval features are computed against *every* annotated beat in
%   each record (via LOAD_ECG_ANNOTATIONS), not just the target-labeled
%   ones, so they reflect the true neighboring beats even when other
%   beat types are excluded from the returned dataset. Y contains the
%   1-based index into TARGET_SYMBOLS for each row of X.
    X = [];
    y = [];
    for i = 1:numel(record_names)
        record_dir = fullfile(data_root, record_names{i});
        [signal, fs, peak_indices, symbols] = load_ecg_annotations(record_dir);

        features_all = extract_beat_features(signal, fs, peak_indices);

        for k = 1:numel(peak_indices)
            label_idx = find(strcmp(target_symbols, symbols(k)), 1);
            if ~isempty(label_idx)
                X(end + 1, :) = features_all(k, :); %#ok<AGROW>
                y(end + 1, 1) = label_idx; %#ok<AGROW>
            end
        end
    end
end
