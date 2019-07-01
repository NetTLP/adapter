module mem_access  #(
	parameter TCQ = 1
) (

	input wire pcie_clk,
	input wire pcie_rst,

	// Read Access
	input wire   [3:0] rd_be,      // I [3:0]   Read Byte Enable
	input wire  [13:0] rd_addr,    // I [13:0]  Read Address
	output wire [31:0] rd_data,         // O [31:0]  Read Data

	// Write Access
	input wire wr_en,              // I	 Write Enable
	input wire  [7:0] wr_be,       // I [7:0]   Write Byte Enable
	input wire [13:0] wr_addr,     // I [10:0]  Write Address
	input wire [31:0] wr_data,     // I [31:0]  Write Data
	output wire wr_busy,           // O	 Write Controller Busy
	
	output reg [31:0] magic,
    output reg [47:0] dstmac,
    output reg [47:0] srcmac,
    output reg [31:0] dstip,
    output reg [31:0] srcip,
    output reg [15:0] dstport,
    output reg [15:0] srcport
);

assign wr_busy = 1'b0;


//// bar0
//// address map:
//// 0-4: id
//reg bram_bar0_we0, bram_bar0_we1, bram_bar0_we2, bram_bar0_we3;
//reg [3:0] bram_bar0_addr0, bram_bar0_addr1, bram_bar0_addr2, bram_bar0_addr3;
//reg [7:0] bram_bar0_din0, bram_bar0_din1, bram_bar0_din2, bram_bar0_din3;
//wire [7:0] bram_bar0_dout0, bram_bar0_dout1, bram_bar0_dout2, bram_bar0_dout3;
//mybram #( .WIDTH(8), .DEPTH(4) ) bar0_bram0 ( .clk(pcie_clk), .we(bram_bar0_we0), .addr(bram_bar0_addr0), .din(bram_bar0_din0), .dout(bram_bar0_dout0) );
//mybram #( .WIDTH(8), .DEPTH(4) ) bar0_bram1 ( .clk(pcie_clk), .we(bram_bar0_we1), .addr(bram_bar0_addr1), .din(bram_bar0_din1), .dout(bram_bar0_dout1) );
//mybram #( .WIDTH(8), .DEPTH(4) ) bar0_bram2 ( .clk(pcie_clk), .we(bram_bar0_we2), .addr(bram_bar0_addr2), .din(bram_bar0_din2), .dout(bram_bar0_dout2) );
//mybram #( .WIDTH(8), .DEPTH(4) ) bar0_bram3 ( .clk(pcie_clk), .we(bram_bar0_we3), .addr(bram_bar0_addr3), .din(bram_bar0_din3), .dout(bram_bar0_dout3) );

// bar2
reg bram_bar2_we0, bram_bar2_we1, bram_bar2_we2, bram_bar2_we3;
reg [7:0] bram_bar2_addr0, bram_bar2_addr1, bram_bar2_addr2, bram_bar2_addr3;
reg [7:0] bram_bar2_din0, bram_bar2_din1, bram_bar2_din2, bram_bar2_din3;
wire [7:0] bram_bar2_dout0, bram_bar2_dout1, bram_bar2_dout2, bram_bar2_dout3;
mybram #( .WIDTH(8), .DEPTH(8) ) bar2_bram0 ( .clk(pcie_clk), .we(bram_bar2_we0), .addr(bram_bar2_addr0), .din(bram_bar2_din0), .dout(bram_bar2_dout0) );
mybram #( .WIDTH(8), .DEPTH(8) ) bar2_bram1 ( .clk(pcie_clk), .we(bram_bar2_we1), .addr(bram_bar2_addr1), .din(bram_bar2_din1), .dout(bram_bar2_dout1) );
mybram #( .WIDTH(8), .DEPTH(8) ) bar2_bram2 ( .clk(pcie_clk), .we(bram_bar2_we2), .addr(bram_bar2_addr2), .din(bram_bar2_din2), .dout(bram_bar2_dout2) );
mybram #( .WIDTH(8), .DEPTH(8) ) bar2_bram3 ( .clk(pcie_clk), .we(bram_bar2_we3), .addr(bram_bar2_addr3), .din(bram_bar2_din3), .dout(bram_bar2_dout3) );

// bar0
reg [31:0] read_data_bar0;

// BAR0
always @(posedge pcie_clk) begin
    if (pcie_rst) begin
        magic <= 32'h01_23_45_67;
        dstmac <= 48'hFF_FF_FF_FF_FF_FF;
        srcmac <= 48'h00_11_22_33_44_55;
        dstip <= {8'd192, 8'd168, 8'd10, 8'd3};
        srcip <= {8'd192, 8'd168, 8'd10, 8'd1};
        dstport <= 16'h3776;
        srcport <= 16'h3776;
    end else begin
        if (wr_en == 1'b1) begin  // write
    		case (wr_addr[13:12])
    		2'b01: begin
                case (wr_addr[5:0])
                6'h00: begin  // magic code
                if (wr_be[0]) magic[ 7: 0] <= wr_data[31:24];
                if (wr_be[1]) magic[15: 8] <= wr_data[23:16];
                if (wr_be[2]) magic[23:16] <= wr_data[15: 8];
                if (wr_be[3]) magic[31:24] <= wr_data[ 7: 0];
                end
                6'h01: begin  // dstmac_low
                if (wr_be[0]) dstmac[ 7: 0] <= wr_data[31:24];
                if (wr_be[1]) dstmac[15: 8] <= wr_data[23:16];
                if (wr_be[2]) dstmac[23:16] <= wr_data[15: 8];
                if (wr_be[3]) dstmac[31:24] <= wr_data[ 7: 0];
                end
                6'h02: begin  // dstmac_high
                if (wr_be[0]) dstmac[39:32] <= wr_data[31:24];
                if (wr_be[1]) dstmac[47:40] <= wr_data[23:16];
                end
                6'h03: begin  // srcmac_low
                if (wr_be[0]) srcmac[ 7: 0] <= wr_data[31:24];
                if (wr_be[1]) srcmac[15: 8] <= wr_data[23:16];
                if (wr_be[2]) srcmac[23:16] <= wr_data[15: 8];
                if (wr_be[3]) srcmac[31:24] <= wr_data[ 7: 0];
                end
                6'h04: begin  // srcmac_high
                if (wr_be[0]) srcmac[39:32] <= wr_data[31:24];
                if (wr_be[1]) srcmac[47:40] <= wr_data[23:16];
                end
                6'h05: begin  // dstip
                if (wr_be[0]) dstip[ 7: 0] <= wr_data[31:24];
                if (wr_be[1]) dstip[15: 8] <= wr_data[23:16];
                if (wr_be[2]) dstip[23:16] <= wr_data[15: 8];
                if (wr_be[3]) dstip[31:24] <= wr_data[ 7: 0];
                end
                6'h06: begin  // srcip
                if (wr_be[0]) srcip[ 7: 0] <= wr_data[31:24];
                if (wr_be[1]) srcip[15: 8] <= wr_data[23:16];
                if (wr_be[2]) srcip[23:16] <= wr_data[15: 8];
                if (wr_be[3]) srcip[31:24] <= wr_data[ 7: 0];
                end
                6'h07: begin  // dstport
                if (wr_be[0]) dstport[ 7: 0] <= wr_data[31:24];
                if (wr_be[1]) dstport[15: 8] <= wr_data[23:16];
                end
                6'h08: begin  // srcport
                if (wr_be[0]) srcport[ 7: 0] <= wr_data[31:24];
                if (wr_be[1]) srcport[15: 8] <= wr_data[23:16];
                end
                endcase
    		end
    		endcase
        end else begin  // read
            case (rd_addr[13:12])
            2'b01: begin
                case (rd_addr[5:0])
                6'h00: read_data_bar0 <= { magic[7:0], magic[15:8], magic[23:16], magic[31:24] };
                6'h01: read_data_bar0 <= { dstmac[7:0], dstmac[15:8], dstmac[23:16], dstmac[31:24] };
                6'h02: read_data_bar0 <= { dstmac[39:32], dstmac[47:40], 8'h0, 8'h0 };
                6'h03: read_data_bar0 <= { srcmac[7:0], srcmac[15:8], srcmac[23:16], srcmac[31:24] };
                6'h04: read_data_bar0 <= { srcmac[39:32], srcmac[47:40], 8'h0, 8'h0 };
                6'h05: read_data_bar0 <= { dstip[7:0], dstip[15:8], dstip[23:16], dstip[31:24] };
                6'h06: read_data_bar0 <= { srcip[7:0], srcip[15:8], srcip[23:16], srcip[31:24] };
                6'h07: read_data_bar0 <= { dstport[7:0], dstport[15:8], 8'h0, 8'h0 };
                6'h08: read_data_bar0 <= { srcport[7:0], srcport[15:8], 8'h0, 8'h0 };
                default:
                    read_data_bar0 <= 32'h0;
                endcase
            end
            default: begin
                read_data_bar0 <= 32'b0;
            end
            endcase
        end
    end
end

reg [31:0] read_data_bar2;

// BAR2
always @* begin
   	bram_bar2_we0 <= 1'b0;
	bram_bar2_we1 <= 1'b0;
	bram_bar2_we2 <= 1'b0;
	bram_bar2_we3 <= 1'b0;

	if (wr_en == 1'b1) begin  // write
		bram_bar2_addr0 <= wr_addr[7:0];
		bram_bar2_addr1 <= wr_addr[7:0];
		bram_bar2_addr2 <= wr_addr[7:0];
		bram_bar2_addr3 <= wr_addr[7:0];

		bram_bar2_din0 <= wr_data[31:24];
		bram_bar2_din1 <= wr_data[23:16];
		bram_bar2_din2 <= wr_data[15: 8];
		bram_bar2_din3 <= wr_data[ 7: 0];

		case (wr_addr[13:12])
		2'b10: begin
			if (wr_be[0]) bram_bar2_we0 <= 1'b1;
			if (wr_be[1]) bram_bar2_we1 <= 1'b1;
			if (wr_be[2]) bram_bar2_we2 <= 1'b1;
			if (wr_be[3]) bram_bar2_we3 <= 1'b1;
		end
		endcase
	end else begin  // read
		bram_bar2_addr0 <= rd_addr[7:0];
		bram_bar2_addr1 <= rd_addr[7:0];
		bram_bar2_addr2 <= rd_addr[7:0];
		bram_bar2_addr3 <= rd_addr[7:0];
		
		case (rd_addr[13:12])
		2'b10: begin
			read_data_bar2 <= { bram_bar2_dout0, bram_bar2_dout1, bram_bar2_dout2, bram_bar2_dout3 };
		end
		default: begin
			read_data_bar2 <= 32'b0;
		end
		endcase
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

