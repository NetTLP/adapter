module axi_10g_ethernet_0
	import utils_pkg::*;
	import endian_pkg::*;
(
	input  logic         tx_axis_aresetn,
	input  logic         rx_axis_aresetn,
	input  logic   [7:0] tx_ifg_delay,
	input  logic         dclk,
	output logic         txp,
	output logic         txn,
	input  logic         rxp,
	input  logic         rxn,
	input  logic         signal_detect,
	input  logic         tx_fault,
	output logic         tx_disable,
	output logic   [7:0] pcspma_status,
	input  logic         sim_speedup_control,
	output logic         rxrecclk_out,
	input  logic  [79:0] mac_tx_configuration_vector,
	input  logic  [79:0] mac_rx_configuration_vector,
	output logic   [2:0] mac_status_vector,
	input  logic [535:0] pcs_pma_configuration_vector,
	output logic [447:0] pcs_pma_status_vector,
	output logic         areset_datapathclk_out,
	output logic         txusrclk_out,
	output logic         txusrclk2_out,
	output logic         gttxreset_out,
	output logic         gtrxreset_out,
	output logic         txuserrdy_out,
	output logic         coreclk_out,
	output logic         resetdone_out,
	output logic         reset_counter_done_out,
	output logic         qplllock_out,
	output logic         qplloutclk_out,
	output logic         qplloutrefclk_out,
	input  logic         refclk_p,
	input  logic         refclk_n,
	input  logic         reset,
	input  logic  [63:0] s_axis_tx_tdata,
	input  logic   [7:0] s_axis_tx_tkeep,
	input  logic         s_axis_tx_tlast,
	output logic         s_axis_tx_tready,
	input  logic   [0:0] s_axis_tx_tuser,
	input  logic         s_axis_tx_tvalid,
	input  logic  [15:0] s_axis_pause_tdata,
	input  logic         s_axis_pause_tvalid,
	output logic  [63:0] m_axis_rx_tdata,
	output logic   [7:0] m_axis_rx_tkeep,
	output logic         m_axis_rx_tlast,
	output logic         m_axis_rx_tuser,
	output logic         m_axis_rx_tvalid,
	output logic         tx_statistics_valid,
	output logic  [25:0] tx_statistics_vector,
	output logic         rx_statistics_valid,
	output logic  [29:0] rx_statistics_vector
);

// refclk_p
always_comb coreclk_out = refclk_p;

// s_axis_tx_tready
logic [1:0] shift_tready;
always_ff @(posedge refclk_p) begin
	if (reset) begin
		s_axis_tx_tready <= 1'b0;
		shift_tready <= 2'b0;
	end else begin
		s_axis_tx_tready <= 1'b1;

		if (s_axis_tx_tlast == 1 || shift_tready != 0) begin
			s_axis_tx_tready <= 1'b0;
			shift_tready <= shift_tready + 1;
		end
	end
end

// coreclk_out
// reset
// m_axis_rx_tvalid
// m_axis_rx_tdata
// m_axis_rx_tkeep
// m_axis_rx_tlast
// m_axis_rx_tuser
device_eth device_eth0 (
	.eth_clk(coreclk_out),
	.sys_rst(reset),

	.eth_rx_tvalid(m_axis_rx_tvalid),
	.eth_rx_tdata(m_axis_rx_tdata),
	.eth_rx_tkeep(m_axis_rx_tkeep),
	.eth_rx_tlast(m_axis_rx_tlast),
	.eth_rx_tuser(m_axis_rx_tuser)
);

// input
wire _unused_ok = &{
	dclk,
	refclk_n,
	rx_axis_aresetn,
	rxn,
	rxp,
	s_axis_pause_tvalid,
	s_axis_tx_tlast,
	s_axis_tx_tvalid,
	signal_detect,
	sim_speedup_control,
	tx_axis_aresetn,
	tx_fault,
	s_axis_tx_tuser,
	s_axis_tx_tkeep,
	tx_ifg_delay,
	s_axis_pause_tdata,
	s_axis_tx_tdata,
	mac_rx_configuration_vector,
	mac_tx_configuration_vector,
	pcs_pma_configuration_vector,
	1'b0
};

// output
always_comb areset_datapathclk_out = 'b0;
always_comb gtrxreset_out = 'b0;
always_comb gttxreset_out = 'b0;
always_comb qplllock_out = 'b0;
always_comb qplloutclk_out = 'b0;
always_comb qplloutrefclk_out = 'b0;
always_comb reset_counter_done_out = 'b0;
always_comb resetdone_out = 'b0;
always_comb rx_statistics_valid = 'b0;
always_comb rxrecclk_out = 'b0;
always_comb tx_disable = 'b0;
always_comb tx_statistics_valid = 'b0;
always_comb txn = 'b0;
always_comb txp = 'b0;
always_comb txuserrdy_out = 'b0;
always_comb txusrclk2_out = 'b0;
always_comb txusrclk_out = 'b0;
always_comb mac_status_vector = 'b0;
always_comb pcspma_status = 'b0;
always_comb tx_statistics_vector = 'b0;
always_comb rx_statistics_vector = 'b0;
always_comb pcs_pma_status_vector = 'b0;

endmodule

