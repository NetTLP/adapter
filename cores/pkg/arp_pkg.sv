`timescale 1ns / 1ps

package arp_pkg;
	import ethernet_pkg::*;

	/* arp packet */
	typedef struct packed {
		macaddr_t h_dest;
		macaddr_t h_source;
		logic [15:0] h_proto;

		logic [15:0] ar_hrd;
		logic [15:0] ar_pro;
		logic [7:0] ar_hln;
		logic [7:0] ar_pln;
		logic [15:0] ar_op;

		logic [47:0] sender_mac;
		logic [31:0] sender_ip;
		logic [47:0] target_mac;
		logic [31:0] target_ip;
	} arphdr;

endpackage :arp_pkg

