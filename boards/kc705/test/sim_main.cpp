#include "Vtestbench.h"
#include "verilated.h"

#define QSFP28_CLK            (32/2)        // 3.2 ns (about 322 MHz)
#define SYS_CLK               (34/2)        // 3.4 ns (300 MHz)
#define PCIE_REF_CLK          (40/2)        // 4 ns (250 MHz)

#define WAVE_FILE_NAME        "wave.vcd"
#define SIM_TIME_RESOLUTION   "100 ps"
#define SIM_TIME              1000000       // 100 us

static uint64_t t = 0;

static inline void tick(Vtestbench *sim, VerilatedVcdC *tfp)
{
	++t;
	sim->eval();
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

	top->QSFP0_CLOCK_P = 0;
	top->QSFP0_CLOCK_N = 1;

	top->SYSCLK0_300_P = 0;
	top->SYSCLK0_300_N = 1;

	top->PCIE_CLK_P = 0;
	top->PCIE_CLK_N = 1;
	top->PCIE_RESET_N = 1;

	while(!Verilated::gotFinish()) {
		// QSFP28
		if ((t % QSFP28_CLK) == 0) {
			sim->QSFP0_CLOCK_P = ~sim->QSFP0_CLOCK_P;
			sim->QSFP0_CLOCK_N = ~sim->QSFP0_CLOCK_N;
		}

		// SYSCLK
		if ((t % SYS_CLK) == 0) {
			sim->SYSCLK0_300_P = ~sim->SYSCLK0_300_P;
			sim->SYSCLK0_300_N = ~sim->SYSCLK0_300_N;
		}

		// PCIE_REF_CLK
		if ((t % PCIE_REF_CLK) == 0) {
			sim->PCIE_CLK_P = ~sim->PCIE_CLK_P;
			sim->PCIE_CLK_N = ~sim->PCIE_CLK_N;
		}

		if (t > SIM_TIME)
			break;

		tick(sim, tfp);
	}
	delete top;
	exit(0);
}

