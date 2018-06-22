module clk_sync_ashot (
	input wire slowclk,
	input wire i,

	input wire fastclk,
	output logic o
);

logic buf0, buf1, buf2, buf3;

always_ff @(posedge slowclk) begin
	buf0 <= i;
end

always_ff @(posedge fastclk) begin
	buf1 <= buf0;
	buf2 <= buf1;
	buf3 <= buf2;
end

always_comb o = buf3 & ~buf2;

endmodule

