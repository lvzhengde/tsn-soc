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

#ifndef _MANAGEMENT_H__
#define _MANAGEMENT_H__

#include "datatypes.h"


class management : public base_data
{
public:
    //member variables

    //member methods
    management(ptpd *pApp);

    void initOutgoingMsgManagement(MsgManagement* incoming, MsgManagement* outgoing, PtpClock *ptpClock);
    
    void handleMMNullManagement(MsgManagement* incoming, MsgManagement* outgoing, PtpClock* ptpClock);
    
    void handleMMClockDescription(MsgManagement* incoming, MsgManagement* outgoing, PtpClock* ptpClock);
    
    void handleMMSlaveOnly(MsgManagement* incoming, MsgManagement* outgoing, PtpClock* ptpClock);
    
    void handleMMUserDescription(MsgManagement* incoming, MsgManagement* outgoing, PtpClock* ptpClock);
    
    void handleMMSaveInNonVolatileStorage(MsgManagement* incoming, MsgManagement* outgoing, PtpClock* ptpClock);
    
    void handleMMResetNonVolatileStorage(MsgManagement* incoming, MsgManagement* outgoing, PtpClock* ptpClock);
    
    void handleMMInitialize(MsgManagement* incoming, MsgManagement* outgoing, PtpClock* ptpClock);
    
    void handleMMDefaultDataSet(MsgManagement* incoming, MsgManagement* outgoing, PtpClock* ptpClock);
    
    void handleMMCurrentDataSet(MsgManagement* incoming, MsgManagement* outgoing, PtpClock* ptpClock);
    
    void handleMMParentDataSet(MsgManagement* incoming, MsgManagement* outgoing, PtpClock* ptpClock);
    
    void handleMMTimePropertiesDataSet(MsgManagement* incoming, MsgManagement* outgoing, PtpClock* ptpClock);
    
    void handleMMPortDataSet(MsgManagement* incoming, MsgManagement* outgoing, PtpClock* ptpClock);
    
    void handleMMPriority1(MsgManagement* incoming, MsgManagement* outgoing, PtpClock* ptpClock);
    
    void handleMMPriority2(MsgManagement* incoming, MsgManagement* outgoing, PtpClock* ptpClock);
    
    void handleMMDomain(MsgManagement* incoming, MsgManagement* outgoing, PtpClock* ptpClock);
    
    void handleMMLogAnnounceInterval(MsgManagement* incoming, MsgManagement* outgoing, PtpClock* ptpClock);
    
    void handleMMAnnounceReceiptTimeout(MsgManagement* incoming, MsgManagement* outgoing, PtpClock* ptpClock);
    
    void handleMMLogSyncInterval(MsgManagement* incoming, MsgManagement* outgoing, PtpClock* ptpClock);
    
    void handleMMVersionNumber(MsgManagement* incoming, MsgManagement* outgoing, PtpClock* ptpClock);
    
    void handleMMEnablePort(MsgManagement* incoming, MsgManagement* outgoing, PtpClock* ptpClock);
    
    void handleMMDisablePort(MsgManagement* incoming, MsgManagement* outgoing, PtpClock* ptpClock);
    
    void handleMMTime(MsgManagement* incoming, MsgManagement* outgoing, PtpClock* ptpClock);
    
    void handleMMClockAccuracy(MsgManagement* incoming, MsgManagement* outgoing, PtpClock* ptpClock);
    
    void handleMMUtcProperties(MsgManagement* incoming, MsgManagement* outgoing, PtpClock* ptpClock);
    
    void handleMMTraceabilityProperties(MsgManagement* incoming, MsgManagement* outgoing, PtpClock* ptpClock);
    
    void handleMMDelayMechanism(MsgManagement* incoming, MsgManagement* outgoing, PtpClock* ptpClock);
    
    void handleMMLogMinPdelayReqInterval(MsgManagement* incoming, MsgManagement* outgoing, PtpClock* ptpClock);
    
    void handleMMErrorStatus(MsgManagement *incoming);
    
    void handleErrorManagementMessage(MsgManagement *incoming, MsgManagement *outgoing, 
        PtpClock *ptpClock, Enumeration16 mgmtId, Enumeration16 errorId);

};

#endif // _MANAGEMENT_H__


