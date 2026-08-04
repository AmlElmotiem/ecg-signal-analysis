function tf = is_beat_annotation(symbol)
%IS_BEAT_ANNOTATION True if SYMBOL is a MIT-BIH annotation code marking
%   an actual heartbeat (QRS complex), as opposed to a non-beat
%   rhythm/quality marker (e.g. '+' rhythm change, '~' signal quality
%   change, '|' isolated artifact).
%
%   List follows the standard WFDB beat annotation codes documented for
%   the MIT-BIH Arrhythmia Database (physionet.org/physiobank/annotations.shtml):
%   normal beats and the various abnormal-beat classes (PVC, paced,
%   fusion, etc.) all count as real heartbeats for R-peak detection
%   purposes -- only structural/quality markers are excluded.
    beat_symbols = {'N', 'L', 'R', 'B', 'A', 'a', 'J', 'S', 'V', 'r', ...
                    'F', 'e', 'j', 'n', 'E', '/', 'f', 'Q'};
    tf = ismember(symbol, beat_symbols);
end
