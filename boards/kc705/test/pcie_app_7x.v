`default_nettype none
`timescale 1ps / 1ps

module  pcie_app_7x #(
	parameter C_DATA_WIDTH = 64,
	parameter KEEP_WIDTH = C_DATA_WIDTH / 8,
	parameter TCQ = 1
)(
  input                         user_clk,
  input                         user_reset,
  input                         user_lnk_up,

  // Tx
  output logic                   s_axis_tx_req,
  input  wire                   s_axis_tx_ack,

  input                         s_axis_tx_tready,
  output  [C_DATA_WIDTH-1:0]    s_axis_tx_tdata,
  output  [KEEP_WIDTH-1:0]      s_axis_tx_tkeep,
  output  [3:0]                 s_axis_tx_tuser,
  output                        s_axis_tx_tlast,
  output                        s_axis_tx_tvalid,

  // Rx
  input  [C_DATA_WIDTH-1:0]     m_axis_rx_tdata,
  input  [KEEP_WIDTH-1:0]       m_axis_rx_tkeep,
  input                         m_axis_rx_tlast,
  input                         m_axis_rx_tvalid,
  output                        m_axis_rx_tready,
  input    [21:0]               m_axis_rx_tuser,

  input                         cfg_to_turnoff,
  input   [7:0]                 cfg_bus_number,
  input   [4:0]                 cfg_device_number,
  input   [2:0]                 cfg_function_number,
  output                        tx_cfg_gnt,
  output                        cfg_pm_halt_aspm_l0s,
  output                        cfg_pm_halt_aspm_l1,
  output                        cfg_pm_force_state_en,
  output [1:0]                  cfg_pm_force_state,
  output                        rx_np_ok,
  output                        rx_np_req,
  output                        cfg_turnoff_ok,
  output                        cfg_trn_pending,
  output                        cfg_pm_wake,
  output [63:0]                 cfg_dsn,
  // Flow Control
  output [2:0]                  fc_sel,
  // CFG
  output                        cfg_err_cor,
  output                        cfg_err_ur,
  output                        cfg_err_ecrc,
  output                        cfg_err_cpl_timeout,
  output                        cfg_err_cpl_unexpect,
  output                        cfg_err_cpl_abort,
  output                        cfg_err_atomic_egress_blocked,
  output                        cfg_err_internal_cor,
  output                        cfg_err_malformed,
  output                        cfg_err_mc_blocked,
  output                        cfg_err_poisoned,
  output                        cfg_err_norecovery,
  output                        cfg_err_acs,
  output                        cfg_err_internal_uncor,
  output                        cfg_err_posted,
  output                        cfg_err_locked,
  output [47:0]                 cfg_err_tlp_cpl_header,
  output [127:0]                cfg_err_aer_headerlog,
  output   [4:0]                cfg_aer_interrupt_msgnum,
  output  [1:0]                 pl_directed_link_change,
  output  [1:0]                 pl_directed_link_width,
  output                        pl_directed_link_speed,
  output                        pl_directed_link_auton,
  output                        pl_upstream_prefer_deemph,
  output [31:0]                 cfg_mgmt_di,
  output  [3:0]                 cfg_mgmt_byte_en,
  output  [9:0]                 cfg_mgmt_dwaddr,
  output                        cfg_mgmt_wr_en,
  output                        cfg_mgmt_rd_en,
  output                        cfg_mgmt_wr_readonly, 
  output                        cfg_interrupt,
  output                        cfg_interrupt_assert,
  output [7:0]                  cfg_interrupt_di,
  output                        cfg_interrupt_stat,
  output  [4:0]                 cfg_pciecap_interrupt_msgnum,

	// adapter registers
	input wire [31:0] adapter_reg_magic,
	input wire [47:0] adapter_reg_dstmac,
	input wire [47:0] adapter_reg_srcmac,
	input wire [31:0] adapter_reg_dstip,
	input wire [31:0] adapter_reg_srcip,
	input wire [15:0] adapter_reg_dstport,
	input wire [15:0] adapter_reg_srcport
);

// input ports
wire _unused_ok = &{
	cfg_to_turnoff,
	m_axis_rx_tlast,
	m_axis_rx_tvalid,
	s_axis_tx_tready,
	user_clk,
	user_lnk_up,
	user_reset,
	m_axis_rx_tuser,
	cfg_function_number,
	cfg_device_number,
	cfg_bus_number,
	m_axis_rx_tdata,
	m_axis_rx_tkeep,
	s_axis_tx_ack,
	adapter_reg_magic,
	adapter_reg_dstmac,
	adapter_reg_srcmac,
	adapter_reg_dstip,
	adapter_reg_srcip,
	adapter_reg_dstport,
	adapter_reg_srcport,
	1'b0
};

// output ports
always_comb cfg_err_acs = 'b0;
always_comb cfg_err_atomic_egress_blocked = 'b0;
always_comb cfg_err_cor = 'b0;
always_comb cfg_err_cpl_abort = 'b0;
always_comb cfg_err_cpl_timeout = 'b0;
always_comb cfg_err_cpl_unexpect = 'b0;
always_comb cfg_err_ecrc = 'b0;
always_comb cfg_err_internal_cor = 'b0;
always_comb cfg_err_internal_uncor = 'b0;
always_comb cfg_err_locked = 'b0;
always_comb cfg_err_malformed = 'b0;
always_comb cfg_err_mc_blocked = 'b0;
always_comb cfg_err_norecovery = 'b0;
always_comb cfg_err_poisoned = 'b0;
always_comb cfg_err_posted = 'b0;
always_comb cfg_err_ur = 'b0;
always_comb cfg_interrupt = 'b0;
always_comb cfg_interrupt_assert = 'b0;
always_comb cfg_interrupt_stat = 'b0;
always_comb cfg_mgmt_rd_en = 'b0;
always_comb cfg_mgmt_wr_en = 'b0;
always_comb cfg_mgmt_wr_readonly = 'b0; 
always_comb cfg_pm_force_state_en = 'b0;
always_comb cfg_pm_halt_aspm_l0s = 'b0;
always_comb cfg_pm_halt_aspm_l1 = 'b0;
always_comb cfg_pm_wake = 'b0;
always_comb cfg_trn_pending = 'b0;
always_comb cfg_turnoff_ok = 'b0;
always_comb m_axis_rx_tready = 'b0;
always_comb pl_directed_link_auton = 'b0;
always_comb pl_directed_link_speed = 'b0;
always_comb pl_upstream_prefer_deemph = 'b0;
always_comb rx_np_ok = 'b0;
always_comb rx_np_req = 'b0;
always_comb s_axis_tx_tlast = 'b0;
always_comb s_axis_tx_tvalid = 'b0;
always_comb tx_cfg_gnt = 'b0;
always_comb cfg_aer_interrupt_msgnum = 'b0;
always_comb pl_directed_link_change = 'b0;
always_comb pl_directed_link_width = 'b0;
always_comb cfg_mgmt_byte_en = 'b0;
always_comb s_axis_tx_tuser = 'b0;
always_comb cfg_pciecap_interrupt_msgnum = 'b0;
always_comb cfg_mgmt_dwaddr = 'b0;
always_comb s_axis_tx_tdata = 'b0;
always_comb s_axis_tx_tkeep = 'b0;
always_comb cfg_err_aer_headerlog = 'b0;
always_comb cfg_pm_force_state = 'b0;
always_comb fc_sel = 'b0;
always_comb cfg_mgmt_di = 'b0;
always_comb cfg_err_tlp_cpl_header = 'b0;
always_comb cfg_dsn = 'b0;
always_comb cfg_interrupt_di = 'b0;
always_comb s_axis_tx_req = 'b0;

endmodule
`default_nettype wire
