module IBUFDS_GTE2 (
	input  logic I,
	input  logic IB,
	input  logic CEB,
	output logic O,
	output logic ODIV2
);

always_comb O = I;

always_ff @(posedge I) begin
	ODIV2 <= ~I;
end

wire _unused_ok = &{
	IB,
	CEB,
	1'b0
};

endmodule

