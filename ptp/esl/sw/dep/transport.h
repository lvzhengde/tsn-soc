#ifndef _TRANSPORT_H__
#define _TRANSPORT_H__

#include "datatypes.h"

class transport : public base_data
{
public:
    //member variables
    unsigned char m_mac_sa[6];

    unsigned char m_mac_da[6];

    unsigned char m_ipv4_sa[4];

    unsigned char m_ipv4_da[4];

    unsigned char m_ipv6_sa[16];

    unsigned char m_ipv6_da[16];

    int m_networkProtocol;      //Table 3 in the 2008 spec

    int m_layer2Encap;          //0: ether2, 1: SNAP, 2: PPPoE

    int m_vlanTag;              //0: no vlan, 1: single vlan, 2: double vlan

    int m_delayMechanism;       //1: E2E, 2: P2P

    unsigned char m_frame_mem[256];

    unsigned char m_rcvd_frame[256];

public:
    //member methods
    transport(ptpd *pApp);

    void init(int networkProtocol, int layer2Encap, int vlanTag, int delayMechanism);

    unsigned char reverse_8b(unsigned char data);

    uint32_t reverse_32b(uint32_t data);

    uint32_t nextCRC32_D8(unsigned char data, uint32_t currentCRC);

    uint32_t calculate_crc(int data_len, unsigned char *frame_mem);

    int assemble_frame(unsigned char *msg_buf, uint16_t msg_len, uint16_t length_type, uint16_t ether2_type, 
                       int vlan_tag, uint16_t udp_dport);

    int transmit(unsigned char *msg_buf, uint16_t msg_len, unsigned char messageType);

    int parse_frame(unsigned char* &pHead, unsigned char &messageType);

    int receive(unsigned char *msb_buf, unsigned char &messageType);

};

#endif // _TRANSPORT_H__

