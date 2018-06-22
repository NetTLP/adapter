open_checkpoint post_place.dcp

phys_opt_design
route_design

report_timing -file post_route_timing.txt -nworst 5
report_timing_summary -file post_route_timing_summary.txt
report_drc -file post_route_drc.txt

write_checkpoint -force post_route

write_verilog -force post_route_netlist.v
write_xdc -no_fixed_only -force post_route_constr.xdc
