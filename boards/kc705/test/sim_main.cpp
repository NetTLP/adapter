#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vtestbench.h"
//#include "verilated.h"

#define SFP_CLK               (64/2)        // 6.4 ns (156.25 MHz)
#define SYS_CLK               (50/2)        // 200 MHz
#define PCIE_REF_CLK          (100/2)       // 100 MHz

#define WAVE_FILE_NAME        "wave.vcd"
#define SIM_TIME_RESOLUTION   "100 ps"
#define SIM_TIME              100000       // 10 us

static uint64_t t = 0;

static inline void tick(Vtestbench *top, VerilatedVcdC *tfp)
{
	++t;
	top->eval();
	tfp->dump(t);
}


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

		if (t > SIM_TIME)
			break;

		tick(top, tfp);
	}

	delete top;
	exit(0);
}

