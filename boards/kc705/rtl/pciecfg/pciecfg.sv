module pciecfg
	import pciecfg_pkg::*;
(
	input wire eth_clk,
	input wire pcie_clk,
	input wire rst,

	// data input
	input wire fifo_pciecfg_i_wr_en,
	output wire fifo_pciecfg_i_full,
	input wire FIFO_PCIECFG_T fifo_pciecfg_i_din,

	// data output
	input wire fifo_pciecfg_o_rd_en,
	output wire fifo_pciecfg_o_empty,
	output wire FIFO_PCIECFG_T fifo_pciecfg_o_dout,

	// pcie configration interface
	output wire [9:0] cfg_mgmt_dwaddr,
	output wire cfg_mgmt_rd_en,
	input wire [31:0] cfg_mgmt_do,
	output wire cfg_mgmt_wr_en,
	output wire [3:0] cfg_mgmt_byte_en,
	output wire [31:0] cfg_mgmt_di,
	input wire cfg_mgmt_rd_wr_done
);

wire fifo_pciecfg_i_rd_en;
wire fifo_pciecfg_i_empty;
FIFO_PCIECFG_T fifo_pciecfg_i_dout;

wire fifo_pciecfg_o_wr_en;
wire fifo_pciecfg_o_full;
FIFO_PCIECFG_T fifo_pciecfg_o_din;

fifo_pciecfg_in fifo_pciecfg_in0 (
	.wr_clk(eth_clk),
	.rd_clk(pcie_clk),
	.rst(rst),

	.wr_en(fifo_pciecfg_i_wr_en),
	.full (fifo_pciecfg_i_full),
	.din  (fifo_pciecfg_i_din),

	.rd_en(fifo_pciecfg_i_rd_en),
	.empty(fifo_pciecfg_i_empty),
	.dout (fifo_pciecfg_i_dout)
);

pciecfg_core pciecfg_core0 (
	.clk(pcie_clk),
	.*
);

fifo_pciecfg_out fifo_pciecfg_out0 (
	.wr_clk(pcie_clk),
	.rd_clk(eth_clk),
	.rst(rst),

	.wr_en(fifo_pciecfg_o_wr_en),
	.full (fifo_pciecfg_o_full),
	.din  (fifo_pciecfg_o_din),

	.rd_en(fifo_pciecfg_o_rd_en),
	.empty(fifo_pciecfg_o_empty),
	.dout (fifo_pciecfg_o_dout)
);

endmodule

