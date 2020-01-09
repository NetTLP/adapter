`default_nettype none

module pcie_afifo
	import nettlp_pkg::*;
(
	input  wire rst,
	input  wire wr_clk,
	input  wire rd_clk,
	input  wire rd_en,
	input  wire wr_en,

	input  wire PCIE_FIFO64_RX din,
	output wire PCIE_FIFO64_RX dout,
	output wire empty,
	output wire full
);

asfifo #(
	.DATA_WIDTH($bits(PCIE_FIFO64_RX)),
	.ADDRESS_WIDTH(7)
) asfifo0 (
	.*
);

endmodule
`default_nettype wire
