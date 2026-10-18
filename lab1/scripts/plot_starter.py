#!/usr/bin/env python3
"""Assignment 1 starter: plot the Lab 1 sweep from results/summary.csv.

    make csv WIDTHS="4 8 16 24 32 48 64" PERIODS="2 4 8 16"
    make plot                      # or: python3 scripts/plot_starter.py results/summary.csv

Writes results/area_vs_width.png, results/power_vs_width.png and
results/power_vs_freq.png with the measured points only.

YOUR JOB (see ASSIGNMENT1.md): add the straight-line fits, report the slopes
with units, and explain where (and why) the points leave the straight line.
Look for the lines marked TODO.
"""
import sys

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

# One color AND one marker per series, in a fixed order (colorblind-safe palette).
COLORS = ["#2a78d6", "#eb6834", "#1baf7a", "#eda100", "#e87ba4", "#6250d6"]
MARKERS = ["o", "s", "^", "D", "v", "P"]


def style(ax, title, xlabel, ylabel):
    ax.set_title(title, loc="left")
    ax.set_xlabel(xlabel)
    ax.set_ylabel(ylabel)
    ax.grid(color="#e4e3df", linewidth=0.6)
    for side in ("top", "right"):
        ax.spines[side].set_visible(False)


def main(path):
    df = pd.read_csv(path)
    periods = sorted(df["period_ns"].unique())
    widths = sorted(df["width"].unique())

    # ---- 1. Area vs width, one series per clock period -------------------
    fig, ax = plt.subplots(figsize=(6.5, 4.2), constrained_layout=True)
    for i, p in enumerate(periods):
        d = df[df["period_ns"] == p].sort_values("width")
        ax.plot(d["width"], d["area_um2"], marker=MARKERS[i % 6], color=COLORS[i % 6],
                linewidth=1.5, label=f"T = {p:g} ns")
        # TODO: fit area = m*width + c to this period's points (np.polyfit(x, y, 1))
        #       and plot the fitted line. Print m in um^2/bit.
        #       Does one straight line fit every period? Over which widths?
    style(ax, "Cell area vs adder width", "WIDTH (bits)", "Cell area (µm²)")
    ax.legend(frameon=False)
    fig.savefig("results/area_vs_width.png", dpi=150)

    # ---- 2. Power vs width, one series per clock period -------------------
    fig, ax = plt.subplots(figsize=(6.5, 4.2), constrained_layout=True)
    for i, p in enumerate(periods):
        d = df[df["period_ns"] == p].sort_values("width")
        ax.plot(d["width"], d["power_total_w"] * 1e6, marker=MARKERS[i % 6], color=COLORS[i % 6],
                linewidth=1.5, label=f"T = {p:g} ns")
        # TODO: fit power = m*width + c (in µW) and report m in µW/bit.
    style(ax, "Total power vs adder width", "WIDTH (bits)", "Total power (µW)")
    ax.legend(frameon=False)
    fig.savefig("results/power_vs_width.png", dpi=150)

    # ---- 3. Power vs clock frequency, one series per width ----------------
    fig, ax = plt.subplots(figsize=(6.5, 4.2), constrained_layout=True)
    for i, w in enumerate(widths[-6:]):
        d = df[df["width"] == w].sort_values("freq_mhz")
        ax.plot(d["freq_mhz"], d["power_total_w"] * 1e6, marker=MARKERS[i % 6], color=COLORS[i % 6],
                linewidth=1.5, label=f"WIDTH = {w}")
        # TODO: fit power = k*f + P0. What is k (µW/MHz), and what is P0?
        #       Compare k / WIDTH across widths.
    style(ax, "Total power vs clock frequency", "Clock frequency (MHz)", "Total power (µW)")
    ax.legend(frameon=False)
    fig.savefig("results/power_vs_freq.png", dpi=150)

    print("wrote results/area_vs_width.png, results/power_vs_width.png, results/power_vs_freq.png")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else "results/summary.csv"))
