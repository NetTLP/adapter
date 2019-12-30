set device_name "xc7k325tffg900-2"

set ip_name     "axi_10g_ethernet"
set ip_vendor   "xilinx.com"
set ip_version   "3.1"

set module_name "axi_10g_ethernet_0"

create_project -in_memory -part ${device_name}

create_ip -name $ip_name -vendor $ip_vendor -library ip -version $ip_version -module_name $module_name

set_property -dict [list                                   \
	CONFIG.Management_Interface {false}                \
	CONFIG.Statistics_Gathering {0}                    \
	CONFIG.SupportLevel {1}                            \
] [get_ips $module_name]

generate_target {instantiation_template} [get_ips $module_name]

#open_example_project -force -dir ${ip_name}_example_design [get_ips $module_name]

