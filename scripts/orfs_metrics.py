#!/usr/bin/env python3
"""Collect ORFS results into a CSV, a Markdown table and comparison plots.

Reads every finished (or partial) run under WORK_HOME:
    logs/<platform>/<design>/<variant>/*.json   per-stage metrics written by the flow
    logs/<platform>/<design>/<variant>/*.log    "Elapsed time ... Peak memory" lines
    results/<platform>/<design>/<variant>/*.sdc clock period

Writes to --out (default WORK_HOME/metrics):
    metrics.csv       one row per (design, platform, variant)
    metrics.md        the same as a Markdown table, plus sky130hd/asap7 ratios
    compare.png       small multiples: one panel per metric, bars per platform
    scaling.png       sky130hd / asap7 ratio per design for area, power, Fmax

All values are normalized to one set of units, regardless of platform:
    time ns, frequency MHz, area um^2, power mW, wirelength um, runtime s.
(asap7 reports times in ps; sky130hd and the other ORFS platforms in ns.)

Usage:
    python3 scripts/orfs_metrics.py --work openroad_flow
    make -C openroad_flow metrics
"""
import argparse
import csv
import glob
import json
import math
import os
import re
import sys

# Platform time unit in the liberty/SDC files, as a multiplier to ns.
TIME_UNIT_NS = {"asap7": 1e-3}

# Each output metric: list of ORFS metric keys to try, in order.
# The first one present wins. Key names follow ORFS "METRICS2.1".
KEYS = {
    "instance_count": ["finish__design__instance__count__stdcell", "finish__design__instance__count"],
    "cell_area_um2": ["finish__design__instance__area__stdcell", "finish__design__instance__area"],
    "core_area_um2": ["finish__design__core__area", "floorplan__design__core__area"],
    "die_area_um2": ["finish__design__die__area", "floorplan__design__die__area"],
    "utilization": ["finish__design__instance__utilization__stdcell", "finish__design__instance__utilization"],
    "setup_ws": ["finish__timing__setup__ws", "detailedroute__timing__setup__ws", "cts__timing__setup__ws"],
    "setup_tns": ["finish__timing__setup__tns"],
    "hold_ws": ["finish__timing__hold__ws"],
    "power_w": ["finish__power__total"],
    "wirelength_um": ["detailedroute__route__wirelength", "globalroute__route__wirelength"],
    "drc_errors": ["detailedroute__route__drc_errors"],
    "synth_area_um2": ["synth__design__instance__area__stdcell", "synth__design__instance__area"],
}
# Fmax metric names carry the clock name, e.g. finish__timing__fmax__clock:core_clock
FMAX_RE = re.compile(r"^finish__timing__fmax(__clock:.*)?$")

ELAPSED_RE = re.compile(
    r"Elapsed time:\s*(?:(\d+):)?(\d+):(\d+(?:\.\d+)?)\[h:\]min:sec.*?Peak memory:\s*(\d+)KB")

COLUMNS = [
    "design", "platform", "variant", "stage", "instance_count", "cell_area_um2",
    "core_area_um2", "die_area_um2", "utilization", "clock_period_ns", "setup_ws_ns",
    "setup_tns_ns", "hold_ws_ns", "fmax_mhz", "power_mw", "wirelength_um",
    "drc_errors", "runtime_s", "peak_mem_mb",
]

STAGES = ["1_synth", "2_floorplan", "3_place", "4_cts", "5_route", "6_finish"]


def num(v):
    try:
        f = float(v)
        # OpenSTA reports +/-1e39 for "no constrained paths"; treat as missing.
        return f if math.isfinite(f) and abs(f) < 1e30 else None
    except (TypeError, ValueError):
        return None


def first(metrics, keys):
    for k in keys:
        if k in metrics and num(metrics[k]) is not None:
            return num(metrics[k])
    return None


def load_metrics(log_dir):
    merged = {}
    for f in sorted(glob.glob(os.path.join(log_dir, "*.json"))):
        try:
            with open(f) as fh:
                data = json.load(fh)
        except (OSError, ValueError):
            continue
        if isinstance(data, dict):
            merged.update(data)
    return merged


def runtime(log_dir):
    total, peak = 0.0, 0.0
    for f in glob.glob(os.path.join(log_dir, "*.log")):
        try:
            text = open(f, errors="replace").read()
        except OSError:
            continue
        for h, m, s, kb in ELAPSED_RE.findall(text):
            total += int(h or 0) * 3600 + int(m) * 60 + float(s)
            peak = max(peak, int(kb) / 1024.0)
    return (round(total, 1) if total else None), (round(peak) if peak else None)


def clock_period(results_dir):
    """Period of the first real (port-attached) clock, in platform units."""
    for name in ("6_final.sdc", "2_floorplan.sdc", "1_synth.sdc"):
        f = os.path.join(results_dir, name)
        if not os.path.isfile(f):
            continue
        for line in open(f, errors="replace"):
            if "create_clock" in line and "get_ports" in line:
                m = re.search(r"-period\s+([0-9.eE+-]+)", line)
                if m:
                    return float(m.group(1))
    return None


def last_stage(log_dir, results_dir):
    done = [s for s in STAGES if glob.glob(os.path.join(results_dir, s[0] + "_*"))]
    return done[-1] if done else ""


def collect(work):
    rows = []
    for log_dir in sorted(glob.glob(os.path.join(work, "logs", "*", "*", "*"))):
        if not os.path.isdir(log_dir):
            continue
        platform, design, variant = log_dir.split(os.sep)[-3:]
        results_dir = os.path.join(work, "results", platform, design, variant)
        m = load_metrics(log_dir)
        unit = TIME_UNIT_NS.get(platform, 1.0)
        row = {"design": design, "platform": platform, "variant": variant,
               "stage": last_stage(log_dir, results_dir)}
        for col, keys in KEYS.items():
            row[col] = first(m, keys)
        period = clock_period(results_dir)
        row["clock_period_ns"] = period * unit if period is not None else None
        for src, dst in (("setup_ws", "setup_ws_ns"), ("setup_tns", "setup_tns_ns"),
                         ("hold_ws", "hold_ws_ns")):
            row[dst] = row.pop(src) * unit if row.get(src) is not None else None
        fmax = next((num(v) for k, v in m.items() if FMAX_RE.match(k) and num(v)), None)
        if fmax:  # reported in Hz
            row["fmax_mhz"] = fmax / 1e6
        elif row["clock_period_ns"] and row["setup_ws_ns"] is not None:
            achievable = row["clock_period_ns"] - row["setup_ws_ns"]
            row["fmax_mhz"] = 1e3 / achievable if achievable > 0 else None
        else:
            row["fmax_mhz"] = None
        row["power_mw"] = row.pop("power_w") * 1e3 if row.get("power_w") is not None else None
        row.pop("synth_area_um2", None)
        row["runtime_s"], row["peak_mem_mb"] = runtime(log_dir)
        rows.append(row)
    return rows


def fmt(v, col):
    if v is None:
        return ""
    if isinstance(v, str):
        return v
    if col in ("instance_count", "drc_errors", "peak_mem_mb"):
        return str(int(round(v)))
    if col == "utilization":
        return f"{v:.3g}"
    return f"{v:.4g}"


def write_csv(rows, path):
    with open(path, "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=COLUMNS, extrasaction="ignore", lineterminator="\n")
        w.writeheader()
        for r in rows:
            w.writerow({c: fmt(r.get(c), c) for c in COLUMNS})


def ratios(rows, a="sky130hd", b="asap7"):
    by = {(r["design"], r["platform"]): r for r in rows if r["variant"] == "base"}
    out = []
    for d in sorted({r["design"] for r in rows}):
        ra, rb = by.get((d, a)), by.get((d, b))
        if not ra or not rb:
            continue
        def q(col):
            x, y = ra.get(col), rb.get(col)
            return x / y if x and y else None
        out.append({"design": d, "cell_area": q("cell_area_um2"), "power": q("power_mw"),
                    "fmax": q("fmax_mhz"), "wirelength": q("wirelength_um")})
    return out


def write_md(rows, path):
    cols = ["design", "platform", "stage", "instance_count", "cell_area_um2", "utilization",
            "clock_period_ns", "setup_ws_ns", "fmax_mhz", "power_mw", "wirelength_um",
            "runtime_s"]
    lines = ["| " + " | ".join(cols) + " |", "|" + "---|" * len(cols)]
    for r in rows:
        lines.append("| " + " | ".join(fmt(r.get(c), c) for c in cols) + " |")
    rat = ratios(rows)
    if rat:
        lines += ["", "**sky130hd / asap7** (same RTL; >1 means sky130hd is larger/higher)", "",
                  "| design | cell area | power | Fmax | wirelength |", "|---|---|---|---|---|"]
        for r in rat:
            lines.append("| {} | {} | {} | {} | {} |".format(
                r["design"], *(f"{r[k]:.3g}x" if r[k] else "" for k in
                               ("cell_area", "power", "fmax", "wirelength"))))
    open(path, "w").write("\n".join(lines) + "\n")


# Validated categorical palette (dataviz skill reference palette, slots 1-2):
# blue/orange pass lightness, chroma, CVD and contrast checks on the light surface.
COLORS = {"sky130hd": "#2a78d6", "asap7": "#eb6834"}
EXTRA = ["#1baf7a", "#eda100", "#e87ba4", "#008300", "#6250d6", "#e34948"]
INK, INK2, GRID, SURFACE = "#0b0b0b", "#52514e", "#e4e3df", "#fcfcfb"


def plot(rows, out_dir):
    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except ImportError:
        print("matplotlib not installed; skipping plots", file=sys.stderr)
        return []
    rows = [r for r in rows if r["variant"] == "base"]
    if not rows:
        return []
    designs = list(dict.fromkeys(r["design"] for r in sorted(rows, key=lambda r: r.get("cell_area_um2") or 0)))
    # Fixed order (and color) per platform, never by data order.
    seen = set(r["platform"] for r in rows)
    platforms = [p for p in COLORS if p in seen] + sorted(seen - set(COLORS))
    color = {p: COLORS.get(p, EXTRA[i % len(EXTRA)]) for i, p in enumerate(platforms)}
    by = {(r["design"], r["platform"]): r for r in rows}

    plt.rcParams.update({
        "font.size": 9, "axes.edgecolor": GRID, "axes.labelcolor": INK2,
        "xtick.color": INK2, "ytick.color": INK2, "axes.titlecolor": INK,
        "figure.facecolor": SURFACE, "axes.facecolor": SURFACE, "savefig.facecolor": SURFACE,
    })
    panels = [("cell_area_um2", "Cell area (µm²)", True), ("power_mw", "Total power (mW)", True),
              ("fmax_mhz", "Fmax (MHz)", True), ("wirelength_um", "Routed wirelength (µm)", True),
              ("utilization", "Utilization", False), ("runtime_s", "Flow runtime (s)", True)]
    fig, axes = plt.subplots(2, 3, figsize=(12, 6.5), constrained_layout=True)
    width = 0.8 / max(1, len(platforms))
    for ax, (col, title, logy) in zip(axes.flat, panels):
        for i, p in enumerate(platforms):
            xs, ys = [], []
            for j, d in enumerate(designs):
                v = by.get((d, p), {}).get(col)
                if v is not None and (v > 0 or not logy):
                    xs.append(j + (i - (len(platforms) - 1) / 2) * width)
                    ys.append(v)
            ax.bar(xs, ys, width=width * 0.9, color=color[p], label=p, zorder=2,
                   edgecolor=SURFACE, linewidth=1)
        ax.set_title(title, loc="left", fontsize=10)
        ax.set_xticks(range(len(designs)))
        ax.set_xticklabels(designs, rotation=30, ha="right")
        if logy:
            ax.set_yscale("log")
        ax.grid(axis="y", color=GRID, linewidth=0.6, zorder=0)
        ax.tick_params(length=0)
        for s in ("top", "right", "left"):
            ax.spines[s].set_visible(False)
    axes.flat[0].legend(frameon=False, loc="upper left")
    fig.suptitle("Same designs, two technologies", x=0.01, ha="left", color=INK, fontsize=12)
    made = [os.path.join(out_dir, "compare.png")]
    fig.savefig(made[0], dpi=150)
    plt.close(fig)

    rat = ratios(rows)
    if rat:
        fig, axes = plt.subplots(1, 3, figsize=(12, 3.4), constrained_layout=True)
        for ax, (k, title) in zip(axes, [("cell_area", "Cell area: sky130hd / asap7"),
                                         ("power", "Power: sky130hd / asap7"),
                                         ("fmax", "Fmax: sky130hd / asap7")]):
            ds = [r["design"] for r in rat if r[k]]
            vs = [r[k] for r in rat if r[k]]
            # Bars grow from the 1x line: up = sky130hd larger, down = asap7 larger.
            ax.bar(range(len(ds)), [v - 1 for v in vs], bottom=1, width=0.6,
                   color=COLORS["sky130hd"], zorder=2)
            for x, v in zip(range(len(ds)), vs):
                up = v >= 1
                ax.annotate(f"{v:.2g}×", (x, v), ha="center", va="bottom" if up else "top",
                            fontsize=8, color=INK2, xytext=(0, 2 if up else -2),
                            textcoords="offset points")
            lo, hi = min(vs + [1]), max(vs + [1])
            ax.set_ylim(lo / 1.6, hi * 1.6)
            ax.axhline(1, color=INK2, linewidth=0.8, zorder=1)
            ax.set_xticks(range(len(ds)))
            ax.set_xticklabels(ds, rotation=30, ha="right")
            ax.set_yscale("log")
            ax.set_title(title, loc="left", fontsize=10)
            ax.grid(axis="y", color=GRID, linewidth=0.6, zorder=0)
            ax.tick_params(length=0)
            for s in ("top", "right", "left"):
                ax.spines[s].set_visible(False)
        made.append(os.path.join(out_dir, "scaling.png"))
        fig.savefig(made[-1], dpi=150)
        plt.close(fig)
    return made


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--work", default="openroad_flow", help="ORFS WORK_HOME (has logs/, results/)")
    ap.add_argument("--out", default=None, help="output dir (default WORK_HOME/metrics)")
    args = ap.parse_args()
    out = args.out or os.path.join(args.work, "metrics")
    rows = collect(args.work)
    if not rows:
        print(f"No ORFS runs found under {args.work}/logs", file=sys.stderr)
        return 1
    os.makedirs(out, exist_ok=True)
    write_csv(rows, os.path.join(out, "metrics.csv"))
    write_md(rows, os.path.join(out, "metrics.md"))
    made = plot(rows, out)
    print(open(os.path.join(out, "metrics.md")).read())
    print("wrote", ", ".join([os.path.join(out, "metrics.csv"), os.path.join(out, "metrics.md")] + made))
    return 0


if __name__ == "__main__":
    sys.exit(main())
