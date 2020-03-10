`timescale 1ns / 1ps

package pciecfg_pkg;
	parameter  udp_pciecfg_port = 16'h5001;

	// opcode
	parameter PCIECFG_OPC_RD = 2'b00;
	parameter PCIECFG_OPC_WR = 2'b01;

	parameter PCIECFG_REG_DEVICE_ID = 10'h00;  // 1100
	parameter PCIECFG_REG_VENDER_ID = 10'h00;  // 0011
	parameter PCIECFG_REG_STATUS    = 10'h01;  // 1100
	parameter PCIECFG_REG_COMMAND   = 10'h01;  // 0011

	parameter PCIECFG_REG_BAR0      = 10'h04;
	parameter PCIECFG_REG_BAR1      = 10'h05;
	parameter PCIECFG_REG_BAR2      = 10'h06;
	parameter PCIECFG_REG_BAR3      = 10'h07;
	parameter PCIECFG_REG_BAR4      = 10'h08;
	parameter PCIECFG_REG_BAR5      = 10'h09;
	parameter PCIECFG_REG_BAR6      = 10'h0A;

	typedef logic [1:0] PCIECFG_OPCODE_T;

	typedef logic [3:0] PCIECFG_BYTE_MASK_T;

	typedef logic [9:0] PCIECFG_DWADDR_T;

	typedef logic [31:0] PCIECFG_DATA_T;

	typedef logic [15:0] PCIECFG_CHECKSUM_T;


	/* nettlp pcie configuration packet */
	typedef struct packed {
		PCIECFG_OPCODE_T opcode;
		PCIECFG_BYTE_MASK_T byte_mask;
		PCIECFG_DWADDR_T dwaddr;
		PCIECFG_DATA_T data;
		//PCIECFG_CHECKSUM_T checksum;  //TODO
	} PCIECFG_T;

	/* nettlp pcie configuration fifo */
	typedef struct packed {
		logic data_valid;
		struct packed {
			logic [15:0] udp_check;
			PCIECFG_OPCODE_T opcode;
			PCIECFG_BYTE_MASK_T byte_mask;
			PCIECFG_DWADDR_T dwaddr;
			PCIECFG_DATA_T data;
		} pkt;
	} FIFO_PCIECFG_T;

endpackage :pciecfg_pkg

