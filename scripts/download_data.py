"""Download a handful of real MIT-BIH Arrhythmia Database records from
PhysioNet and convert them to plain CSV, so the MATLAB pipeline can
consume them without needing a WFDB decoder written in MATLAB.

MIT-BIH ships in a specialized binary signal format (WFDB) from the
1980s. Rather than reimplement that decoder from scratch in MATLAB --
a distraction from the actual signal-processing work this project is
about -- this script uses PhysioNet's own official Python client
library (`wfdb`) to fetch and decode the records, then writes plain
CSV files that MATLAB reads directly.

Requires: pip install wfdb
Run:      python scripts/download_data.py
"""

from __future__ import annotations

import csv
from pathlib import Path

import wfdb

RECORDS = ["100", "101", "103", "105", "111", "119", "122", "205", "213", "223"]
DATA_DIR = Path(__file__).resolve().parents[1] / "data"


def download_record(record_name: str) -> None:
    record = wfdb.rdrecord(record_name, pn_dir="mitdb")
    annotation = wfdb.rdann(record_name, "atr", pn_dir="mitdb")

    signal = record.p_signal[:, 0]  # first channel (typically MLII lead)
    fs = record.fs

    out_dir = DATA_DIR / record_name
    out_dir.mkdir(parents=True, exist_ok=True)

    with open(out_dir / "signal.csv", "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["sample"])
        for value in signal:
            writer.writerow([value])

    with open(out_dir / "annotations.csv", "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["sample_index", "symbol"])
        for idx, symbol in zip(annotation.sample, annotation.symbol):
            writer.writerow([idx, symbol])

    with open(out_dir / "meta.csv", "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["fs"])
        writer.writerow([fs])

    print(f"{record_name}: {len(signal)} samples at {fs} Hz, {len(annotation.sample)} annotated beats")


def main() -> None:
    DATA_DIR.mkdir(exist_ok=True)
    for record_name in RECORDS:
        download_record(record_name)


if __name__ == "__main__":
    main()
