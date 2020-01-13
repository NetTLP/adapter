set device_name "xc7k325tffg900-2"

set ip_name     "ila"
set ip_vendor   "xilinx.com"
set ip_version   "6.2"

set module_name "ila_0"

create_project -in_memory -part ${device_name}

create_ip -name $ip_name -vendor $ip_vendor -library ip -version $ip_version -module_name $module_name

set_property -dict [list                      \
	CONFIG.C_PROBE0_WIDTH {4}             \
	CONFIG.C_PROBE1_WIDTH {1}             \
	CONFIG.C_PROBE2_WIDTH {1}             \
	CONFIG.C_PROBE3_WIDTH {1}             \
	CONFIG.C_PROBE4_WIDTH {1}             \
	CONFIG.C_PROBE5_WIDTH {1}             \
	CONFIG.C_PROBE6_WIDTH {1}             \
	CONFIG.C_PROBE7_WIDTH {1}             \
	CONFIG.C_PROBE8_WIDTH {1}             \
	CONFIG.C_PROBE9_WIDTH {1}             \
	CONFIG.C_PROBE10_WIDTH {1}            \
	CONFIG.C_PROBE11_WIDTH {1}            \
	CONFIG.C_PROBE12_WIDTH {1}            \
	CONFIG.C_PROBE13_WIDTH {1}            \
	CONFIG.C_NUM_OF_PROBES {14}           \
] [get_ips $module_name]

generate_target {instantiation_template} [get_ips $module_name]

#open_example_project -force -dir ${ip_name}_example_design [get_ips $module_name]

