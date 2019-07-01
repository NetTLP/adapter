module mybram #(
	parameter WIDTH=8,
	parameter DEPTH=8
) (
	input wire clk,
	input wire we,
	input wire [DEPTH-1:0] addr,
	input wire [WIDTH-1:0] din,
	output reg [WIDTH-1:0] dout
);


(* ram_style = "block" *) reg [WIDTH-1:0] mem [(1<<DEPTH)-1:0];

always @(posedge clk) begin
	if (we)
		mem[addr] <= din;
	dout <= mem[addr];
end

endmodule

