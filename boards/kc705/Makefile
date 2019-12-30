project_name := nettlp-adapter
device_name := xc7k325t-2-ffg900

HW_SERVER := hw_server

build_dir := build
rtl_dir := rtl
test_dir := test
ip_dir := ip
tcl_dir := scripts
xdc_dir := constraints
cores_dir := ../../cores

PKG_SRC := \
	$(cores_dir)/pkg/endian_pkg.sv             \
	$(cores_dir)/pkg/utils_pkg.sv              \
	$(cores_dir)/pkg/ethernet_pkg.sv           \
	$(cores_dir)/pkg/ip_pkg.sv                 \
	$(cores_dir)/pkg/udp_pkg.sv                \
	$(cores_dir)/pkg/pcie_tlp_pkg.sv           \
	$(cores_dir)/pkg/pcie_tcap_pkg.sv          \
	$(cores_dir)/pkg/nettlp_pkg.sv

RTL_SRC := \
	$(cores_dir)/clk_sync/clk_sync.sv         \
	$(cores_dir)/clk_sync/clk_sync_ashot.sv   \
	$(rtl_dir)/eth/pcs_pma_conf.v                    \
	$(rtl_dir)/eth/eth_mac_conf.v                    \
	$(rtl_dir)/eth/eth_top.v                         \
	$(rtl_dir)/clock_control/clock_control.v         \
	$(rtl_dir)/clock_control/clock_control_program.v \
	$(rtl_dir)/clock_control/kcpsm6.v                \
	$(rtl_dir)/pcie/mybram.v                         \
	$(rtl_dir)/pcie/PIO.v                            \
	$(rtl_dir)/pcie/PIO_EP.v                         \
	$(rtl_dir)/pcie/mem_access.v                     \
	$(rtl_dir)/pcie/PIO_RX_ENGINE.v                  \
	$(rtl_dir)/pcie/PIO_TO_CTRL.v                    \
	$(rtl_dir)/pcie/PIO_TX_ENGINE.v                  \
	$(rtl_dir)/pcie/pcie_app_7x.v                    \
	$(rtl_dir)/pcie/pcie_7x_pipe_clock.v             \
	$(rtl_dir)/pcie/pcie_7x_support.v                \
	$(rtl_dir)/tlp_rx_snoop/tlp_rx_snoop.sv          \
	$(rtl_dir)/tlp_rx_snoop/pcie2fifo.sv             \
	$(rtl_dir)/tlp_rx_snoop/eth_encap.sv             \
	$(rtl_dir)/tlp_tx_inject/eth_decap.sv            \
	$(rtl_dir)/tlp_tx_inject/fifo2pcie.sv            \
	$(rtl_dir)/tlp_tx_inject/tlp_tx_mux.sv           \
	$(rtl_dir)/tlp_tx_inject/tlp_tx_inject.sv        \
	$(rtl_dir)/pcie_rx_filter.sv                     \
	$(rtl_dir)/top.v

XDC_SRC := \
	$(xdc_dir)/nettlp-kc705.xdc

TCL_SRC := \
	$(tcl_dir)/vivado_createprj.tcl  \
	$(tcl_dir)/vivado_synth.tcl      \
	$(tcl_dir)/vivado_place.tcl      \
	$(tcl_dir)/vivado_route.tcl      \
	$(tcl_dir)/vivado_bitstream.tcl

IP_SRC := \
	$(ip_dir)/ila_0/ila_0.xci                           \
	$(ip_dir)/pcie_afifo/pcie_afifo.xci                 \
	$(ip_dir)/eth_afifo/eth_afifo.xci                   \
	$(ip_dir)/axi_10g_ethernet_0/axi_10g_ethernet_0.xci \
	$(ip_dir)/pcie_7x/pcie_7x.xci

XCIS := $(addprefix $(build_dir)/,$(patsubst %.tcl,%.xci,$(IP_SRC)))
TARGET := $(build_dir)/$(project_name)

.PHONY: all
all: $(TARGET)

$(TARGET): $(XCIS) bitstream
	@echo "Done."

$(build_dir)/%.xci: %.tcl
	@if [ ! -e $(dir $@) ]; then mkdir -p $(dir $@); fi
	make -C $(dir $<)
	@cp $(patsubst %.tcl,%.xci,$<) $@

synth: post_syn.dcp
post_syn.dcp: 
	vivado -mode batch -source $(tcl_dir)/vivado_synth.tcl -log $(build_dir)/syn_log.txt -nojournal -tclargs $(project_name) $(build_dir) $(device_name) "$(PKG_SRC) $(RTL_SRC)" "$(XCIS)" "$(XDC_SRC)"

place: $(build_dir)/post_place.dcp
$(build_dir)/post_place.dcp: $(build_dir)/post_syn.dcp
	vivado -mode batch -source scripts/vivado_place.tcl -log $(build_dir)/place_log.txt -nojournal -tclargs $(project_name) $(build_dir)

route: $(build_dir)/post_route.dcp
$(build_dir)/post_route.dcp: $(build_dir)/post_place.dcp
	vivado -mode batch -source scripts/vivado_route.tcl -log $(build_dir)/route_log.txt -nojournal -tclargs $(project_name) $(build_dir)

bitstream: $(build_dir)/$(proj).bit
$(build_dir)/$(proj).bit: $(build_dir)/post_route.dcp
	vivado -mode batch -source scripts/vivado_bitstream.tcl -log $(build_dir)/bitstream_log.txt -nojournal -tclargs $(project_name) $(build_dir)

.PHONY: clean
clean:
	rm -f usage_statistics_webtalk.html usage_statistics_webtalk.xml
	rm -f fsm_encoding.os
	rm -rf build

