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

#ifndef _DISPLAY_H__
#define _DISPLAY_H__

#include "datatypes.h"

class display : public base_data 
{
public:
    //member variables

    //member methods
    display(ptpd *pApp);

    void integer64_display(Integer64 * bigint);
    
    void uInteger48_display(UInteger48 * bigint);
    
    void timeInternal_display(TimeInternal * timeInternal);
    
    void timestamp_display(Timestamp * timestamp);
    
    void clockIdentity_display(ClockIdentity clockIdentity);
    
    void clockUUID_display(Octet * sourceUuid);
    
    void netPath_display(NetPath * net);
    
    void intervalTimer_display(IntervalTimer * ptimer);
    
    void timeInterval_display(TimeInterval * timeInterval);
    
    void portIdentity_display(PortIdentity * portIdentity);
    
    void clockQuality_display(ClockQuality * clockQuality);
    
    void PTPText_display(PTPText *p, PtpClock *ptpClock);
    
    void iFaceName_display(Octet * iFaceName);
    
    void unicast_display(Octet * unicast);
    
    void msgSync_display(MsgSync * sync);
    
    void msgHeader_display(MsgHeader * header);
    
    void msgAnnounce_display(MsgAnnounce * announce);
    
    void msgFollowUp_display(MsgFollowUp * follow);
    
    void msgDelayReq_display(MsgDelayReq * req);
    
    void msgDelayResp_display(MsgDelayResp * resp);
    
    void msgPDelayReq_display(MsgPDelayReq * preq);
    
    void msgPDelayResp_display(MsgPDelayResp * presp);
    
    void msgPDelayRespFollowUp_display(MsgPDelayRespFollowUp * prespfollow);
    
    void msgManagement_display(MsgManagement * manage);
    
    void mMSlaveOnly_display(MMSlaveOnly *slaveOnly, PtpClock *ptpClock);
    
    void mMClockDescription_display(MMClockDescription *clockDescription, PtpClock *ptpClock);
    
    void mMUserDescription_display(MMUserDescription* userDescription, PtpClock *ptpClock);
    
    void mMInitialize_display(MMInitialize* initialize, PtpClock *ptpClock);
    
    void mMDefaultDataSet_display(MMDefaultDataSet* defaultDataSet, PtpClock *ptpClock);
    
    void mMCurrentDataSet_display(MMCurrentDataSet* currentDataSet, PtpClock *ptpClock);
    
    void mMParentDataSet_display(MMParentDataSet* parentDataSet, PtpClock *ptpClock);
    
    void mMTimePropertiesDataSet_display(MMTimePropertiesDataSet* timePropertiesDataSet, PtpClock *ptpClock);
    
    void mMPortDataSet_display(MMPortDataSet* portDataSet, PtpClock *ptpClock);
    
    void mMPriority1_display(MMPriority1* priority1, PtpClock *ptpClock);
    
    void mMPriority2_display(MMPriority2* priority2, PtpClock *ptpClock);
    
    void mMDomain_display(MMDomain* domain, PtpClock *ptpClock);
    
    void mMLogAnnounceInterval_display(MMLogAnnounceInterval* logAnnounceInterval, PtpClock *ptpClock);
    
    void mMAnnounceReceiptTimeout_display(MMAnnounceReceiptTimeout* announceReceiptTimeout, PtpClock *ptpClock);
    
    void mMLogSyncInterval_display(MMLogSyncInterval* logSyncInterval, PtpClock *ptpClock);
    
    void mMVersionNumber_display(MMVersionNumber* versionNumber, PtpClock *ptpClock);
    
    void mMTime_display(MMTime* time, PtpClock *ptpClock);
    
    void mMClockAccuracy_display(MMClockAccuracy* clockAccuracy, PtpClock *ptpClock);
    
    void mMUtcProperties_display(MMUtcProperties* utcProperties, PtpClock *ptpClock);
    
    void mMTraceabilityProperties_display(MMTraceabilityProperties* traceabilityProperties, PtpClock *ptpClock);
    
    void mMDelayMechanism_display(MMDelayMechanism* delayMechanism, PtpClock *ptpClock);
    
    void mMLogMinPdelayReqInterval_display(MMLogMinPdelayReqInterval* logMinPdelayReqInterval, PtpClock *ptpClock);
    
    void mMErrorStatus_display(MMErrorStatus* errorStatus, PtpClock *ptpClock);
    
    void displayRunTimeOpts(RunTimeOpts * rtOpts);
    
    void displayDefault(PtpClock * ptpClock);
    
    void displayCurrent(PtpClock * ptpClock);
    
    void displayParent(PtpClock * ptpClock);
    
    void displayGlobal(PtpClock * ptpClock);
    
    void displayPort(PtpClock * ptpClock);
    
    void displayForeignMaster(PtpClock * ptpClock);
    
    void displayOthers(PtpClock * ptpClock);
    
    void displayBuffer(PtpClock * ptpClock);
    
    void displayPtpClock(PtpClock * ptpClock);
};

#endif // _DISPLAY_H__

