set project_name [lindex $argv 0]
puts ${project_name}

set build_dir [lindex $argv 1]
puts ${build_dir}

set device_name [lindex $argv 2]
puts ${device_name}

set RTL_SRCS [lindex $argv 3]
puts ${RTL_SRCS}

set XCI_SRCS [lindex $argv 4]
puts ${XCI_SRCS}

set XDC_SRCS [lindex $argv 5]
puts ${XDC_SRCS}


# Project Settings
create_project -name ${project_name} -force -part ${device_name}

set_property target_language Verilog [current_project]
set_property default_lib work [current_project]
#set_property board_part ${board_part} [current_project]

update_ip_catalog -rebuild

puts "INFO: Import XDC Sources ..."
read_xdc ${XDC_SRCS}

puts "INFO: Import RTL Sources ..."
foreach file $RTL_SRCS {
	if {[string match *.v $file]} {
		puts "INFO: Import $file (Verilog)"
		read_verilog $file
	} elseif {[string match *.sv $file]} {
		puts "INFO: Import $file (SystemVerilog)"
		read_verilog -sv $file
	} elseif {[string match *.vhd $file] || [string match *.vhdl $file]} {
		puts "INFO: Import $file (VHDL)"
		read_vhdl $file
	} else {
		puts "INFO: Unsupported File $file"    
	}
}

puts "INFO: Import IP Sources ..."
foreach file ${XCI_SRCS} {
	read_ip $file
	set_property GENERATE_SYNTH_CHECKPOINT FALSE [get_files ${file}]
}
generate_target {synthesis} [get_ips]

#set_property strategy Flow_PerfOptimized_High [get_runs synth_1]
#set_property steps.phys_opt_design.is_enabled true [get_runs impl_1]
#set_property strategy Performance_Explore [get_runs impl_1]

synth_design -name ${project_name} -part ${device_name} -top top

opt_design

report_utilization -file ${build_dir}/post_syn_util.txt
report_timing -sort_by group -max_paths 5 -path_type summary -file ${build_dir}/post_synth_timing.txt
write_checkpoint -force ${build_dir}/post_syn

