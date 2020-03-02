/*
 *  NetTLP Header:
 *
 *    0                   1                   2                   3
 *    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 *  0 |                      Destination Address                      |
 *    +                               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 *  1 |                               |                               |
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+                               +
 *  2 |                         Source Address                        |
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 *  3 |           EtherType           |Version|  IHL  |Type of Service|
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 *  4 |          Total Length         |         Identification        |
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 *  5 |Flags|     Fragment Offset     |  Time to Live |    Protocol   |
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 *  6 |        Header Checksum        |         Source Address        |
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 *  7 |                               |      Destination Address      |
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 *  8 |                               |          Source Port          |
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 *  9 |        Destination Port       |             Length            |
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 *  A |            Checksum           | Reserved  |   Sequence num    |
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 *  B |                           Timestamp                           |
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 *  C |R|FMT|   Type  |R|  TC |   R   |T|E|Atr| R |       Length      |
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 *  D |           Request ID          |      Tag      | LastBE|FirstBE|
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 *  E |                          Address                          | R |
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 *
 *
 * NetTLP header: Byte 6
 *  2               1             0B
 * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 * | Reserved  |   Sequence num    |
 * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-|
 * |           Timestamp           |
 * |                               |
 * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 *
 * Reserved: 6 bit, default:0
 * Sequence_num: 10, default:0
 * Timestamp: 32 bit, default:0, Clock_source:PCIe_clock(4ns)
 *
 */


package nettlp_pkg;
	parameter udp_port_nettlp_cpl = 16'h3000;
	parameter udp_port_nettlp_mr  = 16'h4000;

	parameter PACKET_HDR_LEN = 11'd48;    // IPhdr + UDPhdr + NetTLPhdr

	/* nettlp header */
	parameter NETTLP_HDR_LEN = 11'd6;

	typedef struct packed {
		bit [15:0] seq;
		bit [31:0] tstamp;
	} nettlp_hdr;


	/* NetTLP interface */

	// PCIE_RX FIFO (107 bit)
	import pcie_tlp_pkg::*;

	typedef struct packed {
		bit data_valid;
		struct packed {
			struct packed {
				TLPPacketFormat     fmt;     // 2
				TLPPacketType       pkttype; // 5
				TLPPacketLengthByte len;     // 12
				TLPPacketTag        tag;     // 8
			} field;
			PCIE_TVALID64   tvalid;    // 1
			PCIE_TLAST64    tlast;     // 1
			PCIE_TKEEP64    tkeep;     // 8
			PCIE_TDATA64    tdata;     // 64
			PCIE_TUSER64_RX tuser;     // 22
		} tlp;
	} PCIE_FIFO64_RX;

	// PCIE_TX FIFO (78 bit)
	typedef struct packed {
		bit data_valid;
		struct packed {
			PCIE_TVALID64   tvalid;    // 1
			PCIE_TLAST64    tlast;     // 1
			PCIE_TKEEP64    tkeep;     // 8
			PCIE_TDATA64    tdata;     // 64
			PCIE_TUSER64_TX tuser;     // 4
		} tlp;
	} PCIE_FIFO64_TX;
	

	/* Ethernet 10G subsystem interface */

	// clock 0
	typedef struct packed {
		struct packed {
			bit [5:0][7:0] h_dest;
			bit [1:0][7:0] h_source0;
		} eth;

	} PACKET_QWORD0;

	// clock 1
	typedef struct packed {
		struct packed {
			bit [3:0][7:0] h_source1;
			bit [15:0]     h_proto;
		} eth;
		struct packed {
			bit [3:0] version;
			bit [3:0] ihl;
			bit [7:0] tos;
		} ip;
	} PACKET_QWORD1;

	// clock 2
	typedef struct packed {
		struct packed {
			bit [15:0] tot_len;
			bit [15:0] id;
			bit [15:0] frag_off;
			bit [7:0]  ttl;
			bit [7:0]  protocol;
		} ip;
	} PACKET_QWORD2;

	// clock 3
	typedef struct packed {
		struct packed {
			bit [15:0] check;
			bit [31:0] saddr;
			bit [15:0] daddr0;
		} ip;
	} PACKET_QWORD3;

	// clock 4
	typedef struct packed {
		struct packed {
			bit [15:0] daddr1;
		} ip;
		struct packed {
			bit [15:0] source;
			bit [15:0] dest;
			bit [15:0] len;
		} udp;
	} PACKET_QWORD4;

	// clock 5
	typedef struct packed {
		struct packed {
			bit [15:0] check;
		} udp;
		nettlp_hdr nthdr;
	} PACKET_QWORD5;


	// tready
	typedef bit ETH_TREADY64;

	// tvalid
	typedef bit ETH_TVALID64;

	// tlast
	typedef bit ETH_TLAST64;
	
	// tkeep
	typedef bit [7:0] ETH_TKEEP64;

	// tuser (RX)
	typedef bit ETH_TUSER64_RX;

	// tuser (TX)
	typedef bit ETH_TUSER64_TX;

	// tdata (RX)
	typedef bit [63:0] ETH_TDATA64_RX;

	// tdata (TX)
	typedef union packed {
		bit [7:0][7:0] oct;
		PACKET_QWORD0 clk0;
		PACKET_QWORD1 clk1;
		PACKET_QWORD2 clk2;
		PACKET_QWORD3 clk3;
		PACKET_QWORD4 clk4;
		PACKET_QWORD5 clk5;
	} ETH_TDATA64;

endpackage :nettlp_pkg

