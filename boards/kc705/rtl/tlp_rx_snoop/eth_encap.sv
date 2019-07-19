`default_nettype none
`timescale 1ns/1ps

import utils_pkg::*;
import endian_pkg::*;
import ethernet_pkg::*;
import ip_pkg::*;
import udp_pkg::*;
import pcie_tlp_pkg::*;
import nettlp_pkg::*;

module eth_encap #(
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
	
    input wire [31:0] magic,
    input wire [47:0] dstmac,
    input wire [47:0] srcmac,
    input wire [31:0] dstip,
    input wire [31:0] srcip,
    input wire [15:0] dstport,
    input wire [15:0] srcport
);

/* function: ipcheck_gen() */
function [15:0] ipcheck_gen (
	input TLP_LEN tlp_len,
	input bit [31:0] saddr,
	input bit [31:0] daddr
);
	bit [23:0] sum;
	sum = {8'h0, IPVERSION, 4'd5, 8'h0}
	    + {8'h0, tlp_len + PACKET_HDR_LEN - ETH_HDR_LEN}   // tot_len
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
enum logic [1:0] {
	TX_IDLE,
	TX_READY,
	TX_HDR,
	TX_DATA
} tx_state = TX_IDLE, tx_state_next;

always_ff @(posedge eth_clk)
	tx_state <= tx_state_next;


// build packet header
PACKET_QWORD0 tx_hdr0;
PACKET_QWORD1 tx_hdr1;
PACKET_QWORD2 tx_hdr2;
PACKET_QWORD3 tx_hdr3;
PACKET_QWORD4 tx_hdr4;
PACKET_QWORD5 tx_hdr5;

logic [4:0] tx_count;

always_ff @(posedge eth_clk) begin
	if (eth_rst) begin
		tx_hdr0 <= '{default: '0};
		tx_hdr1 <= '{default: '0};
		tx_hdr2 <= '{default: '0};
		tx_hdr3 <= '{default: '0};
		tx_hdr4 <= '{default: '0};
		tx_hdr5 <= '{default: '0};

		tx_count <= 0;
	end else begin
		// immutable values
		tx_hdr0.eth.h_dest <= dstmac;
		{tx_hdr0.eth.h_source0, tx_hdr1.eth.h_source1} <= srcmac;

		tx_hdr1.eth.h_proto <= eth_proto;
		tx_hdr1.ip.version <= IPVERSION;
		tx_hdr1.ip.ihl <= 4'd5;

		tx_hdr2.ip.ttl <= IPDEFTTL;
		tx_hdr2.ip.protocol <= IP4_PROTO_UDP;

		tx_hdr3.ip.saddr <= srcip;
		tx_hdr3.ip.daddr0 <= dstip[31:16];

		tx_hdr4.ip.daddr1 <= dstip[15:0];

		// free running counter for performance measurement
		tx_hdr5.tcap.tstamp <= tx_hdr5.tcap.tstamp + 1;

		case(tx_state)
		TX_IDLE: begin
			// mutable values
			tx_hdr2.ip.tot_len <= dout.tlp_len + PACKET_HDR_LEN - ETH_HDR_LEN;

			tx_hdr3.ip.check <= ipcheck_gen(dout.tlp_len, srcip, dstip);

			tx_hdr4.udp.len <= dout.tlp_len + NETTLP_HDR_LEN + UDP_HDR_LEN;

		    tx_hdr4.udp.source <= udp_sport + {8'b0, dout.tlp_tag};
		    
		    tx_hdr4.udp.dest <= udp_dport + {8'b0, dout.tlp_tag};

			tx_count <= 0;
		end
		TX_HDR: begin
			if (eth_tready) begin
				tx_count <= tx_count + 1;
			end
		end
		TX_DATA: begin
			if (eth_tready && dout.tlast) begin
				tx_hdr5.tcap.seq <= tx_hdr5.tcap.seq + 1;
			end
		end
		endcase
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

	case(tx_state)
	TX_IDLE: begin
		if (eth_tready && ~empty) begin
			tx_state_next = TX_READY;
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
		5'h5: eth_tdata = endian_conv64(tx_hdr5);
		default: eth_tdata = 64'b0;
		endcase

		if (eth_tready) begin
			if (tx_count == 5) begin
				tx_state_next = TX_DATA;
			end

		end
	end
	TX_DATA: begin
		eth_tvalid = dout.tvalid;
		eth_tlast  = dout.tlast;
		eth_tkeep  = dout.tkeep;
		eth_tdata  = {   // byte order
			dout.tdata.oct[4], dout.tdata.oct[5], dout.tdata.oct[6], dout.tdata.oct[7],
			dout.tdata.oct[0], dout.tdata.oct[1], dout.tdata.oct[2], dout.tdata.oct[3]
		};
		eth_tuser  = dout.tuser;

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

`ifdef NO
ila_0 ila0_ins (
	.clk(eth_clk),
	.probe0({       // 109: 107 + 1 + 1
	       rd_en,
	       dout.tlp_len,
	       dout.tvalid,
	       dout.tlast,
	       dout.tkeep,
	       dout.tdata,
	       dout.tuser,
	       empty
	}),
	.probe1({        // 80: 8 + 8 + 64
	       tx_state,
	       eth_tvalid,
	       eth_tlast,
	       eth_tready,
	       eth_tvalid,
	       eth_tlast,
	       eth_tkeep,
	       eth_tdata,
	       eth_tuser
	})
	
);
`endif

endmodule

`default_nettype wire

