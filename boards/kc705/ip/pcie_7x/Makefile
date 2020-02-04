module_name := pcie_7x

build_dir := .srcs

XCI_SRC_GENERATED := .srcs/sources_1/ip/$(module_name)/$(module_name).xci

RTL_SRC += pcie_7x_example_design/pcie_7x_ex/imports/PIO.v
RTL_SRC += pcie_7x_example_design/pcie_7x_ex/imports/PIO_EP.v
RTL_SRC += pcie_7x_example_design/pcie_7x_ex/imports/PIO_RX_ENGINE.v
RTL_SRC += pcie_7x_example_design/pcie_7x_ex/imports/PIO_TO_CTRL.v
RTL_SRC += pcie_7x_example_design/pcie_7x_ex/imports/PIO_TX_ENGINE.v
RTL_SRC += pcie_7x_example_design/pcie_7x_ex/imports/pcie_app_7x.v
RTL_SRC += pcie_7x_example_design/pcie_7x_ex/imports/pcie_7x_pipe_clock.v
RTL_SRC += pcie_7x_example_design/pcie_7x_ex/imports/pcie_7x_support.v

all: clean
	vivado -mode batch -source $(module_name).tcl
	patch -p1 -d $(module_name)_example_design/$(module_name)_ex/imports < pcie_7x.patch
	test -e pcie_pio || mkdir pcie_pio
	cp -R $(RTL_SRC) pcie_pio/
	cp ${XCI_SRC_GENERATED} .

.PHONY: clean
clean:
	rm -f vivado.jou vivado.log
	rm -rf $(build_dir) .Xil
	rm -f $(module_name).xci
	rm -rf $(module_name)_example_design pcie_pio

