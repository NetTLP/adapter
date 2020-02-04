module pcie_mem_access (
	input wire clk,
	input wire rst_n,

	// Read Access
	input wire [3:0] rd_be,
	input wire [13:0] rd_addr,
	output wire [31:0] rd_data,

	// Write Access
	input wire wr_en,
	input wire [7:0] wr_be,
	input wire [13:0] wr_addr,
	input wire [31:0] wr_data,
	output wire wr_busy,

	input wire [15:0] completer_id,

	input wire [31:0] adapter_reg_magic,
	input wire [47:0] adapter_reg_dstmac,
	input wire [47:0] adapter_reg_srcmac,
	input wire [31:0] adapter_reg_dstip,
	input wire [31:0] adapter_reg_srcip,
	input wire [15:0] adapter_reg_dstport,
	input wire [15:0] adapter_reg_srcport
);

assign wr_busy = 1'b0;


// bar2
reg bram_bar2_we0, bram_bar2_we1, bram_bar2_we2, bram_bar2_we3;
reg [7:0] bram_bar2_addr0, bram_bar2_addr1, bram_bar2_addr2, bram_bar2_addr3;
reg [7:0] bram_bar2_din0, bram_bar2_din1, bram_bar2_din2, bram_bar2_din3;
wire [7:0] bram_bar2_dout0, bram_bar2_dout1, bram_bar2_dout2, bram_bar2_dout3;
mybram #( .WIDTH(8), .DEPTH(8) ) bar2_bram0 ( .clk(clk), .we(bram_bar2_we0), .addr(bram_bar2_addr0), .din(bram_bar2_din0), .dout(bram_bar2_dout0) );
mybram #( .WIDTH(8), .DEPTH(8) ) bar2_bram1 ( .clk(clk), .we(bram_bar2_we1), .addr(bram_bar2_addr1), .din(bram_bar2_din1), .dout(bram_bar2_dout1) );
mybram #( .WIDTH(8), .DEPTH(8) ) bar2_bram2 ( .clk(clk), .we(bram_bar2_we2), .addr(bram_bar2_addr2), .din(bram_bar2_din2), .dout(bram_bar2_dout2) );
mybram #( .WIDTH(8), .DEPTH(8) ) bar2_bram3 ( .clk(clk), .we(bram_bar2_we3), .addr(bram_bar2_addr3), .din(bram_bar2_din3), .dout(bram_bar2_dout3) );

// bar0
reg [31:0] read_data_bar0;

always @(posedge clk) begin
	if (rst_n) begin
		if (wr_en == 1'b0) begin  // read
			if (rd_addr[13:12] == 2'b01) begin
				case (rd_addr[5:0])
				6'h00: read_data_bar0 <= { adapter_reg_magic[7:0], adapter_reg_magic[15:8], adapter_reg_magic[23:16], adapter_reg_magic[31:24] };
				6'h01: read_data_bar0 <= { adapter_reg_dstmac[7:0], adapter_reg_dstmac[15:8], adapter_reg_dstmac[23:16], adapter_reg_dstmac[31:24] };
				6'h02: read_data_bar0 <= { adapter_reg_dstmac[39:32], adapter_reg_dstmac[47:40], 8'h0, 8'h0 };
				6'h03: read_data_bar0 <= { adapter_reg_srcmac[7:0], adapter_reg_srcmac[15:8], adapter_reg_srcmac[23:16], adapter_reg_srcmac[31:24] };
				6'h04: read_data_bar0 <= { adapter_reg_srcmac[39:32], adapter_reg_srcmac[47:40], 8'h0, 8'h0 };
				6'h05: read_data_bar0 <= { adapter_reg_dstip[7:0], adapter_reg_dstip[15:8], adapter_reg_dstip[23:16], adapter_reg_dstip[31:24] };
				6'h06: read_data_bar0 <= { adapter_reg_srcip[7:0], adapter_reg_srcip[15:8], adapter_reg_srcip[23:16], adapter_reg_srcip[31:24] };
				6'h07: read_data_bar0 <= { adapter_reg_dstport[7:0], adapter_reg_dstport[15:8], 8'h0, 8'h0 };
				6'h08: read_data_bar0 <= { adapter_reg_srcport[7:0], adapter_reg_srcport[15:8], 8'h0, 8'h0 };

				6'h10: read_data_bar0 <= { completer_id[7:0], completer_id[15:8], 8'h0, 8'h0 };
				default:
				read_data_bar0 <= 32'h0;
				endcase
			end else begin
				read_data_bar0 <= 32'b0;
			end
		end
	end
end

// BAR2
reg [31:0] read_data_bar2;

always @* begin
   	bram_bar2_we0 <= 1'b0;
	bram_bar2_we1 <= 1'b0;
	bram_bar2_we2 <= 1'b0;
	bram_bar2_we3 <= 1'b0;

    read_data_bar2 <= 32'b0;
	if (wr_en == 1'b1) begin  // write
		bram_bar2_addr0 <= wr_addr[7:0];
		bram_bar2_addr1 <= wr_addr[7:0];
		bram_bar2_addr2 <= wr_addr[7:0];
		bram_bar2_addr3 <= wr_addr[7:0];

		bram_bar2_din0 <= wr_data[31:24];
		bram_bar2_din1 <= wr_data[23:16];
		bram_bar2_din2 <= wr_data[15: 8];
		bram_bar2_din3 <= wr_data[ 7: 0];

		if (wr_addr[13:12] == 2'b10) begin
			if (wr_be[0]) bram_bar2_we0 <= 1'b1;
			if (wr_be[1]) bram_bar2_we1 <= 1'b1;
			if (wr_be[2]) bram_bar2_we2 <= 1'b1;
			if (wr_be[3]) bram_bar2_we3 <= 1'b1;
		end
	end else begin  // read
		bram_bar2_addr0 <= rd_addr[7:0];
		bram_bar2_addr1 <= rd_addr[7:0];
		bram_bar2_addr2 <= rd_addr[7:0];
		bram_bar2_addr3 <= rd_addr[7:0];
		
		if (rd_addr[13:12] == 2'b10) begin
			read_data_bar2 <= { bram_bar2_dout0, bram_bar2_dout1, bram_bar2_dout2, bram_bar2_dout3 };
		end
	end
end

function [31:0] dec_data;
	input [1:0] sel;
	input [31:0] bar0;
	input [31:0] bar2;
	case (sel)
		2'b00: dec_data = 32'h0;
		2'b01: dec_data = bar0;
		2'b10: dec_data = bar2;
		2'b11: dec_data = 32'h0;
	endcase
endfunction
assign rd_data = dec_data(rd_addr[13:12], read_data_bar0, read_data_bar2);

endmodule

