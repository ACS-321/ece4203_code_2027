# ECE4203 wrapper around OpenROAD-flow-scripts (ORFS) in the image.
#
# Run from this directory:
#   make                                  # registered_adder on sky130hd, full flow
#   make DESIGN=gcd                       # any ORFS design (looked up in the image)
#   make DESIGN=gcd PLATFORM=asap7 synth  # any ORFS target: synth floorplan place cts route finish ...
#   make DESIGN=gcd gui_final             # open the finished layout in the OpenROAD GUI
#   make DESIGN=gcd clean_all
#   make list                             # designs available here and in ORFS
#
# Comparing two technologies (sky130hd = 130 nm, asap7 = 7 nm predictive):
#   make DESIGN=gcd both                  # run DESIGN on every platform in PLATFORMS
#   make ladder                           # every design in LADDER on every platform
#   make metrics                          # metrics/metrics.csv + plots from finished runs
#
# Designs under ./designs/<platform>/<design>/ win over ORFS's own. Results, logs and
# reports go to ./results, ./logs, ./reports and ./objects in this directory
# (WORK_HOME). The ORFS flow itself (scripts, platforms) is not copied here; it is
# used from the image so it always matches the installed OpenROAD/yosys.

ORFS_FLOW ?= /OpenROAD-flow-scripts/flow
PLATFORM  ?= sky130hd
DESIGN    ?= registered_adder

LOCAL_CONFIG := $(CURDIR)/designs/$(PLATFORM)/$(DESIGN)/config.mk
ifneq ($(wildcard $(LOCAL_CONFIG)),)
DESIGN_CONFIG ?= $(LOCAL_CONFIG)
else
DESIGN_CONFIG ?= $(ORFS_FLOW)/designs/$(PLATFORM)/$(DESIGN)/config.mk
endif
# config.mk lives at <DESIGN_HOME>/<platform>/<design>/config.mk
DESIGN_HOME ?= $(abspath $(dir $(DESIGN_CONFIG))/../..)
WORK_HOME   ?= $(CURDIR)

PLATFORMS ?= sky130hd asap7
# Small -> medium. Add ibex for a bigger core (~30-60 min per platform):
#   make ladder LADDER="registered_adder gcd riscvsingle aes ibex"
LADDER    ?= registered_adder gcd riscvsingle aes

ORFS_MAKE = $(MAKE) --no-print-directory -f $(ORFS_FLOW)/Makefile \
    FLOW_HOME=$(ORFS_FLOW) \
    DESIGN_CONFIG=$(abspath $(DESIGN_CONFIG)) \
    DESIGN_HOME=$(DESIGN_HOME) \
    WORK_HOME=$(WORK_HOME)

.DEFAULT_GOAL := all
.PHONY: all list help both ladder metrics

all:
	@test -f "$(DESIGN_CONFIG)" || { echo "No config.mk for DESIGN=$(DESIGN) PLATFORM=$(PLATFORM) ($(DESIGN_CONFIG)). Try: make list"; exit 1; }
	$(ORFS_MAKE) all

list:
	@echo "Local designs (./designs):"
	@cd designs && ls -d */*/ 2>/dev/null | sed 's#/$$##; s#^#  #' || true
	@echo "ORFS designs ($(ORFS_FLOW)/designs), use DESIGN=<name> PLATFORM=<platform>:"
	@cd $(ORFS_FLOW)/designs && for p in sky130hd asap7 nangate45 ihp-sg13g2 gf180; do \
	    printf "  %-11s" $$p; ls -d $$p/*/ 2>/dev/null | xargs -n1 basename | tr '\n' ' '; echo; done

both:
	@set -e; for p in $(PLATFORMS); do \
	    echo "=== $(DESIGN) on $$p ==="; \
	    $(MAKE) --no-print-directory DESIGN=$(DESIGN) PLATFORM=$$p all; \
	done

# Keeps going after a failed run so one problem doesn't stop the whole ladder;
# the summary at the end lists what failed.
ladder:
	@failed=""; for d in $(LADDER); do for p in $(PLATFORMS); do \
	    echo "=== $$d on $$p ==="; \
	    $(MAKE) --no-print-directory DESIGN=$$d PLATFORM=$$p all || failed="$$failed $$d/$$p"; \
	done; done; \
	$(MAKE) --no-print-directory metrics; \
	if [ -n "$$failed" ]; then echo "FAILED:$$failed"; exit 1; fi

metrics:
	python3 $(CURDIR)/../scripts/orfs_metrics.py --work $(WORK_HOME) --out $(WORK_HOME)/metrics

help:
	@sed -n '3,19p' $(firstword $(MAKEFILE_LIST))

# Everything else is passed straight to ORFS.
Makefile: ;
%:
	$(ORFS_MAKE) $@
