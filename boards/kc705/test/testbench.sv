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

	// inout
	wire I2C_FPGA_SCL = 'b0;
	wire I2C_FPGA_SDA = 'b0;

	// output
	wire [LINK_WIDTH-1:0] pci_exp_rxp = 'b0;
	wire [LINK_WIDTH-1:0] pci_exp_rxn = 'b0;
	wire ETH0_RX_N = 'b0;
	wire ETH0_RX_P = 'b0;
	wire ETH0_TX_DISABLE = 'b0;
	wire I2C_FPGA_RST_N = 'b0;
	wire SI5324_RST_N = 'b0;

	// input
	wire [LINK_WIDTH-1:0] pci_exp_txp;
	wire [LINK_WIDTH-1:0] pci_exp_txn;
	wire ETH0_TX_P;
	wire ETH0_TX_N;

	top top0(.*);

	wire _unused_ok = &{
		pci_exp_txp,
		pci_exp_txn,
		ETH0_TX_P,
		ETH0_TX_N,
		1'b0
	};

endmodule

