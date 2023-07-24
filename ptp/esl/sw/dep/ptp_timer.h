#ifndef _PTP_TIMER_H__
#define _PTP_TIMER_H__

#include "datatypes.h"


class ptp_timer : public base_data
{
private:
    //member variables
    volatile unsigned int elapsed;

    int operator_warned_interval_too_small; 

public:
    //member methods
    ptp_timer(ptpd *pApp);
    
    void catch_alarm(int sig);
    
    void initTimer(void);
    
    void timerUpdate(IntervalTimer * itimer);
    
    void timerStop(UInteger16 index, IntervalTimer * itimer);
    
    void timerStart(UInteger16 index, float interval, IntervalTimer * itimer);
    
    void timerStart_random(UInteger16 index, float interval, IntervalTimer * itimer);
    
    Boolean timerExpired(UInteger16 index, IntervalTimer * itimer);
};


#endif // _PTP_TIMER_H__


