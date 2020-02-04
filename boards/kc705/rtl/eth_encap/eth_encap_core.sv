`default_nettype none
`timescale 1ns/1ps

module eth_encap
	import utils_pkg::*;
	import endian_pkg::*;
	import ethernet_pkg::*;
	import ip_pkg::*;
	import udp_pkg::*;
	import pcie_tlp_pkg::*;
	import nettlp_cmd_pkg::*;
	import pciecfg_pkg::*;
	import nettlp_pkg::*;
#(
	//parameter eth_dst   = 48'h90_E2_BA_5D_91_D0,
	//parameter eth_dst   = 48'h90_E2_BA_5D_8F_CD,
	//parameter eth_dst   = 48'ha0_36_9f_22_ec_c0,
	//parameter eth_dst   = 48'hA0_36_9F_28_AE_9C,
	parameter eth_dst   = 48'hFF_FF_FF_FF_FF_FF,
	parameter eth_src   = 48'h00_11_22_33_44_55,
	parameter eth_proto = ETH_P_IP,
	parameter ip_saddr  = {8'd192, 8'd168, 8'd10, 8'd1},
	parameter ip_daddr  = {8'd192, 8'd168, 8'd10, 8'd3},
	parameter udp_sport = 16'h3000,
	parameter udp_dport = 16'h3000
)(
	input wire eth_clk,
	input wire eth_rst,

	// TLP packet (FIFO read)
	output logic          rd_en,
	input  PCIE_FIFO64_RX dout,
	input  wire           empty,

	// Eth+IP+UDP + TLP packet
	input  ETH_TREADY64    eth_tready,
	output ETH_TVALID64    eth_tvalid,
	output ETH_TLAST64     eth_tlast,
	output ETH_TKEEP64     eth_tkeep,
	output ETH_TDATA64     eth_tdata,
	output ETH_TUSER64_TX  eth_tuser,
	
	input wire [31:0] adapter_reg_magic,
	input wire [47:0] adapter_reg_dstmac,
	input wire [47:0] adapter_reg_srcmac,
	input wire [31:0] adapter_reg_dstip,
	input wire [31:0] adapter_reg_srcip,
	input wire [15:0] adapter_reg_dstport,
	input wire [15:0] adapter_reg_srcport,

	// cmd
	output logic            fifo_cmd_o_rd_en,
	input wire              fifo_cmd_o_empty,
	input FIFO_NETTLP_CMD_T fifo_cmd_o_dout,

	// pciecfg
	output logic         fifo_pciecfg_o_rd_en,
	input wire           fifo_pciecfg_o_empty,
	input FIFO_PCIECFG_T fifo_pciecfg_o_dout
);

/* function: ipcheck_gen() */
function [15:0] ipcheck_gen (
	input TLP_LEN tlp_len,
	input bit [31:0] saddr,
	input bit [31:0] daddr
);
	bit [23:0] sum;
	sum = {8'h0, IPVERSION, 4'd5, 8'h0}
	    + { // tot_len
		    {13'h0, tlp_len} +
		    {13'h0, PACKET_HDR_LEN} -
		    {8'h0, ETH_HDR_LEN}
	    }
	    + {8'h0, 16'h0}
	    + {8'h0, 16'h0}
	    + {8'h0, IPDEFTTL, IP4_PROTO_UDP}
	    + {8'h0, 16'h0}                     // checksum (zero padding)
	    + {8'h0, saddr[31:16]}
	    + {8'h0, saddr[15: 0]}
	    + {8'h0, daddr[31:16]}
	    + {8'h0, daddr[15: 0]};
	ipcheck_gen = ~( sum[15:0] + {8'h0, sum[23:16]} );
endfunction :ipcheck_gen

// state
enum logic [2:0] {
	TX_IDLE,
	TX_READY,
	TX_HDR,
	TX_DATA_TLP,
	TX_DATA_CMD,
	TX_DATA_PCIECFG,
	TX_DATA
} tx_state = TX_IDLE, tx_state_next;

always_ff @(posedge eth_clk)
	tx_state <= tx_state_next;

logic [4:0] tx_count;
logic [15:0] tlp_sequence_count;
logic [31:0] tlp_timestamp_count;
always_ff @(posedge eth_clk) begin
	if (eth_rst) begin
		tx_count <= '0;
		tlp_sequence_count <= '0;
		tlp_timestamp_count <= '0;
	end else begin
		tlp_timestamp_count <= tlp_timestamp_count + 32'd1;

		if (tx_state == TX_IDLE) begin
			tx_count <= 0;
		end else if (tx_state == TX_HDR) begin
			if (eth_tready) begin
				tx_count <= tx_count + 1;
			end
		end else if (tx_state == TX_DATA) begin
			if (eth_tready && dout.tlast) begin
				tlp_sequence_count <= tlp_sequence_count + 16'd1;
			end
		end
	end
end


// build packet header
PACKET_QWORD0 tx_hdr0;
PACKET_QWORD1 tx_hdr1;
PACKET_QWORD2 tx_hdr2;
PACKET_QWORD3 tx_hdr3;
PACKET_QWORD4 tx_hdr4;
PACKET_QWORD5 tx_hdr5;
enum logic [2:0] {
	MODE_NONE,
	MODE_TLP,
	MODE_NETTLP_CMD,
	MODE_PCIECFG
} tx_mode = MODE_NONE;
always_ff @(posedge eth_clk) begin
	if (eth_rst) begin
		tx_hdr0 <= '{default: '0};
		tx_hdr1 <= '{default: '0};
		tx_hdr2 <= '{default: '0};
		tx_hdr3 <= '{default: '0};
		tx_hdr4 <= '{default: '0};
		tx_hdr5 <= '{default: '0};

		tx_mode <= MODE_NONE;
	end else begin
		if (tx_state == TX_IDLE) begin
			tx_hdr0.eth.h_dest <= adapter_reg_dstmac;
			{tx_hdr0.eth.h_source0, tx_hdr1.eth.h_source1} <= adapter_reg_srcmac;

			tx_hdr1.eth.h_proto <= eth_proto;
			tx_hdr1.ip.version <= IPVERSION;
			tx_hdr1.ip.ihl <= 4'd5;

			tx_hdr2.ip.ttl <= IPDEFTTL;
			tx_hdr2.ip.protocol <= IP4_PROTO_UDP;

			tx_hdr3.ip.saddr <= adapter_reg_srcip;
			tx_hdr3.ip.daddr0 <= adapter_reg_dstip[31:16];

			tx_hdr4.ip.daddr1 <= adapter_reg_dstip[15:0];

			tx_hdr5.udp.check <= 16'h0;
			tx_hdr5.nthdr.seq <= tlp_sequence_count;
			tx_hdr5.nthdr.tstamp <= tlp_timestamp_count;

			if (!empty) begin
				tx_mode <= MODE_TLP;

				tx_hdr2.ip.tot_len <= { {5'h0, dout.tlp_len} + {5'h0, PACKET_HDR_LEN} - ETH_HDR_LEN };
				tx_hdr3.ip.check <= ipcheck_gen(dout.tlp_len, adapter_reg_srcip, adapter_reg_dstip);
				tx_hdr4.udp.len <= { {5'h0, dout.tlp_len} + {5'h0, NETTLP_HDR_LEN} + UDP_HDR_LEN };
				tx_hdr4.udp.source <= udp_sport + {12'b0, dout.tlp_tag[3:0]};
				tx_hdr4.udp.dest <= udp_dport + {12'b0, dout.tlp_tag[3:0]};
			end else if (!fifo_cmd_o_empty) begin
				if (fifo_cmd_o_dout.data_valid) begin
					tx_mode <= MODE_NETTLP_CMD;
				end

				tx_hdr2.ip.tot_len <= { 16'd12 + {5'h0, PACKET_HDR_LEN} - ETH_HDR_LEN };
				tx_hdr3.ip.check <= ipcheck_gen(11'd12, adapter_reg_srcip, adapter_reg_dstip);
				tx_hdr4.udp.len <= { 16'd12 + {5'h0, NETTLP_HDR_LEN} + UDP_HDR_LEN };
				tx_hdr4.udp.source <= udp_nettlp_cmd_port;
				tx_hdr4.udp.dest <= udp_nettlp_cmd_port;
			end else if (!fifo_pciecfg_o_empty) begin
				if (fifo_pciecfg_o_dout.data_valid) begin
					tx_mode <= MODE_PCIECFG;
				end

				tx_hdr2.ip.tot_len <= { 16'd12 + {5'h0, PACKET_HDR_LEN} - ETH_HDR_LEN };
				tx_hdr3.ip.check <= ipcheck_gen(11'd12, adapter_reg_srcip, adapter_reg_dstip);
				tx_hdr4.udp.len <= { 16'd12 + {5'h0, NETTLP_HDR_LEN} + UDP_HDR_LEN };
				tx_hdr4.udp.source <= udp_pciecfg_port;
				tx_hdr4.udp.dest <= udp_pciecfg_port;
			end else begin
				tx_mode <= MODE_NONE;

				tx_hdr2.ip.tot_len <= '0;
				tx_hdr3.ip.check <= '0;
				tx_hdr4.udp.len <= '0;
				tx_hdr4.udp.source <= udp_sport;
				tx_hdr4.udp.dest <= udp_dport;
			end
			
		end
	end
end

// pakcet transmission
always_comb begin
	tx_state_next = tx_state;

	eth_tvalid = 0;
	eth_tlast = 0;
	eth_tkeep = '0;
	eth_tdata = '0;
	eth_tuser = 0;

	rd_en = 0;
	fifo_cmd_o_rd_en = 1'b0;
	fifo_pciecfg_o_rd_en = 1'b0;

	case(tx_state)
	TX_IDLE: begin
		// TODO rd_en of afifo should be active on the next clock after the empty
		if (!fifo_cmd_o_empty && !fifo_cmd_o_dout.data_valid) begin
			fifo_cmd_o_rd_en = 1'b1;
		end

		// TODO
		if (!fifo_pciecfg_o_empty && !fifo_pciecfg_o_dout.data_valid) begin
			fifo_pciecfg_o_rd_en = 1'b1;
		end

		if (eth_tready) begin
			if (!empty ||
				(!fifo_cmd_o_empty && fifo_cmd_o_dout.data_valid) ||
				(!fifo_pciecfg_o_empty && fifo_pciecfg_o_dout.data_valid)) begin
				tx_state_next = TX_READY;
			end
		end
	end
	TX_READY: begin
		tx_state_next = TX_HDR;
	end
	TX_HDR: begin
		eth_tvalid = 1'b1;
		eth_tkeep = 8'b1111_1111;

		case (tx_count)
		5'h0: eth_tdata = endian_conv64(tx_hdr0);
		5'h1: eth_tdata = endian_conv64(tx_hdr1);
		5'h2: eth_tdata = endian_conv64(tx_hdr2);
		5'h3: eth_tdata = endian_conv64(tx_hdr3);
		5'h4: eth_tdata = endian_conv64(tx_hdr4);
		default: eth_tdata = 64'b0;
		endcase

		if (eth_tready) begin
			if (tx_count == 4) begin
				// priority TLP > CMD > PCIECFG
				if (tx_mode == MODE_TLP) begin
					tx_state_next = TX_DATA_TLP;
				end else if (tx_mode == MODE_NETTLP_CMD) begin
					tx_state_next = TX_DATA_CMD;
				end else if (tx_mode == MODE_PCIECFG) begin
					tx_state_next = TX_DATA_PCIECFG;
				end
			end

		end
	end
	TX_DATA_TLP: begin
		if (eth_tready) begin
			tx_state_next = TX_DATA;
		end
		eth_tvalid = 1'b1;
		eth_tkeep = 8'b1111_1111;
		eth_tdata = endian_conv64(tx_hdr5);
	end
	TX_DATA_CMD: begin
		if (eth_tready) begin
			tx_state_next = TX_IDLE;

			fifo_cmd_o_rd_en = 1'b1;
		end

		eth_tvalid = 1'b1;
		eth_tlast  = 1'b1;
		eth_tkeep  = 8'b1111_1111;
		eth_tdata  = endian_conv64(fifo_cmd_o_dout.pkt);
	end
	TX_DATA_PCIECFG: begin
		if (eth_tready) begin
			tx_state_next = TX_IDLE;

			fifo_pciecfg_o_rd_en = 1'b1;
		end

		eth_tvalid = 1'b1;
		eth_tlast  = 1'b1;
		eth_tkeep  = 8'b1111_1111;
		eth_tdata  = endian_conv64(fifo_pciecfg_o_dout.pkt);
	end
	TX_DATA: begin
		eth_tvalid = dout.tvalid;
		eth_tlast  = dout.tlast;
		eth_tkeep  = dout.tkeep;
		eth_tdata  = {   // byte order
			dout.tdata.oct[4], dout.tdata.oct[5], dout.tdata.oct[6], dout.tdata.oct[7],
			dout.tdata.oct[0], dout.tdata.oct[1], dout.tdata.oct[2], dout.tdata.oct[3]
		};

		if (eth_tready) begin
			rd_en = 1;
			if (dout.tlast) begin
				tx_state_next = TX_IDLE;
			end
		end
	end
	default:
		tx_state_next = TX_IDLE;
	endcase
end

wire _unused_ok = &{
	dout.tuser,
	adapter_reg_magic,
	adapter_reg_dstport,
	adapter_reg_srcport,
	1'b0
};

`ifdef zero
ila_0 ila_00 (
	.clk(eth_clk),
	.probe0(tx_state),
	.probe1(rd_en),
	.probe2(empty),
	.probe3(eth_tready),
	.probe4(eth_tvalid),
	.probe5(eth_tlast),
	.probe6(fifo_cmd_o_rd_en),
	.probe7(fifo_cmd_o_empty),
	.probe8(tx_state_next)
);
`endif

endmodule

`default_nettype wire

