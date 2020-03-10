/* from Linux/include/uapi/linux/udp.h */
package udp_pkg;
	parameter UDP_HDR_LEN = 16'd8;

	/* UDP header */
	typedef struct packed {
		logic [15:0] source;
		logic [15:0] dest;
		logic [15:0] len;
		logic [15:0] check;
	} udphdr;

	/* udp_init */
	function udphdr udp_init();
		udp_init.source = 9;
		udp_init.dest   = 9;
		udp_init.len    = UDP_HDR_LEN;
		udp_init.check  = 0;
	endfunction :udp_init

endpackage :udp_pkg

