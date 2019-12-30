proj = "kc705-tmpl"

sim_top := top_tb

build_dir := build
rtl_dir := rtl
test_dir := test
ip_catalog_dir := ip_catalog
create_ip_dir := create_ip
tcl_dir := scripts
xdc_dir := constraints
cores_dir := cores

PKG_SRC := \
	../../cores/pkg/endian_pkg.sv             \
	../../cores/pkg/utils_pkg.sv              \
	../../cores/pkg/ethernet_pkg.sv           \
	../../cores/pkg/ip_pkg.sv                 \
	../../cores/pkg/udp_pkg.sv                \
	../../cores/pkg/pcie_tlp_pkg.sv           \
	../../cores/pkg/pcie_tcap_pkg.sv          \
	../../cores/pkg/nettlp_pkg.sv

RTL_SRC_NOSIM := \
	rtl/clock_control/clock_control.v         \
	rtl/clock_control/clock_control_program.v \
	rtl/clock_control/kcpsm6.v

RTL_SRC := \
	../../cores/clk_sync/clk_sync.sv          \
	../../cores/clk_sync/clk_sync_ashot.sv    \
	rtl/eth/pcs_pma_conf.v                    \
	rtl/eth/eth_mac_conf.v                    \
	rtl/eth/eth_top.v                         \
	rtl/tlp_rx_snoop/tlp_rx_snoop.sv          \
	rtl/tlp_rx_snoop/pcie2fifo.sv             \
	rtl/tlp_rx_snoop/eth_encap.sv             \
	rtl/tlp_tx_inject/eth_decap.sv            \
	rtl/tlp_tx_inject/fifo2pcie.sv            \
	rtl/tlp_tx_inject/tlp_tx_mux.sv           \
	rtl/tlp_tx_inject/tlp_tx_inject.sv        \
	rtl/pcie_rx_filter.sv                     \
	rtl/top.v

IPGEN_SRC := \
	rtl/pcie/mybram.v                         \
	rtl/pcie/PIO.v                            \
	rtl/pcie/PIO_EP.v                         \
	rtl/pcie/mem_access.v                     \
	rtl/pcie/PIO_RX_ENGINE.v                  \
	rtl/pcie/PIO_TO_CTRL.v                    \
	rtl/pcie/PIO_TX_ENGINE.v                  \
	rtl/pcie/pcie_app_7x.v                    \
	rtl/pcie/support/pcie_7x_pipe_clock.v     \
	rtl/pcie/support/pcie_7x_support.v


SIMTOP_SRC := test/top_tb.sv

SIM_SRC := \
	test/glbl.v                               \
	test/pcie_7x_support.v                    \
	test/graycounter.v                        \
	test/asfifo.v                             \
	test/pcie_fifo.sv                         \
	test/pcie_afifo.sv                        \
	test/axi_10g_ethernet_0.sv                \
	test/clock_control.sv                     \
	test/host/host_pio_reboot.sv              \
	test/ila_0.sv                             \
	test/device/device_eth.sv                 \
	test/eth_afifo.sv

VERILATOR_SRC := test/sim_main.cpp

XDC_SRC := \
	constraints/nettlp-kc705.xdc

TCL_SRC := \
	scripts/vivado_createprj.tcl  \
	scripts/vivado_synth.tcl      \
	scripts/vivado_place.tcl      \
	scripts/vivado_route.tcl      \
	scripts/vivado_bitstream.tcl

IP_SRC := \
	ip_catalog/ila_0/ila_0.xci                           \
	ip_catalog/pcie_afifo/pcie_afifo.xci                 \
	ip_catalog/eth_afifo/eth_afifo.xci                   \
	ip_catalog/axi_10g_ethernet_0/axi_10g_ethernet_0.xci

CREATE_IP_SRC := \
	create_ip/pcie_7x/Makefile         \
	create_ip/pcie_7x/pcie_7x.tcl      \
	create_ip/pcie_7x/pcie_7x.patch

HW_SERVER := hw_server

#all: bitstream
all: build_setup

$(build_dir):
	mkdir $(build_dir)

$(HW_SERVER): $(build_dir)
	echo 'localhost' > $(build_dir)/hw_server

$(build_dir)/$(rtl_dir): $(build_Dir) $(RTL_SRC_NOSIM) $(RTL_SRC)
	cp -R $(rtl_dir) $(build_dir)

$(build_dir)/$(test_dir): $(build_Dir) $(SIM_SRC)
	cp -R $(test_dir) $(build_dir)

$(build_dir)/$(ip_catalog_dir): $(build_Dir) $(IP_SRC)
	cp -R $(ip_catalog_dir) $(build_dir)

$(build_dir)/$(create_ip_dir): $(build_Dir) $(CREATE_IP_SRC)
	cp -R $(create_ip_dir) $(build_dir)

$(build_dir)/$(tcl_dir): $(build_Dir) $(TCL_SRC)
	cp -R $(tcl_dir) $(build_dir)

$(build_dir)/$(xdc_dir): $(build_Dir) $(XDC_SRC)
	cp -R $(xdc_dir) $(build_dir)

$(build_dir)/$(cores_dir): $(build_Dir) $(PKG_SRC)
	cp -R ../../$(cores_dir) $(build_dir)

build_setup: $(build_dir) $(build_dir)/$(rtl_dir) $(build_dir)/$(test_dir) $(build_dir)/$(ip_catalog_dir) $(build_dir)/$(create_ip_dir) $(build_dir)/$(tcl_dir) $(build_dir)/$(xdc_dir) $(build_dir)/$(cores_dir)
	cp Makefile.Build $(build_dir)/Makefile

.PHONY: clean
clean:
	rm -rf build

.PHONY: distclean
distclean:
	git clean -Xdf

