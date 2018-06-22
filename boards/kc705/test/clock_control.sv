module clock_control (
	inout  logic i2c_clk,
	inout  logic i2c_data,
	output logic i2c_mux_rst_n,
	output logic si5324_rst_n,
	input  logic rst,
	input  logic clk50
);
endmodule
