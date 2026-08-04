function result = match_peaks(detected_indices, true_indices, fs, tolerance_s)
%MATCH_PEAKS Honestly match detected R-peaks against annotated ground
%   truth, greedily and without double-counting.
%
%   result = MATCH_PEAKS(detected_indices, true_indices, fs, tolerance_s)
%   matches each detected peak to the nearest *unmatched* true peak
%   within TOLERANCE_S seconds (default 50ms, the common convention for
%   ECG QRS-detection evaluation). Each true peak can be claimed by at
%   most one detection, so a cluster of detections near one real beat
%   cannot inflate the true-positive count.
%
%   Returns a struct with true_positives, false_positives,
%   false_negatives, precision, recall, f1.
    if nargin < 4
        tolerance_s = 0.05;
    end
    tolerance_samples = tolerance_s * fs;

    detected_indices = detected_indices(:)';
    true_indices = true_indices(:)';

    matched_true = false(size(true_indices));
    tp = 0;

    for i = 1:numel(detected_indices)
        d = detected_indices(i);
        diffs = abs(true_indices - d);
        diffs(matched_true) = inf;
        if isempty(diffs)
            break
        end
        [min_diff, idx] = min(diffs);
        if min_diff <= tolerance_samples
            matched_true(idx) = true;
            tp = tp + 1;
        end
    end

    fp = numel(detected_indices) - tp;
    fn = numel(true_indices) - tp;

    result.true_positives = tp;
    result.false_positives = fp;
    result.false_negatives = fn;

    if (tp + fp) > 0
        result.precision = tp / (tp + fp);
    else
        result.precision = 0;
    end

    if (tp + fn) > 0
        result.recall = tp / (tp + fn);
    else
        result.recall = 0;
    end

    if (result.precision + result.recall) > 0
        result.f1 = 2 * result.precision * result.recall / (result.precision + result.recall);
    else
        result.f1 = 0;
    end
end
