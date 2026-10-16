# Core power grid with a core ring that connects to the supply pads.
# (From ORFS i2c-gpio-expander/pdn.tcl, without its macro grid.)
add_global_connection -net {VDD} -pin_pattern {^VDD$} -power
add_global_connection -net {VDD} -pin_pattern {^VDDPE$}
add_global_connection -net {VDD} -pin_pattern {^VDDCE$}
add_global_connection -net {VSS} -pin_pattern {^VSS$} -ground
add_global_connection -net {VSS} -pin_pattern {^VSSE$}
global_connect

set_voltage_domain -name {CORE} -power {VDD} -ground {VSS}

define_pdn_grid -name {grid} -voltage_domains {CORE}
# Standard-cell rails on Metal1, following the rows
add_pdn_stripe -grid {grid} -layer {Metal1} -width {0.44} -pitch {7.56} -offset {0} \
  -followpins -extend_to_core_ring
# Core ring around the core area; -connect_to_pads joins it to the vdd/vss pads
add_pdn_ring -grid {grid} -layers {Metal5 TopMetal1} -widths {8.0} -spacings {5.0} \
  -core_offsets {4.5} -connect_to_pads
add_pdn_stripe -grid {grid} -layer {TopMetal1} -width {4.0} -pitch {60.0} -offset {10.0} \
  -extend_to_core_ring
add_pdn_stripe -grid {grid} -layer {TopMetal2} -width {4.0} -pitch {60.0} -offset {10.0} \
  -extend_to_core_ring
add_pdn_connect -grid {grid} -layers {Metal1 TopMetal1}
add_pdn_connect -grid {grid} -layers {Metal5 TopMetal1}
add_pdn_connect -grid {grid} -layers {Metal5 TopMetal2}
add_pdn_connect -grid {grid} -layers {TopMetal1 TopMetal2}
