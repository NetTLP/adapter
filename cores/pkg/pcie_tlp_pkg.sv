/* 
 * PCI Express TLP 3DW Header:
 *
 *    |       0       |       1       |       2       |       3       |
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 * r0 |R|FMT|   Type  |R| TC  |   R   |T|E|Atr| R |       Length      |
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 * r1 |           Request ID          |      Tag      |LastBE |FirstBE|
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 * r2 |                           Address                         | R |
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 * 
 * PCI Express TLP 3DW Header:
 *
 *    |       0       |       1       |       2       |       3       |
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 * r0 |R|FMT|   Type  |R| TC  |   R   |T|E|Atr| R |       Length      |
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 * r1 |           Request ID          |      Tag      |LastBE |FirstBE|
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 * r2 |                       Address[63:32]                      | R |
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 * r3 |                       Address[31: 2]                      | R |
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 * 
 * PCI Express TLP Completion:
 *
 *    |       0       |       1       |       2       |       3       |
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 * r0 |R|FMT|   Type  |R| TC  |   R   |T|E|Atr| R |       Length      |
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 * r1 |          Completer ID         |CplSt|B|       Byte Count      |
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 * r2 |           Request ID          |      Tag      |R|Lower Address|
 *    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 * 
 * Xilinx IP (64 bit):
 *
 *     63        31         0 bit
 *      +-+-+-+-+-+-+-+-+-+-+
 * clk0 |    r1   |    r0   |
 *      +-+-+-+-+-+-+-+-+-+-+
 * clk1 |    r3   |    r2   |
 *      +-+-+-+-+-+-+-+-+-+-+
 *              ....
 *
 */

package pcie_tlp_pkg;

	typedef bit [10:0] TLP_LEN;  // max: 2048

	typedef bit [7:0] TLP_TAG;


	// tready
	typedef bit PCIE_TREADY64;

	// tvalid
	typedef bit PCIE_TVALID64;

	// tlast
	typedef bit PCIE_TLAST64;
	
	// tkeep
	typedef bit [7:0] PCIE_TKEEP64;

	// tdata
	typedef enum bit [1:0] {
		MRD_3DW_NODATA = 2'b00,    // 32 bit
		MRD_4DW_NODATA = 2'b01,    // 64 bit
		MWR_3DW_DATA    = 2'b10,    // 32 bit
		MWR_4DW_DATA    = 2'b11     // 64 bit
	} TLPPacketFormat;

	typedef enum bit [1:0] {
		CPL_NODATA = 2'b00,
		CPL_DATA   = 2'b10
	} TLPCplFormat;


	typedef enum bit [4:0] {
	MEMRW    = 5'b00000,
	CFG0RW   = 5'b00100,
	COMPL    = 5'b01010
	} TLPPacketType;

	typedef union packed {
	    // for initialize
	    bit [63:0] raw;
	    
		// octet
		bit [7:0][7:0] oct;

		// clock 0: Memory Request Header
		struct packed {
			// header 1
			bit [15:0]      reqid;
			bit [ 7:0]      tag;
			bit [ 3:0]      lastbe;
			bit [ 3:0]      firstbe;

			// header 0
			bit             r0;
			TLPPacketFormat format;
			TLPPacketType   pkttype;
			bit             r1;
			bit [ 2:0]      tclass;
			bit [ 3:0]      r2;
			bit             digest;
			bit             poison;
			bit [ 1:0]      attr;
			bit [ 1:0]      r3;
			bit [ 9:0]      length;
		} clk0_mem;

		// clock 0: Completion Header
		struct packed {
			// header 1
			bit [15:0]      cplid;
			bit [ 2:0]      cplsta;
			bit             bcm;
			bit [11:0]      bytecount;

			// header 0
			bit             r0;
			TLPCplFormat    format;
			TLPPacketType   pkttype;
			bit             r1;
			bit [ 2:0]      tclass;
			bit [ 3:0]      r2;
			bit             digest;
			bit             poison;
			bit [ 1:0]      attr;
			bit [ 1:0]      r3;
			bit [ 9:0]      length;
		} clk0_cpl;

		// clock 1: Memory Request Header 32 bit address
		struct packed {
			// data
			bit [31:0]      data;

			// header 3
			bit [29:0]      addr;
			bit [ 1:0]      r4;
		} clk1_mem32;

		// clock 1: Memory Request Header 64 bit address
		struct packed {
			// header 4
			bit [29:0]      addr_low;
			bit [ 1:0]      r4;

			// header 3
			bit [31:0]      addr_high;
		} clk1_mem64;

		// clock 1: Completion Header
		struct packed {
			// data
			bit [31:0]      data;

			// header 3
			bit [15:0]      reqid;
			bit [ 7:0]      tag;
			bit             r;
			bit [ 6:0]      lower_addr;
		} clk1_cpl;
		
		// data
		struct packed {
			// data 2
			bit [31:0]      data1;

			// data 1
			bit [31:0]      data0;
		} data;

	} PCIE_TDATA64;

	// tuser (RX)
	typedef struct packed {
		bit       eof;
		bit [3:0] eof_offset;
		bit [1:0] reserved;
		bit       sof;
		bit [3:0] sof_offset;
		bit [7:0] bar;
		bit       err_fwd;
		bit       ecrc_err;
	} PCIE_TUSER64_RX;

	// tuser (TX)
	typedef bit [3:0] PCIE_TUSER64_TX;


endpackage :pcie_tlp_pkg

