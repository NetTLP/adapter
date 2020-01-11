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
	output FIFO_PCIECFG_T fifo_pciecfg_o_din
);


enum logic [1:0] {
	IDLE,
	OPC_READ,
	OPC_WRITE,
	SEND
} state = IDLE;

FIFO_PCIECFG_T cfg_data;

always_ff @(posedge clk) begin
	if (rst) begin
		state <= IDLE;

		cfg_data <= '{default: '0};
	end else begin
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
				state <= SEND;
				// TODO
			end
			OPC_WRITE: begin
				state <= IDLE;
				// TODO
			end
			SEND: begin
				if (!fifo_pciecfg_o_full) begin
					state <= IDLE;

					fifo_pciecfg_o_wr_en <= 1'b1;
					fifo_pciecfg_o_din <= cfg_data;
				end
			end
			default: begin
				state <= IDLE;
			end
		endcase
	end
end

endmodule

