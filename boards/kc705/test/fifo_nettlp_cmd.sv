`default_nettype none

module fifo_nettlp_cmd
	import nettlp_cmd_pkg::*;
(
	input  wire srst,
	input  wire clk,
	input  wire rd_en,
	input  wire wr_en,

	input  wire [$bits(FIFO_NETTLP_CMD_T)-1:0] din,
	output wire [$bits(FIFO_NETTLP_CMD_T)-1:0] dout,
	output wire empty,
	output wire full
);

asfifo #(
	.DATA_WIDTH($bits(FIFO_NETTLP_CMD_T)),
	.ADDRESS_WIDTH(7)
) asfifo0 (
	.rst(srst),
	.rd_clk(clk),
	.wr_clk(clk),
	.*
);

endmodule

`default_nettype wire
