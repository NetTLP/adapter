NetTLP adapter
==============

* Please see our web page for more details on how to use the NetTLP adapter.
  * URL: [https://haeena.dev/nettlp/](https://haeena.dev/nettlp/)
  
### Supported platforms

* Xilinx KC705 Eval board (EK-K7-KC705-G)
  - Xilinx vivado 19.2
  - Additional license: 10 Gigabit Ethernet Media Access Controller (10GEMAC)
  
### Install NetTLP Adapter

The bit file can be found at the [release page](https://github.com/NetTLP/adapter/releases).
This bit file is created with the evaluation version Ethernet-10G MAC license.
Therefore the adapter stops after one day.
Please reload the bit file to the FPGA board when the adapter stops. 

### How to build the nettlp-adapter.bit

```bash
$ git clone https://github.com/NetTLP/adapter.git

# we use the files created by Xilinx for the si5324 configurations.
# please download the rdf0285-vc709-connectivity-trd-2014-3.zip file from the Xilinx web page.
# you need a Xilinx account to download the zip file.
# URL: https://www.xilinx.com/products/boards-and-kits/dk-v7-vc709-g.html#documentation
$ unzip rdf0285-vc709-connectivity-trd-2014-3.zip
$ cp v7_xt_conn_trd/hardware/sources/hdl/clock_control/kcpsm6.v adapter/boards/kc705/rtl/clock_control/
$ cp v7_xt_conn_trd/hardware/sources/hdl/clock_control/clock_control.v adapter/boards/kc705/rtl/clock_control/
$ cp v7_xt_conn_trd/hardware/sources/hdl/clock_control/clock_control_program.v adapter/boards/kc705/rtl/clock_control/

$ source /tools/Xilinx/Vivado/2019.2/settings64.sh
$ cd adapter/boards/kc705
$ make
$ ls build/nettlp-adapter.bit
```
