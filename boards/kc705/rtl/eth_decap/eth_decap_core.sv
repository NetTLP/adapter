`default_nettype none
`timescale 1ns / 1ps

module eth_decap_core
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
	parameter eth_proto = ETH_P_IP,
	parameter ip_saddr  = {8'd192, 8'd168, 8'd10, 8'd1},
	parameter ip_daddr  = {8'd192, 8'd168, 8'd10, 8'd3},
	parameter udp_sport = 16'h3776,
	parameter udp_dport = 16'h3776
)(
	input wire eth_clk,
	input wire eth_rst,

	// packet in
	input ETH_TVALID64   eth_tvalid,
	input ETH_TLAST64    eth_tlast,
	input ETH_TKEEP64    eth_tkeep,
	input ETH_TDATA64_RX eth_tdata,
	input ETH_TUSER64_RX eth_tuser,

	// TLP packet (FIFO write)
	output logic          wr_en,
	output PCIE_FIFO64_TX din,
	input wire            full,

	//output logic [ 7:0] eth_pktcount
	output logic fifo_read_req,

	// to nettlp command fifo
	output logic             fifo_cmd_i_wr_en,
	output FIFO_NETTLP_CMD_T fifo_cmd_i_din,
	input wire               fifo_cmd_i_full,

	// to pciecfg fifo
	output logic          fifo_pciecfg_i_wr_en,
	output FIFO_PCIECFG_T fifo_pciecfg_i_din,
	input wire            fifo_pciecfg_i_full
);

/* state */
enum logic [3:0] {
	RX_HDRCHK0,
	RX_HDRCHK1,
	RX_HDRCHK2,
	RX_HDRCHK3,
	RX_HDRCHK4,
	RX_HDRCHK5,
	RX_PAYLOAD_TLP,
	RX_PAYLOAD_TLP_BUBBLE,
	RX_PAYLOAD_CMD,
	RX_PAYLOAD_CMD_BUBBLE,
	//RX_PAYLOAD_ARP,
	RX_PAYLOAD_PCIECFG,
	RX_PAYLOAD_PCIECFG_BUBBLE,
	RX_ERR_FIFOFULL,
	RX_ERR_NOTLP
} rx_state = RX_HDRCHK0, rx_state_next;

always_ff @(posedge eth_clk)
	rx_state <= rx_state_next;


/* receive packet data */

//PACKET_QWORD0 rx_hdr0;
PACKET_QWORD1 rx_hdr1;
PACKET_QWORD2 rx_hdr2;
PACKET_QWORD3 rx_hdr3;
PACKET_QWORD4 rx_hdr4;
PACKET_QWORD5 rx_hdr5;

ETH_TDATA64 eth_tdata_conv;
always_comb eth_tdata_conv = endian_conv64(eth_tdata);
logic [2:0] cmd_bubble_count;
logic [2:0] pciecfg_bubble_count;
always_ff @(posedge eth_clk) begin
	if (eth_rst) begin
		//rx_hdr0 <= '{default: '0};
		rx_hdr1 <= '{default: '0};
		rx_hdr2 <= '{default: '0};
		rx_hdr3 <= '{default: '0};
		rx_hdr4 <= '{default: '0};
		rx_hdr5 <= '{default: '0};

		cmd_bubble_count <= 3'b0;
		pciecfg_bubble_count <= 3'b0;
	end else begin
		cmd_bubble_count <= 3'b0;
		pciecfg_bubble_count <= 3'b0;

		case (rx_state)
			//RX_HDRCHK0: rx_hdr0 <= eth_tdata_conv;
			RX_HDRCHK1: rx_hdr1 <= eth_tdata_conv;
			RX_HDRCHK2: rx_hdr2 <= eth_tdata_conv;
			RX_HDRCHK3: rx_hdr3 <= eth_tdata_conv;
			RX_HDRCHK4: rx_hdr4 <= eth_tdata_conv;
			RX_HDRCHK5: rx_hdr5 <= eth_tdata_conv;
			RX_PAYLOAD_CMD_BUBBLE: begin
				if (!fifo_cmd_i_full) begin
					cmd_bubble_count <= cmd_bubble_count + 3'd1;
				end
			end
			RX_PAYLOAD_PCIECFG_BUBBLE: begin
				if (!fifo_pciecfg_i_full) begin
					pciecfg_bubble_count <= pciecfg_bubble_count + 3'd1;
				end
			end
			default begin
				//rx_hdr0 <= '{default: '0};
				rx_hdr1 <= '{default: '0};
				rx_hdr2 <= '{default: '0};
				rx_hdr3 <= '{default: '0};
				rx_hdr4 <= '{default: '0};
				rx_hdr5 <= '{default: '0};
			end
		endcase
	end
end


/* packet filter */

wire is_correct_packet1 = (
	//{rx_hdr0.eth.h_source0, rx_hdr1.eth.h_source1} == eth_dst &&
	rx_hdr1.eth.h_proto == eth_proto &&
	{rx_hdr1.ip.version, rx_hdr1.ip.ihl} == {IPVERSION, 4'd5}
);

wire is_correct_packet2 = (rx_hdr2.ip.protocol == IP4_PROTO_UDP);

wire is_correct_packet3 = (rx_hdr3.ip.saddr == ip_daddr);

wire is_correct_packet4_tlp = (
	{rx_hdr3.ip.daddr0, rx_hdr4.ip.daddr1} == ip_saddr &&
	//rx_hdr4.udp.source[15:12] == 4'b0011 &&   // src port: 0x3000 + (TLP_tag & 0xF)
	rx_hdr4.udp.dest[15:12] == 4'b0011        // dest port: 0x3000 + (TLP_tag & 0xF)
);

wire is_correct_packet4_cmd = (
	{rx_hdr3.ip.daddr0, rx_hdr4.ip.daddr1} == ip_saddr &&
	rx_hdr4.udp.dest == udp_nettlp_cmd_port     // dest port: 0x4002
);

wire is_correct_packet4_pciecfg = (
	{rx_hdr3.ip.daddr0, rx_hdr4.ip.daddr1} == ip_saddr &&
	rx_hdr4.udp.dest == udp_pciecfg_port        // dest port: 0x4001
);


// TODO
//wire is_correct_packet4_arp = (
//	{rx_hdr3.ip.daddr0, rx_hdr4.ip.daddr1} == ip_saddr
////	rx_hdr4.udp.dest == 16'h4002        // dest port: 0x4002
//);

always_comb begin
	rx_state_next = rx_state;

	wr_en = '0;

	din.data_valid = '0;

	din.tlp.tvalid = '0;
	din.tlp.tlast = '0;
	din.tlp.tkeep = '0;
	din.tlp.tdata = '0;
	din.tlp.tuser = '0;

	fifo_read_req = '0;

	fifo_cmd_i_wr_en = '0;
	fifo_cmd_i_din = '{default: '0};

	fifo_pciecfg_i_wr_en = '0;
	fifo_pciecfg_i_din = '{default: '0};

	case (rx_state)
	RX_HDRCHK0: begin
		if (eth_tvalid == 1'b1) begin
			rx_state_next = RX_HDRCHK1;
		end
	end
	RX_HDRCHK1: begin
		rx_state_next = RX_HDRCHK2;
	end
	RX_HDRCHK2: begin
		if (is_correct_packet1) begin
			rx_state_next = RX_HDRCHK3;
		end else begin
			rx_state_next = RX_ERR_NOTLP;
		end
	end
	RX_HDRCHK3: begin
		if (is_correct_packet2) begin
			rx_state_next = RX_HDRCHK4;
		end else begin
			rx_state_next = RX_ERR_NOTLP;
		end
	end
	RX_HDRCHK4: begin
		if (is_correct_packet3) begin
			rx_state_next = RX_HDRCHK5;
		end else begin
			rx_state_next = RX_ERR_NOTLP;
		end
	end
	RX_HDRCHK5: begin
		if (is_correct_packet4_tlp) begin
			rx_state_next = RX_PAYLOAD_TLP;
		end else if (is_correct_packet4_cmd) begin
			rx_state_next = RX_PAYLOAD_CMD;
		end else if (is_correct_packet4_pciecfg) begin
			rx_state_next = RX_PAYLOAD_PCIECFG;
		end else begin
			rx_state_next = RX_ERR_NOTLP;
		end
	end
	RX_PAYLOAD_TLP: begin
		if (!full) begin
			if (eth_tlast) begin
				rx_state_next = RX_PAYLOAD_TLP_BUBBLE;

				fifo_read_req = 1'b1;
			end

			wr_en = '1;

			din.data_valid = '1;

			din.tlp.tvalid = eth_tvalid;
			din.tlp.tlast = eth_tlast;
			din.tlp.tkeep = eth_tkeep;
			din.tlp.tdata = {
				eth_tdata_conv.oct[3], eth_tdata_conv.oct[2],
				eth_tdata_conv.oct[1], eth_tdata_conv.oct[0],
				eth_tdata_conv.oct[7], eth_tdata_conv.oct[6],
				eth_tdata_conv.oct[5], eth_tdata_conv.oct[4] 
			};
			//din.tlp.tuser = eth_tuser;
			din.tlp.tuser = '0;
		end else begin
			rx_state_next = RX_ERR_FIFOFULL;
		end
	end
	RX_PAYLOAD_TLP_BUBBLE: begin
		rx_state_next = RX_HDRCHK0;

		wr_en = '1;
	end
	RX_PAYLOAD_CMD: begin
		if (!fifo_cmd_i_full) begin
			rx_state_next = RX_PAYLOAD_CMD_BUBBLE;

			fifo_cmd_i_wr_en = 1'b1;
			fifo_cmd_i_din.data_valid = 1'b1;
			fifo_cmd_i_din.pkt = rx_hdr5;
		end else begin
			rx_state_next = RX_HDRCHK0; // TODO
		end
	end
	RX_PAYLOAD_CMD_BUBBLE: begin
		if (!cmd_bubble_count[2]) begin
			if (!fifo_cmd_i_full) begin
				fifo_cmd_i_wr_en = 1'b1;
				fifo_cmd_i_din.data_valid = 1'b0;
				fifo_cmd_i_din.pkt = rx_hdr5;
			end
		end else begin
			rx_state_next = RX_HDRCHK0;
		end
	end
	RX_PAYLOAD_PCIECFG: begin
		if (!fifo_pciecfg_i_full) begin
			rx_state_next = RX_PAYLOAD_PCIECFG_BUBBLE;

			fifo_pciecfg_i_wr_en = 1'b1;
			fifo_pciecfg_i_din.data_valid = 1'b1;
			fifo_pciecfg_i_din.pkt = rx_hdr5;
		end else begin
			rx_state_next = RX_HDRCHK0; // TODO
		end
	end
	RX_PAYLOAD_PCIECFG_BUBBLE: begin
		if (!pciecfg_bubble_count[2]) begin
			if (!fifo_pciecfg_i_full) begin
				fifo_pciecfg_i_wr_en = 1'b1;
				fifo_pciecfg_i_din.data_valid = 1'b0;
				fifo_pciecfg_i_din.pkt = rx_hdr5;
			end
		end else begin
			rx_state_next = RX_HDRCHK0; // TODO
		end
	end
	RX_ERR_FIFOFULL: begin
		// wait a full space and force insert tlast TODO
		// should use alomost_full
		if (!full) begin
			rx_state_next = RX_HDRCHK0;

			wr_en = '1;

			din.data_valid = '1;

			din.tlp.tlast = '1;

			fifo_read_req = '1;
		end
	end
	RX_ERR_NOTLP: begin
		// wait packet tail
		if (eth_tlast)
			rx_state_next = RX_HDRCHK0;
	end
	default begin
		rx_state_next = RX_HDRCHK0;
	end
	endcase
end

wire _unused_ok = &{
	eth_tuser,
	1'b0
};

`ifdef zero
ila_0 ila_00 (
	.clk(eth_clk),
	.probe0(rx_state),  // 4
	.probe1(wr_en),
	.probe2(full),
	.probe3(fifo_cmd_i_wr_en),
	.probe4(fifo_cmd_i_full),
	.probe5(fifo_pciecfg_i_wr_en),
	.probe6(fifo_pciecfg_i_full),
	.probe7(din.tlp.tvalid),
	.probe8(din.tlp.tlast),
	.probe9(is_correct_packet1),
	.probe10(is_correct_packet2),
	.probe11(is_correct_packet3),
	.probe12(is_correct_packet4_tlp),
	.probe13(is_correct_packet4_cmd),
	.probe14(eth_tvalid),
	.probe15(eth_tlast)
);
`endif

endmodule

`default_nettype wire

