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

#ifndef _SYS_H__
#define _SYS_H__

#include "datatypes.h"

#if defined(PTPD_LSBF)
    Integer16 flip16(Integer16 x);
    
    Integer32 flip32(Integer32 x);
#endif

class sys : public base_data 
{
public:
    //member variables
    char buf0[100];

    char buf1[BUF_SIZE];

    char buf2[1000];

    Boolean logOpened;

    int start;

    char sbuf[SCREEN_BUFSZ];

    TimeInternal prev_now;

    //member methods
    sys(ptpd *pApp);

    char *dump_TimeInternal(const TimeInternal * p);
    
    char *dump_TimeInternal2(const char *st1, const TimeInternal * p1, const char *st2, const TimeInternal * p2);
    
    int snprint_TimeInternal(char *s, int max_len, const TimeInternal * p);
    
    char *time2st(const TimeInternal * p);
    
    void DBG_time(const char *name, const TimeInternal  p);
    

    string translatePortState(PtpClock *ptpClock);
    
    int snprint_ClockIdentity(char *s, int max_len, const ClockIdentity id);
    
    int snprint_ClockIdentity_mac(char *s, int max_len, const ClockIdentity id);
    
    int snprint_PortIdentity(char *s, int max_len, const PortIdentity *id);
    
    void message(int priority, const char * format, ...);
    
    void increaseMaxDelayThreshold();
    
    void decreaseMaxDelayThreshold();
    
    void displayStats(RunTimeOpts * rtOpts, PtpClock * ptpClock);
    
    void recordSync(RunTimeOpts * rtOpts, UInteger16 sequenceId, TimeInternal * time);
    
    void getOsTime(TimeInternal * time);
    
    void setOsTime(TimeInternal * time);
    
    double getRand(void);
    
    Boolean adjTickRate(Integer32 tick_inc);

    void getRtcValue(uint64_t &seconds, uint32_t &nanoseconds);

    void getRtcValue(TimeInternal *time);

    void setRtcValue(int64_t sec_offset, int32_t ns_offset);

    void setRtcValue(TimeInternal *time);
    
    void getTxTimestampIdentity(TimestampIdentity &tsId);

    void getRxTimestampIdentity(TimestampIdentity &tsId);

    Boolean compareRxIdentity(TimestampIdentity *pT, MsgHeader *pH);

    void getPreciseRxTime(MsgHeader *header, TimeInternal *time,  RunTimeOpts *rtOpts, string strPrompt);

};

#endif // _SYS_H__


