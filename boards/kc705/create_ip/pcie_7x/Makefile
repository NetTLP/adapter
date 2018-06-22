build_dir := build

RTL_SRC := \
	pcie_7x_example_design/pcie_7x_ex/imports/mybram.v                  \
	pcie_7x_example_design/pcie_7x_ex/imports/PIO.v                     \
	pcie_7x_example_design/pcie_7x_ex/imports/PIO_EP.v                  \
	pcie_7x_example_design/pcie_7x_ex/imports/mem_access.v              \
	pcie_7x_example_design/pcie_7x_ex/imports/PIO_RX_ENGINE.v           \
	pcie_7x_example_design/pcie_7x_ex/imports/PIO_TO_CTRL.v             \
	pcie_7x_example_design/pcie_7x_ex/imports/PIO_TX_ENGINE.v           \
	pcie_7x_example_design/pcie_7x_ex/imports/pcie_app_7x.v             \
	pcie_7x_example_design/pcie_7x_ex/imports/pcie_7x_pipe_clock.v      \
	pcie_7x_example_design/pcie_7x_ex/imports/pcie_7x_support.v

XCI_SRC := \
	pcie_7x_example_design/pcie_7x_ex/pcie_7x_ex.srcs/sources_1/ip/pcie_7x/pcie_7x.xci

all: clean
	vivado -mode batch -source pcie_7x.tcl
	patch -p1 -d pcie_7x_example_design/pcie_7x_ex/imports < pcie_7x.patch
	test -e $(build_dir) || mkdir $(build_dir)
	test -e $(build_dir)/rtl || mkdir $(build_dir)/rtl
	test -e $(build_dir)/rtl/pcie || mkdir $(build_dir)/rtl/pcie
	cp $(RTL_SRC) $(build_dir)/rtl/pcie/
	test -e $(build_dir)/ip_catalog || mkdir $(build_dir)/ip_catalog
	test -e $(build_dir)/ip_catalog/pcie_7x || mkdir $(build_dir)/ip_catalog/pcie_7x
	cp $(XCI_SRC) $(build_dir)/ip_catalog/pcie_7x/

.PHONY: clean
clean:
	rm -f vivado.jou vivado.log
	rm -rf pcie_7x_example_design
	rm -rf $(build_dir)

