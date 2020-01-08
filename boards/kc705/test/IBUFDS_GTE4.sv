module IBUFDS_GTE4 (
	input  logic I,
	input  logic IB,
	input  logic CEB,
	output logic O,
	output logic ODIV2
);

always_comb  O = I;

always_comb ODIV2 = I;  // ouch

wire _unused_ok = &{
	1'b0,
	IB,
	CEB,
	1'b0
};

endmodule

