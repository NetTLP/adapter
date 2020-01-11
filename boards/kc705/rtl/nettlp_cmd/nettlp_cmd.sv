module nettlp_cmd
	import nettlp_cmd_pkg::*;
(
	input wire clk,
	input wire rst,

	// data input
	input logic fifo_cmd_i_wr_en,
	output wire fifo_cmd_i_full,
	input FIFO_NETTLP_CMD_T fifo_cmd_i_din,

	// data output
	input logic fifo_cmd_o_rd_en,
	output wire fifo_cmd_o_empty,
	output FIFO_NETTLP_CMD_T fifo_cmd_o_dout
);

wire fifo_cmd_i_rd_en;
wire fifo_cmd_i_empty;
FIFO_NETTLP_CMD_T fifo_cmd_i_dout;

wire fifo_cmd_o_wr_en;
wire fifo_cmd_o_full;
FIFO_NETTLP_CMD_T fifo_cmd_o_din;

fifo_nettlp_cmd fifo_nettlp_cmd_in (
	.wr_en(fifo_cmd_i_wr_en),
	.full (fifo_cmd_i_full),
	.din  (fifo_cmd_i_din),

	.rd_en(fifo_cmd_i_rd_en),
	.empty(fifo_cmd_i_empty),
	.dout (fifo_cmd_i_dout),

	.*
);

nettlp_cmd_core nettlp_cmd_core0 (
	.*
);

fifo_nettlp_cmd fifo_nettlp_cmd_out (
	.wr_en(fifo_cmd_o_wr_en),
	.full (fifo_cmd_o_full),
	.din  (fifo_cmd_o_din),

	.rd_en(fifo_cmd_o_rd_en),
	.empty(fifo_cmd_o_empty),
	.dout (fifo_cmd_o_dout),

	.*
);

endmodule

