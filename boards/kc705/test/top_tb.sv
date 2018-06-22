`default_nettype none
`timescale 1ns / 1ps

`ifndef verilator_sim
program sys_test (
	input wire clk100
);
	initial begin
		@(posedge clk100);
		#10000000;

		$finish;
	end
endprogram

program pcie_test (
	input wire pcie_clk,
	output logic sys_rst200,
	output logic pio_rd_req,
	input  wire pio_rd_ack
);
	initial begin
		sys_rst200 = '1;
		#10;
		sys_rst200 = '0;
	end

	initial begin
		@(negedge sys_rst200);

		$display("test: pio_rd_req");
		@(posedge pcie_clk);
		pio_rd_req = '1;
		@(posedge pcie_clk);
		pio_rd_req = '0;
		@(posedge pio_rd_ack);
		$display("test: pio_rd_ack");
		#10;

		$display("test: pio_rd_req");
		@(posedge pcie_clk);
		pio_rd_req = '1;
		@(posedge pcie_clk);
		pio_rd_req = '0;
		@(posedge pio_rd_ack);
		$display("test: pio_rd_ack");
		#10;
	end
endprogram


program eth_test (
	input wire clk156,
	output logic sys_rst156
//	output logic eth_rx_req,
//	input  wire eth_rx_ack
);
	initial begin
		sys_rst156 = '1;
		#12;
		sys_rst156 = '0;
	end

/*
	initial begin
		@(negedge sys_rst156);

		$display("test: eth_rx_req");
		@(posedge clk156);
		eth_rx_req = '1;
		@(posedge clk156);
		eth_rx_req = '0;
		@(posedge eth_rx_ack);
		$display("test: eth_rx_ack");
		#10;

		$display("test: eth_rx_req");
		@(posedge clk156);
		eth_rx_req = '1;
		@(posedge clk156);
		eth_rx_req = '0;
		@(posedge eth_rx_ack);
		$display("test: eth_rx_ack");
		#10;
	end
*/

endprogram
`endif
  

module top_tb;

	localparam C_DATA_WIDTH = 64;
	localparam KEEP_WIDTH = C_DATA_WIDTH / 8;
	localparam  LINK_WIDTH = C_DATA_WIDTH / 16;

	localparam SYSCLK_FREQ = 100e6;
	localparam SYSCLK_HALF_PERIOD = 1/real'(SYSCLK_FREQ)*1000e6/2;

	localparam CLK200_FREQ = 200e6;
	localparam CLK200_HALF_PERIOD = 1/real'(CLK200_FREQ)*1000e6/2;

	localparam SFPCLK_FREQ = 15625e4;
	localparam SFPCLK_HALF_PERIOD = 1/real'(SFPCLK_FREQ)*1000e6/2;

	logic clk200_p, clk200_n;
	logic sys_clk_p, sys_clk_n;
	logic SFP_CLK_P, SFP_CLK_N;

`ifndef verilator_sim
	always begin
		#SYSCLK_HALF_PERIOD sys_clk_p = 0;
		#SYSCLK_HALF_PERIOD sys_clk_p = 1;
	end
	always begin
		#SYSCLK_HALF_PERIOD sys_clk_n = 1;
		#SYSCLK_HALF_PERIOD sys_clk_n = 0;
	end

	always begin
		#CLK200_HALF_PERIOD clk200_p = 0;
		#CLK200_HALF_PERIOD clk200_p = 1;
	end
	always begin
		#CLK200_HALF_PERIOD clk200_n = 1;
		#CLK200_HALF_PERIOD clk200_n = 0;
	end

	always begin
		#SFPCLK_HALF_PERIOD SFP_CLK_P = 0;
		#SFPCLK_HALF_PERIOD SFP_CLK_P = 1;
	end
	always begin
		#SFPCLK_HALF_PERIOD SFP_CLK_N = 1;
		#SFPCLK_HALF_PERIOD SFP_CLK_N = 0;
	end
`endif

	// sys_rst_n
	logic sys_rst_n;
	logic [13:0] cold_counter = 8'd0;
	always @(posedge sys_clk_p) begin
		if (cold_counter != 8'd5) begin
			cold_counter <= cold_counter + 8'd1;
			sys_rst_n <= 1'b0;
		end else begin
			sys_rst_n <= 1'b1;
		end
	end

	wire [LINK_WIDTH-1:0] pci_exp_txp;
	wire [LINK_WIDTH-1:0] pci_exp_txn;
	wire [LINK_WIDTH-1:0] pci_exp_rxp;
	wire [LINK_WIDTH-1:0] pci_exp_rxn;

	wire I2C_FPGA_SCL;
	wire I2C_FPGA_SDA;
	wire I2C_FPGA_RST_N;
	wire SI5324_RST_N;

	wire ETH0_TX_P = 0;
	wire ETH0_TX_N = 0;
	wire ETH0_RX_P;
	wire ETH0_RX_N;
	wire ETH0_TX_DISABLE;

	wire button_n = 0;
	wire button_s = 0;
	wire button_w = 0;
	wire button_e = 0;
	wire button_c = 0;

	wire [3:0] dipsw = 0;
	wire [7:0] led;

	top #(.COLD_RESET_INTVAL(14'h10)) top0 (.*);

endmodule

`default_nettype wire

