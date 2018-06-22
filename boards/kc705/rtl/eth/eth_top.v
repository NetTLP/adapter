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

wire [535:0] pcs_pma_configuration_vector;
pcs_pma_conf pcs_pma_conf0(
	.pcs_pma_configuration_vector(pcs_pma_configuration_vector)
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
	.tx_axis_aresetn             (!sys_rst),        // input wire tx_axis_aresetn
	.rx_axis_aresetn             (!sys_rst),        // input wire rx_axis_aresetn
	.tx_ifg_delay                (8'd0),            // input wire [7 : 0] tx_ifg_delay
	.dclk                        (clk50),          // input wire dclk
	.txp                         (ETH0_RX_P),       // output wire txp
	.txn                         (ETH0_RX_N),       // output wire txn
	.rxp                         (ETH0_TX_P),       // input wire rxp
	.rxn                         (ETH0_TX_N),       // input wire rxn
	.signal_detect               (1'b1),            // input wire signal_detect
	.tx_fault                    (1'b0),            // input wire tx_fault
	.tx_disable                  (ETH0_TX_DISABLE), // output wire tx_disable
	.pcspma_status               (),                // output wire [7 : 0] pcspma_status
	.sim_speedup_control         (1'b0),            // input wire sim_speedup_control
	.rxrecclk_out                (),                // output wire rxrecclk_out
	.mac_tx_configuration_vector (mac_tx_configuration_vector),   // input wire [79 : 0] mac_tx_configuration_vector
	.mac_rx_configuration_vector (mac_rx_configuration_vector),   // input wire [79 : 0] mac_rx_configuration_vector
	.mac_status_vector           (mac_status_vector),             // output wire [1 : 0] mac_status_vector
	.pcs_pma_configuration_vector(pcs_pma_configuration_vector),  // input wire [535 : 0] pcs_pma_configuration_vector
	.pcs_pma_status_vector       (),           // output wire [447 : 0] pcs_pma_status_vector
	.areset_datapathclk_out      (),           // output wire areset_datapathclk_out
	.txusrclk_out                (),           // output wire txusrclk_out
	.txusrclk2_out               (),           // output wire txusrclk2_out
	.gttxreset_out               (),           // output wire gttxreset_out
	.gtrxreset_out               (),           // output wire gtrxreset_out
	.txuserrdy_out               (),           // output wire txuserrdy_out
	.coreclk_out                 (clk156),     // output wire coreclk_out
	.resetdone_out               (),           // output wire resetdone_out
	.reset_counter_done_out      (),           // output wire reset_counter_done_out
	.qplllock_out                (),           // output wire qplllock_out
	.qplloutclk_out              (),           // output wire qplloutclk_out
	.qplloutrefclk_out           (),           // output wire qplloutrefclk_out
	.refclk_p                    (SFP_CLK_P),  // input wire refclk_p
	.refclk_n                    (SFP_CLK_N),  // input wire refclk_n
	.reset                       (sys_rst),    // input wire reset
	// AXI stream
	.s_axis_tx_tdata             (eth_tx_tdata),      // input wire [63 : 0] s_axis_tx_tdata
	.s_axis_tx_tkeep             (eth_tx_tkeep),      // input wire [7 : 0] s_axis_tx_tkeep
	.s_axis_tx_tlast             (eth_tx_tlast),      // input wire s_axis_tx_tlast
	.s_axis_tx_tready            (eth_tx_tready),     // output wire s_axis_tx_tready
	.s_axis_tx_tuser             (eth_tx_tuser),      // input wire [0 : 0] s_axis_tx_tuser
	.s_axis_tx_tvalid            (eth_tx_tvalid),     // input wire s_axis_tx_tvalid
	.s_axis_pause_tdata          (16'd0),   // input wire [15 : 0] s_axis_pause_tdata
	.s_axis_pause_tvalid         (1'd0),  // input wire s_axis_pause_tvalid

	.m_axis_rx_tdata             (eth_rx_tdata),    // output wire [63 : 0] m_axis_rx_tdata
	.m_axis_rx_tkeep             (eth_rx_tkeep),    // output wire [7 : 0] m_axis_rx_tkeep
	.m_axis_rx_tlast             (eth_rx_tlast),    // output wire m_axis_rx_tlast
	.m_axis_rx_tuser             (eth_rx_tuser),    // output wire m_axis_rx_tuser
	.m_axis_rx_tvalid            (eth_rx_tvalid),   // output wire m_axis_rx_tvalid

	.tx_statistics_valid         (),      // output wire tx_statistics_valid
	.tx_statistics_vector        (),    // output wire [25 : 0] tx_statistics_vector
	.rx_statistics_valid         (),      // output wire rx_statistics_valid
	.rx_statistics_vector        ()    // output wire [29 : 0] rx_statistics_vector
);

`ifdef NO
reg [63:0]    eth_rx_tdata_reg;
reg [7:0]     eth_rx_tkeep_reg;
reg           eth_rx_tlast_reg;
reg           eth_rx_tvalid_reg;
reg           eth_rx_tready_reg;
reg           eth_rx_tuser_reg;
always @(posedge clk156) begin
	if(sys_rst) begin
		eth_rx_tdata_reg  <= 0;
		eth_rx_tuser_reg  <= 0;
		eth_rx_tlast_reg  <= 0;
		eth_rx_tkeep_reg  <= 0;
		eth_rx_tvalid_reg <= 0;
		eth_rx_tready_reg <= 0;
	end else begin
		eth_rx_tdata_reg  <= eth_rx_tdata;
		eth_rx_tuser_reg  <= eth_rx_tuser;
		eth_rx_tlast_reg  <= eth_rx_tlast;
		eth_rx_tkeep_reg  <= eth_rx_tkeep;
		eth_rx_tvalid_reg <= eth_rx_tvalid;
//		eth_rx_tready_reg <= eth_rx_tready;
	end
end

reg [63:0]    eth_tx_tdata_reg;
reg [7:0]     eth_tx_tkeep_reg;
reg           eth_tx_tlast_reg;
reg           eth_tx_tvalid_reg;
reg           eth_tx_tready_reg;
reg           eth_tx_tuser_reg;
always @(posedge clk156) begin
	if(sys_rst) begin
		eth_tx_tdata_reg  <= 0;
		eth_tx_tuser_reg  <= 0;
		eth_tx_tlast_reg  <= 0;
		eth_tx_tkeep_reg  <= 0;
		eth_tx_tvalid_reg <= 0;
		eth_tx_tready_reg <= 0;
	end else begin
		eth_tx_tdata_reg  <= eth_tx_tdata;
		eth_tx_tuser_reg  <= eth_tx_tuser;
		eth_tx_tlast_reg  <= eth_tx_tlast;
		eth_tx_tkeep_reg  <= eth_tx_tkeep;
		eth_tx_tvalid_reg <= eth_tx_tvalid;
//		eth_tx_tready_reg <= eth_tx_tready;
	end
end



ila_0 ila_0_ins (
	.clk(clk156),
	.probe0({ eth_tx_tready_reg,
	          eth_tx_tvalid_reg,
	          eth_tx_tlast_reg,
	          eth_tx_tkeep_reg,
	          eth_tx_tdata_reg,
	          eth_tx_tuser_reg, 3'b0 }),
	.probe1({ eth_rx_tready_reg,
	          eth_rx_tvalid_reg,
	          eth_rx_tlast_reg,
	          eth_rx_tkeep_reg,
	          eth_rx_tdata_reg,
	          eth_rx_tuser_reg, 21'b0 })
);
`endif

endmodule

