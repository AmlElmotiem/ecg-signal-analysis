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

- **`bandpass_filter.m`** — zero-phase Butterworth bandpass (5-15 Hz)
  that isolates QRS-complex energy.
- **`pan_tompkins_detector.m`** — the full five-stage pipeline:
  bandpass filter → derivative (emphasizes the steep QRS slope) →
  squaring → moving-window integration (~150ms, roughly one QRS
  width) → adaptive thresholding with a 200ms refractory period.
  **`adaptive_threshold_peaks.m`** implements the running signal/noise
  level tracking; **`refine_peaks.m`** corrects the delay the
  integration stage introduces by snapping each candidate back to the
  true local maximum in the filtered signal.
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
runtests('tests')                   % 19 tests, all on synthetic signals, no download needed
scripts/run_demo                    % annotated plot + HRV for one real record
scripts/evaluate_dataset            % honest precision/recall/F1 across all downloaded records
```

## What we found (the honest part)

To fill in after running `scripts/evaluate_dataset.m` on the real MIT-BIH
records: per-record precision/recall/F1, and which records the
detector struggles with (expected candidates: records with a lot of
ventricular ectopic beats, which have a different QRS morphology than
the normal beats the adaptive threshold tunes itself to first).

## Limitations

- Single-lead detection only (MLII channel) — does not fuse multiple
  ECG leads, which real clinical detectors often do for robustness.
- No beat *classification* (normal vs. PVC vs. paced, etc.) — this
  project only detects and counts R-peaks, it does not diagnose
  arrhythmia type, even though the ground truth annotations include
  that information.
- The adaptive threshold's initial signal/noise levels are estimated
  from the first 2 seconds of each record; a record that starts with
  an atypical rhythm could start with a poorly calibrated threshold.

## Roadmap

- Beat classification using the existing ground-truth annotation
  types (tie together with the general classification approach from
  `bci-arm-control`)
- Multi-lead fusion where a record provides more than one channel
- Frequency-domain HRV metrics (LF/HF ratio) alongside the current
  time-domain ones (SDNN, RMSSD)
