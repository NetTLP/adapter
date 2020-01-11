module nettlp_cmd
	import nettlp_cmd_pkg::*;
(
	input wire clk,
	input wire rst,

	// data input
	output logic fifo_cmd_i_rd_en,
	input wire fifo_cmd_i_empty,
	input wire fifo_cmd_i_dout,

	// data output
	output logic fifo_cmd_o_wr_en,
	input wire fifo_cmd_o_full,
	output logic fifo_cmd_o_din
);

wire fifo_cmd_i_wr_en;
wire fifo_cmd_i_full;
FIFO_NETTLP_CMD_T fifo_cmd_i_din;

wire fifo_cmd_o_rd_en;
wire fifo_cmd_o_empty;
FIFO_NETTLP_CMD_T fifo_cmd_o_dout;

fifo_nettlp_cmd fifo_nettlp_cmd_in (
	.rst(eth_rst),
	.clk(eth_clk),

	.wr_en(fifo_cmd_i_wr_en),
	.full (fifo_cmd_i_full),
	.din  (fifo_cmd_i_din),

	.rd_en(fifo_cmd_i_rd_en),
	.empty(fifo_cmd_i_empty),
	.dout (fifo_cmd_i_dout)
);

nettlp_cmd_core nettlp_cmd_core0 (
	.rst(eth_rst),
	.clk(eth_clk),

	.*
);

fifo_nettlp_cmd fifo_nettlp_cmd_out (
	.rst(eth_rst),
	.clk(eth_clk),

	.wr_en(fifo_cmd_o_wr_en),
	.full (fifo_cmd_o_full),
	.din  (fifo_cmd_o_din),

	.rd_en(fifo_cmd_o_rd_en),
	.empty(fifo_cmd_o_empty),
	.dout (fifo_cmd_o_dout)
);

endmodule

