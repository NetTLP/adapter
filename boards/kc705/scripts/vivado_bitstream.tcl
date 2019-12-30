set project_name [lindex $argv 0]
puts ${project_name}

set build_dir [lindex $argv 1]
puts ${build_dir}

open_checkpoint ${build_dir}/post_route.dcp
write_bitstream -force ${build_dir}/${project_name}.bit
write_debug_probes -force -file ${build_dir}/${project_name}.ltx
