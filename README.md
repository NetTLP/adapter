NetTLP adapter
==============

* Xilinx vivado 19.2
* Xilinx KC705 Eval board (EK-K7-KC705-G)

### Install NetTLP Adapter

The bit file can be found at the [release page](https://github.com/NetTLP/adapter/releases).
 

### How to build the nettlp-adapter.bit

```bash
$ git clone https://github.com/NetTLP/adapter.git

# please download the rdf0285-vc709-connectivity-trd-2014-3.zip from Xilinx web site.
$ unzip rdf0285-vc709-connectivity-trd-2014-3.zip
$ cp v7_xt_conn_trd/hardware/sources/hdl/clock_control/kcpsm6.v adapter/boards/kc705/rtl/clock_control/
$ cp v7_xt_conn_trd/hardware/sources/hdl/clock_control/clock_control.v adapter/boards/kc705/rtl/clock_control/
$ cp v7_xt_conn_trd/hardware/sources/hdl/clock_control/clock_control_program.v adapter/boards/kc705/rtl/clock_control/

$ source /tools/Xilinx/Vivado/2019.2/settings64.sh
$ cd adapter/boards/kc705
$ make
```
