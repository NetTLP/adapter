`default_nettype none
`timescale 1ns / 1ps

module pcie_7x_support #(
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
	// Tx
	output logic  [(LINK_CAP_MAX_LINK_WIDTH - 1) : 0] pci_exp_txn,
	output logic  [(LINK_CAP_MAX_LINK_WIDTH - 1) : 0] pci_exp_txp,

	// Rx
	input wire   [(LINK_CAP_MAX_LINK_WIDTH - 1) : 0] pci_exp_rxn,
	input wire   [(LINK_CAP_MAX_LINK_WIDTH - 1) : 0] pci_exp_rxp,

	//----------------------------------------------------------------------------------------------------------------//
	// Clocking Sharing Interface                                                                                     //
	//----------------------------------------------------------------------------------------------------------------//
	output logic                                     pipe_pclk_out_slave,
	output logic                                     pipe_rxusrclk_out,
	output logic [(LINK_CAP_MAX_LINK_WIDTH - 1) : 0] pipe_rxoutclk_out,
	output logic                                     pipe_dclk_out,
	output logic                                     pipe_userclk1_out,
	output logic                                     pipe_userclk2_out,
	output logic                                     pipe_oobclk_out,
	output logic                                     pipe_mmcm_lock_out,
	input wire  [(LINK_CAP_MAX_LINK_WIDTH - 1) : 0] pipe_pclk_sel_slave,
	input wire                                      pipe_mmcm_rst_n,

	//----------------------------------------------------------------------------------------------------------------//
	// AXI-S Interface                                                                                                //
	//----------------------------------------------------------------------------------------------------------------//

	// Common
	output logic                                     user_clk_out,
	output logic                                     user_reset_out,
	output logic                                     user_lnk_up,
	output logic                                     user_app_rdy,

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
	output logic                                    s_axis_tx_tready,
	input wire   [KEEP_WIDTH-1:0]                   s_axis_tx_tkeep,
	input wire                                      s_axis_tx_tlast,
	input wire   [3:0]                              s_axis_tx_tuser,

	// AXI RX
	//-----------
	output logic [C_DATA_WIDTH-1:0]                  m_axis_rx_tdata,
	output logic                                     m_axis_rx_tvalid,
	input wire                                      m_axis_rx_tready,
	output logic  [KEEP_WIDTH-1:0]                   m_axis_rx_tkeep,
	output logic                                     m_axis_rx_tlast,
	output logic  [21:0]                             m_axis_rx_tuser,

	// Flow Control
	output logic  [11:0]                             fc_cpld,
	output logic  [7:0]                              fc_cplh,
	output logic  [11:0]                             fc_npd,
	output logic  [7:0]                              fc_nph,
	output logic  [11:0]                             fc_pd,
	output logic  [7:0]                              fc_ph,
	input wire   [2:0]                              fc_sel,

	//----------------------------------------------------------------------------------------------------------------//
	// Configuration (CFG) Interface                                                                                  //
	//----------------------------------------------------------------------------------------------------------------//
	//------------------------------------------------//
	// EP and RP                                      //
	//------------------------------------------------//
	output logic                                     tx_err_drop,
	output logic                                     tx_cfg_req,
	output logic  [5:0]                              tx_buf_av,
	output logic   [15:0]                            cfg_status,
	output logic   [15:0]                            cfg_command,
	output logic   [15:0]                            cfg_dstatus,
	output logic   [15:0]                            cfg_dcommand,
	output logic   [15:0]                            cfg_lstatus,
	output logic   [15:0]                            cfg_lcommand,
	output logic   [15:0]                            cfg_dcommand2,
	output logic   [2:0]                             cfg_pcie_link_state,
	output logic                                     cfg_to_turnoff,
	output logic   [7:0]                             cfg_bus_number,
	output logic   [4:0]                             cfg_device_number,
	output logic   [2:0]                             cfg_function_number,

	output logic                                     cfg_pmcsr_pme_en,
	output logic   [1:0]                             cfg_pmcsr_powerstate,
	output logic                                     cfg_pmcsr_pme_status,
	output logic                                     cfg_received_func_lvl_rst,

	//------------------------------------------------//
	// RP Only                                        //
	//------------------------------------------------//
	output logic                                     cfg_bridge_serr_en,
	output logic                                     cfg_slot_control_electromech_il_ctl_pulse,
	output logic                                     cfg_root_control_syserr_corr_err_en,
	output logic                                     cfg_root_control_syserr_non_fatal_err_en,
	output logic                                     cfg_root_control_syserr_fatal_err_en,
	output logic                                     cfg_root_control_pme_int_en,
	output logic                                     cfg_aer_rooterr_corr_err_reporting_en,
	output logic                                     cfg_aer_rooterr_non_fatal_err_reporting_en,
	output logic                                     cfg_aer_rooterr_fatal_err_reporting_en,
	output logic                                     cfg_aer_rooterr_corr_err_received,
	output logic                                     cfg_aer_rooterr_non_fatal_err_received,
	output logic                                     cfg_aer_rooterr_fatal_err_received,
	//----------------------------------------------------------------------------------------------------------------//
	// VC interface                                                                                                   //
	//----------------------------------------------------------------------------------------------------------------//

	output logic   [6:0]                              cfg_vc_tcvc_map,

	// Management Interface
	output logic   [31:0]                             cfg_mgmt_do,
	output logic                                      cfg_mgmt_rd_wr_done,
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
	output logic                                      cfg_err_cpl_rdy,
	input wire                                       cfg_err_locked,
	input wire                                       cfg_err_acs,
	input wire                                       cfg_err_internal_uncor,
	//----------------------------------------------------------------------------------------------------------------//
	// AER interface                                                                                                  //
	//----------------------------------------------------------------------------------------------------------------//
	input wire   [127:0]                             cfg_err_aer_headerlog,
	input wire   [4:0]                               cfg_aer_interrupt_msgnum,
	output logic                                      cfg_err_aer_headerlog_set,
	output logic                                      cfg_aer_ecrc_check_en,
	output logic                                      cfg_aer_ecrc_gen_en,

	output logic                                      cfg_msg_received,
	output logic   [15:0]                             cfg_msg_data,
	output logic                                      cfg_msg_received_pm_as_nak,
	output logic                                      cfg_msg_received_setslotpowerlimit,
	output logic                                      cfg_msg_received_err_cor,
	output logic                                      cfg_msg_received_err_non_fatal,
	output logic                                      cfg_msg_received_err_fatal,
	output logic                                      cfg_msg_received_pm_pme,
	output logic                                      cfg_msg_received_pme_to_ack,
	output logic                                      cfg_msg_received_assert_int_a,
	output logic                                      cfg_msg_received_assert_int_b,
	output logic                                      cfg_msg_received_assert_int_c,
	output logic                                      cfg_msg_received_assert_int_d,
	output logic                                      cfg_msg_received_deassert_int_a,
	output logic                                      cfg_msg_received_deassert_int_b,
	output logic                                      cfg_msg_received_deassert_int_c,
	output logic                                      cfg_msg_received_deassert_int_d,

	//------------------------------------------------//
	// EP Only                                        //
	//------------------------------------------------//
	// Interrupt Interface Signals
	input wire                                       cfg_interrupt,
	output logic                                      cfg_interrupt_rdy,
	input wire                                       cfg_interrupt_assert,
	input wire    [7:0]                              cfg_interrupt_di,
	output logic   [7:0]                              cfg_interrupt_do,
	output logic   [2:0]                              cfg_interrupt_mmenable,
	output logic                                      cfg_interrupt_msienable,
	output logic                                      cfg_interrupt_msixenable,
	output logic                                      cfg_interrupt_msixfm,
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

	output logic                                      pl_sel_lnk_rate,
	output logic   [1:0]                              pl_sel_lnk_width,
	output logic   [5:0]                              pl_ltssm_state,
	output logic   [1:0]                              pl_lane_reversal_mode,
	output logic                                      pl_phy_lnk_up,
	output logic   [2:0]                              pl_tx_pm_state,
	output logic   [1:0]                              pl_rx_pm_state,
	output logic                                      pl_link_upcfg_cap,
	output logic                                      pl_link_gen2_cap,
	output logic                                      pl_link_partner_gen2_supported,
	output logic   [2:0]                              pl_initial_link_width,
	output logic                                      pl_directed_change_done,

	//------------------------------------------------//
	// EP Only                                        //
	//------------------------------------------------//
	output logic                                      pl_received_hot_rst,

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
	output logic                                      pcie_drp_rdy,
	output logic   [15:0]                             pcie_drp_do,

	input wire                                       sys_clk,
	input wire                                       sys_rst_n
);

always_comb user_clk_out = top0.clk200;

always_comb s_axis_tx_tready = 1'b1;

assign user_lnk_up = 'b1;
assign user_reset_out = 'b0;

reg [1:0] state;
always @(posedge user_clk_out) begin
	if (sys_rst_n) begin
		state <= 2'b0;
		cfg_mgmt_rd_wr_done <= 1'b0;
	end else begin
		cfg_mgmt_rd_wr_done <= 1'b0;

		case (state)
		2'b00: begin
			if (cfg_mgmt_rd_en || cfg_mgmt_wr_en) begin
				state <= 2'b01;
			end
		end
		2'b01: begin
			state <= 2'b10;
			cfg_mgmt_rd_wr_done <= 1'b1;
		end
		2'b10: begin
			state <= 2'b00;
		end
		2'b11: begin
		end
		endcase
	end
end

// input wire   [C_DATA_WIDTH-1:0]                 s_axis_tx_tdata,
// input wire                                      s_axis_tx_tvalid,
// output reg                                      s_axis_tx_tready,
// input wire   [KEEP_WIDTH-1:0]                   s_axis_tx_tkeep,
// input wire                                      s_axis_tx_tlast,
// input wire   [3:0]                              s_axis_tx_tuser,
// 
// // AXI RX
// //-----------
// output logic [C_DATA_WIDTH-1:0]                  m_axis_rx_tdata,
// output logic                                     m_axis_rx_tvalid,
// input wire                                      m_axis_rx_tready,
// output logic  [KEEP_WIDTH-1:0]                   m_axis_rx_tkeep,
// output logic                                     m_axis_rx_tlast,
// output logic  [21:0]                             m_axis_rx_tuser,

// input ports
wire _unused_ok = &{
	cfg_err_acs,
	cfg_err_atomic_egress_blocked,
	cfg_err_cor,
	cfg_err_cpl_abort,
	cfg_err_cpl_timeout,
	cfg_err_cpl_unexpect,
	cfg_err_ecrc,
	cfg_err_internal_cor,
	cfg_err_internal_uncor,
	cfg_err_locked,
	cfg_err_malformed,
	cfg_err_mc_blocked,
	cfg_err_norecovery,
	cfg_err_poisoned,
	cfg_err_posted,
	cfg_err_ur,
	cfg_interrupt,
	cfg_interrupt_assert,
	cfg_interrupt_stat,
	cfg_mgmt_rd_en,
	cfg_mgmt_wr_en,
	cfg_mgmt_wr_readonly,
	cfg_mgmt_wr_rw1c_as_rw,
	pcie_drp_clk,
	pcie_drp_en,
	pcie_drp_we,
	pl_directed_link_auton,
	pl_directed_link_speed,
	pl_downstream_deemph_source,
	pl_transmit_hot_rst,
	pl_upstream_prefer_deemph,
	sys_clk,
	sys_rst_n,
	cfg_pm_force_state_en,
	cfg_pm_halt_aspm_l0s,
	cfg_pm_halt_aspm_l1,
	cfg_pm_send_pme_to,
	cfg_pm_wake,
	cfg_trn_pending,
	cfg_turnoff_ok,
	m_axis_rx_tready,
	pipe_mmcm_rst_n,
	rx_np_ok,
	rx_np_req,
	s_axis_tx_tlast,
	s_axis_tx_tvalid,
	tx_cfg_gnt,
	pcie_drp_di,
	pl_directed_link_change,
	pl_directed_link_width,
	cfg_pm_force_state,
	cfg_ds_function_number,
	cfg_mgmt_di,
	cfg_mgmt_byte_en,
	cfg_pciecap_interrupt_msgnum,
	cfg_ds_device_number,
	cfg_dsn,
	cfg_interrupt_di,
	cfg_ds_bus_number,
	pcie_drp_addr,
	cfg_mgmt_dwaddr,
	pci_exp_rxn,
	pci_exp_rxp,
	cfg_err_aer_headerlog,
	fc_sel,
	s_axis_tx_tuser,
	cfg_err_tlp_cpl_header,
	cfg_aer_interrupt_msgnum,
	s_axis_tx_tdata,
	s_axis_tx_tkeep,
	pipe_pclk_sel_slave,
	m_axis_rx_tready,
	1'b0
};

// output ports
always_comb cfg_aer_ecrc_check_en = 'b0;
always_comb cfg_aer_ecrc_gen_en = 'b0;
always_comb cfg_err_aer_headerlog_set = 'b0;
always_comb cfg_err_cpl_rdy = 'b0;
always_comb cfg_interrupt_msienable = 'b0;
always_comb cfg_interrupt_msixenable = 'b0;
always_comb cfg_interrupt_msixfm = 'b0;
always_comb cfg_interrupt_rdy = 'b0;
//always_comb cfg_mgmt_rd_wr_done = 'b0;
always_comb cfg_msg_received = 'b0;
always_comb cfg_msg_received_assert_int_a = 'b0;
always_comb cfg_msg_received_assert_int_b = 'b0;
always_comb cfg_msg_received_assert_int_c = 'b0;
always_comb cfg_msg_received_assert_int_d = 'b0;
always_comb cfg_msg_received_deassert_int_a = 'b0;
always_comb cfg_msg_received_deassert_int_b = 'b0;
always_comb cfg_msg_received_deassert_int_c = 'b0;
always_comb cfg_msg_received_deassert_int_d = 'b0;
always_comb cfg_msg_received_err_cor = 'b0;
always_comb cfg_msg_received_err_fatal = 'b0;
always_comb cfg_msg_received_err_non_fatal = 'b0;
always_comb cfg_msg_received_pm_as_nak = 'b0;
always_comb cfg_msg_received_pm_pme = 'b0;
always_comb cfg_msg_received_pme_to_ack = 'b0;
always_comb cfg_msg_received_setslotpowerlimit = 'b0;
always_comb pcie_drp_rdy = 'b0;
always_comb pl_directed_change_done = 'b0;
always_comb pl_link_gen2_cap = 'b0;
always_comb pl_link_partner_gen2_supported = 'b0;
always_comb pl_link_upcfg_cap = 'b0;
always_comb pl_phy_lnk_up = 'b0;
always_comb pl_received_hot_rst = 'b0;
always_comb pl_sel_lnk_rate = 'b0;
always_comb cfg_aer_rooterr_corr_err_received = 'b0;
always_comb cfg_aer_rooterr_corr_err_reporting_en = 'b0;
always_comb cfg_aer_rooterr_fatal_err_received = 'b0;
always_comb cfg_aer_rooterr_fatal_err_reporting_en = 'b0;
always_comb cfg_aer_rooterr_non_fatal_err_received = 'b0;
always_comb cfg_aer_rooterr_non_fatal_err_reporting_en = 'b0;
always_comb cfg_bridge_serr_en = 'b0;
always_comb cfg_pmcsr_pme_en = 'b0;
always_comb cfg_pmcsr_pme_status = 'b0;
always_comb cfg_received_func_lvl_rst = 'b0;
always_comb cfg_root_control_pme_int_en = 'b0;
always_comb cfg_root_control_syserr_corr_err_en = 'b0;
always_comb cfg_root_control_syserr_fatal_err_en = 'b0;
always_comb cfg_root_control_syserr_non_fatal_err_en = 'b0;
always_comb cfg_slot_control_electromech_il_ctl_pulse = 'b0;
always_comb cfg_to_turnoff = 'b0;
always_comb pipe_dclk_out = 'b0;
always_comb pipe_mmcm_lock_out = 'b0;
always_comb pipe_oobclk_out = 'b0;
always_comb pipe_pclk_out_slave = 'b0;
always_comb pipe_rxusrclk_out = 'b0;
always_comb pipe_userclk1_out = 'b0;
always_comb pipe_userclk2_out = 'b0;
always_comb tx_cfg_req = 'b0;
always_comb tx_err_drop = 'b0;
always_comb user_app_rdy = 'b0;
always_comb cfg_msg_data = 'b0;
always_comb pcie_drp_do = 'b0;
always_comb cfg_command = 'b0;
always_comb cfg_dcommand = 'b0;
always_comb cfg_dcommand2 = 'b0;
always_comb cfg_dstatus = 'b0;
always_comb cfg_lcommand = 'b0;
always_comb cfg_lstatus = 'b0;
always_comb cfg_status = 'b0;
always_comb pl_lane_reversal_mode = 'b0;
always_comb pl_rx_pm_state = 'b0;
always_comb pl_sel_lnk_width = 'b0;
always_comb cfg_pmcsr_powerstate = 'b0;
always_comb cfg_interrupt_mmenable = 'b0;
always_comb pl_initial_link_width = 'b0;
always_comb pl_tx_pm_state = 'b0;
always_comb cfg_function_number = 'b0;
always_comb cfg_pcie_link_state = 'b0;
always_comb cfg_mgmt_do = 'b0;
always_comb cfg_device_number = 'b0;
always_comb pl_ltssm_state = 'b0;
always_comb cfg_vc_tcvc_map = 'b0;
always_comb cfg_interrupt_do = 'b0;
always_comb cfg_bus_number = 'b0;
always_comb pci_exp_txn = 'b0;
always_comb pci_exp_txp = 'b0;
always_comb fc_cpld = 'b0;
always_comb fc_npd = 'b0;
always_comb fc_pd = 'b0;
always_comb tx_buf_av = 'b0;
always_comb fc_cplh = 'b0;
always_comb fc_nph = 'b0;
always_comb fc_ph = 'b0;
always_comb pipe_rxoutclk_out = 'b0;

endmodule

`default_nettype wire

