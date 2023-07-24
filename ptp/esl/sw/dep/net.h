#ifndef _NET_H__
#define _NET_H__

#include "datatypes.h"

class net : public base_data
{
public:
    //member methods
    net(ptpd *pApp);
    
    Boolean netShutdownMulticast(NetPath * netPath);
    
    Boolean netShutdown(NetPath * netPath);
    
    Boolean netInitMulticast(NetPath * netPath,  RunTimeOpts * rtOpts);
    
    Boolean netInitTimestamping(NetPath * netPath);
    
    Boolean netInit(NetPath * netPath, RunTimeOpts * rtOpts, PtpClock * ptpClock);
    
    int netSelect(TimeInternal * timeout, NetPath * netPath);
    
    ssize_t netRecv(Octet * buf, Enumeration4 &messageType);

    ssize_t netSend(Octet * buf, UInteger16 length, Enumeration4 messageType);
    
    Boolean netRefreshIGMP(NetPath * netPath, RunTimeOpts * rtOpts, PtpClock * ptpClock);
};

#endif // _NET_H__

