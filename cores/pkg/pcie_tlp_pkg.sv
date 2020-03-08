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

	// tready
	typedef logic PCIE_TREADY64;

	// tvalid
	typedef logic PCIE_TVALID64;

	// tlast
	typedef logic PCIE_TLAST64;
	
	// tkeep
	typedef logic [7:0] PCIE_TKEEP64;

	// tdata

	typedef logic [9:0] TLPPacketLength;
	typedef logic [11:0] TLPPacketLengthByte;  // max: 2048

	typedef logic [7:0] TLPPacketTag;


	typedef enum logic [1:0] {
		MRD_3DW_NODATA = 2'b00,    // 32 bit
		MRD_4DW_NODATA = 2'b01,    // 64 bit
		MWR_3DW_DATA    = 2'b10,    // 32 bit
		MWR_4DW_DATA    = 2'b11     // 64 bit
	} TLPPacketFormat;

	typedef enum logic [1:0] {
		CPL_NODATA = 2'b00,
		CPL_DATA   = 2'b10
	} TLPCplFormat;


	typedef enum logic [4:0] {
	MEMRW    = 5'b00000,
	CFG0RW   = 5'b00100,
	COMPL    = 5'b01010
	} TLPPacketType;

	typedef union packed {
	    // for initialize
	    logic [63:0] raw;
	    
		// octet
		logic [7:0][7:0] oct;

		// clock 0: Memory Request Header
		struct packed {
			// header 1
			logic [15:0]      reqid;
			TLPPacketTag    tag;
			logic [ 3:0]      lastbe;
			logic [ 3:0]      firstbe;

			// header 0
			logic             r0;
			TLPPacketFormat format;
			TLPPacketType   pkttype;
			logic             r1;
			logic [ 2:0]      tclass;
			logic [ 3:0]      r2;
			logic             digest;
			logic             poison;
			logic [ 1:0]      attr;
			logic [ 1:0]      r3;
			TLPPacketLength length;
		} clk0_mem;

		// clock 0: Completion Header
		struct packed {
			// header 1
			logic [15:0]      cplid;
			logic [ 2:0]      cplsta;
			logic             bcm;
			logic [11:0]      bytecount;

			// header 0
			logic             r0;
			TLPCplFormat    format;
			TLPPacketType   pkttype;
			logic             r1;
			logic [ 2:0]      tclass;
			logic [ 3:0]      r2;
			logic             digest;
			logic             poison;
			logic [ 1:0]      attr;
			logic [ 1:0]      r3;
			TLPPacketLength length;
		} clk0_cpl;

		// clock 1: Memory Request Header 32 bit address
		struct packed {
			// data
			logic [31:0]      data;

			// header 3
			logic [29:0]      addr;
			logic [ 1:0]      r4;
		} clk1_mem32;

		// clock 1: Memory Request Header 64 bit address
		struct packed {
			// header 4
			logic [29:0]      addr_low;
			logic [ 1:0]      r4;

			// header 3
			logic [31:0]      addr_high;
		} clk1_mem64;

		// clock 1: Completion Header
		struct packed {
			// data
			logic [31:0]      data;

			// header 3
			logic [15:0]      reqid;
			TLPPacketTag    tag;
			logic             r;
			logic [ 6:0]      lower_addr;
		} clk1_cpl;
		
		// data
		struct packed {
			// data 2
			logic [31:0]      data1;

			// data 1
			logic [31:0]      data0;
		} data;

	} PCIE_TDATA64;

	// tuser (RX)
	typedef struct packed {
		logic       eof;
		logic [3:0] eof_offset;
		logic [1:0] reserved;
		logic       sof;
		logic [3:0] sof_offset;
		logic [7:0] bar;
		logic       err_fwd;
		logic       ecrc_err;
	} PCIE_TUSER64_RX;

	// tuser (TX)
	typedef logic [3:0] PCIE_TUSER64_TX;


endpackage :pcie_tlp_pkg

