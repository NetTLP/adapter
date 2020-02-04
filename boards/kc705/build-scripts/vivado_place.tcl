set project_name [lindex $argv 0]
puts ${project_name}

set build_dir [lindex $argv 1]
puts ${build_dir}

open_checkpoint ${build_dir}/post_syn.dcp

opt_design
power_opt_design
place_design

report_utilization -file ${build_dir}/post_place_util.txt
report_timing -file ${build_dir}/post_place_timing.txt -nworst 5
write_checkpoint -force ${build_dir}/post_place
