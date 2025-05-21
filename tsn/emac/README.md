# Ethernet MAC

### Introduction
Adapted from two open-source Ethernet MAC projects, which can be found at the following URLs:<br>
http://www.opencores.org/projects/ethmac/<br> 
http://www.opencores.org/projects.cgi/web/ethernet_tri_mode <br>

### Design Features

1. Performing MAC layer functions of IEEE 802.3 and Ethernet 
2. Half-duplex support for 10/100 Mbps mode
3. Full duplex support for 10/100/1000 Mbps mode
4. FIFO interface to user application
5. Support pause frame generation and termination
6. Automatic 32-bit CRC generation and checking
7. RMON MIB statistic counter
8. Combined IEEE 802.3 Gigabit Media Independent Interface/Media Independent Interface (GMII/MII)
9. Generic IP host interface

### User Guide

The subdirectories under the project root directory contain:<br>
<blockquote>
rtl: RTL design files<br>
tb: Testbench design files<br>
tc: Test case files<br>
sim: Simulation execution directory<br>
doc: Reference documents<br>
</blockquote>
<br>
RTL simulation is based on Linux OS using Icarus Verilog.<br>
Execute the following command to run basic RTL function tests:<br>
<blockquote>
cd /path/to/emac/sim<br>
./runsim<br>
</blockquote>
<br>
To change test cases, execute:<br>
<blockquote>
wish script/runcase.tcl<br>
</blockquote>
In the pop-up dialog box, you can select test case files and generate the simulation top file sim_emac.v.<br>
This method requires Tcl/Tk installation.<br>
If Tcl/Tk is not installed, you can directly edit sim_emac.v to change test cases.<br>
<br>
This open-source project focuses on overall architecture design and open source development processes. Currently, it ensures basic function tests pass.<br>
If you want to further develop based on this project, please modify it to meet specific requirements and conduct sufficient verification and testing.<br>

### Disclaimer

This design can be freely used without any fee.<br>
The solutions involved may contain patent claims from institutions or individuals, and the patent rights belong to the relevant owners.<br>
The author makes no commitments to the usage results and assumes no legal responsibility arising from it.<br>
Users should be aware and agree to these statements. If not agreed, please do not use it.<br>

### Follow Developer's Official Account
If you need to understand the latest project status and join technical discussions, search WeChat official account "时光之箭" or scan the QR code below:<br>
![image](https://open.weixin.qq.com/qr/code?username=Arrow-of-Time-zd "时光之箭")