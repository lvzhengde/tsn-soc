# 32-bit Superscalar Dual Issue RISC-V CPU Core

#### 介绍
本项目基于开源项目biRISC-V改编而来，biRISC-V请参见以下网址：<br>
Github: http://github.com/ultraembedded/biriscv <br>

#### 设计特点 

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

#### 使用说明

riscv目录下面几个子目录的内容如下:<br>
<blockquote>
rtl: RTL设计文件<br>
tb: 测试平台设计文件<br>
tc: 测试用例文件<br>
sim: 仿真运行所在目录<br>
doc: 参考文档<br>
</blockquote>
<br>
<br>
RTL仿真基于Linux操作系统，在使用之前，需要保证以下工具都已安装： <br>
* Icarus Verilog <br>
* Verilator <br>
* riscv-gnu-toolchain <br>
* CMake <br>
* Python <br>
工具版本最好是最新能用的。<br>
<br>
<br>
针对不同的设计内容，需要运行不同的仿真测试。<br>
1. 基本功能测试
<blockquote>
cd /path/to/riscv/sim/core_icarus <br>
make <br>
</blockquote>
<br>
2. RISC-V指令一致性测试
<blockquote>
cd /path/to/riscv/sim/riscv-compliance <br>
python3 riscv_compliance_test.py <br>
</blockquote>
<br>
3. 针对C语言的RISC-V软件开发工具链测试
<blockquote>
cd /path/to/riscv/sim/c_demo <br>
python3 run_demo.py <br>
</blockquote>
<br>
4. 使用TCM的RISC-V系统测试
<blockquote>
cd /path/to/riscv/sim/tcm_verilator <br>
python3 run_tcm_verilator.py <br>
</blockquote>
<br>
5. 使用cache的RISC-V系统测试
<blockquote>
cd /path/to/riscv/sim/cache_verilator <br>
python3 run_cache_verilator.py <br>
</blockquote>
<br>
6. RISC-V JTAG调试模块测试
<blockquote>
cd /path/to/riscv/sim/jtag_verilator <br>
python3 run_jtag_verilator.py <br>
</blockquote>
<br>
<br>
##### FAQ
如果在使用CMake运行Verilator程序时碰到类似下面的错误：<br>
<blockquote>
"""
CMake Error at CMakeLists.txt:46 (target_link_libraries):
  The keyword signature for target_link_libraries has already been used with
  the target "example".  All uses of target_link_libraries with a target must
  be either all-keyword or all-plain.

  The uses of the keyword signature are here:

   \* /usr/local/share/verilator/verilator-config.cmake:341 (target_link_libraries)
"""
</blockquote>
则使用下面的命令打开对应文件 <br>
$ sudo vim /usr/local/share/verilator/verilator-config.cmake <br>
定位到相关的"target_link_libraries" 行，并将其注释掉就可以了。<br>
<br>
<br>
本开源项目着重于整体架构设计和开源设计流程的建立，目前情况下，保证基本功能测试通过即可。<br>
如果读者有意在此基础上进一步开发，请自行进行修改，使其功能符合特定需求并得到充分的验证和测试。<br>

#### 免责声明

本设计可以自由使用，作者不索取任何费用。<br>
设计中涉及到的解决方案可能隐含有一些机构或者个人的专利诉求， 则专利权属于相关的所有者。<br>
作者对使用结果不做任何承诺也不承担其产生的任何法律责任。<br>
使用者须知晓并同意上述声明，如不同意则不要使用。<br>

#### 关注开发者公众号
如果需要了解项目最新状态和加入相关技术探讨，请打开微信搜索公众号"时光之箭"或者扫描以下二维码关注开发者公众号。<br>
![image](https://open.weixin.qq.com/qr/code?username=Arrow-of-Time-zd "时光之箭")



