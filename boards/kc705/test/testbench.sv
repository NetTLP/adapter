module testbench #(
	parameter C_DATA_WIDTH        = 64,
	parameter KEEP_WIDTH          = C_DATA_WIDTH / 8,
	parameter LINK_WIDTH          = C_DATA_WIDTH / 16,
	parameter COLD_RESET_INTVAL   = 14'hf
)(
	input wire clk200_p,
	input wire clk200_n,

	input wire sys_clk_p,
	input wire sys_clk_n,
	input wire sys_rst_n,

	input wire SFP_CLK_P,
	input wire SFP_CLK_N,

	output logic sys_rst156,

	input wire eth_tvalid,
	input wire eth_tlast,
	input wire [7:0] eth_tkeep,
	input wire [63:0] eth_tdata,
	input wire eth_tuser,

//	output wire pcie_tready,
	input wire pcie_tvalid,
	input wire pcie_tlast,
	input wire [7:0] pcie_tkeep,
	input wire [63:0] pcie_tdata,
	input wire [21:0] pcie_tuser
);

// output
wire [LINK_WIDTH-1:0] pci_exp_rxp = 'b0;
wire [LINK_WIDTH-1:0] pci_exp_rxn = 'b0;
wire ETH0_TX_P = 'b0;
wire ETH0_TX_N = 'b0;

// inout
wire I2C_FPGA_SCL;
wire I2C_FPGA_SDA;

// input
wire [LINK_WIDTH-1:0] pci_exp_txp;
wire [LINK_WIDTH-1:0] pci_exp_txn;
wire I2C_FPGA_RST_N;
wire SI5324_RST_N;
wire ETH0_RX_P;
wire ETH0_RX_N;
wire ETH0_TX_DISABLE;

// wires
always_comb sys_rst156 = top0.sys_rst156;

// eth_data
wire [7:0] eth_tkeep_rev = {
	eth_tkeep[0], eth_tkeep[1], eth_tkeep[2], eth_tkeep[3],
	eth_tkeep[4], eth_tkeep[5], eth_tkeep[6], eth_tkeep[7]
};
wire [63:0] eth_tdata_rev = {
	eth_tdata[ 7: 0], eth_tdata[15: 8], eth_tdata[23:16], eth_tdata[31:24],
	eth_tdata[39:32], eth_tdata[47:40], eth_tdata[55:48], eth_tdata[63:56]
};
always_comb top0.eth_top0.u_axi_10g_ethernet_0.m_axis_rx_tvalid = eth_tvalid;
always_comb top0.eth_top0.u_axi_10g_ethernet_0.m_axis_rx_tlast  = eth_tlast;
always_comb top0.eth_top0.u_axi_10g_ethernet_0.m_axis_rx_tkeep  = eth_tkeep_rev;
always_comb top0.eth_top0.u_axi_10g_ethernet_0.m_axis_rx_tdata  = eth_tdata_rev;
always_comb top0.eth_top0.u_axi_10g_ethernet_0.m_axis_rx_tuser  = eth_tuser;

// pcie_data
//always_comb pcie_tready = top0.pcie_top0.pcie_7x_support_i.m_axis_rx_tready;
wire [7:0] pcie_tkeep_rev = {
	pcie_tkeep[4], pcie_tkeep[5], pcie_tkeep[6], pcie_tkeep[7],
	pcie_tkeep[0], pcie_tkeep[1], pcie_tkeep[2], pcie_tkeep[3]
};
wire [63:0] pcie_tdata_rev = {
	pcie_tdata[39:32], pcie_tdata[47:40], pcie_tdata[55:48], pcie_tdata[63:56],
	pcie_tdata[ 7: 0], pcie_tdata[15: 8], pcie_tdata[23:16], pcie_tdata[31:24]
};
always_comb top0.pcie_top0.pcie_7x_support_i.m_axis_rx_tvalid = pcie_tvalid;
always_comb top0.pcie_top0.pcie_7x_support_i.m_axis_rx_tlast  = pcie_tlast;
always_comb top0.pcie_top0.pcie_7x_support_i.m_axis_rx_tkeep  = pcie_tkeep_rev;
always_comb top0.pcie_top0.pcie_7x_support_i.m_axis_rx_tdata  = pcie_tdata_rev;
always_comb top0.pcie_top0.pcie_7x_support_i.m_axis_rx_tuser  = pcie_tuser;

top #(
	.COLD_RESET_INTVAL(COLD_RESET_INTVAL)
) top0(.*);

wire _unused_ok = &{
	I2C_FPGA_SCL,
	I2C_FPGA_SDA,

	pci_exp_txp,
	pci_exp_txn,
	I2C_FPGA_RST_N,
	SI5324_RST_N,
	ETH0_RX_P,
	ETH0_RX_N,
	ETH0_TX_DISABLE,
	1'b0
};

endmodule

