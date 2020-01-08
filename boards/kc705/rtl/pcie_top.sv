`default_nettype none
`timescale 1ns / 1ps

module pcie_top #(
	parameter PL_FAST_TRAIN       = "FALSE", // Simulation Speedup
	parameter PCIE_EXT_CLK        = "TRUE",    // Use External Clocking Module
	parameter PCIE_EXT_GT_COMMON  = "FALSE",
	parameter REF_CLK_FREQ        = 0,     // 0 - 100 MHz, 1 - 125 MHz, 2 - 250 MHz
	parameter C_DATA_WIDTH        = 64, // RX/TX interface data width
	parameter KEEP_WIDTH          = C_DATA_WIDTH / 8, // TSTRB width
	parameter LINK_WIDTH          = C_DATA_WIDTH / 16 // PCIe Link Width
) (
	input wire sys_clk,
	input wire sys_rst_n,

	output wire [LINK_WIDTH-1:0] pci_exp_txp,
	output wire [LINK_WIDTH-1:0] pci_exp_txn,
	input wire [LINK_WIDTH-1:0] pci_exp_rxp,
	input wire [LINK_WIDTH-1:0] pci_exp_rxn,

	output wire pcie_clk,
	output logic pcie_rst,

	// to inject
	output wire                     pcie_tx_req,
	input wire                      pcie_tx_ack,
	input wire                      pcie_tx_tready,
	output wire                     pcie_tx_tvalid,
	output wire                     pcie_tx_tlast,
	output wire [KEEP_WIDTH-1:0]    pcie_tx_tkeep,
	output wire [C_DATA_WIDTH-1:0]  pcie_tx_tdata,
	output wire [3:0]               pcie_tx_tuser,

	// from inject
	output wire                     pcie_tx1_tready,
	input wire                      pcie_tx1_tvalid,
	input wire                      pcie_tx1_tlast,
	input wire [KEEP_WIDTH-1:0]     pcie_tx1_tkeep,
	input wire [C_DATA_WIDTH-1:0]   pcie_tx1_tdata,
	input wire [3:0]                pcie_tx1_tuser,

	// to snoop
	output wire                     pcie_rx_tready,
	output wire                     pcie_rx_tvalid,
	output wire                     pcie_rx_tlast,
	output wire [KEEP_WIDTH-1:0]    pcie_rx_tkeep,
	output wire [C_DATA_WIDTH-1:0]  pcie_rx_tdata,
	output wire [21:0]              pcie_rx_tuser,

	output wire [31:0] adapter_reg_magic,
	output wire [47:0] adapter_reg_dstmac,
	output wire [47:0] adapter_reg_srcmac,
	output wire [31:0] adapter_reg_dstip,
	output wire [31:0] adapter_reg_srcip,
	output wire [15:0] adapter_reg_dstport,
	output wire [15:0] adapter_reg_srcport
);

wire user_reset_out;
wire user_lnk_up;

reg user_reset_q;
reg user_lnk_up_q;
always @(posedge pcie_clk) begin
	user_reset_q  <= user_reset_out;
	user_lnk_up_q <= user_lnk_up;
end
// output
always_comb pcie_rst = (~user_lnk_up_q | user_reset_q);


/*
 * ****************************
 * pcie_7x_support
 * ****************************
 */
wire tx_cfg_gnt;
wire rx_np_ok;
wire rx_np_req;
wire cfg_turnoff_ok;
wire cfg_trn_pending;
wire cfg_pm_halt_aspm_l0s;
wire cfg_pm_halt_aspm_l1;
wire cfg_pm_force_state_en;
wire [1:0] cfg_pm_force_state;
wire cfg_pm_wake;
wire [63:0] cfg_dsn;

// Flow Control
wire [2:0] fc_sel;

wire cfg_err_ecrc;
wire cfg_err_cor;
wire cfg_err_ur;
wire cfg_err_cpl_timeout;
wire cfg_err_cpl_abort;
wire cfg_err_cpl_unexpect;
wire cfg_err_posted;
wire cfg_err_locked;
wire [47:0] cfg_err_tlp_cpl_header;
wire [127:0] cfg_err_aer_headerlog;
wire [4:0] cfg_aer_interrupt_msgnum;

wire cfg_interrupt;
wire cfg_interrupt_assert;
wire [7:0] cfg_interrupt_di;
wire cfg_interrupt_stat;
wire [4:0] cfg_pciecap_interrupt_msgnum;

wire cfg_to_turnoff;
wire [7:0] cfg_bus_number;
wire [4:0] cfg_device_number;
wire [2:0] cfg_function_number;

wire [31:0] cfg_mgmt_di;
wire [3:0] cfg_mgmt_byte_en;
wire [9:0] cfg_mgmt_dwaddr;
wire cfg_mgmt_wr_en;
wire cfg_mgmt_rd_en;
wire cfg_mgmt_wr_readonly;

wire pl_directed_link_auton;
wire [1:0] pl_directed_link_change;
wire pl_directed_link_speed;
wire [1:0] pl_directed_link_width;
wire pl_upstream_prefer_deemph;

wire pipe_mmcm_rst_n = 1'b1;

wire cfg_err_atomic_egress_blocked;
wire cfg_err_internal_cor;
wire cfg_err_malformed;
wire cfg_err_mc_blocked;
wire cfg_err_poisoned;
wire cfg_err_norecovery;
wire cfg_err_acs;
wire cfg_err_internal_uncor;

wire m_axis_rx_tready;
wire m_axis_rx_tvalid;
wire m_axis_rx_tlast;
wire [KEEP_WIDTH-1:0] m_axis_rx_tkeep;
wire [C_DATA_WIDTH-1:0] m_axis_rx_tdata;
wire [21:0] m_axis_rx_tuser;

//wire s_axis_tx_tready;
//wire s_axis_tx_tvalid;
//wire s_axis_tx_tlast;
//wire [KEEP_WIDTH-1:0] s_axis_tx_tkeep;
//wire [C_DATA_WIDTH-1:0] s_axis_tx_tdata;
//wire [3:0] s_axis_tx_tuser;

localparam TCQ = 1;
localparam USER_CLK_FREQ = 3;
localparam USER_CLK2_DIV2 = "FALSE";
localparam USERCLK2_FREQ = (USER_CLK2_DIV2 == "TRUE") ? (USER_CLK_FREQ == 4) ? 3 : (USER_CLK_FREQ == 3) ? 2 : USER_CLK_FREQ: USER_CLK_FREQ;
pcie_7x_support #(	 
	.LINK_CAP_MAX_LINK_WIDTH   (LINK_WIDTH),  // PCIe Lane Width
	.C_DATA_WIDTH              (C_DATA_WIDTH), // RX/TX interface data width
	.KEEP_WIDTH                (KEEP_WIDTH), // TSTRB width
	.PCIE_REFCLK_FREQ          (REF_CLK_FREQ), // PCIe reference clock frequency
	.PCIE_USERCLK1_FREQ        (USER_CLK_FREQ+1), // PCIe user clock 1 frequency
	.PCIE_USERCLK2_FREQ        (USERCLK2_FREQ+1), // PCIe user clock 2 frequency             
	.PCIE_USE_MODE             ("3.0"), // PCIe use mode
	.PCIE_GT_DEVICE            ("GTX") // PCIe GT device
) pcie_7x_support_i (
	.user_clk_out                              (pcie_clk),

	.user_app_rdy                              (),

	.s_axis_tx_tready                          (pcie_tx1_tready),
	.s_axis_tx_tvalid                          (pcie_tx1_tvalid),
	.s_axis_tx_tlast                           (pcie_tx1_tlast),
	.s_axis_tx_tkeep                           (pcie_tx1_tkeep),
	.s_axis_tx_tdata                           (pcie_tx1_tdata),
	.s_axis_tx_tuser                           (pcie_tx1_tuser),

	// pipe
	.pipe_pclk_out_slave                       (),
	.pipe_rxusrclk_out                         (),
	.pipe_rxoutclk_out                         (),
	.pipe_dclk_out                             (),
	.pipe_userclk1_out                         (),
	.pipe_oobclk_out                           (),
	.pipe_userclk2_out                         (),
	.pipe_mmcm_lock_out                        (),
	.pipe_pclk_sel_slave                       (4'b0),

	// Flow Control
	.fc_cpld                                   (),
	.fc_cplh                                   (),
	.fc_npd                                    (),
	.fc_nph                                    (),
	.fc_pd                                     (),
	.fc_ph                                     (),

	// mgmt
	.cfg_mgmt_do                               (),
	.cfg_mgmt_rd_wr_done                       (),
	.cfg_mgmt_wr_rw1c_as_rw                    (1'b0),

	// Error Report
	.cfg_err_cpl_rdy                           (),

	.cfg_err_aer_headerlog_set                 (),
	.cfg_aer_ecrc_check_en                     (),
	.cfg_aer_ecrc_gen_en                       (),

	.cfg_pm_send_pme_to                        (1'b0),
	.cfg_ds_bus_number                         (8'b0),
	.cfg_ds_device_number                      (5'b0),
	.cfg_ds_function_number                    (3'b0),

	.cfg_interrupt_rdy                         (),
	.cfg_interrupt_do                          (),
	.cfg_interrupt_mmenable                    (),
	.cfg_interrupt_msienable                   (),
	.cfg_interrupt_msixenable                  (),
	.cfg_interrupt_msixfm                      (),

	.cfg_status                                (),
	.cfg_command                               (),
	.cfg_dstatus                               (),
	.cfg_lstatus                               (),
	.cfg_pcie_link_state                       (),
	.cfg_dcommand                              (),
	.cfg_lcommand                              (),
	.cfg_dcommand2                             (),

	.cfg_pmcsr_pme_en                          (),
	.cfg_pmcsr_powerstate                      (),
	.cfg_pmcsr_pme_status                      (),
	.cfg_received_func_lvl_rst                 (),
	.tx_buf_av                                 (),
	.tx_err_drop                               (),
	.tx_cfg_req                                (),
	.cfg_bridge_serr_en                        (),
	.cfg_slot_control_electromech_il_ctl_pulse (),
	.cfg_root_control_syserr_corr_err_en       (),
	.cfg_root_control_syserr_non_fatal_err_en  (),
	.cfg_root_control_syserr_fatal_err_en      (),
	.cfg_root_control_pme_int_en               (),
	.cfg_aer_rooterr_corr_err_reporting_en     (),
	.cfg_aer_rooterr_non_fatal_err_reporting_en(),
	.cfg_aer_rooterr_fatal_err_reporting_en    (),
	.cfg_aer_rooterr_corr_err_received         (),
	.cfg_aer_rooterr_non_fatal_err_received    (),
	.cfg_aer_rooterr_fatal_err_received        (),

	// VC
	.cfg_vc_tcvc_map                           (),

	.cfg_msg_received                          (),
	.cfg_msg_data                              (),
	.cfg_msg_received_err_cor                  (),
	.cfg_msg_received_err_non_fatal            (),
	.cfg_msg_received_err_fatal                (),
	.cfg_msg_received_pm_as_nak                (),
	.cfg_msg_received_pme_to_ack               (),
	.cfg_msg_received_assert_int_a             (),
	.cfg_msg_received_assert_int_b             (),
	.cfg_msg_received_assert_int_c             (),
	.cfg_msg_received_assert_int_d             (),
	.cfg_msg_received_deassert_int_a           (),
	.cfg_msg_received_deassert_int_b           (),
	.cfg_msg_received_deassert_int_c           (),
	.cfg_msg_received_deassert_int_d           (),
	.cfg_msg_received_pm_pme                   (),
	.cfg_msg_received_setslotpowerlimit        (),

	// PL
	.pl_sel_lnk_rate                           (),
	.pl_sel_lnk_width                          (),
	.pl_ltssm_state                            (),
	.pl_lane_reversal_mode                     (),

	.pl_phy_lnk_up                             (),
	.pl_tx_pm_state                            (),
	.pl_rx_pm_state                            (),

	.pl_link_upcfg_cap                         (),
	.pl_link_gen2_cap                          (),
	.pl_link_partner_gen2_supported            (),
	.pl_initial_link_width                     (),

	.pl_directed_change_done                   (),
	// END: PL

	.pl_received_hot_rst                       (),

	.pl_transmit_hot_rst                       (1'b0),
	.pl_downstream_deemph_source               (1'b0),

	// PCIe DRP
	.pcie_drp_clk                              (1'b1),
	.pcie_drp_en                               (1'b0),
	.pcie_drp_we                               (1'b0),
	.pcie_drp_addr                             (9'h0),
	.pcie_drp_di                               (16'h0),
	.pcie_drp_rdy                              (),
	.pcie_drp_do                               (),

	.*
);


/*
 * ****************************
 * pcie_rx_filter
 * ****************************
 */
wire                    m_axis_rx_tready1;
wire                    m_axis_rx_tvalid1;
wire                    m_axis_rx_tlast1;
wire [KEEP_WIDTH-1:0]   m_axis_rx_tkeep1;
wire [C_DATA_WIDTH-1:0] m_axis_rx_tdata1;
wire [21:0]             m_axis_rx_tuser1;
pcie_rx_filter #(
	.C_DATA_WIDTH(C_DATA_WIDTH),
	.KEEP_WIDTH(KEEP_WIDTH)
) pcie_rx_filter (
	// input from pcie_7x_support
	// output to pcie_app (hardware PIO engine)
	// PCIe output to tlp_rx_snoop (ethernet)
	.*
);


/*
 * ****************************
 * pcie_app_7x
 * ****************************
 */
pcie_app_7x  #(
	.C_DATA_WIDTH(C_DATA_WIDTH),
	.TCQ(TCQ)
) pcie_app_7x0 (
	.user_clk                       (pcie_clk),
	.user_reset                     (user_reset_q),
	.user_lnk_up                    (user_lnk_up_q),

	// Tx: output
	.s_axis_tx_req                  (pcie_tx_req),
	.s_axis_tx_ack                  (pcie_tx_ack),

	.s_axis_tx_tready               (pcie_tx_tready),
	.s_axis_tx_tvalid               (pcie_tx_tvalid),
	.s_axis_tx_tlast                (pcie_tx_tlast),
	.s_axis_tx_tkeep                (pcie_tx_tkeep),
	.s_axis_tx_tdata                (pcie_tx_tdata),
	.s_axis_tx_tuser                (pcie_tx_tuser),

	// Rx: input
	.m_axis_rx_tready               (m_axis_rx_tready1),
	.m_axis_rx_tvalid               (m_axis_rx_tvalid1),
	.m_axis_rx_tlast                (m_axis_rx_tlast1),
	.m_axis_rx_tkeep                (m_axis_rx_tkeep1),
	.m_axis_rx_tdata                (m_axis_rx_tdata1),
	.m_axis_rx_tuser                (m_axis_rx_tuser1),

	.*
);

endmodule

`default_nettype wire

