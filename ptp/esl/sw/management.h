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


