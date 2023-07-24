`ifndef PTPV2_DEFINES
`define PTPV2_DEFINES

//Ethernet codes (for XGE)
`define IDLE       8'h07
`define PREAMBLE   8'h55
`define SEQUENCE   8'h9c
`define SFD        8'hd5
`define START      8'hfb
`define TERMINATE  8'hfd
`define ERROR      8'hfe

//XGMII LANES
`define LANE0        7:0
`define LANE1       15:8
`define LANE2      23:16
`define LANE3      31:24
`define LANE4      39:32
`define LANE5      47:40
`define LANE6      55:48
`define LANE7      63:56

`define OR_LANE(x) (x[0] | x[1] | x[2] | x[3] | x[4] | x[5] | x[6] | x[7])

//rtc related macros
`define FNS_W  (26)                //width of fractional nanosecond(16 < FNS_W < 28)
`define NSC_W  (`FNS_W + 32)       //width of nanosecond counter (ns+fractional ns)
`define SC2NS  (32'd10_0000_0000)  //1 seconds = 10^9 nanoseconds

//rtc register addresses
`define RTC_BLK_ADDR     (24'h00_0000)    //RTC block address

`define RTC_CTL_ADDR     (8'h00)    //rtc control {29'h0, intxms_sel_o, clear_rtc_o, offset_valid_o}
`define TICK_INC_ADDR    (8'h04)    //tick increment valule tick_inc[31:0]
`define NS_OFST_ADDR     (8'h08)    //nanosecond offset ns_offset[31:0]
`define SC_OFST_ADDR0    (8'h0c)    //second offset sc_offset{16'b0, [47:32]}
`define SC_OFST_ADDR1    (8'h10)    //second offset sc_offset[31:0]
`define CUR_TM_ADDR0     (8'h14)    //current time rtc_std[79:48]
`define CUR_TM_ADDR1     (8'h18)    //current time rtc_std[47:16]
`define CUR_TM_ADDR2     (8'h1c)    //current time {rtc_std[15:0], rtc_fns[15:0]}
`define PTS_ADDR0        (8'h20)    //timestamp of pps input pts_std[79:48]
`define PTS_ADDR1        (8'h24)    //timestamp of pps input pts_std[47:16]
`define PTS_ADDR2        (8'h28)    //timestamp of pps input {pts_std[15:0], pts_fns[15:0]}
`define PPS_W_ADDR       (8'h2c)    //pulse width of pps output pps_width[31:0]

//timestamp unit addresses
`define TSU_BLK_ADDR     (24'h00_0001)  //TSU block address

`define TSU_CFG_ADDR     (8'h00)    //TSU configuration register {6'hxx, cf_from_pkt, one_step_from_pkt, 
 // crc_validate, ptp_addr_chk, ptp_ver_chk, ptpVersion[3:0], ipv6_udp_chk, 8'hxx, ing_asym_en, eg_asym_en,
 // emb_ingressTime, bypass, tc_offload, peer_delay, tc, one_step}
`define LINK_DELAY_ADDR  (8'h04)    //link delay setting for peer delay 
`define IN_ASYM_ADDR     (8'h08)    //ingress asymmetry
`define EG_ASYM_ADDR     (8'h0c)    //egress asymmetry
`define LOC_MAC_ADDR0    (8'h10)    //local mac address {tx_latency[15:0], [47:32]}
`define LOC_MAC_ADDR1    (8'h14)    //local mac address [31:0]

//tx direction
`define TX_TS_ADDR0      (8'h20)    //tx timestamp second[47:16]
`define TX_TS_ADDR1      (8'h24)    //tx timestamp {second[15:0], nanosecond[31:16]
`define TX_TS_ADDR2      (8'h28)    //tx timestamp {nanosecond[15:0], frac_ns[15:0]}

`define TX_SPF_ADDR0     (8'h2c)    //tx sourcePortIdentity[79:48]
`define TX_SPF_ADDR1     (8'h30)    //tx sourcePortIdentity[47:16]
`define TX_SPF_ADDR2     (8'h34)    //tx {sourcePortIdentity[15:0], flagField[15:0]}

`define TX_TVID_ADDR     (8'h3c)    //tx {majorSdoId[3:0], messageType[3:0], minorVersionPTP[3:0], versionPTP[3:0], sequenceId[15:0]}

//rx direction
`define RX_TS_ADDR0      (8'h50)    //rx timestamp second[47:16]
`define RX_TS_ADDR1      (8'h54)    //rx timestamp {second[15:0], nanosecond[31:16]
`define RX_TS_ADDR2      (8'h58)    //rx timestamp {nanosecond[15:0], frac_ns[15:0]}

`define RX_SPF_ADDR0     (8'h5c)    //rx sourcePortIdentity[79:48]
`define RX_SPF_ADDR1     (8'h60)    //rx sourcePortIdentity[47:16]
`define RX_SPF_ADDR2     (8'h64)    //rx {sourcePortIdentity[15:0], flagField[15:0]}

`define RX_TVID_ADDR     (8'h6c)    //rx {majorSdoId[3:0], messageType[3:0], minorVersionPTP[3:0], versionPTP[3:0], sequenceId[15:0]}

//`timescale 1ns/10fs

`endif

