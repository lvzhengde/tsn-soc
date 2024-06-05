# 32-bit Superscalar Dual Issue RISC-V CPU Core

#### Introduction
This project is adapted from the open-source project biRISC-V. Please refer to the following website for biRISC-V: <br>
Github: http://github.com/ultraembedded/biriscv <br>

#### Features 

1.  32-bit RISC-V ISA CPU core. 
2.  Superscalar (dual-issue) in-order 6 or 7 stage pipeline.
3.  Support RISC-V’s integer (I), multiplication and division (M), and CSR instructions (Z) extensions (RV32IMZicsr).
4.  Branch prediction (bimodel/gshare) with configurable depth branch target buffer (BTB) and return address stack (RAS).
5.  64-bit instruction fetch, 32-bit data access.
6.  2 x integer ALU (arithmetic, shifters and branch units).
7.  1 x load store unit, 1 x out-of-pipeline divider.
8.  Issue and complete up to 2 independent instructions per cycle.
9.  Supports user, supervisor and machine mode privilege levels.
11. Basic MMU support - capable of booting Linux with atomics (RV-A) SW emulation.
12. Support for instruction / data cache, AXI bus interfaces or tightly coupled memories.
13. Support JTAG debug module.

#### Instructions for Use

The contents of the subdirectories under the riscv directory are as follows: <br>
<blockquote>
rtl:    RTL design files<br>
tb:     Testbench design files<br>
tc:     Test case files<br>
sim:    Directory for simulation runs<br>
doc:    Reference documentation<br>
</blockquote>
<br>
RTL simulation is based on Linux, and before using it, ensure that the following tools have been installed: 

* Icarus Verilog 
* Verilator 
* riscv-gnu-toolchain 
* CMake 
* Python 

Better to use the latest verision that can work properly. 
<br>
For different parts of the design, different simulation tests need to be run. <br>
1. Basic function test
```
cd /path/to/riscv/sim/core_icarus 
make 
```

2. RISC-V compliance test
```
cd /path/to/riscv/sim/riscv-compliance 
python3 riscv_compliance_test.py 
```

3. Test for C language SW development using riscv-gnu-toolchain
```
cd /path/to/riscv/sim/c_demo 
python3 run_demo.py 
```

4. Test for RISC-V system with TCM option
```
cd /path/to/riscv/sim/tcm_verilator 
python3 run_tcm_verilator.py 
```

5. Test for RISC-V system with cache option
```
cd /path/to/riscv/sim/cache_verilator 
python3 run_cache_verilator.py 
```

6. Test for RISC-V JTAG debug module
```
cd /path/to/riscv/sim/jtag_verilator 
python3 run_jtag_verilator.py 
```


##### FAQ

If encounter an error similar to the following when running a Verilator program with CMake: 
```
CMake Error at CMakeLists.txt:46 (target_link_libraries):
  The keyword signature for target_link_libraries has already been used with
  the target "example".  All uses of target_link_libraries with a target must
  be either all-keyword or all-plain.

  The uses of the keyword signature are here:

   \* /usr/local/share/verilator/verilator-config.cmake:341 (target_link_libraries)
```

Open the corresponding file through the following command: 
```
$ sudo vim /usr/local/share/verilator/verilator-config.cmake 
```

Locate the relevant "target_link_libraries" line and comment it out.<br>
<br>
This project basically focuses on the overall architecture design and the establishment of open-source design processes. <br>
Currently, it is enough to ensure that basic function tests pass for developer. <br>
If readers intend to further develop based on this, please make modifications accordingly to make its functions meet specific needs and ensure sufficient verification and testing. <br>

#### Disclaimer

This design can be freely used without any fees charged by the developer. <br>
The solutions involved in the design may implicitly involve some patent claims of organizations or individuals, and the patent rights belong to the relevant owners. <br>
The developer makes no commitment to the results of the use and assumes no legal responsibility arising from it. <br>
Users must be aware of and agree to the above statement. If you do not agree, please do not use it. <br>

#### Follow the Developer's Wechat Official Accountp
If you need to know the latest status of the project and participate in related technical discussions, please open WeChat and search for the official account "时光之箭" or scan the following QR code to follow the Developer's Wechat official account. <br>
![image](https://open.weixin.qq.com/qr/code?username=Arrow-of-Time-zd "时光之箭")



