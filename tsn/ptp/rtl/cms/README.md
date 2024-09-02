# Common Services Hardware Offload
主要针对IEEE std 802.1AS-2020 Common Services的硬件加速，主要功能包括以下两部分：<br>
1. Peer delay机制的硬件加速，即Common Mean Link Delay Service(CMLDS)的硬件加速。<br>
2. 接收Sync以及Follow_Up报文，自动调节RTC，即Clock Servo的硬件加速。<br>

#### 设计说明
CMLDS Hardware Offload<br>
1. 定时自动发送Pdelay_Req消息，获得t1。<br>
2. 接收Pdelay_Req消息，根据配置发送Pdelay_Resp及Pdelay_Resp_Follow_Up消息。<br>
3. 接收Pdelay_Resp消息，得到t2，或者t3-t2，获取t4。<br>
4. 接收Pdeley_Resp_Follow_Up消息，得到t3。<br>
5. 对接收到的Peer delay消息设置出错信息（RX_ER置为1），由上层处理机制丢弃。<br>
6. 根据t1，t2，t3，或者t3-t2，t4，计算得到link delay。<br>

Clock Servo Hardware Offload<br>
1. 接收Sync报文以及Follow_Up报文，得到t_ms，合并上面得到的link delay，可以计算得到offsetFromMaster<br>
2. 根据offsetFromMaster信息，驱动Clock Servo，调节本地RTC，使之和Grandmaster同步。<br>
3. 根据配置，可以对接收到的Sync报文设置出错信息（RX_ER=1），交由上层处理机制丢弃。<br>
<br>
<br>
CMS模块位于GMII_CVT模块和TSU模块之间，统一使用GMII格式处理。<br>
报文发送采取仲裁机制，优先级高的先发送，正在发送的报文不被抢占中断。<br>
CMS模块发送报文时提供反压信号，抑制上层模块的报文发送。<br>
可以通过外部输入的控制信号，让CMS模块在规定的时间间歇发送报文，符合IEEE std 802.1Q流量控制的相关规定。<br>


#### 免责声明

本设计可以自由使用，作者不索取任何费用。<br>
IEEE1588-2008/2019标准以及设计中涉及到的解决方案可能隐含有一些机构或者个人的专利诉求， 则专利权属于相关的所有者。<br>
作者对使用结果不做任何承诺也不承担其产生的任何法律责任。<br>
使用者须知晓并同意上述声明，如不同意则不要使用。<br>

#### 关注开发者公众号
如果需要了解项目最新状态和加入相关技术探讨，请打开微信搜索公众号"时光之箭"或者扫描以下二维码关注开发者公众号。<br>
![image](https://open.weixin.qq.com/qr/code?username=Arrow-of-Time-zd "时光之箭")



