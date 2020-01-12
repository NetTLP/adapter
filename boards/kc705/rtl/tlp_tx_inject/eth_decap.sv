`default_nettype none
`timescale 1ns / 1ps

module eth_decap
	import utils_pkg::*;
	import endian_pkg::*;
	import ethernet_pkg::*;
	import ip_pkg::*;
	import udp_pkg::*;
	import pcie_tlp_pkg::*;
	import nettlp_cmd_pkg::*;
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
	input wire               fifo_cmd_i_full
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
	RX_PAYLOAD_CMD,
	//RX_PAYLOAD_ARP,
	//RX_PAYLOAD_PCIECFG,
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
//PACKET_QWORD5 rx_hdr5;


ETH_TDATA64 eth_tdata_conv;
always_comb eth_tdata_conv = endian_conv64(eth_tdata);

always_ff @(posedge eth_clk) begin
	if (eth_rst) begin
		//rx_hdr0 <= '{default: '0};
		rx_hdr1 <= '{default: '0};
		rx_hdr2 <= '{default: '0};
		rx_hdr3 <= '{default: '0};
		rx_hdr4 <= '{default: '0};
		//rx_hdr5 <= '{default: '0};
	end else begin
		if (eth_tvalid) begin
			case (rx_state)
			//RX_HDRCHK0: rx_hdr0 <= eth_tdata_conv;
			RX_HDRCHK1: rx_hdr1 <= eth_tdata_conv;
			RX_HDRCHK2: rx_hdr2 <= eth_tdata_conv;
			RX_HDRCHK3: rx_hdr3 <= eth_tdata_conv;
			RX_HDRCHK4: rx_hdr4 <= eth_tdata_conv;
			//RX_HDRCHK5: rx_hdr5 <= eth_tdata_conv;
			default begin
			end
			endcase
		end else begin
			//rx_hdr0 <= '{default: '0};
			rx_hdr1 <= '{default: '0};
			rx_hdr2 <= '{default: '0};
			rx_hdr3 <= '{default: '0};
			rx_hdr4 <= '{default: '0};
			//rx_hdr5 <= '{default: '0};
		end
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
	rx_hdr4.udp.dest == 16'h4002        // dest port: 0x4002
);

// TODO
//wire is_correct_packet4_arp = (
//	{rx_hdr3.ip.daddr0, rx_hdr4.ip.daddr1} == ip_saddr
////	rx_hdr4.udp.dest == 16'h4002        // dest port: 0x4002
//);

//wire is_correct_packet4_pciecfg = (
//	{rx_hdr3.ip.daddr0, rx_hdr4.ip.daddr1} == ip_saddr &&
//	rx_hdr4.udp.dest == 16'h4001        // dest port: 0x4001
//);

always_comb begin
	rx_state_next = rx_state;

	wr_en = '0;
	din.tvalid = '0;
	din.tlast = '0;
	din.tkeep = '0;
	din.tdata = '0;
	din.tuser = '0;

	fifo_read_req = '0;

	fifo_cmd_i_wr_en = '0;
	fifo_cmd_i_din = '{default: '0};

	if (eth_tvalid) begin
		case (rx_state)
		RX_HDRCHK0: begin
			rx_state_next = RX_HDRCHK1;
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
				rx_state_next = RX_PAYLOAD_TLP;
			end else begin
				rx_state_next = RX_ERR_NOTLP;
			end
		end
		RX_PAYLOAD_TLP: begin
			if (!full) begin
				if (eth_tlast) begin
					rx_state_next = RX_HDRCHK0;

					fifo_read_req = '1;
				end

				wr_en = '1;

				din.tvalid = eth_tvalid;
				din.tlast = eth_tlast;
				din.tkeep = eth_tkeep;
				din.tdata = {
					eth_tdata_conv.oct[3], eth_tdata_conv.oct[2],
					eth_tdata_conv.oct[1], eth_tdata_conv.oct[0],
					eth_tdata_conv.oct[7], eth_tdata_conv.oct[6],
					eth_tdata_conv.oct[5], eth_tdata_conv.oct[4] 
				};
				//din.tuser = eth_tuser;
				din.tuser = '0;
			end else begin
				rx_state_next = RX_ERR_FIFOFULL;
			end
		end
		RX_PAYLOAD_CMD: begin
			if (!fifo_cmd_i_full) begin
				if (eth_tlast) begin
					rx_state_next = RX_HDRCHK0;
				end

				fifo_cmd_i_wr_en = '1;
				fifo_cmd_i_din = {
					eth_tdata_conv.oct[3], eth_tdata_conv.oct[2],
					eth_tdata_conv.oct[1], eth_tdata_conv.oct[0],
					eth_tdata_conv.oct[7], eth_tdata_conv.oct[6],
					eth_tdata_conv.oct[5], eth_tdata_conv.oct[4] 
				};
			end else begin
				rx_state_next = RX_HDRCHK0; // TODO
			end
		end
		RX_ERR_FIFOFULL: begin
			// wait a full space and force insert tlast
			if (!full) begin
				rx_state_next = RX_HDRCHK0;

				wr_en = '1;

				din.tlast = '1;

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
end

wire _unused_ok = &{
	eth_tuser,
	1'b0
};

ila_0 ila_00 (
	.clk(eth_clk),
	.probe0(rx_state),
	.probe1(wr_en),
	.probe2(full),
	.probe3(fifo_cmd_i_wr_en),
	.probe4(fifo_cmd_i_full),
	.probe5(din.tvalid),
	.probe6(din.tlast),
	.probe7(is_correct_packet1),
    .probe8(is_correct_packet2),
    .probe9(is_correct_packet3),
    .probe10(is_correct_packet4_tlp),
    .probe11(is_correct_packet4_cmd),
    .probe12(eth_tvalid),
    .probe13(eth_tlast)
);

endmodule

`default_nettype wire

