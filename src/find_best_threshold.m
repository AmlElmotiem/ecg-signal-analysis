function best_threshold = find_best_threshold(scores, y, positive_class, negative_class)
%FIND_BEST_THRESHOLD Sweep candidate decision thresholds over SCORES
%   and return the one maximizing F1 for POSITIVE_CLASS.
%
%   Call this on TRAINING scores only, never on test scores -- tuning
%   the threshold against the data you're trying to honestly evaluate
%   on would leak information from the test set into the model.
    candidates = unique(scores);
    best_f1 = -1;
    best_threshold = median(scores);

    for i = 1:numel(candidates)
        th = candidates(i);
        pred = repmat(negative_class, size(scores));
        pred(scores > th) = positive_class;

        tp = sum(pred == positive_class & y == positive_class);
        fp = sum(pred == positive_class & y == negative_class);
        fn = sum(pred == negative_class & y == positive_class);
        if (tp + fp) == 0 || (tp + fn) == 0
            continue
        end

        precision = tp / (tp + fp);
        recall = tp / (tp + fn);
        if (precision + recall) == 0
            continue
        end

        f1 = 2 * precision * recall / (precision + recall);
        if f1 > best_f1
            best_f1 = f1;
            best_threshold = th;
        end
    end
end
