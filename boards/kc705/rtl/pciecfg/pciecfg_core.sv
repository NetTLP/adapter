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
	OPC_READ,
	OPC_WRITE,
	SEND,
	END
} state = IDLE;

FIFO_PCIECFG_T cfg_data;

always_ff @(posedge clk) begin
	if (rst) begin
		state <= IDLE;

		fifo_pciecfg_i_rd_en <= 1'b0;
		fifo_pciecfg_o_wr_en <= 1'b0;

		cfg_data <= '{default: 0};

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
				if (fifo_pciecfg_i_dout.opcode == PCIECFG_OPC_RD) begin
					state <= OPC_READ;
				end else if (fifo_pciecfg_i_dout.opcode == PCIECFG_OPC_WR) begin
					state <= OPC_WRITE;
				end else begin
					state <= IDLE;
				end

				fifo_pciecfg_i_rd_en <= 1'b1;

				cfg_data <= fifo_pciecfg_i_dout;
			end
		end
		OPC_READ: begin
			cfg_mgmt_rd_en <= 1'b1;
			cfg_mgmt_dwaddr <= cfg_data.dwaddr;
			cfg_data.data <= cfg_mgmt_do;

			if (cfg_mgmt_rd_wr_done) begin
				cfg_mgmt_rd_en <= 1'b0;
				state <= SEND;
			end
		end
		OPC_WRITE: begin
			cfg_mgmt_wr_en <= 1'b1;
			cfg_mgmt_dwaddr <= cfg_data.dwaddr;
			cfg_mgmt_byte_en <= cfg_data.byte_mask;
			cfg_mgmt_di <= cfg_data.data;

			if (cfg_mgmt_rd_wr_done) begin
				cfg_mgmt_wr_en <= 1'b0;
				state <= END;
			end
		end
		SEND: begin
			state <= IDLE;

			if (!fifo_pciecfg_o_full) begin
				fifo_pciecfg_o_wr_en <= 1'b1;
				fifo_pciecfg_o_din <= cfg_data;
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

//`ifdef zero
ila_0 ila_00 (
	.clk(clk),
	.probe0(fifo_pciecfg_i_rd_en),
	.probe1(fifo_pciecfg_i_empty),
	.probe2(fifo_pciecfg_o_wr_en),
	.probe3(fifo_pciecfg_o_full),
	.probe4(state),  // 2
	.probe5(cfg_mgmt_dwaddr),  // 10
	.probe6(cfg_mgmt_rd_en),
	.probe7(cfg_mgmt_do),  // 32
	.probe8(cfg_mgmt_wr_en),
	.probe9(cfg_mgmt_byte_en),  // 4
	.probe10(cfg_mgmt_di),  // 32
	.probe11(cfg_mgmt_rd_wr_done)
);
//`endif

endmodule

