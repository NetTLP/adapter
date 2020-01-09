`default_nettype none
`timescale 1ns / 1ps

module top #(
	parameter C_DATA_WIDTH        = 64,
	parameter KEEP_WIDTH          = C_DATA_WIDTH / 8,
	parameter LINK_WIDTH          = C_DATA_WIDTH / 16,

	parameter COLD_RESET_INTVAL   = 14'hfff
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

// sys_clk
wire sys_clk;
IBUFDS_GTE2 refclk_ibuf (
	.I(sys_clk_p),
	.IB(sys_clk_n),
	.ODIV2(),
	.CEB(1'b0),
	.O(sys_clk)
);

wire sys_rst_n_c;
IBUF sys_reset_n_ibuf (
	.I(sys_rst_n),
	.O(sys_rst_n_c)
);

// clk200
wire clk200;
IBUFDS IBUFDS_clk200 (
	.I(clk200_p),
	.IB(clk200_n),
	.O(clk200)
);

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


/*
 * ****************************
 * pcie_top
 * ****************************
 */
wire pcie_clk;
wire pcie_rst;

wire                    pcie_tx_req;
wire                    pcie_tx_ack;
wire                    pcie_tx_tready;
wire                    pcie_tx_tvalid;
wire                    pcie_tx_tlast;
wire [KEEP_WIDTH-1:0]   pcie_tx_tkeep;
wire [C_DATA_WIDTH-1:0] pcie_tx_tdata;
wire [3:0]              pcie_tx_tuser;

wire                     pcie_rx_tready;
wire                     pcie_rx_tvalid;
wire                     pcie_rx_tlast;
wire [KEEP_WIDTH-1:0]    pcie_rx_tkeep;
wire [C_DATA_WIDTH-1:0]  pcie_rx_tdata;
wire [21:0]              pcie_rx_tuser;

wire                     pcie_tx1_tready;
wire                     pcie_tx1_tvalid;
wire                     pcie_tx1_tlast;
wire [KEEP_WIDTH-1:0]    pcie_tx1_tkeep;
wire [C_DATA_WIDTH-1:0]  pcie_tx1_tdata;
wire [3:0]               pcie_tx1_tuser;

wire [31:0] adapter_reg_magic;
wire [47:0] adapter_reg_dstmac;
wire [47:0] adapter_reg_srcmac;
wire [31:0] adapter_reg_dstip;
wire [31:0] adapter_reg_srcip;
wire [15:0] adapter_reg_dstport;
wire [15:0] adapter_reg_srcport;
pcie_top pcie_top0 (
	.sys_rst_n(sys_rst_n_c),
	.*
);


/*
 * ****************************
 * eth_top
 * ****************************
 */
wire clk100;
reg clock_divide = 1'b0;
always @(posedge clk200)
	clock_divide <= ~clock_divide;
BUFG buffer_clk100 (
	.I(clock_divide),
	.O(clk100)
);

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
	.sys_rst(sys_rst156),
	.*
);
 

/*
 * ****************************
 * PCIe-Ethernet bridge (tlp_rx_snoop) top instance
 * ****************************
 */
tlp_rx_snoop tlp_rx_snoop0 (
	.sys_rst156       (sys_rst156),
	.pcie_rst         (pcie_rst),

	.eth_clk          (clk156),
	.pcie_clk          (pcie_clk),

	.*
);


/*
 * ****************************
 * Ethernet-PCIe bridge (tlp_tx_inject) top instance
 * ****************************
 */
tlp_tx_inject tlp_tx_inject0 (
	.pcie_clk (pcie_clk),
	.pcie_rst (pcie_rst),

	.eth_clk (clk156),
	.eth_rst (sys_rst156),
		
	// input: Ethernet
	// input: from pio_tx_engine
	// output: to pcie_7x_support

	.*
);

endmodule

`default_nettype wire

