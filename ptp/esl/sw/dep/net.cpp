/*-
 * Copyright (c) 2022-2023 Zhengde
 *
 * Copyright (c) 2011-2012 George V. Neville-Neil,
 *                         Steven Kreuzer, 
 *                         Martin Burnicki, 
 *                         Jan Breuer,
 *                         Gael Mace, 
 *                         Alexandre Van Kempen,
 *                         Inaqui Delgado,
 *                         Rick Ratzel,
 *                         National Instruments.
 * Copyright (c) 2009-2010 George V. Neville-Neil, 
 *                         Steven Kreuzer, 
 *                         Martin Burnicki, 
 *                         Jan Breuer,
 *                         Gael Mace, 
 *                         Alexandre Van Kempen
 *
 * Copyright (c) 2005-2008 Kendall Correll, Aidan Williams
 *
 * All Rights Reserved
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE AUTHORS ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE AUTHORS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
 * IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @file   net.c
 * @date   Tue Jul 20 16:17:49 2010
 *
 * @brief  Functions to interact with the network sockets and NIC driver.
 *
 *
 */

#include "common.h"


/**
 * The parameter "netPath" in the following functions is unuseful.
 * It is just reserved to keep up with original design.
 */


//constructor
net::net(ptpd *pApp)
{
    BASE_MEMBER_ASSIGN 
}


/**
 * shutdown the multicast (both General and Peer)
 * just a stub function 
 *
 * @param netPath 
 * 
 * @return TRUE if successful
 */
Boolean
net::netShutdownMulticast(NetPath * netPath)
{
    return TRUE;
}


/* just a stub function */
Boolean 
net::netShutdown(NetPath * netPath)
{
    netShutdownMulticast(netPath);

    return TRUE;
}

/**
 * stub function
 * (
 * Init the multcast (both General and Peer)
 * )
 * 
 * @param netPath 
 * @param rtOpts 
 * 
 * @return TRUE if successful
 */
Boolean
net::netInitMulticast(NetPath * netPath,  RunTimeOpts * rtOpts)
{
    return TRUE;
}

/**
 * Initialize timestamping  engine
 *
 * @param netPath 
 * 
 * @return TRUE if successful
 */
Boolean 
net::netInitTimestamping(NetPath * netPath)
{
    int val = 1;
    Boolean result = TRUE;
    
    uint32_t base, addr, data = 0;
    base = TSU_BLK_ADDR << 8;
    addr = base + TSU_CFG_ADDR;

    uint32_t one_step   = (m_pApp->m_rtOpts.one_step != 0) ? 1 : 0;
    uint32_t peer_delay = (m_pApp->m_rtOpts.delayMechanism == P2P) ? 1 : 0;
    uint32_t emb_ingressTime = (m_pApp->m_rtOpts.emb_ingressTime != 0) ? 1 : 0;

    data = one_step | (peer_delay << 2) | (emb_ingressTime << 5);
    REG_WRITE(addr, data);

    return result;
}


/**
 * initialize network configuration
 * (
 * original description:
 * start all of the UDP stuff 
 * must specify 'subdomainName', and optionally 'ifaceName', 
 * if not then pass ifaceName == "" 
 * on socket options, see the 'socket(7)' and 'ip' man pages 
 * )
 *
 * @param netPath 
 * @param rtOpts 
 * @param ptpClock 
 * 
 * @return TRUE if successful
 */
Boolean 
net::netInit(NetPath * netPath, RunTimeOpts * rtOpts, PtpClock * ptpClock)
{
    DBG("netInit\n");

    //initialize ifaceName
    char ifaceName[] = DEFAULT_IFACE_NAME;
    strncpy(rtOpts->ifaceName, ifaceName, sizeof(ifaceName));

    //initialize transport object
    m_pApp->m_ptr_transport->init(rtOpts->networkProtocol, rtOpts->layer2Encap, rtOpts->vlanTag, rtOpts->delayMechanism);

    memcpy(ptpClock->port_uuid_field, m_pApp->m_ptr_transport->m_mac_sa, 6);

    /* stub only, init Multicast*/
    if (!netInitMulticast(netPath, rtOpts)) {
      return FALSE;
    }

    /* configure HW timestamp engine */
    if (!netInitTimestamping(netPath)) {
      ERROR_("failed to enable receive time stamps");
      return FALSE;
    }

    return TRUE;
}


/*Check if data have been received*/
int 
net::netSelect(TimeInternal * timeout, NetPath * netPath)
{
    double wt_us = 1.0; //default to 1 us

    if (timeout < 0)
      return FALSE;
    
    if(timeout) {
      wt_us = timeout->seconds * 1e6;
      wt_us += timeout->nanoseconds / 1000.0;
    }

    //wait event or time out
    uint32_t base, addr, data;

    wait(wt_us, SC_US, m_pController->m_ev_rx | m_pController->m_ev_rx_all);

    base = RX_BUF_BADDR;
    addr = base + RX_FLEN_OFT;
    data = 0;
    REG_READ(addr, data);
    bool data_rdy = (data >> 15) & 0x1;
    unsigned int rx_frm_len = data & 0x1ff;

    return (data_rdy && rx_frm_len > 0);
}



/** 
 * store received data from transport to "buf" , get and store the
 * messageType value
 *
 * @param buf 
 * @param messageType 
 *
 * @return
 *     >  0  : received PTP message length
 *     <= 0  : not PTP message or error
 */
ssize_t net::netRecv(Octet * buf, Enumeration4 &messageType)
{
    ssize_t ret = m_pApp->m_ptr_transport->receive((unsigned char*)buf, messageType);
    return ret;
}

ssize_t net::netSend(Octet * buf, UInteger16 length, Enumeration4 messageType)
{
    ssize_t ret = m_pApp->m_ptr_transport->transmit((unsigned char*)buf, length, messageType);
    return ret;
}

/*
 * stub function in fact
 * (refresh IGMP on a timeout)
 */
/*
 * @return TRUE if successful
 */
Boolean
net::netRefreshIGMP(NetPath * netPath, RunTimeOpts * rtOpts, PtpClock * ptpClock)
{
    DBG("netRefreshIGMP\n");
    
    netShutdownMulticast(netPath);
    
    /* suspend process 100 milliseconds, to make sure the kernel sends the IGMP_leave properly */
    //usleep(100*1000);

    if (!netInitMulticast(netPath, rtOpts)) {
        return FALSE;
    }
    
    INFO("refreshed IGMP multicast memberships\n");
    return TRUE;
}
