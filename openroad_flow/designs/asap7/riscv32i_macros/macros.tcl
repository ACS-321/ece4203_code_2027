# Hand placement of the four 8.36 x 42 um fakeram7_256x32 macros (dmem.dmem0..3).
# Their pins are all on the macro's LEFT edge (x = 0 in the LEF), so they are
# mirrored (MY) to face the standard-cell area on the right.
# Two columns on the left of the core, 9 um apart (more than 2 x the 4 um halo).
place_macro -macro_name dmem.dmem0 -location {8 8}  -orientation MY
place_macro -macro_name dmem.dmem1 -location {8 60} -orientation MY
place_macro -macro_name dmem.dmem2 -location {25 8}  -orientation MY
place_macro -macro_name dmem.dmem3 -location {25 60} -orientation MY
