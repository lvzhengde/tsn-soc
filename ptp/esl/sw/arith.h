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



