module eth_top (
	input  wire                clk100,
	input  wire                sys_rst,

	input  wire                SFP_CLK_P,
	input  wire                SFP_CLK_N,

	inout  wire                I2C_FPGA_SCL,
	inout  wire                I2C_FPGA_SDA,
	output  wire               I2C_FPGA_RST_N,
	output  wire               SI5324_RST_N,

	// Ether Port 0
	input  wire                ETH0_TX_P,
	input  wire                ETH0_TX_N,
	output wire                ETH0_RX_P,
	output wire                ETH0_RX_N,

	//input  wire                ETH0_TX_FAULT,
	//input  wire                ETH0_RX_LOS,
	output wire                ETH0_TX_DISABLE,

	output wire        clk156,

	output wire        eth_rx_tvalid,
	output wire [63:0] eth_rx_tdata,
	output wire [ 7:0] eth_rx_tkeep,
	output wire        eth_rx_tlast,
	output wire        eth_rx_tuser,

	output wire        eth_tx_tready,
	input  wire        eth_tx_tvalid,
	input  wire [63:0] eth_tx_tdata,
	input  wire [ 7:0] eth_tx_tkeep,
	input  wire        eth_tx_tlast,
	input  wire        eth_tx_tuser
);

/*
 * Ethernet Clock Domain : Clocking
 */
wire clk50;			
reg div_clk50;
always @ (posedge clk100)
	div_clk50 <= ~div_clk50;

BUFG clk50_bufg (
	.I(div_clk50),
	.O(clk50)
);

clock_control u_clk_control (
	.i2c_clk       (I2C_FPGA_SCL),
	.i2c_data      (I2C_FPGA_SDA),
	.i2c_mux_rst_n (I2C_FPGA_RST_N),
	.si5324_rst_n  (SI5324_RST_N),
	.rst           (sys_rst),
	.clk50         (clk50)
);


/*
 * Ethernet MAC and PCS/PMA Configuration
 */

wire [535:0] pcspma_configuration_vector;
eth_pcspma_conf eth_pcspma_conf0(
	.pcspma_configuration_vector(pcspma_configuration_vector)
);

wire [79:0] mac_tx_configuration_vector;
wire [79:0] mac_rx_configuration_vector;
eth_mac_conf eth_mac_conf0(
	.mac_tx_configuration_vector(mac_tx_configuration_vector),
	.mac_rx_configuration_vector(mac_rx_configuration_vector)
);


/*
 * Ethernet MAC
 */
wire txusrclk, txusrclk2;
wire gttxreset, gtrxreset;
wire txuserrdy;
wire areset_coreclk;
wire reset_counter_done;
wire qplllock, qplloutclk, qplloutrefclk;
wire [447:0] pcs_pma_status_vector;
wire [2:0] mac_status_vector;
wire [7:0] pcspma_status;
wire rx_statistics_valid, tx_statistics_valid;


axi_10g_ethernet_0 u_axi_10g_ethernet_0 (
	.tx_axis_aresetn             (!sys_rst),
	.rx_axis_aresetn             (!sys_rst),
	.tx_ifg_delay                (8'd0),
	.dclk                        (clk50),
	.txp                         (ETH0_RX_P),
	.txn                         (ETH0_RX_N),
	.rxp                         (ETH0_TX_P),
	.rxn                         (ETH0_TX_N),
	.signal_detect               (1'b1),
	.tx_fault                    (1'b0),
	.tx_disable                  (ETH0_TX_DISABLE),
	.pcspma_status               (),
	.sim_speedup_control         (1'b0),
	.rxrecclk_out                (),
	.mac_tx_configuration_vector (mac_tx_configuration_vector),
	.mac_rx_configuration_vector (mac_rx_configuration_vector),
	.mac_status_vector           (mac_status_vector),
	.pcs_pma_configuration_vector(pcs_pma_configuration_vector),
	.pcs_pma_status_vector       (),
	.areset_datapathclk_out      (),
	.txusrclk_out                (),
	.txusrclk2_out               (),
	.gttxreset_out               (),
	.gtrxreset_out               (),
	.txuserrdy_out               (),
	.coreclk_out                 (clk156),
	.resetdone_out               (),
	.reset_counter_done_out      (),
	.qplllock_out                (),
	.qplloutclk_out              (),
	.qplloutrefclk_out           (),
	.refclk_p                    (SFP_CLK_P),
	.refclk_n                    (SFP_CLK_N),
	.reset                       (sys_rst),
	.s_axis_tx_tdata             (eth_tx_tdata),
	.s_axis_tx_tkeep             (eth_tx_tkeep),
	.s_axis_tx_tlast             (eth_tx_tlast),
	.s_axis_tx_tready            (eth_tx_tready),
	.s_axis_tx_tuser             (eth_tx_tuser),
	.s_axis_tx_tvalid            (eth_tx_tvalid),
	.s_axis_pause_tdata          (16'd0),
	.s_axis_pause_tvalid         (1'd0),
	.m_axis_rx_tdata             (eth_rx_tdata),
	.m_axis_rx_tkeep             (eth_rx_tkeep),
	.m_axis_rx_tlast             (eth_rx_tlast),
	.m_axis_rx_tuser             (eth_rx_tuser),
	.m_axis_rx_tvalid            (eth_rx_tvalid),
	.tx_statistics_valid         (),
	.tx_statistics_vector        (),
	.rx_statistics_valid         (),
	.rx_statistics_vector        ()
);

endmodule

