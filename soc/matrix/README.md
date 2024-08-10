# AXI4 Bus Matrix

#### Introduction
AXI4 bus matrix is used for interconnection between components within TSN-SoC. <br>

#### Features 

1.  Adopt a shared bus architecture to save resources.
2.  Using Round Robin arbitration to access the bus.
3.  Support bridging from AXI4 bus to a customized IPBus.

#### Instructions for Use

The contents of the subdirectories under the matrix directory are as follows: 
```
rtl:        RTL design files
tb:         Testbench design files
  |_bfm:    Bus functional model   
tc:         Test case files
sim:        Directory for simulation runs
doc:        Reference documentation
```

RTL simulation is based on Linux, and before using it, ensure that the following tools have been installed: 

* Icarus Verilog 
* Verilator 

Run the basic simulation using the following commands:
```
cd /path/to/matrix/sim 
make 
```
Run the following command, replacing the test case with tc_name
```
make TC=tc_name 
```
Refer to various test case files in the tc directory. Currently, there are test cases such as tc_m1s1, tc_m4s4, etc.

#### Disclaimer

This design can be freely used without any fees charged by the developer. <br>
The solutions involved in the design may implicitly involve some patent claims of organizations or individuals, and the patent rights belong to the relevant owners. <br>
The developer makes no commitment to the results of the use and assumes no legal responsibility arising from it. <br>
Users must be aware of and agree to the above statement. If you do not agree, please do not use it. <br>

#### Follow the Developer's Wechat Official Account
If you need to know the latest status of the project and participate in related technical discussions, please open WeChat and search for the official account "时光之箭" or scan the following QR code to follow the Developer's Wechat official account. <br>
![image](https://open.weixin.qq.com/qr/code?username=Arrow-of-Time-zd "时光之箭")



