`default_nettype none
`timescale 1ns / 1ps

module fifo2pcie
	import pcie_tlp_pkg::*;
	import nettlp_pkg::*;
#(
	parameter C_DATA_WIDTH        = 64, // RX/TX interface data width
	parameter KEEP_WIDTH          = C_DATA_WIDTH / 8, // TSTRB width
	parameter LINK_WIDTH          = C_DATA_WIDTH / 16 // PCIe Link Width
)(
	input wire pcie_clk,
	input wire pcie_rst,

	// TLP packet (FIFO read)
	output logic         rd_en,
	input PCIE_FIFO64_TX dout,
	input wire           empty,

	//input wire [7:0] eth_pktcount,
	input wire        fifo_read_req,

	output logic      pcie_tx_req,
	input wire        pcie_tx_ack,

	// Eth+IP+UDP + TLP packet
	input  PCIE_TREADY64   pcie_tready,
	output PCIE_TVALID64   pcie_tvalid,
	output PCIE_TLAST64    pcie_tlast,
	output PCIE_TKEEP64    pcie_tkeep,
	output PCIE_TDATA64    pcie_tdata,
	output PCIE_TUSER64_TX pcie_tuser
);

/* eth_pktcount */
logic [7:0] eth_pktcount;
always_ff @(posedge pcie_clk) begin
	if (pcie_rst) begin
		eth_pktcount <= '0;
	end else begin
		if (fifo_read_req)
			eth_pktcount <= eth_pktcount + '1;
	end
end


/* state */
enum logic {
	IDLE,
	READ
} state = IDLE, state_next;

always_ff @(posedge pcie_clk)
	state <= state_next;


/* tlp_pktcount */
logic [7:0] tlp_pktcount;

always_ff @(posedge pcie_clk) begin
	if (pcie_rst) begin
		tlp_pktcount <= '0;
	end else begin
		if (state == READ && dout.tlp.tlast) begin
			tlp_pktcount <= tlp_pktcount + '1;
		end
	end
end


/* fifo2pcie */
always_comb begin
	state_next = state;

	rd_en = '0;

	pcie_tx_req = '0;

	pcie_tvalid = '0;
	pcie_tlast = '0;
	pcie_tkeep = '0;
	pcie_tdata = '0;
	pcie_tuser = '0;

	case (state)
	IDLE: begin
		if (tlp_pktcount != eth_pktcount) begin
			pcie_tx_req = '1;

			if (pcie_tx_ack && !empty) begin  // TODO
				if (dout.data_valid) begin
					state_next = READ;
				end else begin
					// skip bubble
					rd_en = '1;
				end
			end
		end
	end
	READ: begin
		rd_en = '1;

		pcie_tx_req = '1;

		pcie_tvalid = dout.tlp.tvalid;
		pcie_tlast  = dout.tlp.tlast;
		pcie_tkeep  = dout.tlp.tkeep;
		pcie_tdata  = dout.tlp.tdata;
		pcie_tuser  = dout.tlp.tuser;

		if (dout.tlp.tlast) begin
			//pcie_tx_req = 0;

			state_next = IDLE;
		end
	end
	endcase
end

wire _unused_ok = &{
	dout.data_valid,
	pcie_tready,
	1'b0
};

endmodule

`default_nettype wire

