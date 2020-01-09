module testbench #(
	parameter C_DATA_WIDTH        = 64,
	parameter KEEP_WIDTH          = C_DATA_WIDTH / 8,
	parameter LINK_WIDTH          = C_DATA_WIDTH / 16,
	parameter COLD_RESET_INTVAL   = 14'hfff
)(
	input wire clk200_p,
	input wire clk200_n,

	input wire sys_clk_p,
	input wire sys_clk_n,
	input wire sys_rst_n,

	input wire SFP_CLK_P,
	input wire SFP_CLK_N
);

// output
wire [LINK_WIDTH-1:0] pci_exp_rxp = 'b0;
wire [LINK_WIDTH-1:0] pci_exp_rxn = 'b0;
wire ETH0_TX_P = 'b0;
wire ETH0_TX_N = 'b0;

// inout
wire I2C_FPGA_SCL;
wire I2C_FPGA_SDA;

// input
wire [LINK_WIDTH-1:0] pci_exp_txp;
wire [LINK_WIDTH-1:0] pci_exp_txn;
wire I2C_FPGA_RST_N;
wire SI5324_RST_N;
wire ETH0_RX_P;
wire ETH0_RX_N;
wire ETH0_TX_DISABLE;

top top0(.*);

wire _unused_ok = &{
	I2C_FPGA_SCL,
	I2C_FPGA_SDA,

	pci_exp_txp,
	pci_exp_txn,
	I2C_FPGA_RST_N,
	SI5324_RST_N,
	ETH0_RX_P,
	ETH0_RX_N,
	ETH0_TX_DISABLE,
	1'b0
};

endmodule

