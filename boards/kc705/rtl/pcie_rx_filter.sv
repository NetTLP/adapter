`default_nettype none
`timescale 1ns/1ps

module pcie_rx_filter # (
	parameter C_DATA_WIDTH = 64,
	parameter KEEP_WIDTH = C_DATA_WIDTH / 8
)(
	// AXIS Input
	output logic                   m_axis_rx_tready,
	input  wire                    m_axis_rx_tvalid,
	input  wire                    m_axis_rx_tlast,
	input  wire [KEEP_WIDTH-1:0]   m_axis_rx_tkeep,
	input  wire [C_DATA_WIDTH-1:0] m_axis_rx_tdata,
	input  wire [21:0]             m_axis_rx_tuser,

	// AXIS output 1 (Hardware PIO engine)
	input  wire                     pcie_app_rx_tready,
	output logic                    pcie_app_rx_tvalid,
	output logic                    pcie_app_rx_tlast,
	output logic [KEEP_WIDTH-1:0]   pcie_app_rx_tkeep,
	output logic [C_DATA_WIDTH-1:0] pcie_app_rx_tdata,
	output logic [21:0]             pcie_app_rx_tuser,

	// AXIS output 2 (ethernet)
	output logic                    pcie_snoop_rx_tready,
	output logic                    pcie_snoop_rx_tvalid,
	output logic                    pcie_snoop_rx_tlast,
	output logic [KEEP_WIDTH-1:0]   pcie_snoop_rx_tkeep,
	output logic [C_DATA_WIDTH-1:0] pcie_snoop_rx_tdata,
	output logic [21:0]             pcie_snoop_rx_tuser
);

// tready 
always_comb m_axis_rx_tready = pcie_app_rx_tready;
always_comb pcie_snoop_rx_tready = pcie_app_rx_tready;

// others
wire [2:0] rx_bar_hit = {
		m_axis_rx_tuser[6],
		m_axis_rx_tuser[4],
		m_axis_rx_tuser[2] };
parameter [2:0] hit_bar0 = 3'b001;
parameter [2:0] hit_bar2 = 3'b010;
parameter [2:0] hit_bar4 = 3'b100;

always_comb begin
	pcie_app_rx_tvalid = m_axis_rx_tvalid;
	pcie_app_rx_tlast  = m_axis_rx_tlast;
	pcie_app_rx_tkeep  = m_axis_rx_tkeep;
	pcie_app_rx_tdata  = m_axis_rx_tdata;
	pcie_app_rx_tuser  = m_axis_rx_tuser;

	pcie_snoop_rx_tvalid = m_axis_rx_tvalid;
	pcie_snoop_rx_tlast  = m_axis_rx_tlast;
	pcie_snoop_rx_tkeep  = m_axis_rx_tkeep;
	pcie_snoop_rx_tdata  = m_axis_rx_tdata;
	pcie_snoop_rx_tuser  = m_axis_rx_tuser;

	if (rx_bar_hit == hit_bar4) begin
		pcie_app_rx_tvalid = 1'b0;
	end
end

endmodule

`default_nettype wire

