#!/usr/bin/env python3
"""Collect the Lab 1 sweep (Yosys + OpenSTA logs) into one CSV.

    make csv                                   # uses WIDTHS / PERIODS from the Makefile
    make csv WIDTHS="4 8 16 32 64" PERIODS="2 4 8 16"
    python3 scripts/collect_results.py --results results --out results/summary.csv

One row per (width, period) that has both results/yosys_<W>_<P>.log and
results/sta_w<W>p<P>.log. Columns:

    width, period_ns, freq_mhz      the design point
    cells, flops                    standard cells after mapping; how many are flip-flops
    area_um2, seq_area_um2          total cell area; the flip-flop part of it
    wns_ns, tns_ns                  worst / total negative setup slack (OpenSTA)
    arrival_ns                      data arrival time of the worst setup path
    power_total_w, power_seq_w, power_comb_w
                                    OpenSTA report_power (activity 0.2 on inputs)
    power_internal_w, power_switching_w, power_leakage_w
                                    the "Total" row split by component
"""
import argparse
import csv
import glob
import os
import re
import sys

NUM = r"(-?\d+(?:\.\d*)?(?:[eE][+-]?\d+)?)"

COLUMNS = ["width", "period_ns", "freq_mhz", "cells", "flops", "area_um2", "seq_area_um2",
           "wns_ns", "tns_ns", "arrival_ns", "power_total_w", "power_seq_w", "power_comb_w",
           "power_internal_w", "power_switching_w", "power_leakage_w"]


def last(pattern, text, group=1, cast=float):
    hits = re.findall(pattern, text, re.MULTILINE)
    if not hits:
        return None
    hit = hits[-1]
    return cast(hit[group - 1] if isinstance(hit, tuple) else hit)


def parse_yosys(text):
    row = {}
    row["area_um2"] = last(r"Chip area for module .*?:\s*" + NUM, text)
    # Yosys >= 0.6x: "      518 6.92E+03 cells"; older: "Number of cells:   518"
    row["cells"] = last(r"^\s+(\d+)\s+\S+\s+cells\s*$", text, cast=int)
    if row["cells"] is None:
        row["cells"] = last(r"Number of cells:\s+(\d+)", text, cast=int)
    # Flip-flop lines in the last (liberty-mapped) statistics: "   194  4.85E+03   sky130_fd_sc_hd__dfrtp_1"
    stats = text[text.rfind("Printing statistics"):] if "Printing statistics" in text else text
    flops, seq_area = 0, 0.0
    for count, area, cell in re.findall(r"^\s+(\d+)\s+" + NUM + r"\s+(sky130_fd_sc_hd__\w+)\s*$",
                                        stats, re.MULTILINE):
        if re.match(r"sky130_fd_sc_hd__(df|edf|sdf|dl)", cell):
            flops += int(count)
            seq_area += float(area)
    row["flops"] = flops or None
    row["seq_area_um2"] = seq_area or None
    return row


def parse_sta(text):
    row = {}
    # "worst slack max -0.123" (OpenROAD) or "worst slack -0.123" (OpenSTA)
    row["wns_ns"] = last(r"^worst slack(?: max)?\s+" + NUM, text)
    row["tns_ns"] = last(r"^tns(?: max)?\s+" + NUM, text)
    m = re.search(r"^\s*" + NUM + r"\s+data arrival time", text, re.MULTILINE)
    row["arrival_ns"] = float(m.group(1)) if m else None
    # report_power rows: Group  Internal  Switching  Leakage  Total  (Percent)
    def power_row(name):
        m = re.search(r"^" + name + r"\s+" + r"\s+".join([NUM] * 4), text, re.MULTILINE)
        return [float(x) for x in m.groups()] if m else None
    total, seq, comb = power_row("Total"), power_row("Sequential"), power_row("Combinational")
    if total:
        row["power_internal_w"], row["power_switching_w"], row["power_leakage_w"], row["power_total_w"] = total
    row["power_seq_w"] = seq[3] if seq else None
    row["power_comb_w"] = comb[3] if comb else None
    return row


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--results", default="results")
    ap.add_argument("--out", default="results/summary.csv")
    args = ap.parse_args()

    rows = []
    for ylog in glob.glob(os.path.join(args.results, "yosys_*_*.log")):
        m = re.match(r"yosys_(\d+)_(.+)\.log$", os.path.basename(ylog))
        if not m:
            continue
        width, period = int(m.group(1)), m.group(2)
        slog = os.path.join(args.results, f"sta_w{width}p{period}.log")
        if not os.path.isfile(slog):
            print(f"skipping WIDTH={width} PERIOD={period}: no {slog} (run make sta)", file=sys.stderr)
            continue
        row = {"width": width, "period_ns": float(period), "freq_mhz": 1e3 / float(period)}
        row.update(parse_yosys(open(ylog, errors="replace").read()))
        row.update(parse_sta(open(slog, errors="replace").read()))
        rows.append(row)

    if not rows:
        print("No results found. Run: make synth sta", file=sys.stderr)
        return 1
    rows.sort(key=lambda r: (r["period_ns"], r["width"]))
    with open(args.out, "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=COLUMNS, lineterminator="\n")
        w.writeheader()
        for r in rows:
            w.writerow({k: ("" if r.get(k) is None else (f"{r[k]:.6g}" if isinstance(r[k], float) else r[k]))
                        for k in COLUMNS})
    missing = [c for c in COLUMNS if all(r.get(c) is None for r in rows)]
    print(f"wrote {args.out}: {len(rows)} design points")
    if missing:
        print(f"WARNING: no values found for {', '.join(missing)} (log format changed?)", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
