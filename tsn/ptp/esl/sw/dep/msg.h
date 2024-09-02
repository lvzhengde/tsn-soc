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

#ifndef _MSG_H__
#define _MSG_H__

#include "datatypes.h"

class msg  : public base_data
{
public:
    //member methods
    msg(ptpd *pApp);

    void msgUnpackHeader(Octet * buf,MsgHeader*);
    void msgUnpackAnnounce (Octet * buf,MsgAnnounce*);
    void msgUnpackSync(Octet * buf,MsgSync*);
    void msgUnpackFollowUp(Octet * buf,MsgFollowUp*);
    void msgUnpackDelayReq(Octet * buf, MsgDelayReq * delayreq);
    void msgUnpackDelayResp(Octet * buf,MsgDelayResp *);
    void msgUnpackPDelayReq(Octet * buf,MsgPDelayReq*);
    void msgUnpackPDelayResp(Octet * buf,MsgPDelayResp*);
    void msgUnpackPDelayRespFollowUp(Octet * buf,MsgPDelayRespFollowUp*);
    void msgUnpackManagement(Octet * buf,MsgManagement*, MsgHeader*, PtpClock *ptpClock);
    void msgPackHeader(Octet * buf,PtpClock*);
    void msgPackAnnounce(Octet * buf,PtpClock*);
    void msgPackSync(Octet * buf,Timestamp*,PtpClock*);
    void msgPackFollowUp(Octet * buf,Timestamp*,PtpClock*);
    void msgPackDelayReq(Octet * buf,Timestamp *,PtpClock *);
    void msgPackDelayResp(Octet * buf,MsgHeader *,Timestamp *,PtpClock *);
    void msgPackPDelayReq(Octet * buf,Timestamp*,PtpClock*);
    void msgPackPDelayResp(Octet * buf,MsgHeader*,Timestamp*,PtpClock*);
    void msgPackPDelayRespFollowUp(Octet * buf,MsgHeader*,Timestamp*,PtpClock*);
    void msgPackManagement(Octet * buf,MsgManagement*,PtpClock*);
    void msgPackManagementRespAck(Octet *,MsgManagement*,PtpClock*);
    void msgPackManagementTLV(Octet *,MsgManagement*, PtpClock*);
    void msgPackManagementErrorStatusTLV(Octet *,MsgManagement*,PtpClock*);
    
    void freeMMErrorStatusTLV(ManagementTLV*);
    void freeMMTLV(ManagementTLV*);
    
    void msgDump(PtpClock *ptpClock);
    void msgDebugHeader(MsgHeader *header);
    void msgDebugSync(MsgSync *sync);
    void msgDebugAnnounce(MsgAnnounce *announce);
    void msgDebugDelayReq(MsgDelayReq *req);
    void msgDebugFollowUp(MsgFollowUp *follow);
    void msgDebugDelayResp(MsgDelayResp *resp);
    void msgDebugManagement(MsgManagement *manage);
    
    void copyClockIdentity( ClockIdentity dest, ClockIdentity src);
    void copyPortIdentity( PortIdentity * dest, PortIdentity * src);
    
    void unpackMsgManagement(Octet *, MsgManagement*, PtpClock*);
    void packMsgManagement(MsgManagement*, Octet *);
    void unpackManagementTLV(Octet*, MsgManagement*, PtpClock*);
    void packManagementTLV(ManagementTLV*, Octet*);
    void freeManagementTLV(MsgManagement*);
    
    void unpackMMClockDescription( Octet* buf, MsgManagement*, PtpClock* );
    UInteger16 packMMClockDescription( MsgManagement*, Octet*);
    void freeMMClockDescription( MMClockDescription*);
    void unpackMMUserDescription( Octet* buf, MsgManagement*, PtpClock* );
    UInteger16 packMMUserDescription( MsgManagement*, Octet*);
    void freeMMUserDescription( MMUserDescription*);
    void freeMMErrorStatus( MMErrorStatus*);
    void unpackMMInitialize( Octet* buf, MsgManagement*, PtpClock* );
    UInteger16 packMMInitialize( MsgManagement*, Octet*);
    void unpackMMDefaultDataSet( Octet* buf, MsgManagement*, PtpClock* );
    UInteger16 packMMDefaultDataSet( MsgManagement*, Octet*);
    void unpackMMCurrentDataSet( Octet* buf, MsgManagement*, PtpClock* );
    UInteger16 packMMCurrentDataSet( MsgManagement*, Octet*);
    void unpackMMParentDataSet( Octet* buf, MsgManagement*, PtpClock* );
    UInteger16 packMMParentDataSet( MsgManagement*, Octet*);
    void unpackMMTimePropertiesDataSet( Octet* buf, MsgManagement*, PtpClock* );
    UInteger16 packMMTimePropertiesDataSet( MsgManagement*, Octet*);
    void unpackMMPortDataSet( Octet* buf, MsgManagement*, PtpClock* );
    UInteger16 packMMPortDataSet( MsgManagement*, Octet*);
    void unpackMMPriority1( Octet* buf, MsgManagement*, PtpClock* );
    UInteger16 packMMPriority1( MsgManagement*, Octet*);
    void unpackMMPriority2( Octet* buf, MsgManagement*, PtpClock* );
    UInteger16 packMMPriority2( MsgManagement*, Octet*);
    void unpackMMDomain( Octet* buf, MsgManagement*, PtpClock* );
    UInteger16 packMMDomain( MsgManagement*, Octet*);
    void unpackMMSlaveOnly( Octet* buf, MsgManagement*, PtpClock* );
    UInteger16 packMMSlaveOnly( MsgManagement*, Octet* );
    void unpackMMLogAnnounceInterval( Octet* buf, MsgManagement*, PtpClock* );
    UInteger16 packMMLogAnnounceInterval( MsgManagement*, Octet*);
    void unpackMMAnnounceReceiptTimeout( Octet* buf, MsgManagement*, PtpClock* );
    UInteger16 packMMAnnounceReceiptTimeout( MsgManagement*, Octet*);
    void unpackMMLogSyncInterval( Octet* buf, MsgManagement*, PtpClock* );
    UInteger16 packMMLogSyncInterval( MsgManagement*, Octet*);
    void unpackMMVersionNumber( Octet* buf, MsgManagement*, PtpClock* );
    UInteger16 packMMVersionNumber( MsgManagement*, Octet*);
    void unpackMMTime( Octet* buf, MsgManagement*, PtpClock * );
    UInteger16 packMMTime( MsgManagement*, Octet*);
    void unpackMMClockAccuracy( Octet* buf, MsgManagement*, PtpClock* );
    UInteger16 packMMClockAccuracy( MsgManagement*, Octet*);
    void unpackMMUtcProperties( Octet* buf, MsgManagement*, PtpClock* );
    UInteger16 packMMUtcProperties( MsgManagement*, Octet*);
    void unpackMMTraceabilityProperties( Octet* buf, MsgManagement*, PtpClock* );
    UInteger16 packMMTraceabilityProperties( MsgManagement*, Octet*);
    void unpackMMDelayMechanism( Octet* buf, MsgManagement*, PtpClock* );
    UInteger16 packMMDelayMechanism( MsgManagement*, Octet*);
    void unpackMMLogMinPdelayReqInterval( Octet* buf, MsgManagement*, PtpClock* );
    UInteger16 packMMLogMinPdelayReqInterval( MsgManagement*, Octet*);
    void unpackMMErrorStatus( Octet* buf, MsgManagement*, PtpClock* );
    UInteger16 packMMErrorStatus( MsgManagement*, Octet*);
    
    
    void unpackPortAddress( Octet* buf, PortAddress*, PtpClock*);
    void packPortAddress( PortAddress*, Octet*);
    void freePortAddress( PortAddress*);
    void unpackPTPText( Octet* buf, PTPText*, PtpClock*);
    void packPTPText( PTPText*, Octet*);
    void freePTPText( PTPText*);
    void unpackPhysicalAddress( Octet* buf, PhysicalAddress*, PtpClock*);
    void packPhysicalAddress( PhysicalAddress*, Octet*);
    void freePhysicalAddress( PhysicalAddress*);
    void unpackClockIdentity( Octet* buf, ClockIdentity *c, PtpClock*);
    void packClockIdentity( ClockIdentity *c, Octet* buf);
    void freeClockIdentity( ClockIdentity *c);
    void unpackClockQuality( Octet* buf, ClockQuality *c, PtpClock*);
    void packClockQuality( ClockQuality *c, Octet* buf);
    void freeClockQuality( ClockQuality *c);
    void unpackTimeInterval( Octet* buf, TimeInterval *t, PtpClock*);
    void packTimeInterval( TimeInterval *t, Octet* buf);
    void freeTimeInterval( TimeInterval *t);
    void unpackPortIdentity( Octet* buf, PortIdentity *p, PtpClock*);
    void packPortIdentity( PortIdentity *p, Octet*  buf);
    void freePortIdentity( PortIdentity *p);
    void unpackTimestamp( Octet* buf, Timestamp *t, PtpClock*);
    void packTimestamp( Timestamp *t, Octet* buf);
    void freeTimestamp( Timestamp *t);
    UInteger16 msgPackManagementResponse(Octet * buf,MsgHeader*,MsgManagement*,PtpClock*);

    void unpackMsgHeader(Octet *buf, MsgHeader *header, PtpClock *ptpClock);
    void packMsgHeader(MsgHeader *h, Octet *buf);
};

#endif // _MSG_H__


