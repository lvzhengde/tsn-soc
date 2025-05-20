# 基于SystemC TLM平台的PTPv2软件设计
协议软件部分改编自开源项目ptpd，该项目基本按照IEEE 1588-2008标准设计。<br>
如果需要支持IEEE 802.1AS-2020的协议软件，请自行按照该标准设计软件。<br>
至于硬件逻辑部分，IEEE 1588-2019/2018以及作为PTPv2标准的一个profile的IEEE 802.1AS均能完美支持， 不同之处仅在软件。<br>

#### 使用说明
设计和测试均基于Linux操作系统，需要安装Verilator，SystemC，以及CMake。<br>
CMake可以直接使用Linux自带的软件包管理工具安装，而Verilator，SystemC的具体安装方法，可以参考其官方网站或者本项目开发者的公众号文章。<br>
<br>
运行仿真，请执行以下步骤：<br>
>cd /path/to/solution <br>
>rm -rf build && mkdir build && cd build <br>
>cmake .. <br>
>make <br> 
>./ptpv2_tlm <br>
<br>
如果需要调试程序，则可以安装Visual Studio Code并打开ESL项目所在目录ptp/esl。<br>
<br>
具体仿真测试的使用方法请参考以下文档：<br>
 /path/to/ptp/esl/doc/设计及测试说明.pdf<br>
<br>
在SyncE状态下，仿真测试表明协议算法运行不到1秒就可以让PTP Slave和PTP Master达到高精度时间频率同步状态。<br>
在非SyncE状态下，仿真测试结果显示，Protocol及Clock Servo算法运行15秒左右便可以让PTP Slave和PTP Master达到时间及频率同步状态。<br>
至于仿真运行时间，在开发者自己的电脑上，运行SyncE仿真测试大约需要二十几分钟，运行非SyncE仿真测试则需要六个小时以上。<br>

#### 免责声明

本设计可以自由使用，作者不索取任何费用。<br>
IEEE1588-2008/2019标准以及设计中涉及到的解决方案可能隐含有一些机构或者个人的专利诉求， 则专利权属于相关的所有者。<br>
作者对使用结果不做任何承诺也不承担其产生的任何法律责任。<br>
使用者须知晓并同意上述声明，如不同意则不要使用。<br>

#### 关注开发者公众号
如果需要了解项目最新状态和加入相关技术探讨，请打开微信搜索公众号"时光之箭"或者扫描以下二维码关注开发者公众号。<br>
![image](https://open.weixin.qq.com/qr/code?username=Arrow-of-Time-zd "时光之箭")



