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

ORFS_MAKE = $(MAKE) --no-print-directory -f $(ORFS_FLOW)/Makefile \
    FLOW_HOME=$(ORFS_FLOW) \
    DESIGN_CONFIG=$(abspath $(DESIGN_CONFIG)) \
    DESIGN_HOME=$(DESIGN_HOME) \
    WORK_HOME=$(WORK_HOME)

.DEFAULT_GOAL := all
.PHONY: all list help

all:
	@test -f "$(DESIGN_CONFIG)" || { echo "No config.mk for DESIGN=$(DESIGN) PLATFORM=$(PLATFORM) ($(DESIGN_CONFIG)). Try: make list"; exit 1; }
	$(ORFS_MAKE) all

list:
	@echo "Local designs (./designs):"
	@cd designs && ls -d */*/ 2>/dev/null | sed 's#/$$##; s#^#  #' || true
	@echo "ORFS designs ($(ORFS_FLOW)/designs), use DESIGN=<name> PLATFORM=<platform>:"
	@cd $(ORFS_FLOW)/designs && for p in sky130hd asap7 nangate45 ihp-sg13g2 gf180; do \
	    printf "  %-11s" $$p; ls -d $$p/*/ 2>/dev/null | xargs -n1 basename | tr '\n' ' '; echo; done

help:
	@sed -n '3,13p' $(firstword $(MAKEFILE_LIST))

# Everything else is passed straight to ORFS.
Makefile: ;
%:
	$(ORFS_MAKE) $@
