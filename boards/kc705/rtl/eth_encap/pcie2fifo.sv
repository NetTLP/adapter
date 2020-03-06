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

// dword to byte + TLP header length
localparam [11:0] TLP_3DW_HDR_LEN = 12'd12;
localparam [11:0] TLP_4DW_HDR_LEN = 12'd16;

TLPPacketLengthByte bytelen3DW;
TLPPacketLengthByte bytelen4DW;
always_comb bytelen3DW = ({2'b0, pcie_tdata_nxt.clk0_mem.length} << 2) + TLP_3DW_HDR_LEN;
always_comb bytelen4DW = ({2'b0, pcie_tdata_nxt.clk0_mem.length} << 2) + TLP_4DW_HDR_LEN;

enum logic [2:0] {
	IDLE,
	HEADER,
	DATA,
	BUBBLE,
	ERR_FIFOFULL
} state;

always_ff @(posedge pcie_clk) begin
	if (pcie_rst) begin
		state <= IDLE;
		wr_en <= '0;
		din <= '{default: '0};
	end else begin
		wr_en <= '0;

		case (state)
		IDLE: begin
			if (pcie_tready_nxt) begin
				if (pcie_tvalid_nxt && !pcie_tlast_nxt && !full) begin
					state <= HEADER;

					wr_en <= '1;

					din.data_valid <= '1;

					din.tlp.tvalid <= pcie_tvalid_nxt;
					din.tlp.tlast <= pcie_tlast_nxt;
					din.tlp.tkeep <= pcie_tkeep_nxt;
					din.tlp.tdata <= pcie_tdata_nxt;
					din.tlp.tuser <= pcie_tuser_nxt;

					din.tlp.field.fmt <= pcie_tdata_nxt.clk0_mem.format;
					din.tlp.field.pkttype <= pcie_tdata_nxt.clk0_mem.pkttype;
					case ({pcie_tdata_nxt.clk0_mem.format, pcie_tdata_nxt.clk0_mem.pkttype})
						// Memory read request 3DW
						{MRD_3DW_NODATA, MEMRW}: begin
							din.tlp.field.len <= TLP_3DW_HDR_LEN;
							din.tlp.field.tag <= pcie_tdata_nxt.clk0_mem.tag;
						end
						// Memory read request 4DW
						{MRD_4DW_NODATA, MEMRW}: begin
							din.tlp.field.len <= TLP_4DW_HDR_LEN;
							din.tlp.field.tag <= pcie_tdata_nxt.clk0_mem.tag;
						end
						// Memory write request 3DW
						{MWR_3DW_DATA, MEMRW}: begin
							din.tlp.field.len <= bytelen3DW;
							din.tlp.field.tag <= pcie_tdata_nxt.clk0_mem.tag;
						end
						// Memory write request 4DW
						{MWR_4DW_DATA, MEMRW}: begin
							din.tlp.field.len <= bytelen4DW;
							din.tlp.field.tag <= pcie_tdata_nxt.clk0_mem.tag;
						end
						// Completion: No data
						{CPL_NODATA, COMPL}: begin
							din.tlp.field.len <= TLP_3DW_HDR_LEN;
							din.tlp.field.tag <= pcie_tdata.clk1_cpl.tag;
						end
						// Completion: data
						{CPL_DATA, COMPL}: begin
							din.tlp.field.len <= bytelen3DW;
							din.tlp.field.tag <= pcie_tdata.clk1_cpl.tag;
						end
						default: begin
							din.tlp.field.len <= TLP_3DW_HDR_LEN;
							din.tlp.field.tag <= '0;
						end
					endcase
				end else if (full) begin
					state <= ERR_FIFOFULL;
				end
			end
		end
		HEADER: begin
			if (pcie_tready_nxt) begin
				if (pcie_tvalid_nxt && !full) begin
					if (pcie_tlast_nxt) begin
						state <= IDLE;
					end else begin
						state <= DATA;
					end

					wr_en <= '1;

					din.data_valid <= '1;

					din.tlp.tvalid <= pcie_tvalid_nxt;
					din.tlp.tlast <= pcie_tlast_nxt;
					din.tlp.tkeep <= pcie_tkeep_nxt;
					din.tlp.tdata <= pcie_tdata_nxt;
					din.tlp.tuser <= pcie_tuser_nxt;
				end else if (full) begin
					state <= ERR_FIFOFULL;
				end
			end
		end
		DATA: begin
			if (pcie_tready_nxt) begin
				if (pcie_tvalid_nxt && !full) begin
					if (pcie_tlast_nxt) begin
						state <= BUBBLE;
					end

					wr_en <= '1;

					din.data_valid <= '1;

					din.tlp.tvalid <= pcie_tvalid_nxt;
					din.tlp.tlast <= pcie_tlast_nxt;
					din.tlp.tkeep <= pcie_tkeep_nxt;
					din.tlp.tdata <= pcie_tdata_nxt;
					din.tlp.tuser <= pcie_tuser_nxt;
				end else if (full) begin
					state <= ERR_FIFOFULL;
				end
			end
		end
		BUBBLE: begin
			if (!full) begin
				state <= IDLE; 

				wr_en <= '1;

				din.data_valid <= '0;
			end
		end
		ERR_FIFOFULL: begin
			if (!full) begin
				state <= IDLE;

				wr_en <= '1;
				din.data_valid <= '1;

				din.tlp.tlast <= '1;
			end
		end
		default: begin
			state <= IDLE;
		end
		endcase
	end
end

endmodule

`default_nettype wire

