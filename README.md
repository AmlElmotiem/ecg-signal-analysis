# ecg-signal-analysis

R-peak (QRS complex) detection and heart-rate-variability analysis from
real ECG recordings, in MATLAB — implementing the classic
Pan-Tompkins (1985) detection algorithm from its five stages rather
than calling a single toolbox function, and validating it honestly
against real, expert-annotated heartbeats rather than only a
favorable example.

This connects directly to my Biosignal-Labor coursework, but applies
it to a real, public clinical dataset instead of one recording from a
teaching setup.

## What it does

- **`bandpass_filter.m`** — zero-phase bandpass (5-15 Hz) that
  isolates QRS-complex energy, built from scratch as a single biquad
  IIR filter (no Signal Processing Toolbox, since it isn't installed
  on the machine this was developed on) — see "Why a hand-built
  filter" below.
- **`pan_tompkins_detector.m`** — the full five-stage pipeline:
  bandpass filter → derivative (emphasizes the steep QRS slope) →
  squaring → moving-window integration (~150ms, roughly one QRS
  width) → adaptive thresholding with a 200ms refractory period.
  **`adaptive_threshold_peaks.m`** implements the running signal/noise
  level tracking and a search-back step for recovering missed beats
  (see "What we found" below); **`refine_peaks.m`** corrects the delay
  the integration stage introduces by snapping each candidate back to
  the true local maximum in the filtered signal.
- **`compute_hrv.m`** — RR intervals, mean heart rate, SDNN (overall
  variability), RMSSD (short-term variability) from detected beats.
- **`match_peaks.m`** — honestly evaluates detected beats against
  ground truth: greedy nearest-neighbor matching within a 50ms
  tolerance, with each true beat claimable by at most one detection
  (so a cluster of false detections near one real beat can't inflate
  the true-positive count) — precision/recall/F1, same evaluation
  philosophy as `colony-counter`.
- **`synthetic_ecg.m`** — generates a synthetic ECG-like signal with
  exactly known R-peak locations, so the detector's unit tests are
  fully deterministic and need no data download.
- **`scripts/download_data.py`** — fetches real records from the
  [MIT-BIH Arrhythmia Database](https://physionet.org/content/mitdb/)
  via PhysioNet's official `wfdb` Python client and converts them to
  plain CSV. See "Why Python for the download step" below.
- **`scripts/run_demo.m`** — runs the pipeline on one real record,
  plots detected vs. annotated beats, and an HRV Poincaré plot.
- **`scripts/evaluate_dataset.m`** — runs across every downloaded
  record and reports per-record precision/recall/F1, not just one
  cherry-picked example.
- **`extract_beat_features.m`** — four simple per-beat features (RR
  interval before/after, peak amplitude, QRS width) used for beat
  classification.
- **`fisher_lda_train.m`** / **`fisher_lda_predict.m`** — two-class
  Fisher Linear Discriminant Analysis, built from scratch (no
  Statistics and Machine Learning Toolbox) — the same general
  classification approach as `bci-arm-control`, applied here to
  telling normal beats from PVCs instead of EEG motor-imagery classes.
- **`build_beat_dataset.m`** / **`load_ecg_annotations.m`** — load a
  record's full beat list *with* its annotation symbols (not just
  "is this a beat"), so RR-interval features stay correct even when
  only a subset of beat types is used for training.
- **`scripts/train_beat_classifier.m`** — trains the beat classifier
  on some records and evaluates it on others entirely unseen during
  training, honestly, the same across-patient philosophy as
  `bci-arm-control`'s subject-grouped evaluation.

## Why a hand-built filter

The first version of `bandpass_filter.m` used MATLAB's `butter` and
`filtfilt` — standard, sensible choices. Running the tests turned up
that this MATLAB installation doesn't have the Signal Processing
Toolbox those functions require, which would have made the whole
project depend on a toolbox that isn't guaranteed to be there.
`bandpass_filter.m` was rewritten as a single 2nd-order IIR biquad
using the standard Audio EQ Cookbook design formulas (centered at the
geometric mean of the two cutoffs, Q chosen from the requested
bandwidth), applied forward-then-backward for zero phase using only
the base `filter` function. No functionality was lost, and the
project now has one fewer dependency.

## Why Python for the download step

MIT-BIH ships in WFDB, a specialized binary signal format from the
1980s. Reimplementing a WFDB decoder from scratch in MATLAB would be a
distraction from the actual signal-processing work this project is
about, so `scripts/download_data.py` uses PhysioNet's own official
Python client library (`wfdb`) to fetch and decode the records into
plain CSV once. Every actual analysis step — filtering, detection, HRV,
evaluation — happens in MATLAB.

## Getting started

```bash
pip install wfdb
python scripts/download_data.py     # downloads 10 real MIT-BIH records to data/
```

```matlab
addpath(genpath(pwd))
runtests('tests')                   % 26 tests, all on synthetic signals, no download needed
scripts/run_demo                    % annotated plot + HRV for one real record
scripts/evaluate_dataset            % honest precision/recall/F1 across all downloaded records
scripts/train_beat_classifier       % normal-vs-PVC classifier, trained and tested on disjoint records
```

## What we found (the honest part)

The first real-data run (`scripts/run_demo.m` on record 100) found a
real bug immediately: 21 detected beats against 37 annotated ones in
30 seconds — recall of only 0.568, with perfect precision (1.000).
Every detection was correct, but roughly half the real beats were
silently missed, and the computed heart rate (41 bpm) was
implausibly low for that record's actual ~74 bpm rhythm.

The cause: my first implementation of `adaptive_threshold_peaks.m`
left out the **search-back step** from the original 1985 paper. A
single strong beat raises the running "signal level" estimate (and
therefore the threshold) for a moment; on real ECG, where beat
amplitude naturally varies a little from one beat to the next, that
was sometimes enough to make the very next, slightly weaker beat fall
just under the raised threshold and get silently skipped — a pattern
that shows up as roughly "every other beat missed." The original
algorithm handles exactly this: if no beat is confirmed for more than
1.66x the recent average RR interval, it searches back through that
gap at half the threshold to recover the missed beat. Implementing
that (see `search_back` in `adaptive_threshold_peaks.m`) fixed record
100 outright: 37/37 beats, precision 1.000, recall 1.000, HR 74.0 bpm.

Evaluated across all 10 downloaded records in full (roughly 30 minutes
of real ECG each, ~24,000 beats total — not just a 30-second clip):

| Record | Detected | Annotated | Precision | Recall | F1 |
|---|---|---|---|---|---|
| 100 | 2272 | 2273 | 1.000 | 0.999 | 0.999 |
| 101 | 1869 | 1865 | 0.997 | 0.999 | 0.998 |
| 103 | 2083 | 2084 | 1.000 | 1.000 | 1.000 |
| 105 | 2622 | 2572 | 0.973 | 0.991 | 0.982 |
| 111 | 2123 | 2124 | 0.997 | 0.997 | 0.997 |
| 119 | 2027 | 1987 | 0.980 | 1.000 | 0.990 |
| 122 | 2477 | 2476 | 1.000 | 1.000 | 1.000 |
| 205 | 2654 | 2656 | 0.991 | 0.991 | 0.991 |
| 213 | 3249 | 3251 | 0.990 | 0.989 | 0.989 |
| 223 | 2602 | 2605 | 0.969 | 0.968 | 0.968 |

**Mean F1: 0.991.** Record 223 is the weakest (F1 0.968) — it's a
known arrhythmia-heavy recording in the MIT-BIH set with frequent
ectopic beats whose QRS shape differs from the normal beats the
detector calibrates on early in the record, which fits the
expectation that non-normal beat morphology is where a
threshold-based detector like this is weakest. Record 105 (F1 0.982)
is a noisier recording, consistent with more false positives
(precision 0.973 is its lowest score of the ten).

### Beat classification: accuracy looked great and was actually a trap

Trained a from-scratch Fisher LDA classifier (normal vs. PVC) on 8
records (15,855 beats) and evaluated it on 2 entirely different
records held out from training (5,363 beats: 4,670 normal, 693 PVC).
With the classifier's default decision threshold (the midpoint between
the two projected class means):

| | Accuracy | PVC precision | PVC recall | PVC F1 |
|---|---|---|---|---|
| Default threshold | 0.8822 | 0.9296 | 0.0952 | 0.1728 |

88% accuracy sounds good — until you notice the test set is 87% normal
beats, so "always predict normal" alone would already score close to
that. The real story is in the PVC row: recall of 0.095 means the
classifier caught fewer than 1 in 10 real PVCs, while precision stayed
high (0.93) because it only very rarely misfired on a normal beat.
**This is the classic accuracy-on-imbalanced-data trap** — a metric
that looks reassuring while the model is actually failing at the one
thing that matters clinically (missing an abnormal beat is far worse
than a false alarm). Next step: find a way to raise recall without
throwing away the good precision.

## Limitations

- Single-lead detection only (MLII channel) — does not fuse multiple
  ECG leads, which real clinical detectors often do for robustness.
- The adaptive threshold's initial signal/noise levels are estimated
  from the first 2 seconds of each record; a record that starts with
  an atypical rhythm could start with a poorly calibrated threshold.
- The beat classifier's default threshold gives very low PVC recall
  (0.095) despite high overall accuracy — see "What we found" above.

## Roadmap

- Fix the beat classifier's low PVC recall (tune the decision
  threshold, or use a richer feature set)
- Multi-lead fusion where a record provides more than one channel
- Frequency-domain HRV metrics (LF/HF ratio) alongside the current
  time-domain ones (SDNN, RMSSD)
