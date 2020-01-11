module pciecfg
	import pciecfg_pkg::*;
(
	input wire clk,
	input wire rst,

	// data input
	output logic fifo_pciecfg_i_rd_en,
	input wire fifo_pciecfg_i_empty,
	input wire fifo_pciecfg_i_dout,

	// data output
	output logic fifo_pciecfg_o_wr_en,
	input wire fifo_pciecfg_o_full,
	output logic fifo_pciecfg_o_din
);

wire fifo_pciecfg_i_wr_en;
wire fifo_pciecfg_i_full;
FIFO_PCIECFG_T fifo_pciecfg_i_din;

wire fifo_pciecfg_o_rd_en;
wire fifo_pciecfg_o_empty;
FIFO_PCIECFG_T fifo_pciecfg_o_dout;

fifo_pciecfg fifo_pciecfg_in (
	.rst(eth_rst),
	.clk(eth_clk),

	.wr_en(fifo_pciecfg_i_wr_en),
	.full (fifo_pciecfg_i_full),
	.din  (fifo_pciecfg_i_din),

	.rd_en(fifo_pciecfg_i_rd_en),
	.empty(fifo_pciecfg_i_empty),
	.dout (fifo_pciecfg_i_dout)
);

pciecfg_core pciecfg_core0 (
	.rst(eth_rst),
	.clk(eth_clk),

	// data input
	.fifo_i_rd_en(fifo_pciecfg_i_rd_en),
	.fifo_i_empty(fifo_pciecfg_i_empty),
	.fifo_i_dout (fifo_pciecfg_i_dout),

	// data output
	.fifo_o_wr_en(fifo_pciecfg_o_wr_en),
	.fifo_o_full (fifo_pciecfg_o_full),
	.fifo_o_din  (fifo_pciecfg_o_din)
);

fifo_pciecfg fifo_pciecfg_out (
	.rst(eth_rst),
	.clk(eth_clk),

	.wr_en(fifo_pciecfg_o_wr_en),
	.full (fifo_pciecfg_o_full),
	.din  (fifo_pciecfg_o_din),

	.rd_en(fifo_pciecfg_o_rd_en),
	.empty(fifo_pciecfg_o_empty),
	.dout (fifo_pciecfg_o_dout)
);


endmodule
