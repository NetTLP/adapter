set HW_SERVER [lindex $argv 0]

set bitfile kc705-tmpl.bit

set device xc7k325t_0

open_hw
connect_hw_server -url ${HW_SERVER}

current_hw_target [get_hw_targets */xilinx_tcf/Digilent/210203368693A]
set_property PARAM.FREQUENCY 15000000 [get_hw_targets */xilinx_tcf/Digilent/210203368693A]
open_hw_target

current_hw_device [get_hw_devices ${device}]
refresh_hw_device -update_hw_probes false [lindex [get_hw_devices ${device}] 0]

set_property PROGRAM.FILE {kc705-tmpl.bit} [get_hw_devices ${device}]
refresh_hw_device [lindex [get_hw_devices ${device}] 0]

program_hw_devices [get_hw_devices ${device}]
refresh_hw_device [lindex [get_hw_devices ${device}] 0]

