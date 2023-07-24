#ifndef _BMC_H__
#define _BMC_H__

#include "datatypes.h"

class bmc : public base_data 
{
public:
    //member variables
    
    //member methods
    bmc(ptpd *pApp);
    
    void initData(RunTimeOpts *rtOpts, PtpClock *ptpClock);
    
    void m1(RunTimeOpts *rtOpts, PtpClock *ptpClock);
    
    void p1(PtpClock *ptpClock, RunTimeOpts *rtOpts);
    
    void s1(MsgHeader *header,MsgAnnounce *announce,PtpClock *ptpClock, RunTimeOpts *rtOpts);
    
    void copyD0(MsgHeader *header, MsgAnnounce *announce, PtpClock *ptpClock);
    
    Integer8 bmcDataSetComparison(MsgHeader *headerA, MsgAnnounce *announceA,
                MsgHeader *headerB,MsgAnnounce *announceB,
                PtpClock *ptpClock);
    
    UInteger8 bmcStateDecision(MsgHeader *header, MsgAnnounce *announce,
                RunTimeOpts *rtOpts, PtpClock *ptpClock);
    
    UInteger8 bmcExec(ForeignMasterRecord *foreignMaster,
                RunTimeOpts *rtOpts, PtpClock *ptpClock);
};

#endif // _BMC_H__

