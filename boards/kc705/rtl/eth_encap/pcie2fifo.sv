`default_nettype none
`timescale 1ns/1ps

module pcie2fifo
	import pcie_tlp_pkg::*;
	import nettlp_pkg::*;
(
	input wire pcie_clk,
	input wire pcie_rst,

	// Eth+IP+UDP + TLP packet
	input PCIE_TREADY64     pcie_tready,
	input PCIE_TVALID64     pcie_tvalid,
	input PCIE_TLAST64      pcie_tlast,
	input PCIE_TKEEP64      pcie_tkeep,
	input PCIE_TDATA64      pcie_tdata,
	input PCIE_TUSER64_RX   pcie_tuser,

	// TLP packet (FIFO write)
	output logic          wr_en,
	output PCIE_FIFO64_RX din,
	input  wire           full
);

PCIE_TREADY64     pcie_tready_nxt;
PCIE_TVALID64     pcie_tvalid_nxt;
PCIE_TLAST64      pcie_tlast_nxt;
PCIE_TKEEP64      pcie_tkeep_nxt;
PCIE_TDATA64      pcie_tdata_nxt;
PCIE_TUSER64_RX   pcie_tuser_nxt;
always_ff @(posedge pcie_clk) begin
	if (pcie_rst) begin
		pcie_tready_nxt <= 1'b0;
		pcie_tvalid_nxt <= 1'b0;
		pcie_tlast_nxt  <= 1'b0;
		pcie_tkeep_nxt  <= 8'b0;
		pcie_tuser_nxt  <= '{default: '0};

		pcie_tdata_nxt.raw <= '{default: '0};
	end else begin
		pcie_tready_nxt <= pcie_tready;
		pcie_tvalid_nxt <= pcie_tvalid;
		pcie_tlast_nxt  <= pcie_tlast;
		pcie_tkeep_nxt  <= pcie_tkeep;
		pcie_tuser_nxt  <= pcie_tuser;

		pcie_tdata_nxt.raw <= pcie_tdata.raw;
	end
end

enum logic [2:0] {
	IDLE,
	HEADER,
	DATA,
	BUBBLE,
	ERR_TIMEOUT,
	ERR_FIFOFULL
} state, state_next;

always_ff @(posedge pcie_clk) begin
	state <= state_next;
end

// timeout counter
localparam timeout_val = 500;

logic [9:0] timeout;

always_ff @(posedge pcie_clk) begin
	if (pcie_rst)
		timeout <= 0;
	else  begin
		if (state == IDLE) begin
			timeout <= 0;
		end else begin
			timeout <= timeout + 1;
		end
	end
end


// dword to byte + TLP header length
localparam [11:0] TLP_3DW_HDR_LEN = 12'd12;
localparam [11:0] TLP_4DW_HDR_LEN = 12'd16;

TLPPacketLengthByte bytelen3DW;
TLPPacketLengthByte bytelen4DW;
always_comb bytelen3DW = ({2'b0, pcie_tdata_nxt.clk0_mem.length} << 2) + TLP_3DW_HDR_LEN;
always_comb bytelen4DW = ({2'b0, pcie_tdata_nxt.clk0_mem.length} << 2) + TLP_4DW_HDR_LEN;

always_comb begin
	state_next = state;

	wr_en = '0;

	din.data_valid = '0;

	din.tlp.field.fmt = '{default: '0};
	din.tlp.field.pkttype = '{default: '0};
	din.tlp.field.len = '0;
	din.tlp.field.tag = '0;

	din.tlp.tvalid = pcie_tvalid_nxt;
	din.tlp.tlast = pcie_tlast_nxt;
	din.tlp.tkeep = pcie_tkeep_nxt;
	din.tlp.tdata = pcie_tdata_nxt;
	din.tlp.tuser = pcie_tuser_nxt;

	case (state)
	IDLE: begin
		if (pcie_tready_nxt) begin
			if (pcie_tvalid_nxt && !pcie_tlast_nxt && !full) begin
				state_next = HEADER;

				wr_en = '1;
				din.data_valid = '1;

				din.tlp.field.fmt = pcie_tdata_nxt.clk0_mem.format;

				din.tlp.field.pkttype = pcie_tdata_nxt.clk0_mem.pkttype;

				case ({pcie_tdata_nxt.clk0_mem.format, pcie_tdata_nxt.clk0_mem.pkttype})
					// Memory read request 3DW
					{MRD_3DW_NODATA, MEMRW}: begin
						din.tlp.field.len = TLP_3DW_HDR_LEN;
						din.tlp.field.tag = pcie_tdata_nxt.clk0_mem.tag;
					end
					// Memory read request 4DW
					{MRD_4DW_NODATA, MEMRW}: begin
						din.tlp.field.len = TLP_4DW_HDR_LEN;
						din.tlp.field.tag = pcie_tdata_nxt.clk0_mem.tag;
					end
					// Memory write request 3DW
					{MWR_3DW_DATA, MEMRW}: begin
						din.tlp.field.len = bytelen3DW;
						din.tlp.field.tag = pcie_tdata_nxt.clk0_mem.tag;
					end
					// Memory write request 4DW
					{MWR_4DW_DATA, MEMRW}: begin
						din.tlp.field.len = bytelen4DW;
						din.tlp.field.tag = pcie_tdata_nxt.clk0_mem.tag;
					end
					// Completion: No data
					{CPL_NODATA, COMPL}: begin
						din.tlp.field.len = TLP_3DW_HDR_LEN;
						din.tlp.field.tag = pcie_tdata.clk1_cpl.tag;
					end
					// Completion: data
					{CPL_DATA, COMPL}: begin
						din.tlp.field.len = bytelen3DW;
						din.tlp.field.tag = pcie_tdata.clk1_cpl.tag;
					end
					default: begin
						state_next = IDLE;
						wr_en = '0;
					end
				endcase
			end
		end
	end
	HEADER: begin
		if (timeout == timeout_val) begin
			state_next = ERR_TIMEOUT;
		end else if (pcie_tready_nxt) begin
			if (pcie_tvalid_nxt && !full) begin
				if (pcie_tlast_nxt) begin
					state_next = IDLE;
				end else
					state_next = DATA;

				wr_en = '1;
				din.data_valid = '1;
			end else if (full) begin
				state_next = ERR_FIFOFULL;
			end
		end
	end
	DATA: begin
		if (timeout == timeout_val) begin
			state_next = ERR_TIMEOUT;
		end else if (pcie_tready_nxt) begin
			if (pcie_tvalid_nxt && !full) begin
				if (pcie_tlast_nxt) begin
					state_next = BUBBLE;
				end

				wr_en = '1;
				din.data_valid = '1;
			end else if (full) begin
				state_next = ERR_FIFOFULL;
			end
		end
	end
	BUBBLE: begin
		state_next = IDLE;

		wr_en = '1;
	end
	ERR_TIMEOUT: begin
		state_next = IDLE;

		wr_en = '1;
		din.data_valid = '1;

		din.tlp.tlast = '1;
	end
	ERR_FIFOFULL: begin
		if (!full) begin
			state_next = IDLE;

			wr_en = '1;
			din.data_valid = '1;

			din.tlp.tlast = '1;
		end
	end
	default: begin
		state_next = IDLE;
	end
	endcase
end

`ifdef NO
ila_0 ila_0_ins (
	.clk(pcie_clk),
	.probe0({           // 97
		pcie_tdata,
		pcie_tkeep,
		pcie_tlast,
		pcie_tvalid,
		pcie_tready,
		pcie_tuser
	}),
	.probe1({           // 113: 4 + 109
		wr_en,
		state,
		full,
		din.tlp.field.len,
		din.tlp.tvalid,
		din.tlp.tlast,
		din.tlp.tkeep,
		din.tlp.tdata,
		din.tlp.tuser
	})
);
`endif

endmodule

`default_nettype wire

