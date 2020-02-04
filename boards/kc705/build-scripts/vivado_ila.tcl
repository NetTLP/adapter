set HW_SERVER [lindex $argv 0]

set bit_file kc705-tmpl.bit
set ltx_file kc705-tmpl.ltx

set device xc7k325t_0

open_hw
connect_hw_server -url ${HW_SERVER}

current_hw_target [get_hw_targets */xilinx_tcf/Digilent/210203368693A]
set_property PARAM.FREQUENCY 15000000 [get_hw_targets */xilinx_tcf/Digilent/210203368693A]
open_hw_target

current_hw_device [get_hw_devices ${device}]
refresh_hw_device -update_hw_probes false [lindex [get_hw_devices ${device}] 0]

set_property PROBES.FILE {kc705-tmpl.ltx} [get_hw_devices ${device}]
set_property PROGRAM.FILE {kc705-tmpl.bit} [get_hw_devices ${device}]
refresh_hw_device [lindex [get_hw_devices ${device}] 0]

program_hw_devices [get_hw_devices ${device}]
refresh_hw_device [lindex [get_hw_devices ${device}] 0]

#set_property CONTROL.TRIGGER_MODE BASIC_ONLY [get_hw_ilas hw_ila_1]
set_property TRIGGER_COMPARE_VALUE eq1'b1 [get_hw_probes pcie_rx_tvalid_reg -of_objects [get_hw_ilas -of_objects [get_hw_devices ${device}]]]
set_property TRIGGER_COMPARE_VALUE eq1'b1 [get_hw_probes pcie_tx_tvalid_reg -of_objects [get_hw_ilas -of_objects [get_hw_devices ${device}]]]
set_property CONTROL.TRIGGER_CONDITION OR [get_hw_ilas -of_objects [get_hw_devices ${device}]]
run_hw_ila [get_hw_ilas -of_objects [get_hw_devices ${device}]]

wait_on_hw_ila [get_hw_ilas -of_objects [get_hw_devices ${device}]]
current_hw_ila_data [upload_hw_ila_data hw_ila_1]
#write_hw_ila_data -force -csv_file csv/result.csv [current_hw_ila_data]
write_hw_ila_data -force -vcd_file csv/result.vcd [current_hw_ila_data]

