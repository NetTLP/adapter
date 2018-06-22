#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vtestbench.h"
#include "Vtestbench_testbench.h"
#include "Vtestbench_eth_top.h"
#include "Vtestbench_axi_10g_ethernet_0.h"

#include <stdbool.h>
#include <unistd.h>
//#include "axis.h"


#define SFP_CLK               (64/2)        // 6.4 ns (156.25 MHz)
#define PCIE_REF_CLK          (40/2)        // 4 ns (250 MHz)
#define SYS_CLK               (50/2)        // 5 ns (200 MHz)

#define WAVE_FILE_NAME        "wave.vcd"
#define SIM_TIME_RESOLUTION   "100 ps"
#define SIM_TIME              1000000       // 100 us

#define __packed    __attribute__((__packed__))

#define result_tx_tdata    sim->v->eth_top0->u_axi_10g_ethernet_0->s_axis_tx_tdata
#define result_tx_tkeep    sim->v->eth_top0->u_axi_10g_ethernet_0->s_axis_tx_tkeep
#define result_tx_tlast    sim->v->eth_top0->u_axi_10g_ethernet_0->s_axis_tx_tlast
#define result_tx_tvalid   sim->v->eth_top0->u_axi_10g_ethernet_0->s_axis_tx_tvalid

#define result_rx_tdata    sim->v->eth_top0->u_axi_10g_ethernet_0->m_axis_rx_tdata
#define result_rx_tkeep    sim->v->eth_top0->u_axi_10g_ethernet_0->m_axis_rx_tkeep
#define result_rx_tlast    sim->v->eth_top0->u_axi_10g_ethernet_0->m_axis_rx_tlast
#define result_rx_tvalid   sim->v->eth_top0->u_axi_10g_ethernet_0->m_axis_rx_tvalid

//static int debug = 1;

static uint64_t t = 0;


/*
 * tick: a tick
 */
static inline void tick(Vtestbench *sim, VerilatedVcdC *tfp)
{
	++t;
	sim->eval();
	tfp->dump(t);
}

/*
 * time_wait
 */
static inline void time_wait(Vtestbench *sim, VerilatedVcdC *tfp, uint32_t n)
{
	t += n;
	sim->eval();
	tfp->dump(t);
}

void pr_tx_tdata(Vtestbench *sim)
{
	uint8_t *p;
	int i;

	if (result_tx_tvalid) {
		printf("[TX] t=%u:", (uint32_t)t);
		p = (uint8_t *)&result_tx_tdata;
		for (i = 0; i < 8; i++) {
			printf(" %02X", *(p++));
		}
		printf("\n");
	}
}

void pr_tx_tlast(Vtestbench *sim)
{
	if (result_tx_tlast) {
		printf("\n");
	}
}

void pr_rx_tdata(Vtestbench *sim)
{
	uint8_t *p;
	int i;

	if (result_rx_tvalid) {
		printf("[RX] t=%u:", (uint32_t)t);
		p = (uint8_t *)&result_rx_tdata;
		for (i = 0; i < 8; i++) {
			printf(" %02X", *(p++));
		}
		printf("\n");
	}
}

void pr_rx_tlast(Vtestbench *sim)
{
	if (result_rx_tlast) {
		printf("\n");
	}
}

/*
 * main
 */
int main(int argc, char **argv)
{
	int ret;

	Verilated::commandArgs(argc, argv);
	Verilated::traceEverOn(true);

	VerilatedVcdC *tfp = new VerilatedVcdC;
	tfp->spTrace()->set_time_resolution(SIM_TIME_RESOLUTION);
	Vtestbench *sim = new Vtestbench;
	sim->trace(tfp, 99);
	tfp->open(WAVE_FILE_NAME);

	sim->pcie_clk = 0;
	sim->clk200 = 0;
	sim->SFP_CLK_P = 0;

	// debug
	while (!Verilated::gotFinish()) {
		if ((t % SFP_CLK) == 0) {
			sim->SFP_CLK_P = !sim->SFP_CLK_P;
			if (sim->SFP_CLK_P) {
				pr_tx_tdata(sim);
				pr_tx_tlast(sim);

				pr_rx_tdata(sim);
				pr_rx_tlast(sim);
			}
		}

		if ((t % PCIE_REF_CLK) == 0)
			sim->pcie_clk = !sim->pcie_clk;
		
		if ((t % SYS_CLK) == 0)
			sim->clk200 = !sim->clk200;

		if (t > SIM_TIME)
			break;

		tick(sim, tfp);
	}

	tfp->close();
	sim->final();

	return 0;
}

