`default_nettype none
`timescale 1ns/1ps

module tlp_tx_mux # (
	// RX/TX interface data width
	parameter C_DATA_WIDTH = 64,
	// TSTRB width
	parameter KEEP_WIDTH = C_DATA_WIDTH / 8
)(
	input wire pcie_clk,
	input wire pcie_rst,

	// AXIS Output
	input wire                      pcie_tx_tready,
	output logic                    pcie_tx_tvalid,
	output logic                    pcie_tx_tlast,
	output logic [KEEP_WIDTH-1:0]   pcie_tx_tkeep,
	output logic [C_DATA_WIDTH-1:0] pcie_tx_tdata,
	output logic [3:0]              pcie_tx_tuser,

	// AXIS Input 1
	input wire                     pcie_tx1_req,
	output logic                   pcie_tx1_ack,

	output logic                   pcie_tx1_tready,
	input wire                     pcie_tx1_tvalid,
	input wire                     pcie_tx1_tlast,
	input wire [KEEP_WIDTH-1:0]    pcie_tx1_tkeep,
	input wire [C_DATA_WIDTH-1:0]  pcie_tx1_tdata,
	input wire [3:0]               pcie_tx1_tuser,

	// AXIS Input 2
	input wire                     pcie_tx2_req,
	output logic                   pcie_tx2_ack,

	output logic                   pcie_tx2_tready,
	input wire                     pcie_tx2_tvalid,
	input wire                     pcie_tx2_tlast,
	input wire [KEEP_WIDTH-1:0]    pcie_tx2_tkeep,
	input wire [C_DATA_WIDTH-1:0]  pcie_tx2_tdata,
	input wire [3:0]               pcie_tx2_tuser
);

always_ff @(posedge pcie_clk) begin
	if (pcie_rst) begin
		pcie_tx1_ack <= 1'b0;
		pcie_tx2_ack <= 1'b0;
	end else begin
		case ({pcie_tx2_ack, pcie_tx1_ack})
		2'b00: begin
			if (pcie_tx1_req)
				pcie_tx1_ack <= 1'b1;
			else if (pcie_tx2_req)
				pcie_tx2_ack <= 1'b1;
			else begin
				pcie_tx1_ack <= 1'b0;
				pcie_tx2_ack <= 1'b0;
			end
		end
		2'b01: begin
			if (~pcie_tx1_req) begin
				pcie_tx1_ack <= 1'b0;
				if (pcie_tx2_req)
					pcie_tx2_ack <= 1'b1;
			end
		end
		2'b10: begin
			if (~pcie_tx2_req) begin
				pcie_tx2_ack <= 1'b0;
				if (pcie_tx1_req)
					pcie_tx1_ack <= 1'b1;
			end
		end
		default: begin
		end
		endcase
	end
end

always_comb pcie_tx1_tready = pcie_tx_tready & pcie_tx1_ack;
always_comb pcie_tx2_tready = pcie_tx_tready & pcie_tx2_ack;

always_comb pcie_tx_tvalid  = pcie_tx2_ack ? pcie_tx2_tvalid  : pcie_tx1_tvalid;
always_comb pcie_tx_tlast   = pcie_tx2_ack ? pcie_tx2_tlast   : pcie_tx1_tlast;
always_comb pcie_tx_tkeep   = pcie_tx2_ack ? pcie_tx2_tkeep   : pcie_tx1_tkeep;
always_comb pcie_tx_tdata   = pcie_tx2_ack ? pcie_tx2_tdata   : pcie_tx1_tdata;
always_comb pcie_tx_tuser   = pcie_tx2_ack ? pcie_tx2_tuser   : pcie_tx1_tuser;

endmodule

`default_nettype wire

