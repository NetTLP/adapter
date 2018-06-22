proj = "kc705-tmpl"

sim_top := top_tb

rtl_dir := rtl
test_dir := test
ip_catalog_dir := ip_catalog
create_ip_dir := create_ip
tcl_dir := scripts
xdc_dir := constraints
cores_dir := cores

PKG_SRC := \
	cores/pkg/endian_pkg.sv             \
	cores/pkg/utils_pkg.sv              \
	cores/pkg/ethernet_pkg.sv           \
	cores/pkg/ip_pkg.sv                 \
	cores/pkg/udp_pkg.sv                \
	cores/pkg/pcie_tlp_pkg.sv           \
	cores/pkg/pcie_tcap_pkg.sv          \
	cores/pkg/nettlp_pkg.sv

RTL_SRC_NOSIM := \
	rtl/clock_control/clock_control.v         \
	rtl/clock_control/clock_control_program.v \
	rtl/clock_control/kcpsm6.v

RTL_SRC := \
	cores/clk_sync/clk_sync.sv                \
	cores/clk_sync/clk_sync_ashot.sv          \
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
	rtl/top.v

RTL_SRC_IPGEN := \
	rtl/pcie/mybram.v                         \
	rtl/pcie/PIO.v                            \
	rtl/pcie/PIO_EP.v                         \
	rtl/pcie/mem_access.v                     \
	rtl/pcie/PIO_RX_ENGINE.v                  \
	rtl/pcie/PIO_TO_CTRL.v                    \
	rtl/pcie/PIO_TX_ENGINE.v                  \
	rtl/pcie/pcie_app_7x.v                    \
	rtl/pcie/pcie_7x_pipe_clock.v             \
	rtl/pcie/pcie_7x_support.v


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

IP_SRC_IPGEN := \
	ip_catalog/pcie_7x/pcie_7x.xci

CREATE_IP_SRC := \
	create_ip/pcie_7x/Makefile         \
	create_ip/pcie_7x/pcie_7x.tcl      \
	create_ip/pcie_7x/pcie_7x.patch    \

HW_SERVER := hw_server

all: bitstream

generate_ipsrcs:
	make -C $(create_ip_dir)/pcie_7x
	cp -R $(create_ip_dir)/pcie_7x/build ..

build_setup: generate_ipsrcs $(rtl_dir) $(test_dir) $(ip_catalog_dir) $(create_ip_dir) $(tcl_dir) $(xdc_dir) $(cores_dir)

prj: $(proj).xpr
$(proj).xpr: build_setup
	vivado -mode batch -source scripts/vivado_createprj.tcl -log createprj_log.txt -nojournal -tclargs "$(PKG_SRC) $(RTL_SRC_NOSIM) $(RTL_SRC_IPGEN) $(RTL_SRC)" "$(IP_SRC) $(IP_SRC_IPGEN)" "$(XDC_SRC)"

synth: post_syn.dcp
post_syn.dcp: build_setup
	vivado -mode batch -source scripts/vivado_synth.tcl -log syn_log.txt -nojournal -tclargs "$(PKG_SRC) $(RTL_SRC_NOSIM) $(RTL_SRC_IPGEN) $(RTL_SRC)" "$(IP_SRC) $(IP_SRC_IPGEN)" "$(XDC_SRC)"

place: post_place.dcp
post_place.dcp: post_syn.dcp
	vivado -mode batch -source scripts/vivado_place.tcl -log place_log.txt -nojournal

route: post_route.dcp
post_route.dcp: post_place.dcp
	vivado -mode batch -source scripts/vivado_route.tcl -log route_log.txt -nojournal

bitstream: $(proj).bit
$(proj).bit: post_route.dcp
	vivado -mode batch -source scripts/vivado_bitstream.tcl -log bitstream_log.txt -nojournal

program: $(proj).bit $(HW_SERVER)
	vivado -mode batch -source scripts/vivado_program.tcl -log program_log.txt -nojournal -tclargs "`cat $(HW_SERVER)`"

load: $(proj).bit
	./script/xprog.sh load $(proj).bit

ila:
	test -e csv || mkdir csv 
	vivado -mode batch -source scripts/vivado_ila.tcl -tclargs "`cat $(HW_SERVER)`"

ila2:
	test -e csv || mkdir csv 
	vivado -mode batch -source scripts/vivado_ila2.tcl -tclargs "`cat $(HW_SERVER)`"

xsim: build_setup test/run.tcl $(SIMTOP_SRC) $(PKG_SRC) $(SIMTOP_SRC) $(SIM_SRC) $(RTL_SRC)
	xvlog -log xvlog.log -sv $(SIMTOP_SRC) $(PKG_SRC) $(SIM_SRC) $(RTL_SRC) $(XSIM_SRC)
	xelab -log xelab.log -L xil_defaultlib -L unisims_ver $(sim_top) glbl -s $(sim_top)_sim -debug all
	xsim -log xsim.log $(sim_top)_sim -t test/run.tcl

synth-clean:
	rm -f fsm_encoding.os usage_stat*
	rm -rf .Xil .srcs
	rm -rf *.jou *.log *.mif *.hw  *.ip_user_files *.cache  *.sim *.runs *.srcs

sim-clean:
	rm -rf webtalk* xelab* xsim* xvlog* xvhdl* xsc* *.wdb
	rm -f wave.vcd
	rm -rf obj_dir

.PHONY: clean load
clean: sim-clean synth-clean

.PHONY: distclean
distclean:
	git clean -Xdf

