`default_nettype none

module eth_afifo (
	input  wire rst,
	input  wire wr_clk,
	input  wire rd_clk,
	input  wire rd_en,
	input  wire wr_en,

	input  wire [77:0] din,
	output wire [77:0] dout,
	output wire empty,
	output wire full
);

asfifo #(
	.DATA_WIDTH(78),
	.ADDRESS_WIDTH(7)
) asfifo0 (
	.*
);

endmodule

`default_nettype wire
