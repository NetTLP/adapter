module ila_1 (
	input wire clk,
	input wire sys_reset,
	input wire probe0,
	input wire probe1,
	input wire [2:0] probe2,
	input wire [27:0] probe3,
	input wire probe4,
	input wire probe5,
	input wire probe6,
	input wire probe7
);

wire _unused_ok = &{
	1'b0,
	clk,
	sys_reset,
	probe0,
	probe1,
	probe2,
	probe3,
	probe4,
	probe5,
	probe6,
	probe7,
	1'b0
};

endmodule

