#!/bin/bash
# Smoke test for the ECE4203 image. CI runs it inside the freshly built container
# (as `user`, from the repo root); it can also be run by hand in a Codespace:
#   bash docker/smoke-test.sh            # everything (~10-15 min)
#   QUICK=1 bash docker/smoke-test.sh    # skip the ORFS place-and-route runs
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
OUT="${SMOKE_OUT:-/tmp/ece4203-smoke}"
mkdir -p "$OUT"
declare -a RESULTS=()
fails=0

# In CI (CI_ANNOTATE=1) also emit GitHub annotations, which stay readable through
# the API even when the raw job log is not.
annotate() {   # annotate <error|notice> <title> <text>
    [ -n "${CI_ANNOTATE:-}" ] || return 0
    local msg="${3:0:3500}"
    msg="${msg//'%'/'%25'}"; msg="${msg//$'\r'/}"; msg="${msg//$'\n'/'%0A'}"
    echo "::$1 title=$2::${msg}"
}

step() {   # step <name> <command...>
    local name="$1"; shift
    local log="${OUT}/${name}.log" t0=$SECONDS
    echo "::group::${name}"
    # Run in a background subshell: `set -e` is ignored inside an `if` condition.
    ( set -e; "$@" ) >"$log" 2>&1 &
    if wait $!; then
        RESULTS+=("PASS  ${name}  ($((SECONDS - t0)) s)")
    else
        RESULTS+=("FAIL  ${name}  ($((SECONDS - t0)) s)  -> ${log}")
        fails=$((fails + 1))
        annotate error "smoke: ${name} failed" "$(tail -n 40 "$log")"
    fi
    tail -n 25 "$log"
    echo "::endgroup::"
}

t_versions() {
    set -e
    for t in openroad sta yosys oss-yosys klayout iverilog vvp verilator gtkwave ngspice sby; do
        printf '%-10s %s\n' "$t" "$(command -v "$t")"
    done
    openroad -version
    yosys -V
    oss-yosys -V
    klayout -v
    # (no `| head`: with pipefail, the early close makes the producer fail)
    iverilog -V 2>&1 | sed -n 1p
    verilator --version
    ngspice -v 2>&1 | sed -n '/ngspice/{p;q}' 
    python3 -c "import matplotlib, pandas; print('matplotlib', matplotlib.__version__, 'pandas', pandas.__version__)"
    # The ORFS builds must win on PATH.
    [ "$(command -v yosys)" = /OpenROAD-flow-scripts/tools/install/yosys/bin/yosys ]
    [ "$(command -v openroad)" = /OpenROAD-flow-scripts/tools/install/OpenROAD/bin/openroad ]
    # FPGA tools must be gone.
    if command -v nextpnr-ice40; then echo "FPGA tools were not pruned"; exit 1; fi
    echo "PDK_ROOT=$PDK_ROOT PDK=$PDK open_pdks=$(cat "$PDK_ROOT/$PDK/OPEN_PDKS_VERSION")"
    du -sh /opt/oss-cad-suite "$PDK_ROOT"
}

t_desktop() {
    set -e
    bash scripts/desktop.sh ensure
    bash scripts/desktop.sh status
    [ "$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:6080/vnc.html)" = 200 ]
    pgrep -a Xtigervnc | grep -q -- '-SecurityTypes VncAuth'
    pgrep -x xfce4-session >/dev/null
}

wait_window() {   # wait_window <title regex> <seconds>: a mapped window >= 200x100
    local i tree
    for ((i = 0; i < $2; i++)); do
        tree="$(xwininfo -root -tree -display :1 2>/dev/null || true)"
        if awk -v re="$1" '$0 ~ re && match($0, /\) +[0-9]+x[0-9]+/) {
                split(substr($0, RSTART + 2, RLENGTH - 2), g, "x");
                if (g[1] + 0 >= 200 && g[2] + 0 >= 100) { print "found:", $0; f = 1 } }
                END { exit !f }' <<<"$tree"; then
            return 0
        fi
        sleep 1
    done
    grep -Ei "$1" <<<"$tree" || echo "no window matching $1"
    return 1
}

t_klayout_gui() {
    set -e
    DISPLAY=:1 klayout -e klayout/nand3_example.gds > "${OUT}/klayout-app.log" 2>&1 &
    local pid=$!
    wait_window '"[^"]*KLayout[^"]*"' 60 || { tail -n 20 "${OUT}/klayout-app.log"; kill "$pid"; return 1; }
    kill "$pid"
}

t_openroad_gui() {
    set -e
    local odb
    odb="$(ls openroad_flow/results/sky130hd/gcd/base/6_final.odb 2>/dev/null || true)"
    printf '%s\n' ${odb:+"read_db $odb"} > "${OUT}/gui.tcl"
    DISPLAY=:1 openroad -gui "${OUT}/gui.tcl" > "${OUT}/openroad-app.log" 2>&1 &
    local pid=$!
    wait_window '"[^"]*OpenROAD[^"]*"' 90 || { tail -n 20 "${OUT}/openroad-app.log"; kill "$pid"; return 1; }
    kill "$pid"
}

t_ngspice_sky130() {
    set -e
    local d="${OUT}/spice"
    mkdir -p "$d"
    # klayout/*.spice are LVS netlists (M devices); sky130 models are subcircuits (X).
    sed 's/^M/XM/' klayout/inverter.spice > "$d/inverter_sim.spice"
    cat > "$d/tb.spice" <<EOF
* inverter DC transfer, sky130 tt
.lib ${PDK_ROOT}/${PDK}/libs.tech/ngspice/sky130.lib.spice tt
.include ${d}/inverter_sim.spice
X1 vdd in out 0 inverter
Vdd vdd 0 1.8
Vin in 0 0
.dc Vin 0 1.8 0.01
.control
run
meas dc vm when v(out)=v(in)
.endc
.end
EOF
    # ngspice -b can exit non-zero even when the analysis ran; check the result.
    (cd "$d" && ngspice -b tb.spice > out.txt 2>&1) || true
    cat "$d/out.txt"
    awk '/^vm +=/ { v = $3 } END { exit !(v > 0.7 && v < 1.1) }' "$d/out.txt"
}

t_lab1() {
    set -e
    make -C lab1 clean
    make -C lab1 sim
    make -C lab1 sim_timed WIDTH=8 PERIOD=4
    grep -q 'tests passed' lab1/results/sim_timed_8_4.log
    make -C lab1 summary
}

t_orfs() {   # t_orfs <make args...>
    set -e
    make -C openroad_flow "$@"
}

step versions        t_versions
step desktop         t_desktop
step klayout-gui     t_klayout_gui
step ngspice-sky130  t_ngspice_sky130
step lab1            t_lab1
if [ -z "${QUICK:-}" ]; then
    step orfs-gcd-sky130hd   t_orfs DESIGN_CONFIG=/OpenROAD-flow-scripts/flow/designs/sky130hd/gcd/config.mk
    step orfs-registered-adder t_orfs DESIGN=registered_adder PLATFORM=sky130hd
fi
step openroad-gui    t_openroad_gui

echo
echo "================ smoke test summary ================"
printf '%s\n' "${RESULTS[@]}"
echo "logs: ${OUT}"
annotate notice "smoke test summary (${fails} failed)" "$(printf '%s\n' "${RESULTS[@]}")"
exit "$fails"
