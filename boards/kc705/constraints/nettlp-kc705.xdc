# LED
#set_property PACKAGE_PIN AB8 [get_ports {led[0]}]
#set_property PACKAGE_PIN AA8 [get_ports {led[1]}]
#set_property PACKAGE_PIN AC9 [get_ports {led[2]}]
#set_property PACKAGE_PIN AB9 [get_ports {led[3]}]
#set_property PACKAGE_PIN AE26 [get_ports {led[4]}]
#set_property PACKAGE_PIN G19 [get_ports {led[5]}]
#set_property PACKAGE_PIN E18 [get_ports {led[6]}]
#set_property PACKAGE_PIN F16 [get_ports {led[7]}]

#set_property IOSTANDARD LVCMOS15 [get_ports {led[0]}]
#set_property IOSTANDARD LVCMOS15 [get_ports {led[1]}]
#set_property IOSTANDARD LVCMOS15 [get_ports {led[2]}]
#set_property IOSTANDARD LVCMOS15 [get_ports {led[3]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {led[4]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {led[5]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {led[6]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {led[7]}]

#set_property SLEW SLOW [get_ports {led[7]}]
#set_property SLEW SLOW [get_ports {led[6]}]
#set_property SLEW SLOW [get_ports {led[5]}]
#set_property SLEW SLOW [get_ports {led[4]}]
#set_property SLEW SLOW [get_ports {led[3]}]
#set_property SLEW SLOW [get_ports {led[2]}]
#set_property SLEW SLOW [get_ports {led[1]}]
#set_property SLEW SLOW [get_ports {led[0]}]

#set_property DRIVE 4 [get_ports {led[7]}]
#set_property DRIVE 4 [get_ports {led[6]}]
#set_property DRIVE 4 [get_ports {led[5]}]
#set_property DRIVE 4 [get_ports {led[4]}]
#set_property DRIVE 4 [get_ports {led[3]}]
#set_property DRIVE 4 [get_ports {led[2]}]
#set_property DRIVE 4 [get_ports {led[1]}]
#set_property DRIVE 4 [get_ports {led[0]}]

# button
#set_property PACKAGE_PIN AA12 [get_ports {button_n}]
#set_property PACKAGE_PIN AB12 [get_ports {button_s}]
#set_property PACKAGE_PIN AC6  [get_ports {button_w}]
#set_property PACKAGE_PIN AG5  [get_ports {button_e}]
#set_property PACKAGE_PIN G12  [get_ports {button_c}]

#set_property IOSTANDARD LVCMOS15 [get_ports {button_n}]
#set_property IOSTANDARD LVCMOS15 [get_ports {button_s}]
#set_property IOSTANDARD LVCMOS15 [get_ports {button_w}]
#set_property IOSTANDARD LVCMOS15 [get_ports {button_e}]
#set_property IOSTANDARD LVCMOS25 [get_ports {button_c}]

## dipsw
#set_property PACKAGE_PIN Y28  [get_ports {dipsw[3]}]
#set_property PACKAGE_PIN AA28 [get_ports {dipsw[2]}]
#set_property PACKAGE_PIN W29  [get_ports {dipsw[1]}]
#set_property PACKAGE_PIN Y29  [get_ports {dipsw[0]}]

#set_property IOSTANDARD LVCMOS25 [get_ports {dipsw[3]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {dipsw[2]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {dipsw[1]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {dipsw[0]}]

# clk200
create_clock -period 5.000 -name clk200_p [get_ports clk200_p]
set_property IOSTANDARD DIFF_SSTL15 [get_ports clk200_n]
set_property IOSTANDARD DIFF_SSTL15 [get_ports clk200_p]
set_property PACKAGE_PIN AD12 [get_ports clk200_p]
set_property PACKAGE_PIN AD11 [get_ports clk200_n]

# SFP_CLK
set_property PACKAGE_PIN L8  [get_ports SFP_CLK_P]
set_property PACKAGE_PIN L7  [get_ports SFP_CLK_N]

# I2C_FPGA_SCL
set_property IOSTANDARD LVCMOS25 [get_ports I2C_FPGA_SCL]
set_property SLEW SLOW [get_ports I2C_FPGA_SCL]
set_property DRIVE 16 [get_ports I2C_FPGA_SCL]
set_property PULLUP TRUE [get_ports I2C_FPGA_SCL]
set_property PACKAGE_PIN K21  [get_ports I2C_FPGA_SCL]

# I2C_FPGA_SDA
set_property IOSTANDARD LVCMOS25 [get_ports I2C_FPGA_SDA]
set_property SLEW SLOW [get_ports I2C_FPGA_SDA]
set_property DRIVE 16 [get_ports I2C_FPGA_SDA]
set_property PULLUP TRUE [get_ports I2C_FPGA_SDA]
set_property PACKAGE_PIN L21  [get_ports I2C_FPGA_SDA]

#I2C_FPGA_RST_N
set_property IOSTANDARD LVCMOS25 [get_ports I2C_FPGA_RST_N]
set_property SLEW SLOW [get_ports I2C_FPGA_RST_N]
set_property DRIVE 16 [get_ports I2C_FPGA_RST_N]
set_property PACKAGE_PIN P23  [get_ports I2C_FPGA_RST_N]

# SI5324_RST_N
set_property IOSTANDARD LVCMOS25 [get_ports SI5324_RST_N]
set_property SLEW SLOW [get_ports SI5324_RST_N]
set_property DRIVE 16 [get_ports SI5324_RST_N]
set_property PACKAGE_PIN AE20 [get_ports SI5324_RST_N]

# Ethernet (eth0)
#set_property LOC GTXE2_CHANNEL_X0Y10 [get_cells eth_top0/u_axi_10g_ethernet_0/inst/xpcs/inst/ten_gig_eth_pcs_pma_block_i/gt0_gtwizard_10gbaser_multi_gt_i/gt0_gtwizard_10gbaser_i/gtxe2_i]
set_property PACKAGE_PIN G4 [get_ports ETH0_TX_N]
set_property PACKAGE_PIN G3 [get_ports ETH0_TX_P]
set_property PACKAGE_PIN H1 [get_ports ETH0_RX_N]
set_property PACKAGE_PIN H2 [get_ports ETH0_RX_P]
set_property PACKAGE_PIN Y20 [get_ports {ETH0_TX_DISABLE}]
set_property IOSTANDARD LVCMOS25 [get_ports {ETH0_TX_DISABLE}]

# sys_rst_n
set_property IOSTANDARD LVCMOS25 [get_ports sys_rst_n]
set_property PULLUP true [get_ports sys_rst_n]
set_property LOC G25 [get_ports sys_rst_n]
set_false_path -from [get_ports sys_rst_n]

# PCIe
create_clock -name sys_clk -period 10 [get_pins refclk_ibuf/O]

set_false_path -to [get_pins {pcie_7x_support_i/pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/S0}]
set_false_path -to [get_pins {pcie_7x_support_i/pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/S1}]

create_generated_clock -name clk_125mhz_x0y0 [get_pins pcie_7x_support_i/pipe_clock_i/mmcm_i/CLKOUT0]
create_generated_clock -name clk_250mhz_x0y0 [get_pins pcie_7x_support_i/pipe_clock_i/mmcm_i/CLKOUT1]
create_generated_clock -name clk_125mhz_mux_x0y0 \ 
                        -source [get_pins pcie_7x_support_i/pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/I0] \
                        -divide_by 1 \
                        [get_pins pcie_7x_support_i/pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/O]

create_generated_clock -name clk_250mhz_mux_x0y0 \ 
                        -source [get_pins pcie_7x_support_i/pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/I1] \
                        -divide_by 1 -add -master_clock [get_clocks -of [get_pins pcie_7x_support_i/pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/I1]] \
                        [get_pins pcie_7x_support_i/pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/O]

set_clock_groups -name pcieclkmux -physically_exclusive -group clk_125mhz_mux_x0y0 -group clk_250mhz_mux_x0y0

set_property LOC IBUFDS_GTE2_X0Y1 [get_cells refclk_ibuf]


# false_path
#set_false_path -from [get_pins tlp_tx_inject0/eth2pcie_sync_ashot/buf0_reg/C] -to [get_pins tlp_tx_inject0/eth2pcie_sync_ashot/buf1_reg/D]

set_false_path -from [get_clocks SFP_CLK_P] -to [get_clocks userclk1]
set_false_path -from [get_clocks userclk1] -to [get_clocks SFP_CLK_P]
