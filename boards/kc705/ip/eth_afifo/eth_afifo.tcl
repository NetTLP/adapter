set device_name "xc7k325tffg900-2"

set ip_name     "fifo_generator"
set ip_vendor   "xilinx.com"
set ip_version   "13.2"

set module_name "eth_afifo"

create_project -in_memory -part ${device_name}

create_ip -name $ip_name -vendor $ip_vendor -library ip -version $ip_version -module_name $module_name

set_property -dict [list                                          \
	CONFIG.Component_Name {$module_name}                      \
	CONFIG.Fifo_Implementation {Independent_Clocks_Block_RAM} \
	CONFIG.Performance_Options {First_Word_Fall_Through}      \
	CONFIG.Input_Data_Width {79}                              \
	CONFIG.Input_Depth {2048}                                 \
	CONFIG.Output_Data_Width {79}                             \
	CONFIG.Output_Depth {2048}                                \
	CONFIG.Reset_Type {Asynchronous_Reset}                    \
	CONFIG.Full_Flags_Reset_Value {1}                         \
	CONFIG.Data_Count_Width {11}                              \
	CONFIG.Write_Data_Count_Width {11}                        \
	CONFIG.Read_Data_Count_Width {11}                         \
	CONFIG.Full_Threshold_Assert_Value {2047}                 \
	CONFIG.Full_Threshold_Negate_Value {2046}                 \
	CONFIG.Empty_Threshold_Assert_Value {4}                   \
	CONFIG.Empty_Threshold_Negate_Value {5}                   \
	CONFIG.Enable_Safety_Circuit {true}                       \
] [get_ips $module_name]

generate_target {instantiation_template} [get_ips $module_name]

#open_example_project -force -dir ${ip_name}_example_design [get_ips $module_name]

