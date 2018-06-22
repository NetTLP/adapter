/* PCIe TLP capture header: Byte 6
 * Byte 6
 *
 *  2               1             0B
 * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 * |DIR|        Reserved           |
 * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-|
 * |            Sequence           |
 * |                               |
 * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 * Direction, 2bit
 * Reserved, 14bit
 * Sequence, 32bit
 */

package pcie_tcap_pkg;
	parameter PCIE_TCAP_LEN = 6;

	typedef struct packed {
		bit [ 1:0] dir;
		bit [13:0] rsrv;
		bit [31:0] seq;
	} pcie_tcaphdr;

	function pcie_tcaphdr tcap_init();
		tcap_init.dir = 0;
		tcap_init.rsrv = 0;
		tcap_init.seq = 0;
	endfunction :tcap_init

endpackage :pcie_tcap_pkg

