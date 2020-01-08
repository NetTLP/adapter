module testbench (
	input wire SYSCLK0_300_P,
	input wire SYSCLK0_300_N,

	input wire QSFP0_CLOCK_P,
	input wire QSFP0_CLOCK_N,

	input wire PCIE_CLK_P,
	input wire PCIE_CLK_N,
	input wire PCIE_RESET_N
);

	// output
	wire QSFP0_INTL = 1'b0;
	wire QSFP0_MODPRSL = 1'b0;
	wire [3:0] QSFP0_RX_P = 4'b0;
	wire [3:0] QSFP0_RX_N = 4'b0;
	wire [1:0] pci_exp_rxp = 2'b0;
	wire [1:0] pci_exp_rxn = 2'b0;

	// input
	wire QSFP0_FS0;
	wire QSFP0_FS1;
	wire QSFP0_LPMODE;
	wire QSFP0_MODSELL;
	wire QSFP0_RESETL;
	wire [3:0] QSFP0_TX_P;
	wire [3:0] QSFP0_TX_N;
	wire [1:0] pci_exp_txp;
	wire [1:0] pci_exp_txn;

	wire LED_R;
	wire LED_Y;
	wire LED_G;

	top top_ins(.*);

	wire _unused_ok = &{
		1'b0,
		QSFP0_FS0,
		QSFP0_FS1,
		QSFP0_LPMODE,
		QSFP0_MODSELL,
		QSFP0_RESETL,
		QSFP0_TX_P,
		QSFP0_TX_N,
		pci_exp_txp,
		pci_exp_txn,
		LED_R,
		LED_Y,
		LED_G,
		1'b0
	};

endmodule

