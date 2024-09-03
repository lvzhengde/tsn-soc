# UART for TSN-SoC

#### Introduction

The UART core is designed based on the specification of Xilinx UART Macros. <br>
UART module can be configured as AXI Slave or AXI Master through external port. <br>
When configured in AXI Master mode, can access the processor's memory address space, thus serving as a debug bridge, and can download binary software code to memory also. <br>

#### Features 

1. Contains universal UART transmission and reception functions<br> 
    (1) One start bit<br>
    (2) 8 data bits, serial transmission and reception of data bits, can be set to LSB first or MSB first<br>
    (3) Parity bit can be set to none or yes.<br>
    (4) One stop bit<br>
    (5) Baud rate can be configured as needed<br>
2.  Can be used for mutual communication between chips, and is fully compatible with the standard UART communication protocol. 
3.  Can be configured as an AXI Slave, serving as a standard UART peripheral for the MCU.
4.  Can be configured as an AXI Master, serving as a debug bridge between the PC host and the MCU, and allowing for the download of executable programs into the MCU's memory space.
5.  Modular design.

####  Instructions for Use

The contents of the subdirectories under the uart directory are as follows: 
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
cd /path/to/uart/sim 
make 
```
Run the following command, replacing the test case with tc_name
```
make TC=tc_name 
(e.g. make TC=tc_aximst)
```
Refer to various test case files in the tc directory. Currently, there are test cases such as tc_slvh2d, tc_aximst, etc. <br>

####  Configuration

The register description refers to the uart_registers.v file in the rtl directory.<br>
Setting the uart_mst_i input port of uart_top.v to 1 will make the UART work in AXI Master mode.<br>


#### Disclaimer

This design can be freely used without any fees charged by the developer. <br>
The solutions involved in the design may implicitly involve some patent claims of organizations or individuals, and the patent rights belong to the relevant owners. <br>
The developer makes no commitment to the results of the use and assumes no legal responsibility arising from it. <br>
Users must be aware of and agree to the above statement. If you do not agree, please do not use it. <br>

#### Follow the Developer's Wechat Official Account
If you need to know the latest status of the project and participate in related technical discussions, please open WeChat and search for the official account "时光之箭" or scan the following QR code to follow the Developer's Wechat official account. <br>
![image](https://open.weixin.qq.com/qr/code?username=Arrow-of-Time-zd "时光之箭")
