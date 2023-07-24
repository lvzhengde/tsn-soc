/*
 * ptp memory address map for register access
 */

#ifndef __PTP_MEMMAP_H__
#define __PTP_MEMMAP_H__

//rtc related macros
#define FNS_W  (26)                //width of fractional nanosecond(16 < FNS_W < 28)
#define NSC_W  (FNS_W + 32)        //width of nanosecond counter (ns+fractional ns)
#define SC2NS  (1000000000)        //1 seconds = 10^9 nanoseconds

//rtc register addresses
#define RTC_BLK_ADDR     (0x0)     //RTC block address

#define RTC_CTL_ADDR     (0x00)    //rtc control {29'h0, intxms_sel_o, clear_rtc_o, offset_valid_o}
#define TICK_INC_ADDR    (0x04)    //tick increment valule tick_inc[31:0]
#define NS_OFST_ADDR     (0x08)    //nanosecond offset ns_offset[31:0]
#define SC_OFST_ADDR0    (0x0c)    //second offset sc_offset{16'b0, [47:32]}
#define SC_OFST_ADDR1    (0x10)    //second offset sc_offset[31:0]
#define CUR_TM_ADDR0     (0x14)    //current time rtc_std[79:48]
#define CUR_TM_ADDR1     (0x18)    //current time rtc_std[47:16]
#define CUR_TM_ADDR2     (0x1c)    //current time {rtc_std[15:0], rtc_fns[15:0]}
#define PTS_ADDR0        (0x20)    //timestamp of pps input pts_std[79:48]
#define PTS_ADDR1        (0x24)    //timestamp of pps input pts_std[47:16]
#define PTS_ADDR2        (0x28)    //timestamp of pps input {pts_std[15:0], pts_fns[15:0]}
#define PPS_W_ADDR       (0x2c)    //pulse width of pps output pps_width[31:0]

//timestamp unit addresses
#define TSU_BLK_ADDR     (0x1)     //TSU block address

#define TSU_CFG_ADDR     (0x00)    //TSU configuration register {6'hxx, cf_from_pkt, one_step_from_pkt, 
 // crc_validate, ptp_addr_chk, ptp_ver_chk, ptpVersion[3:0], ipv6_udp_chk, 8'hxx, ing_asym_en, eg_asym_en,
 // emb_ingressTime, bypass, tc_offload, peer_delay, tc, one_step}
#define LINK_DELAY_ADDR  (0x04)    //link delay setting for peer delay 
#define IN_ASYM_ADDR     (0x08)    //ingress asymmetry
#define EG_ASYM_ADDR     (0x0c)    //egress asymmetry
#define LOC_MAC_ADDR0    (0x10)    //local mac address {tx_latency[15:0], [47:32]}
#define LOC_MAC_ADDR1    (0x14)    //local mac address [31:0]

//tx direction
#define TX_TS_ADDR0      (0x20)    //tx timestamp second[47:16]
#define TX_TS_ADDR1      (0x24)    //tx timestamp {second[15:0], nanosecond[31:16]
#define TX_TS_ADDR2      (0x28)    //tx timestamp {nanosecond[15:0], frac_ns[15:0]}

#define TX_SPF_ADDR0     (0x2c)    //tx sourcePortIdentity[79:48]
#define TX_SPF_ADDR1     (0x30)    //tx sourcePortIdentity[47:16]
#define TX_SPF_ADDR2     (0x34)    //tx {sourcePortIdentity[15:0], flagField[15:0]}

#define TX_TVID_ADDR     (0x3c)    //tx {majorSdoId[3:0], messageType[3:0], minorVersionPTP[3:0], versionPTP[3:0], sequenceId[15:0]}

//rx direction
#define RX_TS_ADDR0      (0x50)    //rx timestamp second[47:16]
#define RX_TS_ADDR1      (0x54)    //rx timestamp {second[15:0], nanosecond[31:16]
#define RX_TS_ADDR2      (0x58)    //rx timestamp {nanosecond[15:0], frac_ns[15:0]}

#define RX_SPF_ADDR0     (0x5c)    //rx sourcePortIdentity[79:48]
#define RX_SPF_ADDR1     (0x60)    //rx sourcePortIdentity[47:16]
#define RX_SPF_ADDR2     (0x64)    //rx {sourcePortIdentity[15:0], flagField[15:0]}

#define RX_TVID_ADDR     (0x6c)    //rx {majorSdoId[3:0], messageType[3:0], minorVersionPTP[3:0], versionPTP[3:0], sequenceId[15:0]}

//++
//address map for Verilog adapter for SystemC TLM
//--

//interrupt controller
#define INT_BASE_ADDR   (0x300)    //base address for interrupt controller
#define INT_STS_OFT     (0x0)      //interrupt status offset address {29'b0, int_xms, int_rx_ptp, int_tx_ptp}
#define INT_MSK_OFT     (0x1)      //interrupt mask offset addrress

//ptp rx buffer
#define RX_BUF_BADDR    (0x1000)   //ptp rx buffer base address
#define RX_FLEN_OFT     (0x200)    //rx frame length offset address {16'b0, data_rdy, 6'b0, frm_len[8:0]}

//ptp tx buffer         
#define TX_BUF_BADDR    (0x2000)   //ptp tx buffer base address
#define TX_FLEN_OFT     (0x200)    //tx frame length offset address {16'b0, tx_start, 6'b0, frm_len[8:0]}

#define RESET_ADDR      (0xffff)   //write this address to reset peripheral bus

//register access interface
#ifdef CONTROLLER_ITSELF
#define REG_READ(x, y)        reg_read(x, y)
#define REG_WRITE(x, y)       reg_write(x, y)
#define BURST_READ(x, y, z)   burst_read(x, y, z)
#define BURST_WRITE(x, y, z)  burst_write(x, y, z)
#else
#define REG_READ(x, y)        this->m_pController->reg_read(x, y)
#define REG_WRITE(x, y)       this->m_pController->reg_write(x, y)
#define BURST_READ(x, y, z)   this->m_pController->burst_read(x, y, z)
#define BURST_WRITE(x, y, z)  this->m_pController->burst_write(x, y, z)
#endif

#endif /* __PTP_MEMMAP_H__ */

