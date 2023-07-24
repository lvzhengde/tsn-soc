/*-
 * class to transport ptp message over ethernet, udp/ipv4, udp/ipv6
 *
 */


#include "common.h"


//constructor
transport::transport(ptpd *pApp)
{
    BASE_MEMBER_ASSIGN 

    m_networkProtocol = IEEE_802_3;      //Table 3 in the 2008 spec

    m_layer2Encap     = 0;               //0: ether2, 1: SNAP, 2: PPPoE

    m_vlanTag         = 0;               //0: no vlan, 1: single vlan, 2: double vlan

    m_delayMechanism  = P2P;             //1: E2E, 2: P2P
}

void transport::init(int networkProtocol, int layer2Encap, int vlanTag, int delayMechanism)
{
    m_networkProtocol = networkProtocol;      
    m_layer2Encap     = layer2Encap    ;         
    m_vlanTag         = vlanTag        ;            
    m_delayMechanism  = delayMechanism ;       

    //initialize source address
    unsigned char mac_sa_tmp[6]   = {0xb0, 0x80, 0x63, 0xd2, 0x09, 0xba};
    unsigned char ipv4_sa_tmp[4]  = {192, 168, 1, 11};
    unsigned char ipv6_sa_tmp[16] = {0xfe, 0x80, 0xbe, 0x10, 0xdc, 0xd7, 0x1a, 0xc0, 
                                     0xbd, 0x72, 0xde, 0x90, 0x08, 0x24, 0x00, 0x00};

    for(int i = 0; i < 4; i++) {
      m_mac_sa[i] = mac_sa_tmp[i];  
    }
    m_mac_sa[2] = m_pController->m_clock_id;
    m_mac_sa[4] = m_pController->m_clock_id;
    m_mac_sa[5] = m_pController->m_clock_id;

    for(int i = 0; i < 2; i++) {
      m_ipv4_sa[i] = ipv4_sa_tmp[i];  
    }
    m_ipv4_sa[2] = m_pController->m_clock_id;
    m_ipv4_sa[3] = m_pController->m_clock_id;

    for(int i = 0; i < 14; i++) {
      m_ipv6_sa[i] = ipv6_sa_tmp[i];  
    }
    m_ipv6_sa[14] = m_pController->m_clock_id;
    m_ipv6_sa[15] = m_pController->m_clock_id;

    //initialize destination address
    unsigned char mac_da_e2e[6]   = {0x01, 0x1b, 0x19, 0x00, 0x00, 0x00};
    unsigned char mac_da_p2p[6]   = {0x01, 0x80, 0xc2, 0x00, 0x00, 0x0e};
    unsigned char ipv4_da_e2e[4]  = {224, 0, 1, 129};
    unsigned char ipv4_da_p2p[4]  = {224, 0, 0, 107};
    unsigned char ipv6_da_e2e[16] = {0xff, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x81};
    unsigned char ipv6_da_p2p[16] = {0xff, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x6b};
    
    if(delayMechanism == P2P) {
      for(int i = 0; i < 6; i++) {
        m_mac_da[i] = mac_da_p2p[i];
      }

      for(int i = 0; i < 4; i++) {
        m_ipv4_da[i] = ipv4_da_p2p[i];
      }

      for(int i = 0; i < 16; i++) {
        m_ipv6_da[i] = ipv6_da_p2p[i];
      }
    }
    else {
      for(int i = 0; i < 6; i++) {
        m_mac_da[i] = mac_da_e2e[i];
      }

      for(int i = 0; i < 4; i++) {
        m_ipv4_da[i] = ipv4_da_e2e[i];
      }

      for(int i = 0; i < 16; i++) {
        m_ipv6_da[i] = ipv6_da_e2e[i];
      }
    }
}

unsigned char transport::reverse_8b(unsigned char data)
{
    unsigned char ra[8];
    int shift;

    for(int i = 0; i < 8; i++)
    {
      shift = 7 - i;
      ra[i] = (data >> shift) & 0x1;
    }

    unsigned char reverse = 0;
    for(int i = 0; i < 8; i++)
      reverse = reverse | (ra[i] << i);

    return reverse;
}

uint32_t transport::reverse_32b(uint32_t data)
{
    uint32_t ra[32];
    int shift;

    for(int i = 0; i < 32; i++)
    {
      shift = 31 - i;
      ra[i] = (data >> shift) & 0x1;
    }

    uint32_t reverse = 0;
    for(int i = 0; i < 32; i++)
      reverse = reverse | (ra[i] << i);

    return reverse;
}

uint32_t transport::nextCRC32_D8(unsigned char data, uint32_t currentCRC)
{
    uint32_t     data_in[8];
    uint32_t     lfsr_q[32];
    uint32_t     lfsr_c[32];

    for(int i = 0; i < 8; i++)
      data_in[i] = uint32_t(data >> i) & 0x1;

    for(int i = 0; i < 32; i++)
      lfsr_q[i] = (currentCRC >> i) & 0x1;

    lfsr_c[0] = lfsr_q[24] ^ lfsr_q[30] ^ data_in[0] ^ data_in[6];
    lfsr_c[1] = lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_in[0] ^ data_in[1] ^ data_in[6] ^ data_in[7];
    lfsr_c[2] = lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_in[0] ^ data_in[1] ^ data_in[2]
                ^ data_in[6] ^ data_in[7];
    lfsr_c[3] = lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[27] ^ lfsr_q[31] ^ data_in[1] ^ data_in[2] ^ data_in[3] ^ data_in[7];
    lfsr_c[4] = lfsr_q[24] ^ lfsr_q[26] ^ lfsr_q[27] ^ lfsr_q[28] ^ lfsr_q[30] ^ data_in[0] ^ data_in[2] ^ data_in[3] 
                ^ data_in[4] ^ data_in[6];
    lfsr_c[5] = lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[27] ^ lfsr_q[28] ^ lfsr_q[29] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_in[0]
                ^ data_in[1] ^ data_in[3] ^ data_in[4] ^ data_in[5] ^ data_in[6] ^ data_in[7];
    lfsr_c[6] = lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[28] ^ lfsr_q[29] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_in[1] ^ data_in[2]
                ^ data_in[4] ^ data_in[5] ^ data_in[6] ^ data_in[7];
    lfsr_c[7] = lfsr_q[24] ^ lfsr_q[26] ^ lfsr_q[27] ^ lfsr_q[29] ^ lfsr_q[31] ^ data_in[0] ^ data_in[2] ^ data_in[3] 
                ^ data_in[5] ^ data_in[7];
    lfsr_c[8] = lfsr_q[0] ^ lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[27] ^ lfsr_q[28] ^ data_in[0] ^ data_in[1] ^ data_in[3] ^ data_in[4];
    lfsr_c[9] = lfsr_q[1] ^ lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[28] ^ lfsr_q[29] ^ data_in[1] ^ data_in[2] ^ data_in[4] ^ data_in[5];
    lfsr_c[10] = lfsr_q[2] ^ lfsr_q[24] ^ lfsr_q[26] ^ lfsr_q[27] ^ lfsr_q[29] ^ data_in[0] ^ data_in[2] ^ data_in[3] ^ data_in[5];
    lfsr_c[11] = lfsr_q[3] ^ lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[27] ^ lfsr_q[28] ^ data_in[0] ^ data_in[1] ^ data_in[3] ^ data_in[4];
    lfsr_c[12] = lfsr_q[4] ^ lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[28] ^ lfsr_q[29] ^ lfsr_q[30] ^ data_in[0] ^ data_in[1]
                 ^ data_in[2] ^ data_in[4] ^ data_in[5] ^ data_in[6];
    lfsr_c[13] = lfsr_q[5] ^ lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[27] ^ lfsr_q[29] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_in[1] 
                 ^ data_in[2] ^ data_in[3] ^ data_in[5] ^ data_in[6] ^ data_in[7];
    lfsr_c[14] = lfsr_q[6] ^ lfsr_q[26] ^ lfsr_q[27] ^ lfsr_q[28] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_in[2] ^ data_in[3]
                 ^ data_in[4] ^ data_in[6] ^ data_in[7];
    lfsr_c[15] = lfsr_q[7] ^ lfsr_q[27] ^ lfsr_q[28] ^ lfsr_q[29] ^ lfsr_q[31] ^ data_in[3] ^ data_in[4]
                 ^ data_in[5] ^ data_in[7];
    lfsr_c[16] = lfsr_q[8] ^ lfsr_q[24] ^ lfsr_q[28] ^ lfsr_q[29] ^ data_in[0] ^ data_in[4] ^ data_in[5];
    lfsr_c[17] = lfsr_q[9] ^ lfsr_q[25] ^ lfsr_q[29] ^ lfsr_q[30] ^ data_in[1] ^ data_in[5] ^ data_in[6];
    lfsr_c[18] = lfsr_q[10] ^ lfsr_q[26] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_in[2] ^ data_in[6] ^ data_in[7];
    lfsr_c[19] = lfsr_q[11] ^ lfsr_q[27] ^ lfsr_q[31] ^ data_in[3] ^ data_in[7];
    lfsr_c[20] = lfsr_q[12] ^ lfsr_q[28] ^ data_in[4];
    lfsr_c[21] = lfsr_q[13] ^ lfsr_q[29] ^ data_in[5];
    lfsr_c[22] = lfsr_q[14] ^ lfsr_q[24] ^ data_in[0];
    lfsr_c[23] = lfsr_q[15] ^ lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[30] ^ data_in[0] ^ data_in[1] ^ data_in[6];
    lfsr_c[24] = lfsr_q[16] ^ lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[31] ^ data_in[1] ^ data_in[2] ^ data_in[7];
    lfsr_c[25] = lfsr_q[17] ^ lfsr_q[26] ^ lfsr_q[27] ^ data_in[2] ^ data_in[3];
    lfsr_c[26] = lfsr_q[18] ^ lfsr_q[24] ^ lfsr_q[27] ^ lfsr_q[28] ^ lfsr_q[30] ^ data_in[0] ^ data_in[3] ^ data_in[4] ^ data_in[6];
    lfsr_c[27] = lfsr_q[19] ^ lfsr_q[25] ^ lfsr_q[28] ^ lfsr_q[29] ^ lfsr_q[31] ^ data_in[1] ^ data_in[4] ^ data_in[5] ^ data_in[7];
    lfsr_c[28] = lfsr_q[20] ^ lfsr_q[26] ^ lfsr_q[29] ^ lfsr_q[30] ^ data_in[2] ^ data_in[5] ^ data_in[6];
    lfsr_c[29] = lfsr_q[21] ^ lfsr_q[27] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_in[3] ^ data_in[6] ^ data_in[7];
    lfsr_c[30] = lfsr_q[22] ^ lfsr_q[28] ^ lfsr_q[31] ^ data_in[4] ^ data_in[7];
    lfsr_c[31] = lfsr_q[23] ^ lfsr_q[29] ^ data_in[5];

    uint32_t nextCRC = 0;
    for(int i = 0; i < 32; i++)
      nextCRC = nextCRC | (lfsr_c[i] << i);

    return nextCRC;
}

uint32_t transport::calculate_crc(int data_len, unsigned char *frame_mem)
{
    uint32_t current_crc;
    uint32_t next_crc;

    current_crc = 0xffffffff;
    for(int i = 0; i < data_len; i++)
    {
      next_crc = nextCRC32_D8(reverse_8b(frame_mem[i]), current_crc);
      current_crc = next_crc; 
    }

    return  ~reverse_32b(current_crc);
}


int transport::assemble_frame(unsigned char *msg_buf, uint16_t msg_len, uint16_t length_type, uint16_t ether2_type, 
                     int vlan_tag, uint16_t udp_dport)
{

    int len;
    int m;
    int pad_len;
    int len_sub_vlan;
    uint32_t frame_crc;

    len = 0;
    //preamble added by verilog, skip
    
    //destination mac address
    for(int i = 0; i < 6; i++) {
      m_frame_mem[len++] = m_mac_da[i];
    }

    //source mac address
    for(int i = 0; i < 6; i++) {
      m_frame_mem[len++] = m_mac_sa[i];
    }

    //external vlan tag
    if(vlan_tag == 2) {
      m_frame_mem[len++] = 0x88;  m_frame_mem[len++] = 0xa8;  
      m_frame_mem[len++] = 0x00;  m_frame_mem[len++] = 0x02;
    }
    //inner vlan tag or single vlan
    if(vlan_tag == 1 || vlan_tag == 2) {
      m_frame_mem[len++] = 0x81;  m_frame_mem[len++] = 0x00;  
      m_frame_mem[len++] = 0x00;  m_frame_mem[len++] = 0x02;
    }

    //ethernet length/type field
    m_frame_mem[len++] = (length_type >> 8) & 0xff;  
    m_frame_mem[len++] = length_type & 0xff;

    //802.3/snap header
    if(length_type <= 1500) {
      //snap header
      m_frame_mem[len++] = 0xaa;  m_frame_mem[len++] = 0xaa;  m_frame_mem[len++] = 0x00;  
      m_frame_mem[len++] = 0x00;  m_frame_mem[len++] = 0x00;  m_frame_mem[len++] = 0x00;  
      m_frame_mem[len++] = (ether2_type >> 8) & 0xff;  
      m_frame_mem[len++] = ether2_type & 0xff;
    }
    else if(length_type == 0x8864) {
      //pppoe header
      m_frame_mem[len++] = 0x00;  m_frame_mem[len++] = 0x00;  m_frame_mem[len++] = 0x00;  
      m_frame_mem[len++] = 0x00;  m_frame_mem[len++] = 0x00;  m_frame_mem[len++] = 0x00;  
      m_frame_mem[len++] = (ether2_type >> 8) & 0xff;  
      m_frame_mem[len++] = ether2_type & 0xff;
    }

    //ipv4 header
    if(length_type == 0x0800 || (length_type < 1500 && ether2_type == 0x0800) || (length_type == 0x8864 && ether2_type == 0x0021)) {
      uint16_t total_len = 20 + 8 + msg_len;  //IP header length, UDP header length, message length
      m_frame_mem[len++] = 0x45;  m_frame_mem[len++] = 0x00;  
      m_frame_mem[len++] = (total_len >> 8) & 0xff;  m_frame_mem[len++] = total_len & 0xff;
      m_frame_mem[len++] = 0x00;  m_frame_mem[len++] = 0x00;  m_frame_mem[len++] = 0x00;  m_frame_mem[len++] = 0x00;
      m_frame_mem[len++] = 0xff;  m_frame_mem[len++] = 17;  m_frame_mem[len++] = 0x00;  m_frame_mem[len++] = 0x00;
      
      for(int i = 0; i < 4; i++) {
        m_frame_mem[len++] = m_ipv4_sa[i];
      }

      for(int i = 0; i < 4; i++) {
        m_frame_mem[len++] = m_ipv4_da[i];
      }
    }

    //ipv6 header
    if(length_type == 0x86dd || (length_type < 1500 && ether2_type == 0x86dd) ||(length_type == 0x8864 && ether2_type == 0x0057)) {
      m_frame_mem[len++] = 0x60;  m_frame_mem[len++] = 0x00;  m_frame_mem[len++] = 0x00;  m_frame_mem[len++] = 0x00;
      uint16_t payload_len = 8 + msg_len + 2; //UDP header length + PTP message length + padding
      m_frame_mem[len++] = (payload_len >> 8) & 0xff;  m_frame_mem[len++] = payload_len & 0xff;  
      m_frame_mem[len++] = 17;  m_frame_mem[len++] = 0xff;

      for(int i = 0; i < 16; i++) {
        m_frame_mem[len++] = m_ipv6_sa[i];
      }

      for(int i = 0; i < 16; i++) {
        m_frame_mem[len++] = m_ipv6_da[i];
      }
    }

    //udp header
    if(length_type == 0x0800 || length_type == 0x86dd || (length_type < 1500 && (ether2_type == 0x0800 || ether2_type == 0x86dd))
          || (length_type == 0x8864 && (ether2_type == 0x0021 || ether2_type == 0x0057))) {
      m_frame_mem[len++] = 0x00;  m_frame_mem[len++] = 0x00;  
      m_frame_mem[len++] = (udp_dport >> 8) & 0xff;  m_frame_mem[len++] = udp_dport & 0xff;

      uint16_t udp_len = 8 + msg_len;  //udp header length + ptp message length
      if(length_type == 0x86dd || (length_type < 1500 &&  ether2_type == 0x86dd) 
          || (length_type == 0x8864 && ether2_type == 0x0057)) {
        udp_len = udp_len + 2;    //+ padding
      }
      m_frame_mem[len++] = (udp_len >> 8) & 0xff; m_frame_mem[len++] = udp_len & 0xff;  

      m_frame_mem[len++] = 0xab; m_frame_mem[len++] = 0xcd;
    }

    //ptpv2 message payload
    for(int i = 0; i < msg_len; i++) {
      m_frame_mem[len++] = msg_buf[i];
    }

    //padding octets
    len_sub_vlan = (vlan_tag == 2) ? len-8 : ((vlan_tag == 1) ? len-4 : len);
    pad_len = 64 - (len_sub_vlan+4); //64 - (payload length + crc length)
    if(length_type == 0x86dd || (length_type < 1500 &&  ether2_type == 0x86dd) || (length_type == 0x8864 && ether2_type == 0x0057)) {
      pad_len = 2;
    }

    if(pad_len > 0) {
      for(m = 0; m < pad_len; m = m+1) {
        m_frame_mem[len++] = 0x00;
      }
    }

    //crc octets
    frame_crc = calculate_crc(len, m_frame_mem);

    m_frame_mem[len++] = frame_crc & 0xff;
    m_frame_mem[len++] = (frame_crc >> 8) & 0xff;
    m_frame_mem[len++] = (frame_crc >> 16) & 0xff;
    m_frame_mem[len++] = (frame_crc >> 24) & 0xff;
    
    return len;
}

int transport::transmit(unsigned char *msg_buf, uint16_t msg_len, unsigned char messageType)
{
    uint16_t length_type = 0;
    uint16_t ether2_type = 0;
    uint16_t udp_dport   = 0;

    //determine lenth_type/ether2_type field
    if(m_layer2Encap == 0) {                 //ehter2 frame
      if(m_networkProtocol == UDP_IPV4)
        length_type = 0x0800;
      else if(m_networkProtocol == UDP_IPV6)
        length_type = 0x86dd;
      else if(m_networkProtocol == IEEE_802_3)
        length_type = 0x88f7;
    }
    else if(m_layer2Encap == 1) {            //snap frame
      length_type = 12 + 2 + 8 + 4;          //da+sa+length+snap header+crc

      if(m_networkProtocol == UDP_IPV4){
        length_type += 20 + 8 + msg_len;     //ipv4 header+udp header+ptp message
        ether2_type = 0x0800;
      }
      else if(m_networkProtocol == UDP_IPV6) {
        length_type += 40 + 8 + msg_len + 2;  //ipv4 header+udp header+ptp message+padding
        ether2_type = 0x86dd;
      }
      else if(m_networkProtocol == IEEE_802_3) {
        length_type += msg_len;               //+ptp message
        ether2_type = 0x88f7;
      }
    }
    else if(m_layer2Encap == 2) {            //PPPoE
      length_type = 0x8864; 

      if(m_networkProtocol == UDP_IPV4)
        ether2_type = 0x0021;
      else if(m_networkProtocol == UDP_IPV6) 
        ether2_type = 0x0057;
    }

    //determine udp destination port
    if(messageType < 8)  //event messasge
      udp_dport = 319;
    else
      udp_dport = 320;

    //assemble message
    int frame_len = assemble_frame(msg_buf, msg_len, length_type, ether2_type, m_vlanTag, udp_dport);

    uint32_t base, addr, data;

    //write data to TX buffer
    base = TX_BUF_BADDR;
    BURST_WRITE(base, m_frame_mem, frame_len);

    //transmit frame
    addr = base + TX_FLEN_OFT;
    data = frame_len + (1 << 15);
    REG_WRITE(addr, data);

    return frame_len;
}

/**
 * parse received frame
 * parameters
 * pHead:       pointer to the start of PTP message
 * messageType: the received PTP message type
 * return value: int
 *   >  0 : PTP message length
 *   <= 0 : error or not PTP message
 */
int transport::parse_frame(unsigned char* &pHead, unsigned char &messageType)
{
    bool is_ptp_message = false;
    unsigned char eth_data = 0;
    uint16_t eth_type = 0;
    uint16_t ppp_id = 0;
    unsigned char snap_dsap = 0;
    unsigned char snap_ssap = 0;
    uint16_t snap_length_type = 0;
    unsigned char  next_layer_protocol = 0;
    uint16_t destination_udp_port = 0;
    int k = 0, m = 0;
    int eth_base_addr = 0;
    int ptp_base_addr = 0;
    int protocol_overhead = 0;

    //get protocal_overhead;
    m = eth_base_addr + 12;
    protocol_overhead = 0;

    eth_type = ((m_rcvd_frame[m] << 8) & 0xff00) + m_rcvd_frame[m+1];
    if(eth_type == 0x8100) {              //single vlan 
      eth_type = ((m_rcvd_frame[m+4] << 8) & 0xff00) + m_rcvd_frame[m+5];
      protocol_overhead = 4;
    } 

    if(eth_type == 0x88a8 || eth_type == 0x9100 || eth_type == 0x9200 || eth_type == 0x9300 || 
                   eth_type == 0x8100) {  //double vlan
      eth_type = ((m_rcvd_frame[m+8] << 8) & 0xff00) + m_rcvd_frame[m+9];
      protocol_overhead = 8;
    }

    if(eth_type == 0x88f7) {         //ptpv2 in ethernet2 
      is_ptp_message = true;
    }
    else if(eth_type == 0x0800) {   //may be ptpv2 in ipv4
      m = eth_base_addr + 14 + protocol_overhead;
      next_layer_protocol = m_rcvd_frame[m+9];
      destination_udp_port = ((m_rcvd_frame[m+22] << 8) & 0xff00) + m_rcvd_frame[m+23];

      if(next_layer_protocol == 17 && (destination_udp_port == 319 || destination_udp_port == 320)) {
        is_ptp_message = true;
        protocol_overhead = protocol_overhead + 28;
      }
    }
    else if(eth_type == 0x86dd) { //may be ptpv2 in ipv6
      m = eth_base_addr + 14 + protocol_overhead;
      next_layer_protocol = m_rcvd_frame[m+6];
      destination_udp_port = ((m_rcvd_frame[m+42] << 8) & 0xff00) + m_rcvd_frame[m+43];

      if(next_layer_protocol == 17 && (destination_udp_port == 319 || destination_udp_port == 320)) {
        is_ptp_message = true;
        protocol_overhead = protocol_overhead + 48;
      }
    }
    else if(eth_type == 0x8864) {  //pppo_e
      m = eth_base_addr + 14 + protocol_overhead;
      ppp_id = ((m_rcvd_frame[m+6] << 8) & 0xff00) + m_rcvd_frame[m+7];

      if(ppp_id == 0x0021) {         //pppoe, may be ptp over ipv4
        next_layer_protocol = m_rcvd_frame[m+17];
        destination_udp_port = ((m_rcvd_frame[m+30] << 8) & 0xff00) + m_rcvd_frame[m+31];

        if(next_layer_protocol == 17 && (destination_udp_port == 319 || destination_udp_port == 320)) {
          is_ptp_message = true;
          protocol_overhead = protocol_overhead + 36;
        }
      }
      else if(ppp_id == 0x0057) {    //pppoe, may be ptp over ipv6
        next_layer_protocol = m_rcvd_frame[m+14];
        destination_udp_port = ((m_rcvd_frame[m+50] << 8) & 0xff00) + m_rcvd_frame[m+51];

        if(next_layer_protocol == 17 && (destination_udp_port == 319 || destination_udp_port == 320)) {
          is_ptp_message = true;
          protocol_overhead = protocol_overhead + 56;
        }
      }
    }
    else if(eth_type <= 1500)  {  //snap
      m = eth_base_addr + 14 + protocol_overhead;
      snap_dsap = m_rcvd_frame[m];
      snap_ssap = m_rcvd_frame[m+1];
      snap_length_type = ((m_rcvd_frame[m+6] << 8) & 0xff00) + m_rcvd_frame[m+7];

      if(snap_dsap == 0xaa && snap_ssap == 0xaa && snap_length_type == 0x0800) {       //may be ptp over ipv4 
        next_layer_protocol = m_rcvd_frame[m+17];
        destination_udp_port = ((m_rcvd_frame[m+30] << 8) & 0xff00) + m_rcvd_frame[m+31];

        if(next_layer_protocol == 17 && (destination_udp_port == 319 || destination_udp_port == 320)) {
          is_ptp_message = true;
          protocol_overhead = protocol_overhead + 36;
        }
      }
      else if(snap_dsap == 0xaa && snap_ssap == 0xaa && snap_length_type == 0x86dd) {  //may be ptp over ipv6
        next_layer_protocol = m_rcvd_frame[m+14];
        destination_udp_port = ((m_rcvd_frame[m+50] << 8) & 0xff00) + m_rcvd_frame[m+51];

        if(next_layer_protocol == 17 && (destination_udp_port == 319 || destination_udp_port == 320)) {
          is_ptp_message = true;
          protocol_overhead = protocol_overhead + 56;
        }
      }
      else if(snap_dsap == 0xaa && snap_ssap == 0xaa && snap_length_type == 0x88f7)  { //snap 802.3
        is_ptp_message = true;
        protocol_overhead = protocol_overhead + 8;
      }
    }
          
    int messageLength = 0;
    pHead = NULL;
    messageType = 0xf;

    if(is_ptp_message == true) {
      ptp_base_addr = eth_base_addr + 14 + protocol_overhead;

      eth_data = m_rcvd_frame[ptp_base_addr];
      messageType = eth_data & 0xf;
    
      eth_data = m_rcvd_frame[ptp_base_addr+2];
      messageLength = (eth_data << 8) & 0xff00;
      eth_data = m_rcvd_frame[ptp_base_addr+3];
      messageLength += eth_data;

      pHead = m_rcvd_frame + ptp_base_addr;
    }

    return messageLength;
}

/**
 * receive frame
 * parameters
 * msb_buf:     pointer to input buffer for PTP message
 * messageType: the received PTP message type
 * return value: int
 *   >  0 : PTP message length
 *   <= 0 : error or not PTP message
 */
int transport::receive(unsigned char *msb_buf, unsigned char &messageType)
{
    uint32_t base, addr, data;

    unsigned char* pHead = NULL;
    int messageLength = 0;
    messageType = 0xf;

    base = RX_BUF_BADDR;
    addr = base + RX_FLEN_OFT;
    data = 0;
    REG_READ(addr, data);
    unsigned int rx_frm_len = data & 0x1ff;

    if(rx_frm_len > 0)
    {
      //read RX PTPv2 message from RX buffer
      addr = base;
      BURST_READ(addr, m_rcvd_frame, rx_frm_len);

      messageLength = parse_frame(pHead, messageType);
      if(messageLength > 0) {
        memcpy(msb_buf, pHead, messageLength);
      }
    }

    return messageLength;
}

