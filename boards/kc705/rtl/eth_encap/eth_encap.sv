module eth_encap
	import endian_pkg::*;
	import ethernet_pkg::*;
	import ip_pkg::*;
	import udp_pkg::*;
	import nettlp_cmd_pkg::*;
	import pciecfg_pkg::*;
	import nettlp_pkg::*;
#(
	parameter PL_FAST_TRAIN       = "FALSE", // Simulation Speedup
	parameter PCIE_EXT_CLK        = "TRUE",    // Use External Clocking Module
	parameter PCIE_EXT_GT_COMMON  = "FALSE",
	parameter REF_CLK_FREQ        = 0,     // 0 - 100 MHz, 1 - 125 MHz, 2 - 250 MHz
	parameter C_DATA_WIDTH        = 64, // RX/TX interface data width
	parameter KEEP_WIDTH          = C_DATA_WIDTH / 8, // TSTRB width
	parameter LINK_WIDTH          = C_DATA_WIDTH / 16, // PCIe Link Width

	parameter ifg_len = 28'hFFFF,
	parameter frame_len = 16'd1020,
	parameter head_size = 6,
	parameter pad_size  = 121, //249

    parameter eth_dst   = 48'h90_E2_BA_5D_8D_C8,
//    parameter eth_dst   = 48'h90_E2_BA_92_CB_D5,
	parameter eth_src   = 48'h00_BB_00_BB_00_BB,
	parameter eth_proto = ETH_P_IP,
	parameter ip_saddr  = {8'd192, 8'd168, 8'd11, 8'd122},
	parameter ip_daddr  = {8'd10, 8'd0, 8'd0, 8'd1},
	parameter udp_sport = 16'd53,
	parameter udp_dport = 16'd50001            // 50001 ~ 51000
)(
	input wire sys_rst156,
	input wire pcie_rst,

	input wire eth_clk,

	input  wire        eth_tx_tready,
	output wire        eth_tx_tvalid,
	output wire [63:0] eth_tx_tdata,
	output wire [ 7:0] eth_tx_tkeep,
	output wire        eth_tx_tlast,
	output wire        eth_tx_tuser,

	input wire pcie_clk,

	input wire                         pcie_rx_tready,
	input wire  [C_DATA_WIDTH-1:0]     pcie_rx_tdata,
	input wire  [KEEP_WIDTH-1:0]       pcie_rx_tkeep,
	input wire                         pcie_rx_tlast,
	input wire                         pcie_rx_tvalid,
	input wire  [21:0]                 pcie_rx_tuser,

	input wire [31:0] adapter_reg_magic,
	input wire [47:0] adapter_reg_dstmac,
	input wire [47:0] adapter_reg_srcmac,
	input wire [31:0] adapter_reg_dstip,
	input wire [31:0] adapter_reg_srcip,
	input wire [15:0] adapter_reg_dstport,
	input wire [15:0] adapter_reg_srcport,

	// cmd
	output wire             fifo_cmd_o_rd_en,
	input wire              fifo_cmd_o_empty,
	input wire FIFO_NETTLP_CMD_T fifo_cmd_o_dout,

	// pciecfg
	output wire          fifo_pciecfg_o_rd_en,
	input wire           fifo_pciecfg_o_empty,
	input wire FIFO_PCIECFG_T fifo_pciecfg_o_dout
);

/*
 * ****************************
 * pcie2fifo_rx (PCIe-RX to FIFO)
 * ****************************
 */
logic fifo0_wr_en, fifo0_rd_en;
logic fifo0_full, fifo0_empty;
PCIE_FIFO64_RX fifo0_din, fifo0_dout;

pcie2fifo pcie2fifo0 (
	.pcie_clk(pcie_clk),
	.pcie_rst(pcie_rst),

	// PCIe input
	.pcie_tvalid(pcie_rx_tvalid),
	.pcie_tready(pcie_rx_tready),
	.pcie_tdata (pcie_rx_tdata),
	.pcie_tkeep (pcie_rx_tkeep),
	.pcie_tlast (pcie_rx_tlast),
	.pcie_tuser (pcie_rx_tuser),

	// FIFO write
	.wr_en(fifo0_wr_en),
	.din(fifo0_din),
	.full(fifo0_full)
);

/*
 * ****************************
 * pciefifo_rx
 * ****************************
 */
pcie_afifo pciefifo_rx (
	.rst(pcie_rst),

	.wr_clk(pcie_clk),    // data in (PCIe)
	.wr_en(fifo0_wr_en),
	.din(fifo0_din),
	.full(fifo0_full),

	.rd_clk(eth_clk),      // data out (Eth)
	.rd_en(fifo0_rd_en),
	.dout(fifo0_dout),
	.empty(fifo0_empty)
);

/*
 * ****************************
 * eth_encap_core0 (FIFO to eth_encap)
 * ****************************
 */
eth_encap_core eth_encap_core0 (
	.eth_clk(eth_clk),
	.eth_rst(sys_rst156),

	// data out(encap)
	.eth_tvalid(eth_tx_tvalid),
	.eth_tready(eth_tx_tready),
	.eth_tdata (eth_tx_tdata),
	.eth_tkeep (eth_tx_tkeep),
	.eth_tlast (eth_tx_tlast),
	.eth_tuser (eth_tx_tuser),

	// FIFO0 read
	.rd_en(fifo0_rd_en),
	.dout (fifo0_dout),
	.empty(fifo0_empty),

	.*
);

endmodule :eth_encap

