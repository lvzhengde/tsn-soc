/*+
 * Copyright (c) 2022-2023 Zhengde
 * 
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * 1 Redistributions of source code must retain the above copyright notice, this
 *   list of conditions and the following disclaimer.
 * 
 * 2 Redistributions in binary form must reproduce the above copyright notice,
 *   this list of conditions and the following disclaimer in the documentation
 *   and/or other materials provided with the distribution.
 * 
 * 3 Neither the name of the copyright holder nor the names of its
 *   contributors may be used to endorse or promote products derived from
 *   this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-*/

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

