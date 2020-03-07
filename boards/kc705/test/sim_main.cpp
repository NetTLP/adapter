#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vtestbench.h"
//#include "verilated.h"

#include <sys/stat.h>
#include <fcntl.h>

#include <net/ethernet.h>
#include <netinet/ip.h>
#include <netinet/udp.h>

static int debug = 0;


#define SFP_CLK               (64/2)        // 6.4 ns (156.25 MHz)
#define SYS_CLK               (50/2)        // 200 MHz
#define PCIE_REF_CLK          (100/2)       // 100 MHz

#define WAVE_FILE_NAME        "wave.vcd"
#define SIM_TIME_RESOLUTION   "100 ps"
#define SIM_TIME              100000       // 10 us


#define PCAP_MAGIC         (0xa1b2c3d4)
#define PCAP_NANO_MAGIC    (0xa1b23c4d)

#define PCAP_VERSION_MAJOR (0x2)
#define PCAP_VERSION_MINOR (0x4)
#define PCAP_SNAPLEN       (0xFFFF)
#define PCAP_NETWORK       (0x1)      // linktype_ethernet

#define NPKT_MAX        (0x300)

#define PKT_SIZE_MAX    (2048)
#define PKT_SIZE_MIN    (60)


#define pr_info(S, ...)   printf("\x1b[1m\x1b[94minfo:\x1b[0m " S "\n", ##__VA_ARGS__)
#define pr_err(S, ...)    fprintf(stderr, "\x1b[1m\x1b[31merror:\x1b[0m " S "\n", ##__VA_ARGS__)
#define pr_warn(S, ...)   if (warn) fprintf(stderr, "\x1b[1m\x1b[33mwarn :\x1b[0m " S "\n", ##__VA_ARGS__)
#define pr_debug(S, ...)  if (debug) fprintf(stderr, "\x1b[1m\x1b[90mdebug:\x1b[0m " S "\n", ##__VA_ARGS__)


/* pcap v2.4 global header */
struct pcap_hdr_s {
	unsigned int   magic_number;   /* magic number */
	unsigned short version_major;  /* major version number */
	unsigned short version_minor;  /* minor version number */
	int            thiszone;       /* GMT to local correction */
	unsigned int   sigfigs;        /* accuracy of timestamps */
	unsigned int   snaplen;        /* max length of captured packets, in octets */
	unsigned int   network;        /* data link type */
} __attribute__((packed));

/* pcap v2.4 packet header */
struct pcaprec_hdr_s {
	unsigned int ts_sec;         /* timestamp seconds */
	unsigned int ts_usec;        /* timestamp microseconds */
	unsigned int incl_len;       /* number of octets of packet saved in file */
	unsigned int orig_len;       /* actual length of packet */
} __attribute__((packed));

struct memh {
	unsigned int len;
	unsigned char buf[PKT_SIZE_MAX];
};

struct nettlphdr {
	unsigned short seq;
	unsigned int timestamp;
} __attribute__((packed));

struct pkthdr {
	struct ether_header eth;
	struct ip ip4;
	struct udphdr udp;
	struct nettlphdr nt;
} __attribute__((packed));


int
loadpcap(int fd, struct memh pkt[], int skip_iphdr)
{
	unsigned char pcapbuf[0xFF];

	struct pcap_hdr_s *pcap_ghdr = (struct pcap_hdr_s *)&pcapbuf[0];

	// check global pcap header
	if (read(fd, pcapbuf, sizeof(struct pcap_hdr_s)) <= 0) {
		fprintf(stderr, "input file is too short\n");
		return -1;
	}

	/* check the pcap global header */
	if (pcap_ghdr->magic_number != PCAP_MAGIC) {
		printf("unsupported pcap format: pcap_ghdr.magic_number=%X\n",
				(int)pcap_ghdr->magic_number);
		return -1;
	}
	if (pcap_ghdr->version_major != PCAP_VERSION_MAJOR) {
		printf("unsupported pcap format: pcap_ghdr.version_major=%X\n",
				(int)pcap_ghdr->version_major);
		return -1;
	}
	if (pcap_ghdr->version_minor != PCAP_VERSION_MINOR) {
		printf("unsupported pcap format: pcap_ghdr.version_minor=%X\n",
				(int)pcap_ghdr->version_minor);
		return -1;
	}

	int iphdr_len = sizeof(struct pkthdr);
	int i;
	for (i = 0; i < NPKT_MAX; i++) {
		struct pcaprec_hdr_s *pcaphdr = (struct pcaprec_hdr_s *)&pcapbuf[0];
		int orig_len, incl_len;

		// pcap header
		if (read(fd, pcapbuf, sizeof(struct pcaprec_hdr_s)) <= 0) {
			break;
		}

		incl_len = pcaphdr->incl_len;
		orig_len = pcaphdr->orig_len;

		if ((orig_len < PKT_SIZE_MIN) || (orig_len > PKT_SIZE_MAX)) {
			pr_err("[warn] frame length: frame_len=%d\n", (int)orig_len);
			return -1;
		}
		//pr_debug("incl_len: %d, orig_len: %d\n", incl_len, orig_len);

		int offset = 0;
		if (skip_iphdr) {
			if (lseek(fd, iphdr_len, SEEK_CUR) <= 0)
				break;

			offset = iphdr_len;
		}

		// packet data
		pkt[i].len = orig_len - offset;
		if (read(fd, pkt[i].buf, incl_len - offset) <= 0)
			break;
	}

	return 1;
}

void
print_pkt(struct memh pkt[])
{
	int i, j;
	for (i = 0; i < NPKT_MAX; i++) {
		if (pkt[i].len == 0) {
			continue;
		}

		printf("len: %d\n", pkt[i].len);

		for (j = 0; j < pkt[i].len; j++) {
			printf(" %02X", pkt[i].buf[j]);

			if ((j + 1) % 8 == 0) {
				printf("\n");
			}
		}
		printf("\n\n");
	}
}



static uint64_t t = 0;

static inline void tick(Vtestbench *top, VerilatedVcdC *tfp)
{
	++t;
	top->eval();
	tfp->dump(t);
}

//#define tdata top->Vtestbench->top0->eth_top0->u_axi_10g_ethernet_0->device_eth0->eth_rx_tdata

const static char *pcap_files[] = {
	"test/pcap/simple-nic-ping.pcap",
	NULL
};

int main(int argc, char **argv)
{
	Verilated::commandArgs(argc, argv);
	Verilated::traceEverOn(true);

	VerilatedVcdC *tfp = new VerilatedVcdC;
	tfp->spTrace()->set_time_resolution(SIM_TIME_RESOLUTION);

	Vtestbench* top = new Vtestbench;
	top->trace(tfp, 99);
	tfp->open(WAVE_FILE_NAME);

	top->clk200_p = 0;
	top->clk200_n = 1;

	top->sys_clk_p = 0;
	top->sys_clk_n = 1;
	top->sys_rst_n = 1;

	top->SFP_CLK_P = 0;
	top->SFP_CLK_N = 1;

	top->eth_tvalid = 0;
	top->eth_tlast = 0;
	top->eth_tkeep = 0;
	top->eth_tdata = 0;
	top->eth_tuser = 0;

	int i, n, fd, ret;

	n = sizeof(pcap_files) / sizeof(pcap_files[0]);

	// load ethernet data
	struct memh eth_data[NPKT_MAX] = {};
	for (i = 0; i < n - 1; i++) {
		fd = open(pcap_files[i], O_RDONLY);
		if (fd < 0) {
			fprintf(stderr, "cannot open pcap file: %s\n", pcap_files[i]);
			return 1;
		}

		ret = loadpcap(fd, eth_data, 0);
		if (!ret) {
			pr_err("loadpcap, %d", ret);
			return 1;
		}

		if (debug) {
			print_pkt(eth_data);
		}

		close(fd);
	}

	// load PCIe (TLP) data
	struct memh pcie_data[NPKT_MAX] = {};
	for (i = 0; i < n - 1; i++) {
		fd = open(pcap_files[i], O_RDONLY);
		if (fd < 0) {
			fprintf(stderr, "cannot open pcap file: %s\n", pcap_files[i]);
			return 1;
		}

		ret = loadpcap(fd, pcie_data, 1);
		if (!ret) {
			pr_err("loadpcap, %d", ret);
			return 1;
		}

		if (debug) {
			print_pkt(pcie_data);
		}

		close(fd);
	}

	uint32_t eth_n = 0, eth_pos = 0, eth_intval = 5;
	uint32_t pcie_n = 0, pcie_pos = 0, pcie_intval = 5;
	int nleft;
	while(!Verilated::gotFinish()) {
		// SFP
		if ((t % SFP_CLK) == 0) {
			top->SFP_CLK_P = ~top->SFP_CLK_P;
			top->SFP_CLK_N = ~top->SFP_CLK_N;
		}

		// sys_clk
		if ((t % SYS_CLK) == 0) {
			top->sys_clk_p = ~top->sys_clk_p;
			top->sys_clk_n = ~top->sys_clk_n;
		}

		//clk200
		if ((t % PCIE_REF_CLK) == 0) {
			top->clk200_p = ~top->clk200_p;
			top->clk200_n = ~top->clk200_n;
		}

		if (t > 10)
			top->sys_rst_n = 0;

		// Ethernet link from pcap files
		if ((t > 0) && !top->sys_rst156) {
			if (top->SFP_CLK_P && ((t % SFP_CLK) == 0)) {
				nleft = eth_data[eth_n].len - eth_pos;
				//printf("%d %d %d\n", eth_n, eth_data[eth_n].len, eth_pos);
				if (nleft > 8) {
					top->eth_tvalid = 1;
					top->eth_tlast = 0;
					top->eth_tkeep = 0xFF;
					top->eth_tdata = *(uint64_t *)&eth_data[eth_n].buf[eth_pos];
					top->eth_tuser = 0;

					eth_pos += 8;
				} else if (nleft > 0) {
					top->eth_tvalid = 1;
					top->eth_tlast = 1;
					top->eth_tkeep = (1 << nleft) - 1;
					top->eth_tdata = *(uint64_t *)&eth_data[eth_n].buf[eth_pos];
					top->eth_tuser = 0;

					eth_pos += 8;
				} else {
					top->eth_tvalid = 0;
					top->eth_tlast = 0;
					top->eth_tkeep = 0;
					top->eth_tdata = 0;
					top->eth_tuser = 0;
					if (eth_intval == 0) {
						++eth_n;
						eth_pos = 0;
						eth_intval = 5;
					} else {
						--eth_intval;
					}
				}
			}
		} else {
			eth_n = 0;
			eth_pos = 0;
			eth_intval = 5;

			top->eth_tvalid = 0;
			top->eth_tlast = 0;
			top->eth_tkeep = 0;
			top->eth_tdata = 0;
			top->eth_tuser = 0;
		}

		// PCIe link from pcap files
		if ((t > 0) && !top->sys_rst156) {
			if (top->sys_clk_p && ((t % SYS_CLK) == 0)) {
				nleft = pcie_data[pcie_n].len - pcie_pos;
				//printf("%d %d %d\n", pcie_n, pcie_data[pcie_n].len, pcie_pos);
				if (nleft > 8) {
					top->pcie_tvalid = 1;
					top->pcie_tlast = 0;
					top->pcie_tkeep = 0xFF;
					top->pcie_tdata = *(uint64_t *)&pcie_data[pcie_n].buf[pcie_pos];
					top->pcie_tuser = 0;

					pcie_pos += 8;
				} else if (nleft > 0) {
					top->pcie_tvalid = 1;
					top->pcie_tlast = 1;
					top->pcie_tkeep = (1 << nleft) - 1;
					top->pcie_tdata = *(uint64_t *)&pcie_data[pcie_n].buf[pcie_pos];
					top->pcie_tuser = 0;

					pcie_pos += 8;
				} else {
					top->pcie_tvalid = 0;
					top->pcie_tlast = 0;
					top->pcie_tkeep = 0;
					top->pcie_tdata = 0;
					top->pcie_tuser = 0;
					if (pcie_intval == 0) {
						++pcie_n;
						pcie_pos = 0;
						pcie_intval = 5;
					} else {
						--pcie_intval;
					}
				}
			}
		} else {
			pcie_n = 0;
			pcie_pos = 0;
			pcie_intval = 5;

			top->pcie_tvalid = 0;
			top->pcie_tlast = 0;
			top->pcie_tkeep = 0;
			top->pcie_tdata = 0;
			top->pcie_tuser = 0;
		}

		if (t > SIM_TIME)
			break;

		tick(top, tfp);
	}

	delete top;
	exit(0);
}

