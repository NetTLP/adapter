`timescale 1ns / 1ps

package nettlp_cmd_pkg;

	// opcode
	parameter NETTLP_OPC_REG_RD  = 8'b0001_0000;
	parameter NETTLP_OPC_REG_WR  = 8'b0001_0001;

	parameter NETTLP_OPC_MAGIC   = 8'b0010_0000;
	parameter NETTLP_OPC_TSTAMP  = 8'b0010_0001;
	parameter NETTLP_OPC_RST_ALL = 8'b0010_0010;

	// dwaddr: adapter register
	parameter ADAPTER_REG_MAGIC        = 8'h00;
	parameter ADAPTER_REG_DSTMAC_LOW   = 8'h01;
	parameter ADAPTER_REG_DSTMAC_HIGH  = 8'h02;
	parameter ADAPTER_REG_SRCMAC_LOW   = 8'h03;
	parameter ADAPTER_REG_SRCMAC_HIGH  = 8'h04;
	parameter ADAPTER_REG_DSTIP        = 8'h05;
	parameter ADAPTER_REG_SRCIP        = 8'h06;
	parameter ADAPTER_REG_DSTPORT      = 8'h07;
	parameter ADAPTER_REG_SRCPORT      = 8'h08;

	parameter ADAPTER_REG_REQUESTER_ID = 8'h10;

	typedef bit [7:0] NETTLP_CMD_OPCODE_T;

	typedef bit [7:0] NETTLP_CMD_DWADDR_T;

	typedef bit [31:0] NETTLP_CMD_DATA_T;

	typedef bit [15:0] NETTLP_CMD_CHECKSUM_T;

	/* nettlp command packet */
	typedef struct packed {
		NETTLP_CMD_OPCODE_T opcode;
		NETTLP_CMD_DWADDR_T dwaddr;
		NETTLP_CMD_DATA_T data;
		//NETTLP_CMD_CHECKSUM_T checksum; //TODO
	} NETTLP_CMD_T;

	/* nettlp command fifo */
	typedef struct packed {
		bit [15:0] udp_check;
		NETTLP_CMD_OPCODE_T opcode;
		NETTLP_CMD_DWADDR_T dwaddr;
		NETTLP_CMD_DATA_T data;
	} FIFO_NETTLP_CMD_T;

endpackage :nettlp_cmd_pkg

