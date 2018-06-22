`default_nettype none
`timescale 1ns / 1ps

module pcie_7x_0_support #(
	parameter LINK_CAP_MAX_LINK_WIDTH = 8,                       // PCIe Lane Width
	parameter CLK_SHARING_EN          = "FALSE",                 // Enable Clock Sharing
	parameter C_DATA_WIDTH            = 256,                     // AXI interface data width
	parameter KEEP_WIDTH              = C_DATA_WIDTH / 8,        // TSTRB width
	parameter PCIE_REFCLK_FREQ        = 0,                       // PCIe reference clock frequency
	parameter PCIE_USERCLK1_FREQ      = 2,                       // PCIe user clock 1 frequency
	parameter PCIE_USERCLK2_FREQ      = 2,                       // PCIe user clock 2 frequency
	parameter PCIE_GT_DEVICE          = "GTX",                   // PCIe GT device
	parameter PCIE_USE_MODE           = "2.1"                    // PCIe use mode
)(
	//----------------------------------------------------------------------------------------------------------------//
	// PCI Express (pci_exp) Interface                                                                                //
	//----------------------------------------------------------------------------------------------------------------//

	// Tx
	output reg  [(LINK_CAP_MAX_LINK_WIDTH - 1) : 0] pci_exp_txn,
	output reg  [(LINK_CAP_MAX_LINK_WIDTH - 1) : 0] pci_exp_txp,

	// Rx
	input wire   [(LINK_CAP_MAX_LINK_WIDTH - 1) : 0] pci_exp_rxn,
	input wire   [(LINK_CAP_MAX_LINK_WIDTH - 1) : 0] pci_exp_rxp,

	//----------------------------------------------------------------------------------------------------------------//
	// Clocking Sharing Interface                                                                                     //
	//----------------------------------------------------------------------------------------------------------------//
	output reg                                     pipe_pclk_out_slave,
	output reg                                     pipe_rxusrclk_out,
	output reg [(LINK_CAP_MAX_LINK_WIDTH - 1) : 0] pipe_rxoutclk_out,
	output reg                                     pipe_dclk_out,
	output reg                                     pipe_userclk1_out,
	output reg                                     pipe_userclk2_out,
	output reg                                     pipe_oobclk_out,
	output reg                                     pipe_mmcm_lock_out,
	input wire  [(LINK_CAP_MAX_LINK_WIDTH - 1) : 0] pipe_pclk_sel_slave,
	input wire                                      pipe_mmcm_rst_n,

	//----------------------------------------------------------------------------------------------------------------//
	// AXI-S Interface                                                                                                //
	//----------------------------------------------------------------------------------------------------------------//

	// Common
	output reg                                     user_clk_out,
	output reg                                     user_reset_out,
	output reg                                     user_lnk_up,
	output reg                                     user_app_rdy,

	input wire                                      tx_cfg_gnt,
	input wire                                      rx_np_ok,
	input wire                                      rx_np_req,
	input wire                                      cfg_turnoff_ok,
	input wire                                      cfg_trn_pending,
	input wire                                      cfg_pm_halt_aspm_l0s,
	input wire                                      cfg_pm_halt_aspm_l1,
	input wire                                      cfg_pm_force_state_en,
	input wire    [1:0]                             cfg_pm_force_state,
	input wire    [63:0]                            cfg_dsn,
	input wire                                      cfg_pm_send_pme_to,
	input wire    [7:0]                             cfg_ds_bus_number,
	input wire    [4:0]                             cfg_ds_device_number,
	input wire    [2:0]                             cfg_ds_function_number,
	input wire                                      cfg_pm_wake,

	// AXI TX
	//-----------
	input wire   [C_DATA_WIDTH-1:0]                 s_axis_tx_tdata,
	input wire                                      s_axis_tx_tvalid,
	output reg                                      s_axis_tx_tready,
	input wire   [KEEP_WIDTH-1:0]                   s_axis_tx_tkeep,
	input wire                                      s_axis_tx_tlast,
	input wire   [3:0]                              s_axis_tx_tuser,

	// AXI RX
	//-----------
	output wire [C_DATA_WIDTH-1:0]                  m_axis_rx_tdata,
	output wire                                     m_axis_rx_tvalid,
	input wire                                      m_axis_rx_tready,
	output wire  [KEEP_WIDTH-1:0]                   m_axis_rx_tkeep,
	output wire                                     m_axis_rx_tlast,
	output wire  [21:0]                             m_axis_rx_tuser,

	// Flow Control
	output reg  [11:0]                             fc_cpld,
	output reg  [7:0]                              fc_cplh,
	output reg  [11:0]                             fc_npd,
	output reg  [7:0]                              fc_nph,
	output reg  [11:0]                             fc_pd,
	output reg  [7:0]                              fc_ph,
	input wire   [2:0]                              fc_sel,

	//----------------------------------------------------------------------------------------------------------------//
	// Configuration (CFG) Interface                                                                                  //
	//----------------------------------------------------------------------------------------------------------------//
	//------------------------------------------------//
	// EP and RP                                      //
	//------------------------------------------------//
	output reg                                     tx_err_drop,
	output reg                                     tx_cfg_req,
	output reg  [5:0]                              tx_buf_av,
	output reg   [15:0]                            cfg_status,
	output reg   [15:0]                            cfg_command,
	output reg   [15:0]                            cfg_dstatus,
	output reg   [15:0]                            cfg_dcommand,
	output reg   [15:0]                            cfg_lstatus,
	output reg   [15:0]                            cfg_lcommand,
	output reg   [15:0]                            cfg_dcommand2,
	output reg   [2:0]                             cfg_pcie_link_state,
	output reg                                     cfg_to_turnoff,
	output reg   [7:0]                             cfg_bus_number,
	output reg   [4:0]                             cfg_device_number,
	output reg   [2:0]                             cfg_function_number,

	output reg                                     cfg_pmcsr_pme_en,
	output reg   [1:0]                             cfg_pmcsr_powerstate,
	output reg                                     cfg_pmcsr_pme_status,
	output reg                                     cfg_received_func_lvl_rst,

	//------------------------------------------------//
	// RP Only                                        //
	//------------------------------------------------//
	output reg                                     cfg_bridge_serr_en,
	output reg                                     cfg_slot_control_electromech_il_ctl_pulse,
	output reg                                     cfg_root_control_syserr_corr_err_en,
	output reg                                     cfg_root_control_syserr_non_fatal_err_en,
	output reg                                     cfg_root_control_syserr_fatal_err_en,
	output reg                                     cfg_root_control_pme_int_en,
	output reg                                     cfg_aer_rooterr_corr_err_reporting_en,
	output reg                                     cfg_aer_rooterr_non_fatal_err_reporting_en,
	output reg                                     cfg_aer_rooterr_fatal_err_reporting_en,
	output reg                                     cfg_aer_rooterr_corr_err_received,
	output reg                                     cfg_aer_rooterr_non_fatal_err_received,
	output reg                                     cfg_aer_rooterr_fatal_err_received,
	//----------------------------------------------------------------------------------------------------------------//
	// VC interface                                                                                                   //
	//----------------------------------------------------------------------------------------------------------------//

	output reg   [6:0]                              cfg_vc_tcvc_map,

	// Management Interface
	output reg   [31:0]                             cfg_mgmt_do,
	output reg                                      cfg_mgmt_rd_wr_done,
	input wire    [31:0]                             cfg_mgmt_di,
	input wire    [3:0]                              cfg_mgmt_byte_en,
	input wire    [9:0]                              cfg_mgmt_dwaddr,
	input wire                                       cfg_mgmt_wr_en,
	input wire                                       cfg_mgmt_rd_en,
	input wire                                       cfg_mgmt_wr_readonly,
	input wire                                       cfg_mgmt_wr_rw1c_as_rw,

	// Error Reporting Interface
	input wire                                       cfg_err_ecrc,
	input wire                                       cfg_err_ur,
	input wire                                       cfg_err_cpl_timeout,
	input wire                                       cfg_err_cpl_unexpect,
	input wire                                       cfg_err_cpl_abort,
	input wire                                       cfg_err_posted,
	input wire                                       cfg_err_cor,
	input wire                                       cfg_err_atomic_egress_blocked,
	input wire                                       cfg_err_internal_cor,
	input wire                                       cfg_err_malformed,
	input wire                                       cfg_err_mc_blocked,
	input wire                                       cfg_err_poisoned,
	input wire                                       cfg_err_norecovery,
	input wire   [47:0]                              cfg_err_tlp_cpl_header,
	output reg                                      cfg_err_cpl_rdy,
	input wire                                       cfg_err_locked,
	input wire                                       cfg_err_acs,
	input wire                                       cfg_err_internal_uncor,
	//----------------------------------------------------------------------------------------------------------------//
	// AER interface                                                                                                  //
	//----------------------------------------------------------------------------------------------------------------//
	input wire   [127:0]                             cfg_err_aer_headerlog,
	input wire   [4:0]                               cfg_aer_interrupt_msgnum,
	output reg                                      cfg_err_aer_headerlog_set,
	output reg                                      cfg_aer_ecrc_check_en,
	output reg                                      cfg_aer_ecrc_gen_en,

	output reg                                      cfg_msg_received,
	output reg   [15:0]                             cfg_msg_data,
	output reg                                      cfg_msg_received_pm_as_nak,
	output reg                                      cfg_msg_received_setslotpowerlimit,
	output reg                                      cfg_msg_received_err_cor,
	output reg                                      cfg_msg_received_err_non_fatal,
	output reg                                      cfg_msg_received_err_fatal,
	output reg                                      cfg_msg_received_pm_pme,
	output reg                                      cfg_msg_received_pme_to_ack,
	output reg                                      cfg_msg_received_assert_int_a,
	output reg                                      cfg_msg_received_assert_int_b,
	output reg                                      cfg_msg_received_assert_int_c,
	output reg                                      cfg_msg_received_assert_int_d,
	output reg                                      cfg_msg_received_deassert_int_a,
	output reg                                      cfg_msg_received_deassert_int_b,
	output reg                                      cfg_msg_received_deassert_int_c,
	output reg                                      cfg_msg_received_deassert_int_d,

	//------------------------------------------------//
	// EP Only                                        //
	//------------------------------------------------//
	// Interrupt Interface Signals
	input wire                                       cfg_interrupt,
	output reg                                      cfg_interrupt_rdy,
	input wire                                       cfg_interrupt_assert,
	input wire    [7:0]                              cfg_interrupt_di,
	output reg   [7:0]                              cfg_interrupt_do,
	output reg   [2:0]                              cfg_interrupt_mmenable,
	output reg                                      cfg_interrupt_msienable,
	output reg                                      cfg_interrupt_msixenable,
	output reg                                      cfg_interrupt_msixfm,
	input wire                                       cfg_interrupt_stat,
	input wire    [4:0]                              cfg_pciecap_interrupt_msgnum,

	//----------------------------------------------------------------------------------------------------------------//
	// Physical Layer Control and Status (PL) Interface                                                               //
	//----------------------------------------------------------------------------------------------------------------//
	//------------------------------------------------//
	// EP and RP                                      //
	//------------------------------------------------//
	input wire    [1:0]                              pl_directed_link_change,
	input wire    [1:0]                              pl_directed_link_width,
	input wire                                       pl_directed_link_speed,
	input wire                                       pl_directed_link_auton,
	input wire                                       pl_upstream_prefer_deemph,

	output reg                                      pl_sel_lnk_rate,
	output reg   [1:0]                              pl_sel_lnk_width,
	output reg   [5:0]                              pl_ltssm_state,
	output reg   [1:0]                              pl_lane_reversal_mode,
	output reg                                      pl_phy_lnk_up,
	output reg   [2:0]                              pl_tx_pm_state,
	output reg   [1:0]                              pl_rx_pm_state,
	output reg                                      pl_link_upcfg_cap,
	output reg                                      pl_link_gen2_cap,
	output reg                                      pl_link_partner_gen2_supported,
	output reg   [2:0]                              pl_initial_link_width,
	output reg                                      pl_directed_change_done,

	//------------------------------------------------//
	// EP Only                                        //
	//------------------------------------------------//
	output reg                                      pl_received_hot_rst,

	//------------------------------------------------//
	// RP Only                                        //
	//------------------------------------------------//
	input wire                                       pl_transmit_hot_rst,
	input wire                                       pl_downstream_deemph_source,

	//----------------------------------------------------------------------------------------------------------------//
	// PCIe DRP (PCIe DRP) Interface                                                                                  //
	//----------------------------------------------------------------------------------------------------------------//
	input wire                                       pcie_drp_clk,
	input wire                                       pcie_drp_en,
	input wire                                       pcie_drp_we,
	input wire    [8:0]                              pcie_drp_addr,
	input wire    [15:0]                             pcie_drp_di,
	output reg                                      pcie_drp_rdy,
	output reg   [15:0]                             pcie_drp_do,

	input wire                                       sys_clk,
	input wire                                       sys_rst_n
);

localparam CLK200_FREQ = 200e6;
localparam CLK200_HALF_PERIOD = 1/real'(CLK200_FREQ)*1000e6/2;

`ifndef verilator_sim
always begin
	#CLK200_HALF_PERIOD user_clk_out = 0;
	#CLK200_HALF_PERIOD user_clk_out = 1;
end
`endif

assign user_reset_out = ~sys_rst_n;
assign user_lnk_up = 1;
assign user_app_rdy = 1;

assign s_axis_tx_tready = 1;

reg [3:0] tuser = s_axis_tx_tuser;

host_pio host_pio0 (
	.pcie_clk(user_clk_out),
	.sys_rst(user_reset_out),

	.pcie_rx_tdata(m_axis_rx_tdata),
	.pcie_rx_tuser(m_axis_rx_tuser),
	.pcie_rx_tlast(m_axis_rx_tlast),
	.pcie_rx_tkeep(m_axis_rx_tkeep),
	.pcie_rx_tvalid(m_axis_rx_tvalid),
	.pcie_rx_tready(m_axis_rx_tready)
);

endmodule

`default_nettype wire

