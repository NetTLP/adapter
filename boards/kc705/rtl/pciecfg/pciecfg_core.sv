module pciecfg_core
	import pciecfg_pkg::*;
(
	input wire clk,
	input wire rst,

	// data input
	output logic fifo_pciecfg_i_rd_en,
	input wire fifo_pciecfg_i_empty,
	input FIFO_PCIECFG_T fifo_pciecfg_i_dout,

	// data output
	output logic fifo_pciecfg_o_wr_en,
	input wire fifo_pciecfg_o_full,
	output FIFO_PCIECFG_T fifo_pciecfg_o_din,

	// pcie configration interface
	output logic [9:0]  cfg_mgmt_dwaddr,
	output logic        cfg_mgmt_rd_en,
	input wire [31:0]   cfg_mgmt_do,
	output logic        cfg_mgmt_wr_en,
	output logic [3:0]  cfg_mgmt_byte_en,
	output logic [31:0] cfg_mgmt_di,
	input wire          cfg_mgmt_rd_wr_done
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

FIFO_PCIECFG_T cfg_data;
FIFO_PCIECFG_T cfg_data_bubble;
logic [2:0] bubble_count;

always_ff @(posedge clk) begin
	if (rst) begin
		state <= IDLE;

		fifo_pciecfg_i_rd_en <= 1'b0;
		fifo_pciecfg_o_wr_en <= 1'b0;

		cfg_data <= '{default: 0};
		cfg_data_bubble <= '{default: 0};
		bubble_count <= 3'h0;

		cfg_mgmt_rd_en <= 1'b0;
		cfg_mgmt_wr_en <= 1'b0;
		cfg_mgmt_dwaddr <= 10'b0;
		cfg_mgmt_byte_en <= 4'b0;
		cfg_mgmt_di <= 32'b0;
	end else begin
		fifo_pciecfg_i_rd_en <= 1'b0;
		fifo_pciecfg_o_wr_en <= 1'b0;

		cfg_mgmt_rd_en <= 1'b0;
		cfg_mgmt_wr_en <= 1'b0;
		cfg_mgmt_byte_en <= 4'b0;

		case (state)
		IDLE: begin
			if (!fifo_pciecfg_i_empty) begin
				if (fifo_pciecfg_i_dout.data_valid) begin
					state <= MODE_SELECT;
				end else begin
					fifo_pciecfg_i_rd_en <= 1'b1;
				end
			end
		end
		MODE_SELECT: begin
			if (!fifo_pciecfg_i_empty) begin
				if (fifo_pciecfg_i_dout.pkt.opcode == PCIECFG_OPC_RD) begin
					state <= OPC_READ;
				end else if (fifo_pciecfg_i_dout.pkt.opcode == PCIECFG_OPC_WR) begin
					state <= OPC_WRITE;
				end

				fifo_pciecfg_i_rd_en <= 1'b1;

				cfg_data <= fifo_pciecfg_i_dout;

				bubble_count <= 3'h0;
			end
		end
		OPC_READ: begin
			cfg_mgmt_rd_en <= 1'b1;
			cfg_mgmt_dwaddr <= cfg_data.pkt.dwaddr;
			cfg_data.pkt.data <= cfg_mgmt_do;
			cfg_data.pkt.udp_check <= 16'h0;

			if (cfg_mgmt_rd_wr_done) begin
				cfg_mgmt_rd_en <= 1'b0;
				state <= SEND;
			end
		end
		OPC_WRITE: begin
			cfg_mgmt_wr_en <= 1'b1;
			cfg_mgmt_dwaddr <= cfg_data.pkt.dwaddr;
			cfg_mgmt_byte_en <= cfg_data.pkt.byte_mask;
			cfg_mgmt_di <= cfg_data.pkt.data;

			if (cfg_mgmt_rd_wr_done) begin
				cfg_mgmt_wr_en <= 1'b0;
				state <= END;
			end
		end
		SEND: begin
			if (!fifo_pciecfg_o_full) begin
				state <= BUBBLE;

				fifo_pciecfg_o_wr_en <= 1'b1;
				fifo_pciecfg_o_din <= cfg_data;
			end
		end
		BUBBLE: begin
			if (!fifo_pciecfg_o_full) begin
				if (bubble_count[2] == 1'b1) begin
					state <= IDLE;
				end

				bubble_count <= bubble_count + 3'd1;

				fifo_pciecfg_o_wr_en <= 1'b1;
				fifo_pciecfg_o_din <= cfg_data_bubble;
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

