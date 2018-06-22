module clk_sync (
	input wire fastclk,
	input wire i,

	input wire slowclk,
	output logic o
);

logic buf0, buf1, buf2, buf3;

always_ff @(posedge fastclk)
	buf0 <= i;

always_ff @(posedge slowclk) begin
	buf1 <= buf0;
	buf2 <= buf1;
	buf3 <= buf2;
end

always_comb o = buf2 & buf3;

endmodule

