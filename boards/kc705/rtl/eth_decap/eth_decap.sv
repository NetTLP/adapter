`default_nettype none
`timescale 1ns / 1ps

module eth_decap
	import endian_pkg::*;
	import ethernet_pkg::*;
	import ip_pkg::*;
	import udp_pkg::*;
	import pciecfg_pkg::*;
	import nettlp_cmd_pkg::*;
	import nettlp_pkg::*;
#(
	parameter PL_FAST_TRAIN       = "FALSE", // Simulation Speedup
	parameter PCIE_EXT_CLK        = "TRUE",    // Use External Clocking Module
	parameter PCIE_EXT_GT_COMMON  = "FALSE",
	parameter REF_CLK_FREQ        = 0,     // 0 - 100 MHz, 1 - 125 MHz, 2 - 250 MHz
	parameter C_DATA_WIDTH        = 64, // RX/TX interface data width
	parameter KEEP_WIDTH          = C_DATA_WIDTH / 8, // TSTRB width
	parameter LINK_WIDTH          = C_DATA_WIDTH / 16 // PCIe Link Width
)(
	input wire pcie_clk,
	input wire pcie_rst,

	input wire eth_clk,
	input wire eth_rst,

	// output: pcie_support (IP)
	input  wire                        pcie_tx1_tready,
	output wire                        pcie_tx1_tvalid,
	output wire                        pcie_tx1_tlast,
	output wire  [KEEP_WIDTH-1:0]      pcie_tx1_tkeep,
	output wire  [C_DATA_WIDTH-1:0]    pcie_tx1_tdata,
	output wire  [3:0]                 pcie_tx1_tuser,

	// input: pcie_app(tx_engine)
	input  wire                        pcie_tx_req,
	output wire                        pcie_tx_ack,

	output wire                        pcie_tx_tready,
	input  wire                        pcie_tx_tvalid,
	input  wire                        pcie_tx_tlast,
	input  wire  [KEEP_WIDTH-1:0]      pcie_tx_tkeep,
	input  wire  [C_DATA_WIDTH-1:0]    pcie_tx_tdata,
	input  wire  [3:0]                 pcie_tx_tuser,

	// input: ethernet
	input  wire        eth_rx_tvalid,
	input  wire        eth_rx_tlast,
	input  wire [ 7:0] eth_rx_tkeep,
	input  wire [63:0] eth_rx_tdata,
	input  wire        eth_rx_tuser,

	// to pcie configuration space fifo
	output logic          fifo_pciecfg_i_wr_en,
	output FIFO_PCIECFG_T fifo_pciecfg_i_din,
	input wire            fifo_pciecfg_i_full,
	
	// to nettlp command fifo
	output wire              fifo_cmd_i_wr_en,
	output FIFO_NETTLP_CMD_T fifo_cmd_i_din,
	input wire               fifo_cmd_i_full
);

/*
 * ****************************
 * input: eth_decap_core0 (decap to fifo)
 * ****************************
 */
wire fifo0_wr_en, fifo0_rd_en;
wire fifo0_full, fifo0_empty;
PCIE_FIFO64_TX fifo0_din, fifo0_dout;

wire fifo_read_req_eth, fifo_read_req_pcie;
eth_decap_core eth_decap_core0 (
	.eth_clk(eth_clk),
	.eth_rst(eth_rst),

	// data in(decap)
	.eth_tvalid(eth_rx_tvalid),
	.eth_tdata (eth_rx_tdata),
	.eth_tkeep (eth_rx_tkeep),
	.eth_tlast (eth_rx_tlast),
	.eth_tuser (eth_rx_tuser),

	// FIFO0 output
	.wr_en(fifo0_wr_en),
	.din  (fifo0_din),
	.full(fifo0_full),
	
	.fifo_read_req(fifo_read_req_eth),

	.*
);

/*
 * ****************************
 * eth_afifo
 * ****************************
 */
eth_afifo eth_afifo (
	.rst(eth_rst),

	.wr_clk(eth_clk),    // data in (Eth)
	.wr_en(fifo0_wr_en),
	.full(fifo0_full),
	.din(fifo0_din),

	.rd_clk(pcie_clk),      // data out (PCIe)
	.rd_en(fifo0_rd_en),
	.empty(fifo0_empty),
	.dout(fifo0_dout)
);


/*
 * ****************************
 * eth2pcie_sync_ashot
 * ****************************
 */
clk_sync_ashot eth2pcie_sync_ashot (
	.slowclk(eth_clk),
	.i(fifo_read_req_eth),
	.fastclk(pcie_clk),
	.o(fifo_read_req_pcie)
);


/*
 * ****************************
 * fifo2pcie_axis
 * ****************************
 */
wire                    pcie_tx2_req;
wire                    pcie_tx2_ack;

wire                    pcie_tx2_tready;
wire                    pcie_tx2_tvalid;
wire                    pcie_tx2_tlast;
wire [KEEP_WIDTH-1:0]   pcie_tx2_tkeep;
wire [C_DATA_WIDTH-1:0] pcie_tx2_tdata;
wire [3:0]              pcie_tx2_tuser;
fifo2pcie fifo2pcie0 (
	.pcie_clk(pcie_clk),
	.pcie_rst(pcie_rst),

	.rd_en(fifo0_rd_en),
	.dout(fifo0_dout),
	.empty(fifo0_empty),

	.fifo_read_req(fifo_read_req_pcie), 

	.pcie_tx_req(pcie_tx2_req),
	.pcie_tx_ack(pcie_tx2_ack),

	.pcie_tready(pcie_tx2_tready),
	.pcie_tdata(pcie_tx2_tdata),
	.pcie_tkeep(pcie_tx2_tkeep),
	.pcie_tlast(pcie_tx2_tlast),
	.pcie_tvalid(pcie_tx2_tvalid),
	.pcie_tuser(pcie_tx2_tuser)
);

/*
 * ****************************
 * PCIE_TX_MUX
 * ****************************
 */
tlp_tx_mux #(
	.C_DATA_WIDTH( C_DATA_WIDTH ),
	.KEEP_WIDTH( KEEP_WIDTH )
) tlp_tx_mux0 (
	.pcie_clk(pcie_clk),
	.pcie_rst(pcie_rst),

	// AXIS Output
	.pcie_tx_tready   (pcie_tx1_tready),
	.pcie_tx_tvalid   (pcie_tx1_tvalid),
	.pcie_tx_tlast    (pcie_tx1_tlast),
	.pcie_tx_tkeep    (pcie_tx1_tkeep),
	.pcie_tx_tdata    (pcie_tx1_tdata),
	.pcie_tx_tuser    (pcie_tx1_tuser),

	// AXIS Input 1 (from tx engine)
	.pcie_tx1_req     (pcie_tx_req),
	.pcie_tx1_ack     (pcie_tx_ack),

	.pcie_tx1_tready  (pcie_tx_tready),
	.pcie_tx1_tvalid  (pcie_tx_tvalid),
	.pcie_tx1_tlast   (pcie_tx_tlast),
	.pcie_tx1_tkeep   (pcie_tx_tkeep),
	.pcie_tx1_tdata   (pcie_tx_tdata),
	.pcie_tx1_tuser   (pcie_tx_tuser),

	// AXIS Input 2 (from ethernet)
	.pcie_tx2_req     (pcie_tx2_req),
	.pcie_tx2_ack     (pcie_tx2_ack),

	.pcie_tx2_tready  (pcie_tx2_tready),
	.pcie_tx2_tvalid  (pcie_tx2_tvalid),
	.pcie_tx2_tlast   (pcie_tx2_tlast),
	.pcie_tx2_tkeep   (pcie_tx2_tkeep),
	.pcie_tx2_tdata   (pcie_tx2_tdata),
	.pcie_tx2_tuser   (pcie_tx2_tuser)
);

endmodule

`default_nettype wire

