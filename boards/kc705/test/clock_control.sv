module clock_control (
	inout  logic i2c_clk,
	inout  logic i2c_data,
	output logic i2c_mux_rst_n,
	output logic si5324_rst_n,
	input  logic rst,
	input  logic clk50
);

	// inout
	always_comb i2c_clk = 'b0;
	always_comb i2c_data = 'b0;

	// output
	always_comb i2c_mux_rst_n = 'b0;
	always_comb si5324_rst_n = 'b0;

	// input
	wire _unused_ok = &{
		clk50,
		rst,
		1'b0
	};

endmodule
