`default_nettype none
`timescale 1ns / 1ps

module top #(
	parameter COLD_RESET_INTVAL   = 14'hfff,
	parameter PL_FAST_TRAIN       = "FALSE", // Simulation Speedup
	parameter PCIE_EXT_CLK        = "TRUE",    // Use External Clocking Module
	parameter PCIE_EXT_GT_COMMON  = "FALSE",
	parameter REF_CLK_FREQ        = 0,     // 0 - 100 MHz, 1 - 125 MHz, 2 - 250 MHz
	parameter C_DATA_WIDTH        = 64, // RX/TX interface data width
	parameter KEEP_WIDTH          = C_DATA_WIDTH / 8, // TSTRB width
	parameter LINK_WIDTH          = C_DATA_WIDTH / 16 // PCIe Link Width
) (
	input wire clk200_p,
	input wire clk200_n,

	input wire sys_clk_p,
	input wire sys_clk_n,
	input wire sys_rst_n,

	output wire [LINK_WIDTH-1:0] pci_exp_txp,
	output wire [LINK_WIDTH-1:0] pci_exp_txn,
	input wire [LINK_WIDTH-1:0] pci_exp_rxp,
	input wire [LINK_WIDTH-1:0] pci_exp_rxn,

	inout  wire I2C_FPGA_SCL,
	inout  wire I2C_FPGA_SDA,
	output wire I2C_FPGA_RST_N,
	output wire SI5324_RST_N,

	// Ethernet
	input  wire SFP_CLK_P,
	input  wire SFP_CLK_N,

	// Ethernet (ETH0)
	input  wire ETH0_TX_P,
	input  wire ETH0_TX_N,
	output wire ETH0_RX_P,
	output wire ETH0_RX_N,
	output wire ETH0_TX_DISABLE
);

// clk200
wire clk200;
IBUFDS IBUFDS_clk200 (
	.I(clk200_p),
	.IB(clk200_n),
	.O(clk200)
);

// sys_rst_200
reg [13:0] cold_counter200 = 14'd0;
reg sys_rst200;
always @(posedge clk200) begin
	if (cold_counter200 != COLD_RESET_INTVAL) begin
		cold_counter200 <= cold_counter200 + 14'd1;
		sys_rst200 <= 1'b1;
	end else begin
		sys_rst200 <= 1'b0;
	end
end

// clk156
wire clk156;

// sys_rst_156
reg [13:0] cold_counter156 = 14'd0;
reg sys_rst156;
always @(posedge clk156) begin
	if (cold_counter156 != COLD_RESET_INTVAL) begin
		cold_counter156 <= cold_counter156 + 14'd1;
		sys_rst156 <= 1'b1;
	end else begin
		sys_rst156 <= 1'b0;
	end
end

// clk100
wire clk100;
reg clock_divide = 1'b0;
always @(posedge clk200)
	clock_divide <= ~clock_divide;
BUFG buffer_clk100 (
	.I(clock_divide),
	.O(clk100)
);

wire user_clk;
wire user_reset;
wire user_lnk_up;

reg user_reset_q;
reg user_lnk_up_q;
reg [25:0] user_clk_heartbeat = 'h0;

wire pcie_rst = (~user_lnk_up_q | user_reset_q);

/*
 * ****************************
 * Eternet top instance
 * ****************************
 */
wire        eth_rx_tvalid;
wire [63:0] eth_rx_tdata;
wire [ 7:0] eth_rx_tkeep;
wire        eth_rx_tlast;
wire        eth_rx_tuser;
wire        eth_tx_tready;
wire        eth_tx_tvalid;
wire [63:0] eth_tx_tdata;
wire [ 7:0] eth_tx_tkeep;
wire        eth_tx_tlast;
wire        eth_tx_tuser;

eth_top eth_top0 (
	.clk100             (clk100),
	.sys_rst            (sys_rst156),

	/* XGMII */
	.SFP_CLK_P          (SFP_CLK_P),
	.SFP_CLK_N          (SFP_CLK_N),

	.ETH0_TX_P          (ETH0_TX_P),
	.ETH0_TX_N          (ETH0_TX_N),
	.ETH0_RX_P          (ETH0_RX_P),
	.ETH0_RX_N          (ETH0_RX_N),

	.I2C_FPGA_SCL       (I2C_FPGA_SCL),
	.I2C_FPGA_SDA       (I2C_FPGA_SDA),
	.I2C_FPGA_RST_N     (I2C_FPGA_RST_N),
	.SI5324_RST_N       (SI5324_RST_N),

	.ETH0_TX_DISABLE    (ETH0_TX_DISABLE),

	// ethernet
	.clk156           (clk156),

	.eth_rx_tvalid    (eth_rx_tvalid),
	.eth_rx_tdata     (eth_rx_tdata),
	.eth_rx_tkeep     (eth_rx_tkeep),
	.eth_rx_tlast     (eth_rx_tlast),
	.eth_rx_tuser     (eth_rx_tuser),

	.eth_tx_tvalid    (eth_tx_tvalid),
	.eth_tx_tready    (eth_tx_tready),
	.eth_tx_tdata     (eth_tx_tdata),
	.eth_tx_tkeep     (eth_tx_tkeep),
	.eth_tx_tlast     (eth_tx_tlast),
	.eth_tx_tuser     (eth_tx_tuser)
);
 

wire sys_rst_n_c;
wire sys_clk;

// PCIe Rx
wire                       m_axis_rx_tready;
wire                       m_axis_rx_tvalid;
wire                       m_axis_rx_tlast;
wire [KEEP_WIDTH-1:0]      m_axis_rx_tkeep;
wire [C_DATA_WIDTH-1:0]    m_axis_rx_tdata;
wire [21:0]                m_axis_rx_tuser;

wire                       pcie_app_rx_tready;
wire                       pcie_app_rx_tvalid;
wire                       pcie_app_rx_tlast;
wire [KEEP_WIDTH-1:0]      pcie_app_rx_tkeep;
wire [C_DATA_WIDTH-1:0]    pcie_app_rx_tdata;
wire [21:0]                pcie_app_rx_tuser;

wire                       pcie_snoop_rx_tready;
wire                       pcie_snoop_rx_tvalid;
wire                       pcie_snoop_rx_tlast;
wire [KEEP_WIDTH-1:0]      pcie_snoop_rx_tkeep;
wire [C_DATA_WIDTH-1:0]    pcie_snoop_rx_tdata;
wire [21:0]                pcie_snoop_rx_tuser;

pcie_rx_filter #(
	.C_DATA_WIDTH (C_DATA_WIDTH),
	.KEEP_WIDTH   (KEEP_WIDTH)
) pcie_rx_filter (
	// PCIe input from pcie_7x_support
	.m_axis_rx_tready    (m_axis_rx_tready), 
	.m_axis_rx_tvalid    (m_axis_rx_tvalid),
	.m_axis_rx_tdata     (m_axis_rx_tdata),
	.m_axis_rx_tkeep     (m_axis_rx_tkeep),
	.m_axis_rx_tlast     (m_axis_rx_tlast),
	.m_axis_rx_tuser     (m_axis_rx_tuser),
		
	// PCIe output to pcie_app (hardware PIO engine)
	.pcie_app_rx_tready    (pcie_app_rx_tready),
	.pcie_app_rx_tvalid    (pcie_app_rx_tvalid),
	.pcie_app_rx_tdata     (pcie_app_rx_tdata),
	.pcie_app_rx_tkeep     (pcie_app_rx_tkeep),
	.pcie_app_rx_tlast     (pcie_app_rx_tlast),
	.pcie_app_rx_tuser     (pcie_app_rx_tuser),

	// PCIe output to tlp_rx_snoop (ethernet)
	.pcie_snoop_rx_tready    (pcie_snoop_rx_tready),
	.pcie_snoop_rx_tvalid    (pcie_snoop_rx_tvalid),
	.pcie_snoop_rx_tdata     (pcie_snoop_rx_tdata),
	.pcie_snoop_rx_tkeep     (pcie_snoop_rx_tkeep),
	.pcie_snoop_rx_tlast     (pcie_snoop_rx_tlast),
	.pcie_snoop_rx_tuser     (pcie_snoop_rx_tuser)
);

//assign m_axis_rx_tready = pcie_app_rx_tready;
//assign pcie_app_rx_tvalid = m_axis_rx_tvalid;
//assign pcie_app_rx_tlast  = m_axis_rx_tlast;
//assign pcie_app_rx_tkeep  = m_axis_rx_tkeep;
//assign pcie_app_rx_tdata  = m_axis_rx_tdata;
//assign pcie_app_rx_tuser  = m_axis_rx_tuser;
// 
//assign pcie_snoop_rx_tready = pcie_app_rx_tready;
//assign pcie_snoop_rx_tvalid = m_axis_rx_tvalid;
//assign pcie_snoop_rx_tlast  = m_axis_rx_tlast;
//assign pcie_snoop_rx_tkeep  = m_axis_rx_tkeep;
//assign pcie_snoop_rx_tdata  = m_axis_rx_tdata;
//assign pcie_snoop_rx_tuser  = m_axis_rx_tuser;


/*
 * ****************************
 * PCIe-Ethernet bridge (tlp_rx_snoop) top instance
 * ****************************
 */

wire [31:0] adapter_reg_magic;
wire [47:0] adapter_reg_dstmac;
wire [47:0] adapter_reg_srcmac;
wire [31:0] adapter_reg_dstip;
wire [31:0] adapter_reg_srcip;
wire [15:0] adapter_reg_dstport;
wire [15:0] adapter_reg_srcport;

tlp_rx_snoop tlp_rx_snoop0 (
	.sys_rst156       (sys_rst156),
	.pcie_rst         (pcie_rst),
//	.pcie_rst         (sys_rst200),

	.eth_clk          (clk156),
	.pcie_clk          (user_clk),
		
	// Eth output
	.eth_tx_tready    (eth_tx_tready),
	.eth_tx_tvalid    (eth_tx_tvalid),
	.eth_tx_tdata     (eth_tx_tdata),
	.eth_tx_tkeep     (eth_tx_tkeep),
	.eth_tx_tlast     (eth_tx_tlast),
	.eth_tx_tuser     (eth_tx_tuser),

	// PCIe input
	.pcie_rx_tready    (pcie_snoop_rx_tready), 
	.pcie_rx_tvalid    (pcie_snoop_rx_tvalid),
	.pcie_rx_tdata     (pcie_snoop_rx_tdata),
	.pcie_rx_tkeep     (pcie_snoop_rx_tkeep),
	.pcie_rx_tlast     (pcie_snoop_rx_tlast),
	.pcie_rx_tuser     (pcie_snoop_rx_tuser),

	.adapter_reg_magic  (adapter_reg_magic),
	.adapter_reg_dstmac (adapter_reg_dstmac),
	.adapter_reg_srcmac (adapter_reg_srcmac),
	.adapter_reg_dstip  (adapter_reg_dstip),
	.adapter_reg_srcip  (adapter_reg_srcip),
	.adapter_reg_dstport(adapter_reg_dstport),
	.adapter_reg_srcport(adapter_reg_srcport)
);

/*
 * ****************************
 * Ethernet-PCIe bridge (tlp_tx_inject) top instance
 * ****************************
 */

// PCIe TX: input from pcie_app_7x.PIO.PIO_EP.PIO_TX_ENGINE
wire                    pcie_tx_req_app;
wire                    pcie_tx_ack_app;

wire                    pcie_tx_tready_app;
wire                    pcie_tx_tvalid_app;
wire                    pcie_tx_tlast_app;
wire [KEEP_WIDTH-1:0]   pcie_tx_tkeep_app;
wire [C_DATA_WIDTH-1:0] pcie_tx_tdata_app;
wire [3:0]              pcie_tx_tuser_app;

// PCIe TX: output to pcie_supprt
wire                    pcie_tx_tready;
wire                    pcie_tx_tvalid;
wire                    pcie_tx_tlast;
wire [KEEP_WIDTH-1:0]   pcie_tx_tkeep;
wire [C_DATA_WIDTH-1:0] pcie_tx_tdata;
wire [3:0]              pcie_tx_tuser;

tlp_tx_inject tlp_tx_inject0 (
	.pcie_clk (user_clk),
	.pcie_rst (pcie_rst),

	.eth_clk (clk156),
	.eth_rst (sys_rst156),
		
	// input: Ethernet
	.eth_rx_tvalid   (eth_rx_tvalid),
	.eth_rx_tdata    (eth_rx_tdata),
	.eth_rx_tkeep    (eth_rx_tkeep),
	.eth_rx_tlast    (eth_rx_tlast),
	.eth_rx_tuser    (eth_rx_tuser),

	// input: from pio_tx_engine
	.pcie_tx1_req     (pcie_tx_req_app),
	.pcie_tx1_ack     (pcie_tx_ack_app),

	.pcie_tx1_tready  (pcie_tx_tready_app),
	.pcie_tx1_tvalid  (pcie_tx_tvalid_app),
	.pcie_tx1_tdata   (pcie_tx_tdata_app),
	.pcie_tx1_tkeep   (pcie_tx_tkeep_app),
	.pcie_tx1_tlast   (pcie_tx_tlast_app),
	.pcie_tx1_tuser   (pcie_tx_tuser_app),

	// output: to pcie_7x_support
	.pcie_tx_tready  (pcie_tx_tready), 
	.pcie_tx_tvalid  (pcie_tx_tvalid),
	.pcie_tx_tdata   (pcie_tx_tdata),
	.pcie_tx_tkeep   (pcie_tx_tkeep),
	.pcie_tx_tlast   (pcie_tx_tlast),
	.pcie_tx_tuser   (pcie_tx_tuser)
);

/*
* ****************************
* PCIe top instance
* ****************************
*/
wire                                        pipe_mmcm_rst_n;

wire                                        tx_cfg_gnt;
wire                                        rx_np_ok;
wire                                        rx_np_req;
wire                                        cfg_turnoff_ok;
wire                                        cfg_trn_pending;
wire                                        cfg_pm_halt_aspm_l0s;
wire                                        cfg_pm_halt_aspm_l1;
wire                                        cfg_pm_force_state_en;
wire   [1:0]                                cfg_pm_force_state;
wire                                        cfg_pm_wake;
wire  [63:0]                                cfg_dsn;

// Flow Control
wire [2:0]                                  fc_sel;

//-------------------------------------------------------
// Configuration (CFG) Interface
//-------------------------------------------------------
wire                                        cfg_err_ecrc;
wire                                        cfg_err_cor;
wire                                        cfg_err_ur;
wire                                        cfg_err_cpl_timeout;
wire                                        cfg_err_cpl_abort;
wire                                        cfg_err_cpl_unexpect;
wire                                        cfg_err_posted;
wire                                        cfg_err_locked;
wire  [47:0]                                cfg_err_tlp_cpl_header;
wire [127:0]                                cfg_err_aer_headerlog;
wire   [4:0]                                cfg_aer_interrupt_msgnum;

wire                                        cfg_interrupt;
wire                                        cfg_interrupt_assert;
wire   [7:0]                                cfg_interrupt_di;
wire                                        cfg_interrupt_stat;
wire   [4:0]                                cfg_pciecap_interrupt_msgnum;

wire                                        cfg_to_turnoff;
wire   [7:0]                                cfg_bus_number;
wire   [4:0]                                cfg_device_number;
wire   [2:0]                                cfg_function_number;

wire  [31:0]                                cfg_mgmt_di;
wire   [3:0]                                cfg_mgmt_byte_en;
wire   [9:0]                                cfg_mgmt_dwaddr;
wire                                        cfg_mgmt_wr_en;
wire                                        cfg_mgmt_rd_en;
wire                                        cfg_mgmt_wr_readonly;

//-------------------------------------------------------
// Physical Layer Control and Status (PL) Interface
//-------------------------------------------------------
wire                                        pl_directed_link_auton;
wire [1:0]                                  pl_directed_link_change;
wire                                        pl_directed_link_speed;
wire [1:0]                                  pl_directed_link_width;
wire                                        pl_upstream_prefer_deemph;


// Local Parameters
localparam TCQ               = 1;
localparam USER_CLK_FREQ     = 3;
localparam USER_CLK2_DIV2    = "FALSE";
localparam USERCLK2_FREQ     = (USER_CLK2_DIV2 == "TRUE") ? (USER_CLK_FREQ == 4) ? 3 : (USER_CLK_FREQ == 3) ? 2 : USER_CLK_FREQ: USER_CLK_FREQ;

 //-----------------------------I/O BUFFERS------------------------//

IBUF   sys_reset_n_ibuf (.O(sys_rst_n_c), .I(sys_rst_n));

IBUFDS_GTE2 refclk_ibuf (.O(sys_clk), .ODIV2(), .I(sys_clk_p), .CEB(1'b0), .IB(sys_clk_n));

wire sys_rst = (sys_rst200 | ~user_lnk_up_q | user_reset_q);


always @(posedge user_clk) begin
	user_reset_q  <= user_reset;
	user_lnk_up_q <= user_lnk_up;
end

// Create a Clock Heartbeat on LED #3
always @(posedge user_clk) begin
	user_clk_heartbeat <= #TCQ user_clk_heartbeat + 1'b1;
end


assign pipe_mmcm_rst_n = 1'b1;

wire cfg_err_atomic_egress_blocked;
wire cfg_err_internal_cor;
wire cfg_err_malformed;
wire cfg_err_mc_blocked;
wire cfg_err_poisoned;
wire cfg_err_norecovery;
wire cfg_err_acs;
wire cfg_err_internal_uncor;

pcie_7x_support #
   (	 
    .LINK_CAP_MAX_LINK_WIDTH        ( LINK_WIDTH ),  // PCIe Lane Width
    .C_DATA_WIDTH                   ( C_DATA_WIDTH ),                       // RX/TX interface data width
    .KEEP_WIDTH                     ( KEEP_WIDTH ),                         // TSTRB width
    .PCIE_REFCLK_FREQ               ( REF_CLK_FREQ ),                       // PCIe reference clock frequency
    .PCIE_USERCLK1_FREQ             ( USER_CLK_FREQ +1 ),                   // PCIe user clock 1 frequency
    .PCIE_USERCLK2_FREQ             ( USERCLK2_FREQ +1 ),                   // PCIe user clock 2 frequency             
    .PCIE_USE_MODE                  ("3.0"),           // PCIe use mode
    .PCIE_GT_DEVICE                 ("GTX")              // PCIe GT device
   ) 
pcie_7x_support_i
  (

  //----------------------------------------------------------------------------------------------------------------//
  // PCI Express (pci_exp) Interface                                                                                //
  //----------------------------------------------------------------------------------------------------------------//
  // Tx
  .pci_exp_txn                               ( pci_exp_txn ),
  .pci_exp_txp                               ( pci_exp_txp ),

  // Rx
  .pci_exp_rxn                               ( pci_exp_rxn ),
  .pci_exp_rxp                               ( pci_exp_rxp ),

  //----------------------------------------------------------------------------------------------------------------//
  // Clocking Sharing Interface                                                                                     //
  //----------------------------------------------------------------------------------------------------------------//
  .pipe_pclk_out_slave                        ( ),
  .pipe_rxusrclk_out                          ( ),
  .pipe_rxoutclk_out                          ( ),
  .pipe_dclk_out                              ( ),
  .pipe_userclk1_out                          ( ),
  .pipe_oobclk_out                            ( ),
  .pipe_userclk2_out                          ( ),
  .pipe_mmcm_lock_out                         ( ),
  .pipe_pclk_sel_slave                        ( 4'b0),
  .pipe_mmcm_rst_n                            ( pipe_mmcm_rst_n ),        // Async      | Async


  //----------------------------------------------------------------------------------------------------------------//
  // AXI-S Interface                                                                                                //
  //----------------------------------------------------------------------------------------------------------------//

  // Common
  .user_clk_out                              ( user_clk ),
  .user_reset_out                            ( user_reset ),
  .user_lnk_up                               ( user_lnk_up ),
  .user_app_rdy                              ( ),

  // TX
  .s_axis_tx_tready                          ( pcie_tx_tready ),
  .s_axis_tx_tvalid                          ( pcie_tx_tvalid ),
  .s_axis_tx_tlast                           ( pcie_tx_tlast ),
  .s_axis_tx_tkeep                           ( pcie_tx_tkeep ),
  .s_axis_tx_tdata                           ( pcie_tx_tdata ),
  .s_axis_tx_tuser                           ( pcie_tx_tuser ),

  // Rx
  .m_axis_rx_tready                          ( m_axis_rx_tready ),
  .m_axis_rx_tvalid                          ( m_axis_rx_tvalid ),
  .m_axis_rx_tlast                           ( m_axis_rx_tlast ),
  .m_axis_rx_tkeep                           ( m_axis_rx_tkeep ),
  .m_axis_rx_tdata                           ( m_axis_rx_tdata ),
  .m_axis_rx_tuser                           ( m_axis_rx_tuser ),

  // Flow Control
  .fc_cpld                                   ( ),
  .fc_cplh                                   ( ),
  .fc_npd                                    ( ),
  .fc_nph                                    ( ),
  .fc_pd                                     ( ),
  .fc_ph                                     ( ),
  .fc_sel                                    ( fc_sel ),

  // Management Interface
  .cfg_mgmt_di                               ( cfg_mgmt_di ),
  .cfg_mgmt_byte_en                          ( cfg_mgmt_byte_en ),
  .cfg_mgmt_dwaddr                           ( cfg_mgmt_dwaddr ),
  .cfg_mgmt_wr_en                            ( cfg_mgmt_wr_en ),
  .cfg_mgmt_rd_en                            ( cfg_mgmt_rd_en ),
  .cfg_mgmt_wr_readonly                      ( cfg_mgmt_wr_readonly ),

  //------------------------------------------------//
  // EP and RP                                      //
  //------------------------------------------------//
  .cfg_mgmt_do                               ( ),
  .cfg_mgmt_rd_wr_done                       ( ),
  .cfg_mgmt_wr_rw1c_as_rw                    ( 1'b0 ),

  // Error Reporting Interface
  .cfg_err_ecrc                              ( cfg_err_ecrc ),
  .cfg_err_ur                                ( cfg_err_ur ),
  .cfg_err_cpl_timeout                       ( cfg_err_cpl_timeout ),
  .cfg_err_cpl_unexpect                      ( cfg_err_cpl_unexpect ),
  .cfg_err_cpl_abort                         ( cfg_err_cpl_abort ),
  .cfg_err_posted                            ( cfg_err_posted ),
  .cfg_err_cor                               ( cfg_err_cor ),
  .cfg_err_atomic_egress_blocked             ( cfg_err_atomic_egress_blocked ),
  .cfg_err_internal_cor                      ( cfg_err_internal_cor ),
  .cfg_err_malformed                         ( cfg_err_malformed ),
  .cfg_err_mc_blocked                        ( cfg_err_mc_blocked ),
  .cfg_err_poisoned                          ( cfg_err_poisoned ),
  .cfg_err_norecovery                        ( cfg_err_norecovery ),
  .cfg_err_tlp_cpl_header                    ( cfg_err_tlp_cpl_header ),
  .cfg_err_cpl_rdy                           ( ),
  .cfg_err_locked                            ( cfg_err_locked ),
  .cfg_err_acs                               ( cfg_err_acs ),
  .cfg_err_internal_uncor                    ( cfg_err_internal_uncor ),

  //----------------------------------------------------------------------------------------------------------------//
  // AER Interface                                                                                                  //
  //----------------------------------------------------------------------------------------------------------------//
  .cfg_err_aer_headerlog                     ( cfg_err_aer_headerlog ),
  .cfg_err_aer_headerlog_set                 ( ),
  .cfg_aer_ecrc_check_en                     ( ),
  .cfg_aer_ecrc_gen_en                       ( ),
  .cfg_aer_interrupt_msgnum                  ( cfg_aer_interrupt_msgnum ),

  .tx_cfg_gnt                                ( tx_cfg_gnt ),
  .rx_np_ok                                  ( rx_np_ok ),
  .rx_np_req                                 ( rx_np_req ),
  .cfg_trn_pending                           ( cfg_trn_pending ),
  .cfg_pm_halt_aspm_l0s                      ( cfg_pm_halt_aspm_l0s ),
  .cfg_pm_halt_aspm_l1                       ( cfg_pm_halt_aspm_l1 ),
  .cfg_pm_force_state_en                     ( cfg_pm_force_state_en ),
  .cfg_pm_force_state                        ( cfg_pm_force_state ),
  .cfg_dsn                                   ( cfg_dsn ),
  .cfg_turnoff_ok                            ( cfg_turnoff_ok ),
  .cfg_pm_wake                               ( cfg_pm_wake ),
  //------------------------------------------------//
  // RP Only                                        //
  //------------------------------------------------//
  .cfg_pm_send_pme_to                        ( 1'b0 ),
  .cfg_ds_bus_number                         ( 8'b0 ),
  .cfg_ds_device_number                      ( 5'b0 ),
  .cfg_ds_function_number                    ( 3'b0 ),

  //------------------------------------------------//
  // EP Only                                        //
  //------------------------------------------------//
  .cfg_interrupt                             ( cfg_interrupt ),
  .cfg_interrupt_rdy                         ( ),
  .cfg_interrupt_assert                      ( cfg_interrupt_assert ),
  .cfg_interrupt_di                          ( cfg_interrupt_di ),
  .cfg_interrupt_do                          ( ),
  .cfg_interrupt_mmenable                    ( ),
  .cfg_interrupt_msienable                   ( ),
  .cfg_interrupt_msixenable                  ( ),
  .cfg_interrupt_msixfm                      ( ),
  .cfg_interrupt_stat                        ( cfg_interrupt_stat ),
  .cfg_pciecap_interrupt_msgnum              ( cfg_pciecap_interrupt_msgnum ),

  //----------------------------------------------------------------------------------------------------------------//
  // Configuration (CFG) Interface                                                                                  //
  //----------------------------------------------------------------------------------------------------------------//
  .cfg_status                                ( ),
  .cfg_command                               ( ),
  .cfg_dstatus                               ( ),
  .cfg_lstatus                               ( ),
  .cfg_pcie_link_state                       ( ),
  .cfg_dcommand                              ( ),
  .cfg_lcommand                              ( ),
  .cfg_dcommand2                             ( ),

  .cfg_pmcsr_pme_en                          ( ),
  .cfg_pmcsr_powerstate                      ( ),
  .cfg_pmcsr_pme_status                      ( ),
  .cfg_received_func_lvl_rst                 ( ),
  .tx_buf_av                                 ( ),
  .tx_err_drop                               ( ),
  .tx_cfg_req                                ( ),
  .cfg_to_turnoff                            ( cfg_to_turnoff ),
  .cfg_bus_number                            ( cfg_bus_number ),
  .cfg_device_number                         ( cfg_device_number ),
  .cfg_function_number                       ( cfg_function_number ),
  .cfg_bridge_serr_en                        ( ),
  .cfg_slot_control_electromech_il_ctl_pulse ( ),
  .cfg_root_control_syserr_corr_err_en       ( ),
  .cfg_root_control_syserr_non_fatal_err_en  ( ),
  .cfg_root_control_syserr_fatal_err_en      ( ),
  .cfg_root_control_pme_int_en               ( ),
  .cfg_aer_rooterr_corr_err_reporting_en     ( ),
  .cfg_aer_rooterr_non_fatal_err_reporting_en( ),
  .cfg_aer_rooterr_fatal_err_reporting_en    ( ),
  .cfg_aer_rooterr_corr_err_received         ( ),
  .cfg_aer_rooterr_non_fatal_err_received    ( ),
  .cfg_aer_rooterr_fatal_err_received        ( ),
  //----------------------------------------------------------------------------------------------------------------//
  // VC interface                                                                                                  //
  //---------------------------------------------------------------------------------------------------------------//
  .cfg_vc_tcvc_map                           ( ),

  .cfg_msg_received                          ( ),
  .cfg_msg_data                              ( ),
  .cfg_msg_received_err_cor                  ( ),
  .cfg_msg_received_err_non_fatal            ( ),
  .cfg_msg_received_err_fatal                ( ),
  .cfg_msg_received_pm_as_nak                ( ),
  .cfg_msg_received_pme_to_ack               ( ),
  .cfg_msg_received_assert_int_a             ( ),
  .cfg_msg_received_assert_int_b             ( ),
  .cfg_msg_received_assert_int_c             ( ),
  .cfg_msg_received_assert_int_d             ( ),
  .cfg_msg_received_deassert_int_a           ( ),
  .cfg_msg_received_deassert_int_b           ( ),
  .cfg_msg_received_deassert_int_c           ( ),
  .cfg_msg_received_deassert_int_d           ( ),
  .cfg_msg_received_pm_pme                  ( ),
  .cfg_msg_received_setslotpowerlimit       ( ),

  //----------------------------------------------------------------------------------------------------------------//
  // Physical Layer Control and Status (PL) Interface                                                               //
  //----------------------------------------------------------------------------------------------------------------//
  .pl_directed_link_change                   ( pl_directed_link_change ),
  .pl_directed_link_width                    ( pl_directed_link_width ),
  .pl_directed_link_speed                    ( pl_directed_link_speed ),
  .pl_directed_link_auton                    ( pl_directed_link_auton ),
  .pl_upstream_prefer_deemph                 ( pl_upstream_prefer_deemph ),

  .pl_sel_lnk_rate                           ( ),
  .pl_sel_lnk_width                          ( ),
  .pl_ltssm_state                            ( ),
  .pl_lane_reversal_mode                     ( ),

  .pl_phy_lnk_up                             ( ),
  .pl_tx_pm_state                            ( ),
  .pl_rx_pm_state                            ( ),

  .pl_link_upcfg_cap                         ( ),
  .pl_link_gen2_cap                          ( ),
  .pl_link_partner_gen2_supported            ( ),
  .pl_initial_link_width                     ( ),

  .pl_directed_change_done                   ( ),

  //------------------------------------------------//
  // EP Only                                        //
  //------------------------------------------------//
  .pl_received_hot_rst                       ( ),

  //------------------------------------------------//
  // RP Only                                        //
  //------------------------------------------------//
  .pl_transmit_hot_rst                       ( 1'b0 ),
  .pl_downstream_deemph_source               ( 1'b0 ),

  //----------------------------------------------------------------------------------------------------------------//
  // PCIe DRP (PCIe DRP) Interface                                                                                  //
  //----------------------------------------------------------------------------------------------------------------//
  .pcie_drp_clk                               ( 1'b1 ),
  .pcie_drp_en                                ( 1'b0 ),
  .pcie_drp_we                                ( 1'b0 ),
  .pcie_drp_addr                              ( 9'h0 ),
  .pcie_drp_di                                ( 16'h0 ),
  .pcie_drp_rdy                               ( ),
  .pcie_drp_do                                ( ),



  //----------------------------------------------------------------------------------------------------------------//
  // System  (SYS) Interface                                                                                        //
  //----------------------------------------------------------------------------------------------------------------//
  .sys_clk                                    ( sys_clk ),
  .sys_rst_n                                  ( sys_rst_n_c )

);


pcie_app_7x  #(
  .C_DATA_WIDTH( C_DATA_WIDTH ),
  .TCQ( TCQ )

) app (
  //----------------------------------------------------------------------------------------------------------------//
  // AXI-S Interface                                                                                                //
  //----------------------------------------------------------------------------------------------------------------//

  // Common
  .user_clk                       ( user_clk ),
  .user_reset                     ( user_reset_q ),
  .user_lnk_up                    ( user_lnk_up_q ),

  // Tx: output
  .s_axis_tx_req                  (pcie_tx_req_app),
  .s_axis_tx_ack                  (pcie_tx_ack_app),

  .s_axis_tx_tready               ( pcie_tx_tready_app ),
  .s_axis_tx_tvalid               ( pcie_tx_tvalid_app ),
  .s_axis_tx_tlast                ( pcie_tx_tlast_app ),
  .s_axis_tx_tkeep                ( pcie_tx_tkeep_app ),
  .s_axis_tx_tdata                ( pcie_tx_tdata_app ),
  .s_axis_tx_tuser                ( pcie_tx_tuser_app ),

  // Rx: input
  .m_axis_rx_tready               ( pcie_app_rx_tready ),
  .m_axis_rx_tvalid               ( pcie_app_rx_tvalid ),
  .m_axis_rx_tlast                ( pcie_app_rx_tlast ),
  .m_axis_rx_tkeep                ( pcie_app_rx_tkeep ),
  .m_axis_rx_tdata                ( pcie_app_rx_tdata ),
  .m_axis_rx_tuser                ( pcie_app_rx_tuser ),

  .tx_cfg_gnt                     ( tx_cfg_gnt ),
  .rx_np_ok                       ( rx_np_ok ),
  .rx_np_req                      ( rx_np_req ),
  .cfg_turnoff_ok                 ( cfg_turnoff_ok ),
  .cfg_trn_pending                ( cfg_trn_pending ),
  .cfg_pm_halt_aspm_l0s           ( cfg_pm_halt_aspm_l0s ),
  .cfg_pm_halt_aspm_l1            ( cfg_pm_halt_aspm_l1 ),
  .cfg_pm_force_state_en          ( cfg_pm_force_state_en ),
  .cfg_pm_force_state             ( cfg_pm_force_state ),
  .cfg_pm_wake                    ( cfg_pm_wake ),
  .cfg_dsn                        ( cfg_dsn ),

  // Flow Control
  .fc_sel                         ( fc_sel ),

  //----------------------------------------------------------------------------------------------------------------//
  // Configuration (CFG) Interface                                                                                  //
  //----------------------------------------------------------------------------------------------------------------//
  .cfg_err_cor                    ( cfg_err_cor ),
  .cfg_err_atomic_egress_blocked  ( cfg_err_atomic_egress_blocked ),
  .cfg_err_internal_cor           ( cfg_err_internal_cor ),
  .cfg_err_malformed              ( cfg_err_malformed ),
  .cfg_err_mc_blocked             ( cfg_err_mc_blocked ),
  .cfg_err_poisoned               ( cfg_err_poisoned ),
  .cfg_err_norecovery             ( cfg_err_norecovery ),
  .cfg_err_ur                     ( cfg_err_ur ),
  .cfg_err_ecrc                   ( cfg_err_ecrc ),
  .cfg_err_cpl_timeout            ( cfg_err_cpl_timeout ),
  .cfg_err_cpl_abort              ( cfg_err_cpl_abort ),
  .cfg_err_cpl_unexpect           ( cfg_err_cpl_unexpect ),
  .cfg_err_posted                 ( cfg_err_posted ),
  .cfg_err_locked                 ( cfg_err_locked ),
  .cfg_err_acs                    ( cfg_err_acs ), //1'b0 ),
  .cfg_err_internal_uncor         ( cfg_err_internal_uncor ), //1'b0 ),
  .cfg_err_tlp_cpl_header         ( cfg_err_tlp_cpl_header ),
  //----------------------------------------------------------------------------------------------------------------//
  // Advanced Error Reporting (AER) Interface                                                                       //
  //----------------------------------------------------------------------------------------------------------------//
  .cfg_err_aer_headerlog          ( cfg_err_aer_headerlog ),
  .cfg_aer_interrupt_msgnum       ( cfg_aer_interrupt_msgnum ),

  .cfg_to_turnoff                 ( cfg_to_turnoff ),
  .cfg_bus_number                 ( cfg_bus_number ),
  .cfg_device_number              ( cfg_device_number ),
  .cfg_function_number            ( cfg_function_number ),

  //----------------------------------------------------------------------------------------------------------------//
  // Management (MGMT) Interface                                                                                    //
  //----------------------------------------------------------------------------------------------------------------//
  .cfg_mgmt_di                    ( cfg_mgmt_di ),
  .cfg_mgmt_byte_en               ( cfg_mgmt_byte_en ),
  .cfg_mgmt_dwaddr                ( cfg_mgmt_dwaddr ),
  .cfg_mgmt_wr_en                 ( cfg_mgmt_wr_en ),
  .cfg_mgmt_rd_en                 ( cfg_mgmt_rd_en ),
  .cfg_mgmt_wr_readonly           ( cfg_mgmt_wr_readonly ),

  //----------------------------------------------------------------------------------------------------------------//
  // Physical Layer Control and Status (PL) Interface                                                               //
  //----------------------------------------------------------------------------------------------------------------//
  .pl_directed_link_auton         ( pl_directed_link_auton ),
  .pl_directed_link_change        ( pl_directed_link_change ),
  .pl_directed_link_speed         ( pl_directed_link_speed ),
  .pl_directed_link_width         ( pl_directed_link_width ),
  .pl_upstream_prefer_deemph      ( pl_upstream_prefer_deemph ),

  .cfg_interrupt                  ( cfg_interrupt ),
  .cfg_interrupt_assert           ( cfg_interrupt_assert ),
  .cfg_interrupt_di               ( cfg_interrupt_di ),
  .cfg_interrupt_stat             ( cfg_interrupt_stat ),
  .cfg_pciecap_interrupt_msgnum   ( cfg_pciecap_interrupt_msgnum ),
  
	.adapter_reg_magic  (adapter_reg_magic),
	.adapter_reg_dstmac (adapter_reg_dstmac),
	.adapter_reg_srcmac (adapter_reg_srcmac),
	.adapter_reg_dstip  (adapter_reg_dstip),
	.adapter_reg_srcip  (adapter_reg_srcip),
	.adapter_reg_dstport(adapter_reg_dstport),
	.adapter_reg_srcport(adapter_reg_srcport)
);


/***********************************************
 * ILA
 */

`ifdef NO
reg [C_DATA_WIDTH-1:0]    pcie_rx_tdata_reg;
reg [KEEP_WIDTH-1:0]      pcie_rx_tkeep_reg;
reg                       pcie_rx_tlast_reg;
reg                       pcie_rx_tvalid_reg;
reg                       pcie_rx_tready_reg;
reg  [21:0]               pcie_rx_tuser_reg;

always @(posedge user_clk) begin
	if(~sys_rst_n_c) begin
		pcie_rx_tdata_reg  <= 0;
		pcie_rx_tuser_reg  <= 0;
		pcie_rx_tlast_reg  <= 0;
		pcie_rx_tkeep_reg  <= 0;
		pcie_rx_tvalid_reg <= 0;
		pcie_rx_tready_reg <= 0;
	end else begin
		pcie_rx_tdata_reg  <= pcie_rx_tdata;
		pcie_rx_tuser_reg  <= pcie_rx_tuser;
		pcie_rx_tlast_reg  <= pcie_rx_tlast;
		pcie_rx_tkeep_reg  <= pcie_rx_tkeep;
		pcie_rx_tvalid_reg <= pcie_rx_tvalid;
		pcie_rx_tready_reg <= pcie_rx_tready;
	end
end


// for ila
reg [C_DATA_WIDTH-1:0]   pcie_tx_tdata_reg;
reg [KEEP_WIDTH-1:0]     pcie_tx_tkeep_reg;
reg                      pcie_tx_tlast_reg;
reg                      pcie_tx_tvalid_reg;
reg                      pcie_tx_tready_reg;
reg  [3:0]               pcie_tx_tuser_reg;

always @(posedge user_clk) begin
	if(~sys_rst_n_c) begin
		pcie_tx_tdata_reg  <= 0;
		pcie_tx_tuser_reg  <= 0;
		pcie_tx_tlast_reg  <= 0;
		pcie_tx_tkeep_reg  <= 0;
		pcie_tx_tvalid_reg <= 0;
		pcie_tx_tready_reg <= 0;
	end else begin
		pcie_tx_tdata_reg  <= pcie_tx_tdata;
		pcie_tx_tuser_reg  <= pcie_tx_tuser;
		pcie_tx_tlast_reg  <= pcie_tx_tlast;
		pcie_tx_tkeep_reg  <= pcie_tx_tkeep;
		pcie_tx_tvalid_reg <= pcie_tx_tvalid;
		pcie_tx_tready_reg <= pcie_tx_tready;
	end
end

ila_0 ila_0_ins (
	.clk(user_clk),
	.probe0({ pcie_tx_tready_reg,
	          pcie_tx_tvalid_reg,
	          pcie_tx_tlast_reg,
	          pcie_tx_tkeep_reg,
	          pcie_tx_tdata_reg,
	          pcie_tx_tuser_reg }),
	.probe1({ pcie_rx_tready_reg,
	          pcie_rx_tvalid_reg,
	          pcie_rx_tlast_reg,
	          pcie_rx_tkeep_reg,
	          pcie_rx_tdata_reg,
	          pcie_rx_tuser_reg })
);
`endif

// end: ila

endmodule

`default_nettype wire

