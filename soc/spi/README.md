# SPI for TSN-SoC

#### Introduction

The SPI Core is designed based on Xilinx's "LogiCORE IP AXI Quad Serial Peripheral Interface" specification, but only supports standard SPI functionality and master mode only. <br>
SPI Core supports XIP (eXecute In Place) mode and Non-XIP mode, XIP mode is selected automatically through address decoding. <br>

#### Features 

1. Programmable SPI clock phase and polarity. 
2. Configurable Slave Select (SS) lines on the SPI bus. 
3. Configurable FIFO depth.
4. Connects as a 32-bit slave on  AXI4 memory mapped interface.
5. Read only XIP mode, Support the reading and execution of program startup code.
6. Enhanced non-XIP mode of operation.

####  Instructions for Use

The contents of the subdirectories under the spi directory are as follows: 
```
rtl:        RTL design files
tb:         Testbench design files
tc:         Test case files
sim:        Directory for simulation runs
doc:        Reference documentation
```

RTL simulation is based on Linux, and before using it, ensure that the following tools have been installed: 

* Icarus Verilog 
* Verilator 

Run the basic simulation using the following commands:
```
cd /path/to/spi/sim 
make 
```
Run the following command, replacing the test case with tc_name
```
make TC=tc_name 
(e.g. make TC=tc_xip03n)
```
Refer to various test case files in the tc directory. Currently, there are test cases such as tc_regraw, tc_xip03n, etc. <br>

####  Configuration

The register description refers to the spi_registers.v file in the rtl directory.<br>
The following address decoding statements in rtl/spi_top.v determine whether the current access is in XIP mode: <br>
    wire  xip_sel_w  = ((bus2ip_addr_w & `SPI_ADDR_MASK) == `SPI_FLASH_BASEADDR);

#### Disclaimer

This design can be freely used without any fees charged by the developer. <br>
The solutions involved in the design may implicitly involve some patent claims of organizations or individuals, and the patent rights belong to the relevant owners. <br>
The developer makes no commitment to the results of the use and assumes no legal responsibility arising from it. <br>
Users must be aware of and agree to the above statement. If you do not agree, please do not use it. <br>

#### Follow the Developer's Wechat Official Account
If you need to know the latest status of the project and participate in related technical discussions, please open WeChat and search for the official account "时光之箭" or scan the following QR code to follow the Developer's Wechat official account. <br>
![image](https://open.weixin.qq.com/qr/code?username=Arrow-of-Time-zd "时光之箭")
