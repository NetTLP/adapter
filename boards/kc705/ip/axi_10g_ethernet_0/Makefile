module_name := axi_10g_ethernet_0

build_dir := .srcs

XCI_SRC_GENERATED := \
	.srcs/sources_1/ip/${module_name}/${module_name}.xci

all: clean
	vivado -mode batch -source ${module_name}.tcl
	cp ${XCI_SRC_GENERATED} .

.PHONY: clean
clean:
	rm -f vivado.jou vivado.log
	rm -rf ${build_dir} .Xil
	rm -f ${module_name}.xci
