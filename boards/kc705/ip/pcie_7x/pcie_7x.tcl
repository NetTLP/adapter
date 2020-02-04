set device_name "xc7k325tffg900-2"

set ip_name     "pcie_7x"
set ip_vendor   "xilinx.com"
set ip_version   "3.3"

set module_name "pcie_7x"

create_project -in_memory -part ${device_name}

create_ip -name $ip_name -vendor $ip_vendor -library ip -version $ip_version -module_name $module_name

set_property -dict [list                       \
	CONFIG.mode_selection {Advanced}       \
	CONFIG.Maximum_Link_Width {X4}         \
	CONFIG.Link_Speed {5.0_GT/s}           \
	CONFIG.User_Clk_Freq {250}             \
	CONFIG.Bar0_Size {16}                  \
	CONFIG.Bar2_Enabled {true}             \
	CONFIG.Bar2_64bit {true}               \
	CONFIG.Bar2_Prefetchable {true}        \
	CONFIG.Bar2_Scale {Megabytes}          \
	CONFIG.Bar2_Size {256}                 \
	CONFIG.Bar2_Type {Memory}              \
	CONFIG.Bar4_Enabled {true}             \
	CONFIG.Bar4_64bit {true}               \
	CONFIG.Bar4_Prefetchable {true}        \
	CONFIG.Bar4_Scale {Megabytes}          \
	CONFIG.Bar4_Size {256}                 \
	CONFIG.Bar4_Type {Memory}              \
	CONFIG.Vendor_ID {3776}                \
	CONFIG.Device_ID {8022}                \
	CONFIG.Subsystem_Vendor_ID {3776}      \
	CONFIG.Subsystem_ID {8022}             \
	CONFIG.Interface_Width {64_bit}        \
	CONFIG.Max_Payload_Size {512_bytes}    \
	CONFIG.Trgt_Link_Speed {4'h2}          \
	CONFIG.Legacy_Interrupt {NONE}         \
	CONFIG.IntX_Generation {false}         \
	CONFIG.MSI_Enabled {false}             \
	CONFIG.MSIx_Table_BIR {BAR_3:2}        \
	CONFIG.MSIx_PBA_BIR {BAR_3:2}          \
	CONFIG.MSIx_Enabled {true}             \
	CONFIG.MSIx_Table_Size {16}            \
	CONFIG.MSIx_Table_Offset {0}           \
	CONFIG.MSIx_PBA_Offset {60}            \
	CONFIG.RBAR_Num {0}                    \
	CONFIG.PCIe_Blk_Locn {X0Y0}            \
	CONFIG.Trans_Buf_Pipeline {None}       \
	CONFIG.Ref_Clk_Freq {100_MHz}          \
] [get_ips $module_name]

generate_target {instantiation_template} [get_ips $module_name]

open_example_project -force -dir ${ip_name}_example_design [get_ips $module_name]

