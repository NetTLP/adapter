set RTL_SRC [lindex $argv 0]
puts "INFO: RTL_SRC"
puts ${RTL_SRC}
set IP_SRC [lindex $argv 1]
puts "INFO: IP_SRC"
puts ${IP_SRC}
set XDC_SRC [lindex $argv 2]
puts "INFO: XDC_SRC"
puts ${XDC_SRC}

set design top
set device xc7k325t-2-ffg900

# Project Settings
create_project -part ${device} -in_memory

set_property target_language Verilog [current_project]
set_property default_lib work [current_project]
#set_property verilog_define { {USE_DDR3_FIFO=1} {USE_XPHY=1} {USE_PVTMON=1} } [current_fileset]

update_ip_catalog -rebuild

puts "INFO: Import XDC Sources ..."
read_xdc ${XDC_SRC}

puts "INFO: Import RTL Sources ..."
foreach file $RTL_SRC {
	# verilog
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

puts "INFO: Create IPs"

#create_ip -name axis_data_fifo -dir ip_catalog/ -vendor xilinx.com -library ip -version 1.1 -module_name axis_data_fifo_0
#set_property -dict [list CONFIG.TDATA_NUM_BYTES {8}\
#                         CONFIG.TUSER_WIDTH {1}  \
#                         CONFIG.FIFO_DEPTH  {16} \
#                         CONFIG.FIFO_MODE   {1}  \
#						 CONFIG.HAS_TREADY  {1}  \
#                         CONFIG.HAS_TKEEP   {1}  \
#						 CONFIG.HAS_TLAST   {1}] [get_ips axis_data_fifo_0]
#
#read_ip ip_catalog/axis_data_fifo_0/axis_data_fifo_0.xci
#synth_ip -force [get_files ip_catalog/axis_data_fifo_0/axis_data_fifo_0.xci]

puts "INFO: Import IP Sources ..."
foreach file ${IP_SRC} {
	read_ip ${file}
	set_property GENERATE_SYNTH_CHECKPOINT FALSE [get_files ${file}]
}
generate_target {synthesis simulation} [get_ips]

#set_property strategy Flow_PerfOptimized_High [get_runs synth_1]
#set_property steps.phys_opt_design.is_enabled true [get_runs impl_1]
#set_property strategy Performance_Explore [get_runs impl_1]

synth_design -name kc705-tmpl -part ${device} -top top

opt_design

report_utilization -file post_syn_util.txt
report_timing -sort_by group -max_paths 5 -path_type summary -file post_synth_timing.txt
write_checkpoint -force post_syn

