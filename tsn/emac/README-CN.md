# Ethernet MAC

#### 介绍
基于两个开源以太网MAC项目改编而来，这两个项目请参见以下网址：<br>
http://www.opencores.org/projects/ethmac/ <br>
http://www.opencores.org/projects.cgi/web/ethernet_tri_mode <br>

#### 设计特点 

1.  Performing MAC layer functions of IEEE 802.3 and Ethernet 
2.  Half-duplex support for 10/100 Mbps mode
3.  Full duplex support for 10/100/1000 Mbps mode
4.  FIFO interface to user application
5.  Support pause frame generation and termination
6.  Automatic 32-bit CRC generation and checking
7.  RMON MIB statistic counter
8.  Combined IEEE 802.3 Gigabit Media Independent Interface/Media Independent Interface (GMII/MII)
9.  Generic IP host interface

#### 使用说明

项目根目录下几个子目录的内容如下:<br>
<blockquote>
rtl: RTL设计文件<br>
tb: 测试平台设计文件<br>
tc: 测试用例文件<br>
sim: 仿真运行所在目录<br>
doc: 参考文档<br>
</blockquote>
<br>
RTL仿真基于Linux操作系统，使用Icarus Verilog完成。<br>
执行以下命令以运行基本的RTL功能测试：<br>
<blockquote>
cd /path/to/emac/sim<br>
./runsim<br>
</blockquote>
<br>
如果需要更换测试用例，执行以下命令：<br>
<blockquote>
wish script/runcase.tcl<br>
</blockquote>
在弹出的对话框中可以选择测试用例文件，并生成仿真的顶层文件sim_emac.v。<br>
上面产生测试顶层文件的方法需要安装Tcl/Tk。<br>
如果没有安装Tcl/Tk，也可以直接编辑sim_emac.v文件以更换测试用例文件。<br>
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



