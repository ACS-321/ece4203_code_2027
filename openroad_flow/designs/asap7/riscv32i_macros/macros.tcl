# Hand placement of the four 8.36 x 42 um fakeram7_256x32 macros.
# Their pins are all on the macro's LEFT edge (x = 0 in the LEF), so they are
# mirrored (MY) to face the standard-cell area on the right.
# Two columns on the left of the core, 9 um apart (more than 2 x the 4 um halo).
#
# The macro instance names depend on how the hierarchy was flattened, so look
# them up (any instance whose master is a BLOCK) and print them.
set macros {}
foreach inst [[ord::get_db_block] getInsts] {
  if { [[$inst getMaster] isBlock] } { lappend macros [$inst getName] }
}
set macros [lsort $macros]
puts "SRAM macros: $macros"
if { [llength $macros] != 4 } { error "expected 4 SRAM macros, found [llength $macros]" }

foreach name $macros loc {{8 8} {8 60} {25 8} {25 60}} {
  place_macro -macro_name $name -location $loc -orientation MY
}
