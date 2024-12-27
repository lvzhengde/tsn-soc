# SDRAM Controller for TSN-SoC

#### Introduction

This IP core is a simple, lightweight SDRAM controller designed to interface an external 16-bit SDRAM chip through a 32-bit AXI-4 bus. <br>
When accessing open rows, reads and writes can be pipelined to achieve full SDRAM bus utilization, however switching between reads & writes takes a few cycles.<br>
The row management strategy is to leave active rows open until a row needs to be closed for a periodic auto refresh or until that bank needs to open another row due to a read or write request.<br>
This IP supports supports 4 open active rows (one per bank).<br>

#### Features 

1. AXI4-Slave supporting FIXED, INCR and WRAP bursts. 
2. Support for 16-bit SDRAM parts.

####  Instructions for Use

The contents of the subdirectories under the sdram directory are as follows: 
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
cd /path/to/sdram/sim 
make 
```
Run the following command, replacing the test case with tc_name
```
make TC=tc_name 
(e.g. make TC=tc_simple)
```
Refer to various test case files in the tc directory. 

#### Disclaimer

This design can be freely used without any fees charged by the developer. <br>
The solutions involved in the design may implicitly involve some patent claims of organizations or individuals, and the patent rights belong to the relevant owners. <br>
The developer makes no commitment to the results of the use and assumes no legal responsibility arising from it. <br>
Users must be aware of and agree to the above statement. If you do not agree, please do not use it. <br>

#### Follow the Developer's Wechat Official Account
If you need to know the latest status of the project and participate in related technical discussions, please open WeChat and search for the official account "时光之箭" or scan the following QR code to follow the Developer's Wechat official account. <br>
![image](https://open.weixin.qq.com/qr/code?username=Arrow-of-Time-zd "时光之箭")
