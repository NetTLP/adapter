`timescale 1ns / 1ps

package arp_pkg;
	import ethernet_pkg::*;

	/* arp packet */
	typedef struct packed {
		macaddr_t h_dest;
		macaddr_t h_source;
		bit [15:0] h_proto;

		bit [15:0] ar_hrd;
		bit [15:0] ar_pro;
		bit [7:0] ar_hln;
		bit [7:0] ar_pln;
		bit [15:0] ar_op;

		bit [47:0] sender_mac;
		bit [31:0] sender_ip;
		bit [47:0] target_mac;
		bit [31:0] target_ip;
	} arphdr;

endpackage :arp_pkg

