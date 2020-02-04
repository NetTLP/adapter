set project_name [lindex $argv 0]
puts ${project_name}

set build_dir [lindex $argv 1]
puts ${build_dir}

open_checkpoint ${build_dir}/post_place.dcp

phys_opt_design
route_design

report_timing -file ${build_dir}/post_route_timing.txt -nworst 5
report_timing_summary -file ${build_dir}/post_route_timing_summary.txt
report_drc -file ${build_dir}/post_route_drc.txt

write_checkpoint -force ${build_dir}/post_route

write_verilog -force ${build_dir}/post_route_netlist.v
write_xdc -no_fixed_only -force ${build_dir}/post_route_constr.xdc
