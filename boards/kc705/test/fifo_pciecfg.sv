`default_nettype none

module fifo_pciecfg
	import pciecfg_pkg::*;
(
	input  wire rst,
	input  wire clk,
	input  wire rd_en,
	input  wire wr_en,

	input  wire [$bits(FIFO_PCIECFG_T)-1:0] din,
	output wire [$bits(FIFO_PCIECFG_T)-1:0] dout,
	output wire empty,
	output wire full
);

asfifo #(
	.DATA_WIDTH($bits(FIFO_PCIECFG_T)),
	.ADDRESS_WIDTH(7)
) asfifo0 (
	.rd_clk(clk),
	.wr_clk(clk),
	.*
);

endmodule

`default_nettype wire
