#ifndef _PROTOCOL_H__
#define _PROTOCOL_H__

#include "datatypes.h"


class protocol : public base_data 
{
private:
    //member variables
    bool m_master_has_sent_annouce;

public:
    //member methods
    protocol(ptpd *pApp);

    void protocolExec(RunTimeOpts *rtOpts, PtpClock *ptpClock);
    
    void toState(UInteger8 state, RunTimeOpts *rtOpts, PtpClock *ptpClock);
    
    Boolean doInit(RunTimeOpts *rtOpts, PtpClock *ptpClock);
    
    void doState(RunTimeOpts *rtOpts, PtpClock *ptpClock);
    
    void handle(RunTimeOpts *rtOpts, PtpClock *ptpClock);
    
    void handleAnnounce(MsgHeader *header, Octet *msgIbuf, ssize_t length, 
             Boolean isFromSelf, RunTimeOpts *rtOpts, PtpClock *ptpClock);
    
    void handleSync(MsgHeader *header, Octet *msgIbuf, ssize_t length, 
         TimeInternal *time, Boolean isFromSelf, 
         RunTimeOpts *rtOpts, PtpClock *ptpClock);
    
    void handleFollowUp(MsgHeader *header, Octet *msgIbuf, ssize_t length, 
             Boolean isFromSelf, RunTimeOpts *rtOpts, PtpClock *ptpClock);
    
    void handleDelayReq(MsgHeader *header, Octet *msgIbuf, ssize_t length, 
             TimeInternal *time, Boolean isFromSelf,
             RunTimeOpts *rtOpts, PtpClock *ptpClock);
    
    void handleDelayResp(MsgHeader *header, Octet *msgIbuf, ssize_t length,
          Boolean isFromSelf, RunTimeOpts *rtOpts, PtpClock *ptpClock);
    
    void handlePDelayReq(MsgHeader *header, Octet *msgIbuf, ssize_t length, 
          TimeInternal *time, Boolean isFromSelf, 
          RunTimeOpts *rtOpts, PtpClock *ptpClock);
    
    void handlePDelayResp(MsgHeader *header, Octet *msgIbuf, TimeInternal *time,
           ssize_t length, Boolean isFromSelf, 
           RunTimeOpts *rtOpts, PtpClock *ptpClock);
    
    void handlePDelayRespFollowUp(MsgHeader *header, Octet *msgIbuf, ssize_t length, 
               Boolean isFromSelf, RunTimeOpts *rtOpts, PtpClock *ptpClock);
    
    void handleManagement(MsgHeader *header, Octet *msgIbuf, ssize_t length, 
           Boolean isFromSelf, RunTimeOpts *rtOpts, PtpClock *ptpClock);
    
    void handleSignaling(MsgHeader *header, Octet *msgIbuf, ssize_t length, 
               Boolean isFromSelf, RunTimeOpts *rtOpts, PtpClock *ptpClock);

    void waitGuardInterval();
    
    void issueAnnounce(RunTimeOpts *rtOpts,PtpClock *ptpClock);
    
    void issueSync(RunTimeOpts *rtOpts,PtpClock *ptpClock);
    
    void issueFollowup(TimeInternal *time,RunTimeOpts *rtOpts,PtpClock *ptpClock);
    
    void issueDelayReq(RunTimeOpts *rtOpts,PtpClock *ptpClock);
    
    void issuePDelayReq(RunTimeOpts *rtOpts,PtpClock *ptpClock);
    
    void issuePDelayResp(TimeInternal *time,MsgHeader *header,RunTimeOpts *rtOpts, PtpClock *ptpClock);
    
    void issueDelayResp(TimeInternal *time,MsgHeader *header,RunTimeOpts *rtOpts, PtpClock *ptpClock);
    
    void issuePDelayRespFollowUp(TimeInternal *time, MsgHeader *header, RunTimeOpts *rtOpts, PtpClock *ptpClock);
    
    void issueManagement(MsgHeader *header,MsgManagement *manage,RunTimeOpts *rtOpts,PtpClock *ptpClock);
    
    void issueManagementRespOrAck(MsgManagement *outgoing, RunTimeOpts *rtOpts, PtpClock *ptpClock);
    
    void issueManagementErrorStatus(MsgManagement *outgoing, RunTimeOpts *rtOpts, PtpClock *ptpClock);
    
    void addForeign(Octet *buf,MsgHeader *header,PtpClock *ptpClock);
};

#endif // _PROTOCOL_H__

