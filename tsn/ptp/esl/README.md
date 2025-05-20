# PTPv2 Software Design Based on SystemC TLM Platform
The protocol software part is adapted from the open source project ptpd, which basically follows IEEE 1588-2008 standard.<br>
If you need to support IEEE 802.1AS-2020 protocol software, please design the software according to that standard.<br>
As for the hardware logic part, both IEEE 1588-2019/2018 and IEEE 802.1AS (as a profile of PTPv2 standard) are fully supported, with differences only in software.<br>

#### Usage Instructions
Design and testing are based on Linux OS, requiring installation of Verilator, SystemC, and CMake.<br>
CMake can be directly installed using Linux's built-in package manager, while Verilator and SystemC installation methods can refer to their official websites or the developer's official WeChat account articles.<br>

To run simulations, please follow these steps:<br>
>cd /path/to/solution<br> 
>rm -rf build && mkdir build && cd build<br> 
>cmake ..<br> 
>make <br>
>./ptpv2_tlm <br>
<br>
If you need to debug the program, you can install Visual Studio Code and open the ESL project directory ptp/esl.<br>
<br>
For specific simulation test usage methods, please refer to the following document:
/path/to/ptp/esl/doc/Design-Testing-Description.pdf<br>
<br>
In SyncE state, simulation tests show that the protocol algorithm can make PTP Slave and PTP Master achieve high-precision time and frequency synchronization within less than 1 second.<br>
In non-SyncE state, simulation results show that after running Protocol and Clock Servo algorithms for about 15 seconds, PTP Slave and PTP Master can achieve time and frequency synchronization.<br>
As for simulation runtime, on the developer's own computer, running SyncE simulation takes about twenty minutes, while non-SyncE simulation requires more than six hours.<br>

#### Disclaimer

This design can be freely used without any fees from the author.<br>
IEEE1588-2008/2019 standards and solutions involved in the design may contain patent claims from certain organizations or individuals, and the patent rights belong to the relevant owners.<br>
The author makes no commitments to the usage results and assumes no legal responsibility arising from its use.<br>
The user must be aware of and agree to the above disclaimer, otherwise do not use it.<br>

#### Follow Developer Official Account
If you need to understand the latest status of the project and join related technical discussions, please search for WeChat official account "时光之箭" or scan the QR code below:<br>
![image](https://open.weixin.qq.com/qr/code?username=Arrow-of-Time-zd "时光之箭")