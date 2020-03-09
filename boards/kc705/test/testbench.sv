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

	output wire sys_rst156,
	output wire pcie_rst,

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

assign sys_rst156 = top0.sys_rst156;
assign pcie_rst = top0.pcie_rst;

// eth_data
logic eth_tvalid_nxt;
logic eth_tlast_nxt;
logic [7:0] eth_tkeep_nxt;
logic [63:0] eth_tdata_nxt;
logic eth_tuser_nxt;
always_ff @(posedge SFP_CLK_P) begin
	eth_tvalid_nxt <= eth_tvalid;
	eth_tlast_nxt <= eth_tlast;
//	eth_tkeep_nxt <= {
//		eth_tkeep[0], eth_tkeep[1], eth_tkeep[2], eth_tkeep[3],
//		eth_tkeep[4], eth_tkeep[5], eth_tkeep[6], eth_tkeep[7]
//	};
//	eth_tdata_nxt <= {
//		eth_tdata[ 7: 0], eth_tdata[15: 8], eth_tdata[23:16], eth_tdata[31:24],
//		eth_tdata[39:32], eth_tdata[47:40], eth_tdata[55:48], eth_tdata[63:56]
//	};
	eth_tkeep_nxt <= eth_tkeep;
	eth_tdata_nxt <= eth_tdata;
	eth_tuser_nxt <= eth_tuser;
end
always_comb top0.eth_top0.u_axi_10g_ethernet_0.m_axis_rx_tvalid = eth_tvalid_nxt;
always_comb top0.eth_top0.u_axi_10g_ethernet_0.m_axis_rx_tlast  = eth_tlast_nxt;
always_comb top0.eth_top0.u_axi_10g_ethernet_0.m_axis_rx_tkeep  = eth_tkeep_nxt;
always_comb top0.eth_top0.u_axi_10g_ethernet_0.m_axis_rx_tdata  = eth_tdata_nxt;
always_comb top0.eth_top0.u_axi_10g_ethernet_0.m_axis_rx_tuser  = eth_tuser_nxt;


// pcie_data
logic pcie_tvalid_nxt;
logic pcie_tlast_nxt;
logic [7:0] pcie_tkeep_nxt;
logic [63:0] pcie_tdata_nxt;
logic [21:0] pcie_tuser_nxt;
always_ff @(posedge clk200_p) begin
	pcie_tvalid_nxt <= pcie_tvalid;
	pcie_tlast_nxt <= pcie_tlast;
	pcie_tkeep_nxt <= {
		pcie_tkeep[4], pcie_tkeep[5], pcie_tkeep[6], pcie_tkeep[7],
		pcie_tkeep[0], pcie_tkeep[1], pcie_tkeep[2], pcie_tkeep[3]
	};
	pcie_tdata_nxt <= {
		pcie_tdata[39:32], pcie_tdata[47:40], pcie_tdata[55:48], pcie_tdata[63:56],
		pcie_tdata[ 7: 0], pcie_tdata[15: 8], pcie_tdata[23:16], pcie_tdata[31:24]
	};
	pcie_tuser_nxt <= pcie_tuser;
end
always_comb top0.pcie_top0.pcie_7x_support_i.m_axis_rx_tvalid = pcie_tvalid_nxt;
always_comb top0.pcie_top0.pcie_7x_support_i.m_axis_rx_tlast  = pcie_tlast_nxt;
always_comb top0.pcie_top0.pcie_7x_support_i.m_axis_rx_tkeep  = pcie_tkeep_nxt;
always_comb top0.pcie_top0.pcie_7x_support_i.m_axis_rx_tdata  = pcie_tdata_nxt;
always_comb top0.pcie_top0.pcie_7x_support_i.m_axis_rx_tuser  = pcie_tuser_nxt;

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

