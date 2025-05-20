# XGE-PTPv2

# Basic Function Test
Execute the following commands to run basic RTL function tests<br>
>cd /path/to/sim<br>
>./runcase.sh tc_rapid_ptp_test<br>

# Design Related Notes
1. RTC and TSU design are basically separated, can be used in switch/router or single-port MAC/PHY PTP design according to needs.
2. One-step clock, TC offload, and embedding ingress time into PTP packets designs will introduce processing delay in data path.
3. External dis_ptpv2_i signal can bypass the entire design, and can also be used to disable the working clock signal.
4. Configuration register bypass_dp signal can also bypass the data path, but TSU unit continues to work normally. This mode can be used for two-step clock where data path doesn't introduce additional delay.
5. RTC operating precision can be adjusted by setting the decimal position of tick_inc.

This open source project focuses on establishing overall architecture design and open design processes. Currently, it ensures basic function testing passes.<br>
If readers intend to further develop on this basis, please modify it according to specific requirements and perform sufficient validation and testing.<br>

# About Documentation
Currently there is no plan to write formal documentation. The developer will periodically publish articles discussing design details in their official WeChat account.
If readers want to understand related updates and design notes, please follow the developer's official WeChat account.

#### Follow Developer Official Account
If you need to understand the latest status of the project and join related technical discussions, please search for WeChat official account "时光之箭" or scan the QR code below:<br>
![image](https://open.weixin.qq.com/qr/code?username=Arrow-of-Time-zd "时光之箭")