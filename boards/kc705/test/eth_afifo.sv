`default_nettype none

module eth_afifo
	import nettlp_pkg::*;
(
	input  wire rst,
	input  wire wr_clk,
	input  wire rd_clk,
	input  wire rd_en,
	input  wire wr_en,

	input  PCIE_FIFO64_TX din,
	output PCIE_FIFO64_TX dout,
	output wire empty,
	output wire full
);

asfifo #(
	.DATA_WIDTH($bits(PCIE_FIFO64_TX)),
	.ADDRESS_WIDTH(7)
) asfifo0 (
	.*
);

endmodule

`default_nettype wire
