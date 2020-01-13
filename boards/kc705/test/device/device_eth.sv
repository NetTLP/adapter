`default_nettype none
`timescale 1ns / 1ps

module device_eth
	import endian_pkg::*;
	import utils_pkg::*;
#(
	parameter C_DATA_WIDTH               = 64,
	parameter KEEP_WIDTH                 = C_DATA_WIDTH / 8
)(
	input wire eth_clk,
	input wire sys_rst,

	output logic        eth_rx_tvalid,
	output logic [63:0] eth_rx_tdata,
	output logic [ 7:0] eth_rx_tkeep,
	output logic        eth_rx_tlast,
	output logic        eth_rx_tuser
);

logic [7:0] count;
enum logic [1:0] { IDLE, RX, TX } state;
always_ff @(posedge eth_clk) begin
	if (sys_rst) begin
		count <= 0;
		state <= IDLE;
	end else begin
		case (state)
		IDLE: begin
			count <= 0;
			state <= RX;
		end
		RX: begin
			count <= count + 1;
			if (count == 50) begin
				state <= IDLE;
			end
		end
		default: state <= IDLE;
		endcase
	end
end

logic [63:0] eth_rx_tdata_tmp;
logic [7:0] eth_rx_tkeep_tmp;

// 90e2ba5d_8dc90011
// 22334455_08004500
// 002e0000_00004011
// e36ac0a8_0b01c0a8
// 0b033776_3776001a
// 0000001a_5249c267
// 00000001_00000003
// c0004000_00000000

// compl
// 02000002 4a000001
// 67452301 00000000


// ffff ffff ffff 0011
// 2233 4455 0800 4500
// 0022 0000 0000 4011
// e576 c0a8 0a01 c0a8
// 0a03 3000 3000 000e
// 0000 0000 0000 0000
// 0000 0000 0000 0000
// 0000 0000          

// cmd_wr
// 00112233_4455a036
// 9f28ae9c_08004500
// 0022f1d3_0000ff11
// 34a2c0a8_0a03c0a8
// 0a014002_4002000e
// 00001107_33330000

// cmd_rd
// 00112233_4455a036
// 9f28ae9c_08004500
// 002244b3_0000ff11
// e1c2c0a8_0a03c0a8
// 0a014002_4002000e
// 00001007_00000000

// cc
always_comb begin
	case (state)
	RX: begin
		case (count)
		8'h04: {eth_rx_tvalid, eth_rx_tlast, eth_rx_tkeep_tmp, eth_rx_tdata_tmp, eth_rx_tuser} = {1'b1, 1'b0, 8'b1111_1111, 64'h00112233_4455a036, 1'b0};
		8'h05: {eth_rx_tvalid, eth_rx_tlast, eth_rx_tkeep_tmp, eth_rx_tdata_tmp, eth_rx_tuser} = {1'b1, 1'b0, 8'b1111_1111, 64'h9f28ae9c_08004500, 1'b0};
		8'h06: {eth_rx_tvalid, eth_rx_tlast, eth_rx_tkeep_tmp, eth_rx_tdata_tmp, eth_rx_tuser} = {1'b1, 1'b0, 8'b1111_1111, 64'h0022f1d3_0000ff11, 1'b0};
		8'h07: {eth_rx_tvalid, eth_rx_tlast, eth_rx_tkeep_tmp, eth_rx_tdata_tmp, eth_rx_tuser} = {1'b1, 1'b0, 8'b1111_1111, 64'h34a2c0a8_0a03c0a8, 1'b0};
		8'h08: {eth_rx_tvalid, eth_rx_tlast, eth_rx_tkeep_tmp, eth_rx_tdata_tmp, eth_rx_tuser} = {1'b1, 1'b0, 8'b1111_1111, 64'h0a014002_4002000e, 1'b0};
		//8'h09: {eth_rx_tvalid, eth_rx_tlast, eth_rx_tkeep_tmp, eth_rx_tdata_tmp, eth_rx_tuser} = {1'b1, 1'b1, 8'b1111_1111, 64'h00001107_33330000, 1'b0};
		8'h09: {eth_rx_tvalid, eth_rx_tlast, eth_rx_tkeep_tmp, eth_rx_tdata_tmp, eth_rx_tuser} = {1'b1, 1'b1, 8'b1111_1111, 64'h00001007_00000000, 1'b0};

		8'h14: {eth_rx_tvalid, eth_rx_tlast, eth_rx_tkeep_tmp, eth_rx_tdata_tmp, eth_rx_tuser} = {1'b1, 1'b0, 8'b1111_1111, 64'h90e2ba5d_8dc90011, 1'b0};
		8'h15: {eth_rx_tvalid, eth_rx_tlast, eth_rx_tkeep_tmp, eth_rx_tdata_tmp, eth_rx_tuser} = {1'b1, 1'b0, 8'b1111_1111, 64'h22334455_08004600, 1'b0};    // 45 -> 46
		8'h16: {eth_rx_tvalid, eth_rx_tlast, eth_rx_tkeep_tmp, eth_rx_tdata_tmp, eth_rx_tuser} = {1'b1, 1'b0, 8'b1111_1111, 64'h002e0000_00004011, 1'b0};
		8'h17: {eth_rx_tvalid, eth_rx_tlast, eth_rx_tkeep_tmp, eth_rx_tdata_tmp, eth_rx_tuser} = {1'b1, 1'b0, 8'b1111_1111, 64'he36ac0a8_0a03c0a8, 1'b0};
		8'h18: {eth_rx_tvalid, eth_rx_tlast, eth_rx_tkeep_tmp, eth_rx_tdata_tmp, eth_rx_tuser} = {1'b1, 1'b0, 8'b1111_1111, 64'h0a013776_3776001a, 1'b0};
		8'h19: {eth_rx_tvalid, eth_rx_tlast, eth_rx_tkeep_tmp, eth_rx_tdata_tmp, eth_rx_tuser} = {1'b1, 1'b0, 8'b1111_1111, 64'h0000001a_5249c267, 1'b0};
		8'h1a: {eth_rx_tvalid, eth_rx_tlast, eth_rx_tkeep_tmp, eth_rx_tdata_tmp, eth_rx_tuser} = {1'b1, 1'b0, 8'b1111_1111, 64'h00000001_00000003, 1'b0};
		8'h1b: {eth_rx_tvalid, eth_rx_tlast, eth_rx_tkeep_tmp, eth_rx_tdata_tmp, eth_rx_tuser} = {1'b1, 1'b1, 8'b1111_0000, 64'hc0004000_00000000, 1'b0};

		8'h24: {eth_rx_tvalid, eth_rx_tlast, eth_rx_tkeep_tmp, eth_rx_tdata_tmp, eth_rx_tuser} = {1'b1, 1'b0, 8'b1111_1111, 64'h90e2ba5d_8dc90011, 1'b0};
		8'h25: {eth_rx_tvalid, eth_rx_tlast, eth_rx_tkeep_tmp, eth_rx_tdata_tmp, eth_rx_tuser} = {1'b1, 1'b0, 8'b1111_1111, 64'h22334455_08004500, 1'b0};
		8'h26: {eth_rx_tvalid, eth_rx_tlast, eth_rx_tkeep_tmp, eth_rx_tdata_tmp, eth_rx_tuser} = {1'b1, 1'b0, 8'b1111_1111, 64'h002e0000_00004011, 1'b0};
		8'h27: {eth_rx_tvalid, eth_rx_tlast, eth_rx_tkeep_tmp, eth_rx_tdata_tmp, eth_rx_tuser} = {1'b1, 1'b0, 8'b1111_1111, 64'he36ac0a8_0a03c0a8, 1'b0};
		8'h28: {eth_rx_tvalid, eth_rx_tlast, eth_rx_tkeep_tmp, eth_rx_tdata_tmp, eth_rx_tuser} = {1'b1, 1'b0, 8'b1111_1111, 64'h0a013011_3011001a, 1'b0};
		8'h29: {eth_rx_tvalid, eth_rx_tlast, eth_rx_tkeep_tmp, eth_rx_tdata_tmp, eth_rx_tuser} = {1'b1, 1'b0, 8'b1111_1111, 64'h0000001a_5249c267, 1'b0};
		8'h2a: {eth_rx_tvalid, eth_rx_tlast, eth_rx_tkeep_tmp, eth_rx_tdata_tmp, eth_rx_tuser} = {1'b1, 1'b0, 8'b1111_1111, 64'h00000001_00000003, 1'b0};
		8'h2b: {eth_rx_tvalid, eth_rx_tlast, eth_rx_tkeep_tmp, eth_rx_tdata_tmp, eth_rx_tuser} = {1'b1, 1'b1, 8'b1111_0000, 64'hc0004000_00000000, 1'b0};
		default:
		      {eth_rx_tvalid, eth_rx_tlast, eth_rx_tkeep_tmp, eth_rx_tdata_tmp, eth_rx_tuser} = {1'b0, 1'b0, 8'b0000_0000, 64'h00000000_00000000, 1'b0};
		endcase
	end
	TX: begin
		{eth_rx_tvalid, eth_rx_tlast, eth_rx_tkeep_tmp, eth_rx_tdata_tmp, eth_rx_tuser} = {1'b0, 1'b0, 8'b0000_0000, 64'h00000000_00000000, 1'b0};
	end
	default: begin
	end
	endcase
end

always_comb eth_rx_tkeep = reverse8(eth_rx_tkeep_tmp);
always_comb eth_rx_tdata = endian_conv64(eth_rx_tdata_tmp);

endmodule

`default_nettype wire

