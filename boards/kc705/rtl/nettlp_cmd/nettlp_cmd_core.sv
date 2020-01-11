module nettlp_cmd_core
	import nettlp_cmd_pkg::*;
(
	
	input wire clk,
	input wire rst,

	// data input
	output logic fifo_cmd_i_rd_en,
	input wire fifo_cmd_i_empty,
	input FIFO_NETTLP_CMD_T fifo_cmd_i_dout,

	// data output
	output logic fifo_cmd_o_wr_en,
	input wire fifo_cmd_o_full,
	output FIFO_NETTLP_CMD_T fifo_cmd_o_din
);

// adapter registers
logic [31:0] adapter_reg_magic;
logic [47:0] adapter_reg_dstmac;
logic [47:0] adapter_reg_srcmac;
logic [31:0] adapter_reg_dstip;
logic [31:0] adapter_reg_srcip;
logic [15:0] adapter_reg_dstport;
logic [15:0] adapter_reg_srcport;

enum logic [1:0] {
	IDLE,
	OPC_READ,
	OPC_WRITE,
	SEND
} state = IDLE;

FIFO_NETTLP_CMD_T cmd_data;

always_ff @(posedge clk) begin
	if (rst) begin
		state <= IDLE;

		cmd_data <= '{default: 0};

		adapter_reg_magic <= 32'h01_23_45_67;
		adapter_reg_dstmac <= 48'hFF_FF_FF_FF_FF_FF;
		adapter_reg_srcmac <= 48'h00_11_22_33_44_55;
		adapter_reg_dstip <= {8'd192, 8'd168, 8'd10, 8'd3};
		adapter_reg_srcip <= {8'd192, 8'd168, 8'd10, 8'd1};
		adapter_reg_dstport <= 16'h3776;
		adapter_reg_srcport <= 16'h3776;
	end else begin
		case (state)
		IDLE: begin
			if (!fifo_cmd_i_empty) begin
				if (fifo_cmd_i_dout.opcode == NETTLP_OPC_REG_RD) begin
					state <= OPC_READ;
				end else if (fifo_cmd_i_dout.opcode == NETTLP_OPC_REG_WR) begin
					state <= OPC_WRITE;
				end else begin
					state <= IDLE;
				end

				fifo_cmd_i_rd_en <= 1'b1;

				cmd_data <= fifo_cmd_i_dout;
			end
		end
		OPC_READ: begin
			state <= SEND;

			case (cmd_data.dwaddr)
				ADAPTER_REG_MAGIC: begin
					cmd_data.data <= {
						adapter_reg_magic[ 7: 0],
						adapter_reg_magic[15: 8],
						adapter_reg_magic[23:16], 
						adapter_reg_magic[31:24]
					};
				end
				ADAPTER_REG_DSTMAC_LOW: begin
					cmd_data.data <= {
						adapter_reg_dstmac[ 7: 0],
						adapter_reg_dstmac[15: 8],
						adapter_reg_dstmac[23:16],
						adapter_reg_dstmac[31:24]
					};
				end
				ADAPTER_REG_DSTMAC_HIGH: begin
					cmd_data.data <= {
						adapter_reg_dstmac[39:32],
						adapter_reg_dstmac[47:40],
						8'h0,
						8'h0
					};
				end
				ADAPTER_REG_SRCMAC_LOW: begin
					cmd_data.data <= {
						adapter_reg_srcmac[ 7: 0],
						adapter_reg_srcmac[15: 8],
						adapter_reg_srcmac[23:16],
						adapter_reg_srcmac[31:24]
					};
				end
				ADAPTER_REG_SRCMAC_HIGH: begin
					cmd_data.data <= {
						adapter_reg_srcmac[39:32],
						adapter_reg_srcmac[47:40],
						8'h0,
						8'h0
					};
				end
				ADAPTER_REG_DSTIP: begin
					cmd_data.data <= {
						adapter_reg_dstip[ 7: 0],
						adapter_reg_dstip[15: 8],
						adapter_reg_dstip[23:16],
						adapter_reg_dstip[31:24]
					};
				end
				ADAPTER_REG_SRCIP: begin
					cmd_data.data <= {
						adapter_reg_srcip[ 7: 0],
					       	adapter_reg_srcip[15: 8],
						adapter_reg_srcip[23:16],
						adapter_reg_srcip[31:24]
					};
				end
				ADAPTER_REG_DSTPORT: begin
					cmd_data.data <= {
						adapter_reg_dstport[ 7: 0],
						adapter_reg_dstport[15: 8],
						8'h0,
						8'h0
					};
				end
				ADAPTER_REG_SRCPORT: begin
					cmd_data.data <= {
						adapter_reg_srcport[ 7: 0],
						adapter_reg_srcport[15: 8],
						8'h0,
						8'h0
					};
				end
				ADAPTER_REG_REQUESTER_ID: begin
					cmd_data.data <= {
						adapter_reg_srcport[ 7: 0],
						adapter_reg_srcport[15: 8],
						8'h0,
						8'h0
					};
				end
				default: begin
					state <= IDLE;
				end
			endcase
		end
		OPC_WRITE: begin
			state <= IDLE;

			case (cmd_data.dwaddr)
				// read only
				ADAPTER_REG_MAGIC: begin
					adapter_reg_magic[ 7: 0] <= adapter_reg_magic[ 7: 0];
					adapter_reg_magic[15: 8] <= adapter_reg_magic[15: 8];
					adapter_reg_magic[23:16] <= adapter_reg_magic[23:16];
					adapter_reg_magic[31:24] <= adapter_reg_magic[31:24];
				end
				ADAPTER_REG_DSTMAC_LOW: begin
					adapter_reg_dstmac[ 7: 0] <= cmd_data.data[31:24];
					adapter_reg_dstmac[15: 8] <= cmd_data.data[23:16];
					adapter_reg_dstmac[23:16] <= cmd_data.data[15: 8];
					adapter_reg_dstmac[31:24] <= cmd_data.data[ 7: 0];
				end
				ADAPTER_REG_DSTMAC_HIGH: begin
					adapter_reg_dstmac[39:32] <= cmd_data.data[31:24];
					adapter_reg_dstmac[47:40] <= cmd_data.data[23:16];
				end
				ADAPTER_REG_SRCMAC_LOW: begin
					adapter_reg_srcmac[ 7: 0] <= cmd_data.data[31:24];
					adapter_reg_srcmac[15: 8] <= cmd_data.data[23:16];
					adapter_reg_srcmac[23:16] <= cmd_data.data[15: 8];
					adapter_reg_srcmac[31:24] <= cmd_data.data[ 7: 0];
				end
				ADAPTER_REG_SRCMAC_HIGH: begin
					adapter_reg_srcmac[39:32] <= cmd_data.data[31:24];
					adapter_reg_srcmac[47:40] <= cmd_data.data[23:16];
				end
				ADAPTER_REG_DSTIP: begin
					adapter_reg_dstip[ 7: 0] <= cmd_data.data[31:24];
					adapter_reg_dstip[15: 8] <= cmd_data.data[23:16];
					adapter_reg_dstip[23:16] <= cmd_data.data[15: 8];
					adapter_reg_dstip[31:24] <= cmd_data.data[ 7: 0];
				end
				ADAPTER_REG_SRCIP: begin
					adapter_reg_srcip[ 7: 0] <= cmd_data.data[31:24];
					adapter_reg_srcip[15: 8] <= cmd_data.data[23:16];
					adapter_reg_srcip[23:16] <= cmd_data.data[15: 8];
					adapter_reg_srcip[31:24] <= cmd_data.data[ 7: 0];
				end
				ADAPTER_REG_DSTPORT: begin
					adapter_reg_dstport[ 7: 0] <= cmd_data.data[31:24];
					adapter_reg_dstport[15: 8] <= cmd_data.data[23:16];
				end
				ADAPTER_REG_SRCPORT: begin
					adapter_reg_srcport[ 7: 0] <= cmd_data.data[31:24];
					adapter_reg_srcport[15: 8] <= cmd_data.data[23:16];
				end
				default: begin
					state <= IDLE;
				end
			endcase
		end
		SEND: begin
			if (!fifo_cmd_o_full) begin
				state <= IDLE;

				fifo_cmd_o_wr_en <= 1'b1;
				fifo_cmd_o_din <= cmd_data;
			end
		end
		default: begin
			state <= IDLE;
		end
		endcase
	end
end
endmodule

