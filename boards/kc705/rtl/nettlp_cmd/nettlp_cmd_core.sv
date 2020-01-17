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
	output FIFO_NETTLP_CMD_T fifo_cmd_o_din,

	// adapter registers
	output logic [31:0] adapter_reg_magic,
	output logic [47:0] adapter_reg_dstmac,
	output logic [47:0] adapter_reg_srcmac,
	output logic [31:0] adapter_reg_dstip,
	output logic [31:0] adapter_reg_srcip,
	output logic [15:0] adapter_reg_dstport,
	output logic [15:0] adapter_reg_srcport
);

enum logic [2:0] {
	IDLE,
	MODE_SELECT,
	OPC_READ,
	OPC_WRITE,
	SEND,
	BUBBLE,
	END
} state = IDLE;

FIFO_NETTLP_CMD_T cmd_data;
FIFO_NETTLP_CMD_T cmd_data_bubble;
logic [2:0] bubble_count;

always_ff @(posedge clk) begin
	if (rst) begin
		state <= IDLE;

		fifo_cmd_i_rd_en <= 1'b0;
		fifo_cmd_o_wr_en <= 1'b0;

		cmd_data <= '{default: 0};
		cmd_data_bubble <= '{default: 0};
		bubble_count <= 3'h0;

		adapter_reg_magic <= 32'h01_23_45_67;
		adapter_reg_dstmac <= 48'hFF_FF_FF_FF_FF_FF;
		adapter_reg_srcmac <= 48'h00_11_22_33_44_55;
		adapter_reg_dstip <= {8'd192, 8'd168, 8'd10, 8'd3};
		adapter_reg_srcip <= {8'd192, 8'd168, 8'd10, 8'd1};
		adapter_reg_dstport <= 16'h3776;
		adapter_reg_srcport <= 16'h3776;
	end else begin
		fifo_cmd_i_rd_en <= 1'b0;
		fifo_cmd_o_wr_en <= 1'b0;

		case (state)
		IDLE: begin
			if (!fifo_cmd_i_empty) begin
				if (fifo_cmd_i_dout.data_valid) begin
					state <= MODE_SELECT;
				end else begin
					fifo_cmd_i_rd_en <= 1'b1;
				end
			end
		end
		MODE_SELECT: begin
			if (!fifo_cmd_i_empty) begin
				if (fifo_cmd_i_dout.pkt.opcode == NETTLP_OPC_REG_RD) begin
					state <= OPC_READ;
				end else if (fifo_cmd_i_dout.pkt.opcode == NETTLP_OPC_REG_WR) begin
					state <= OPC_WRITE;
				end

				fifo_cmd_i_rd_en <= 1'b1;

				cmd_data <= fifo_cmd_i_dout;

				bubble_count <= 3'h0;
			end
		end
		OPC_READ: begin
			state <= SEND;

			cmd_data.pkt.udp_check <= 16'h0;

			case (cmd_data.pkt.dwaddr)
				ADAPTER_REG_MAGIC: begin
					cmd_data.pkt.data <= {
						adapter_reg_magic[ 7: 0],
						adapter_reg_magic[15: 8],
						adapter_reg_magic[23:16], 
						adapter_reg_magic[31:24]
					};
				end
				ADAPTER_REG_DSTMAC_LOW: begin
					cmd_data.pkt.data <= {
						adapter_reg_dstmac[ 7: 0],
						adapter_reg_dstmac[15: 8],
						adapter_reg_dstmac[23:16],
						adapter_reg_dstmac[31:24]
					};
				end
				ADAPTER_REG_DSTMAC_HIGH: begin
					cmd_data.pkt.data <= {
						adapter_reg_dstmac[39:32],
						adapter_reg_dstmac[47:40],
						8'h0,
						8'h0
					};
				end
				ADAPTER_REG_SRCMAC_LOW: begin
					cmd_data.pkt.data <= {
						adapter_reg_srcmac[ 7: 0],
						adapter_reg_srcmac[15: 8],
						adapter_reg_srcmac[23:16],
						adapter_reg_srcmac[31:24]
					};
				end
				ADAPTER_REG_SRCMAC_HIGH: begin
					cmd_data.pkt.data <= {
						adapter_reg_srcmac[39:32],
						adapter_reg_srcmac[47:40],
						8'h0,
						8'h0
					};
				end
				ADAPTER_REG_DSTIP: begin
					cmd_data.pkt.data <= {
						adapter_reg_dstip[ 7: 0],
						adapter_reg_dstip[15: 8],
						adapter_reg_dstip[23:16],
						adapter_reg_dstip[31:24]
					};
				end
				ADAPTER_REG_SRCIP: begin
					cmd_data.pkt.data <= {
						adapter_reg_srcip[ 7: 0],
					       	adapter_reg_srcip[15: 8],
						adapter_reg_srcip[23:16],
						adapter_reg_srcip[31:24]
					};
				end
				ADAPTER_REG_DSTPORT: begin
					cmd_data.pkt.data <= {
						adapter_reg_dstport[ 7: 0],
						adapter_reg_dstport[15: 8],
						8'h0,
						8'h0
					};
				end
				ADAPTER_REG_SRCPORT: begin
					cmd_data.pkt.data <= {
						adapter_reg_srcport[ 7: 0],
						adapter_reg_srcport[15: 8],
						8'h0,
						8'h0
					};
				end
				ADAPTER_REG_REQUESTER_ID: begin
					cmd_data.pkt.data <= {
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
			state <= END;

			case (cmd_data.pkt.dwaddr)
				// read only
				ADAPTER_REG_MAGIC: begin
					adapter_reg_magic[ 7: 0] <= adapter_reg_magic[ 7: 0];
					adapter_reg_magic[15: 8] <= adapter_reg_magic[15: 8];
					adapter_reg_magic[23:16] <= adapter_reg_magic[23:16];
					adapter_reg_magic[31:24] <= adapter_reg_magic[31:24];
				end
				ADAPTER_REG_DSTMAC_LOW: begin
					adapter_reg_dstmac[ 7: 0] <= cmd_data.pkt.data[31:24];
					adapter_reg_dstmac[15: 8] <= cmd_data.pkt.data[23:16];
					adapter_reg_dstmac[23:16] <= cmd_data.pkt.data[15: 8];
					adapter_reg_dstmac[31:24] <= cmd_data.pkt.data[ 7: 0];
				end
				ADAPTER_REG_DSTMAC_HIGH: begin
					adapter_reg_dstmac[39:32] <= cmd_data.pkt.data[31:24];
					adapter_reg_dstmac[47:40] <= cmd_data.pkt.data[23:16];
				end
				ADAPTER_REG_SRCMAC_LOW: begin
					adapter_reg_srcmac[ 7: 0] <= cmd_data.pkt.data[31:24];
					adapter_reg_srcmac[15: 8] <= cmd_data.pkt.data[23:16];
					adapter_reg_srcmac[23:16] <= cmd_data.pkt.data[15: 8];
					adapter_reg_srcmac[31:24] <= cmd_data.pkt.data[ 7: 0];
				end
				ADAPTER_REG_SRCMAC_HIGH: begin
					adapter_reg_srcmac[39:32] <= cmd_data.pkt.data[31:24];
					adapter_reg_srcmac[47:40] <= cmd_data.pkt.data[23:16];
				end
				ADAPTER_REG_DSTIP: begin
					adapter_reg_dstip[ 7: 0] <= cmd_data.pkt.data[31:24];
					adapter_reg_dstip[15: 8] <= cmd_data.pkt.data[23:16];
					adapter_reg_dstip[23:16] <= cmd_data.pkt.data[15: 8];
					adapter_reg_dstip[31:24] <= cmd_data.pkt.data[ 7: 0];
				end
				ADAPTER_REG_SRCIP: begin
					adapter_reg_srcip[ 7: 0] <= cmd_data.pkt.data[31:24];
					adapter_reg_srcip[15: 8] <= cmd_data.pkt.data[23:16];
					adapter_reg_srcip[23:16] <= cmd_data.pkt.data[15: 8];
					adapter_reg_srcip[31:24] <= cmd_data.pkt.data[ 7: 0];
				end
				ADAPTER_REG_DSTPORT: begin
					adapter_reg_dstport[ 7: 0] <= cmd_data.pkt.data[31:24];
					adapter_reg_dstport[15: 8] <= cmd_data.pkt.data[23:16];
				end
				ADAPTER_REG_SRCPORT: begin
					adapter_reg_srcport[ 7: 0] <= cmd_data.pkt.data[31:24];
					adapter_reg_srcport[15: 8] <= cmd_data.pkt.data[23:16];
				end
				default: begin
					state <= IDLE;
				end
			endcase
		end
		SEND: begin
			if (!fifo_cmd_o_full) begin
				state <= BUBBLE;

				fifo_cmd_o_wr_en <= 1'b1;
				fifo_cmd_o_din <= cmd_data;
			end
		end
		BUBBLE: begin
			if (!fifo_cmd_o_full) begin
				if (bubble_count[2] == 1'b1) begin
					state <= IDLE;
				end

				bubble_count <= bubble_count + 3'd1;

				fifo_cmd_o_wr_en <= 1'b1;
				fifo_cmd_o_din <= cmd_data_bubble;
			end
		end
		END: begin
			state <= IDLE;
		end
		default: begin
			state <= IDLE;
		end
		endcase
	end
end

endmodule

