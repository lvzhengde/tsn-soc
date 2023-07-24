#ifndef _ARITH_H__
#define _ARITH_H__

#include "datatypes.h"


class arith : public base_data
{
public:
    //member methods
    arith(ptpd *pApp);
    
    void internalTime_to_integer64(TimeInternal internal, Integer64 *bigint);
    
    void integer64_to_internalTime(Integer64 bigint, TimeInternal * internal);
    
    void fromInternalTime(TimeInternal * internal, Timestamp * external);
    
    void toInternalTime(TimeInternal * internal, Timestamp * external);
    
    void ts_to_InternalTime(struct timespec *a,  TimeInternal * b);
    
    void tv_to_InternalTime(struct timeval *a,  TimeInternal * b);
    
    void normalizeTime(TimeInternal * r);
    
    void addTime(TimeInternal * r, const TimeInternal * x, const TimeInternal * y);
    
    void subTime(TimeInternal * r, const TimeInternal * x, const TimeInternal * y);
    
    void div2Time(TimeInternal *r);
    
    /* clear an internal time value */
    void clearTime(TimeInternal *time);
    
    /* sets a time value to a certain nanoseconds */
    void nano_to_Time(TimeInternal *time, int nano);
    
    /* greater than operation */
    int gtTime(TimeInternal *x, TimeInternal *y);
    
    /* remove sign from variable */
    void absTime(TimeInternal *time);
    
    /* if 2 time values are close enough for X nanoseconds */
    int is_Time_close(TimeInternal *x, TimeInternal *y, int nanos);
    
    int check_timestamp_is_fresh2(TimeInternal * timeA, TimeInternal * timeB);
    
    int check_timestamp_is_fresh(TimeInternal * timeA);
    
    int isTimeInternalNegative(const TimeInternal * p);
    
    float secondsToMidnight(void);
    
    float getPauseAfterMidnight(Integer8 announceInterval);
    
};

#endif // _ARITH_H__



