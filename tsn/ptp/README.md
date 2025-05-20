# PTP

#### Introduction
Adapted from the XGE-PTPv2 project, it only supports 10M/1000M/1G/2.5G Ethernet.<br>
Modified the TSU module to only support GMII/MII interfaces, avoiding the inherent Octet Slide phenomenon caused by conversion to XGMII interfaces, improving timestamp accuracy while reducing resource utilization.<br>

#### Design Features

1. Built-in high-precision RTC supporting PPS output and PPS input
2. Fully supports both One-step Clock and Two-step Clock operating modes described in IEEE Std 1588-2008/2019 standards
3. Supports both Delay Request-Response mechanism and Peer Delay mechanism
4. Supports various encapsulation formats for IEEE1588v2 packets:
	- PTP over IEEE802.3/Ethernet (supports 802.1AS)
	- PTP over UDP IPv4/IPv6
	- No VLAN/Single VLAN/Double VLAN
5. Fully supports Transparent Clock hardware implementation (TC Hardware Offload)
6. Precise and efficient timestamp processing:
	- Timestamps are fixed at SFD position to ensure consistency and precision
	- Insert timestamps into PTP packets on-the-fly during transmission
	- Update packet CRC and IPv6 UDP Checksum on-the-fly during transmission
7. Uses GMII/MII interface, supports 10M/100M/1G/2.5G Ethernet

#### Usage Instructions

The root directory contains several subdirectories with the following contents:<br>
<blockquote>
esl: SystemC TLM platform and software design<br>
rtl: RTL design files<br>
tb: Testbench design files<br>
tc: Test case files<br>
sim: Simulation execution directory<br>
doc: Reference documents<br>
</blockquote>
<br>
RTL simulation is based on Linux OS using Icarus Verilog.<br>
Execute the following commands to run basic RTL function tests:<br>
<blockquote>
cd /path/to/sim<br>
./runcase.sh tc_rapid_ptp_test<br>
</blockquote>
<br>
If interested in software design or co-design, please read the esl directory.<br>
To run hardware-software co-simulation, execute the following commands:<br>
<blockquote>
cd /path/to/esl/solution <br>
mkdir build <br>
cd build <br>
cmake .. <br>
make <br>
./ptpv2_tlm<br> 
</blockquote>

This open source project focuses on establishing overall architecture design and open design processes. Currently, it ensures basic function testing passes.<br>
If readers intend to further develop on this basis, please modify it according to specific requirements and perform sufficient validation and testing.<br>

#### Integrating IP
When integrating PTP IP into a network system, please note the following:<br>
1. Place as close to PHY as possible, if placing IP in PHY, place near PCS layer
2. Use Full Duplex
3. To improve synchronization accuracy, disable any functions that may cause variable delay in the downstream direction of PTP IP (such as 802.3az)
4. RTC working clock frequency should be greater than or equal to data transfer clock frequency
5. Try to use SyncE recovered clock as RTC working clock to achieve highest synchronization accuracy

#### Disclaimer

This design can be freely used, and the author does not charge any fees.<br>
IEEE1588-2008/2019 standards and solutions involved in the design may contain patent claims from certain organizations or individuals, and the patent rights belong to the relevant owners.<br>
The author makes no commitments to the usage results and assumes no legal responsibility arising from its use.<br>
The user must be aware of and agree to the above disclaimer, otherwise do not use it.<br>

#### Follow Developer WeChat Official Account
If you need to understand the latest status of the project and join related technical discussions, please search for WeChat official account "时光之箭" or scan the QR code below:<br> 
![image](https://open.weixin.qq.com/qr/code?username=Arrow-of-Time-zd "时光之箭")