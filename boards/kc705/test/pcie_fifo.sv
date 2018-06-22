`default_nettype none
module pcie_fifo (
	input  wire srst,
	input  wire clk,
	input  wire rd_en,
	input  wire wr_en,

	input  wire [73:0] din,
	output wire [73:0] dout,
	output wire empty,
	output wire full
);

asfifo #(
	.DATA_WIDTH(74),
	.ADDRESS_WIDTH(7)
) asfifo_arb (
	.rst(srst),
	.rd_clk(clk),
	.wr_clk(clk),
	.*
);

endmodule
`default_nettype wire
