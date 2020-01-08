module IBUFDS (
	input  logic I,
	input  logic IB,
	output logic O
);

assign O = I & ~IB; 

endmodule

