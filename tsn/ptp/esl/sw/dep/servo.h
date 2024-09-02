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

#ifndef _SERVO_H__
#define _SERVO_H__

#include "datatypes.h"


class servo : public base_data
{
public:
    //member variables
    uint32_t    m_initial_tick;

    uint32_t    m_updateOffset_count;

    int32_t     m_ofm_zline[OFM_DELAY_LEN];

    bool        m_frequency_syntonized;     //current syntonization state

    bool        m_frequency_syntonized_z1;  //1 sync delayed

    bool        m_frequency_syntonized_z2;  //2 sync delayed

 public: 
    //member methods
    servo(ptpd *pApp);

    void reset_operator_messages(RunTimeOpts * rtOpts, PtpClock * ptpClock);
    
    void initClock(RunTimeOpts * rtOpts, PtpClock * ptpClock);
    
    void updateDelay(one_way_delay_filter * owd_filt, RunTimeOpts * rtOpts, PtpClock * ptpClock, TimeInternal * correctionField);
    
    void updatePeerDelay(one_way_delay_filter * owd_filt, RunTimeOpts * rtOpts, 
        PtpClock * ptpClock, TimeInternal * correctionField, Boolean twoStep);
    
    void updateOffset(TimeInternal * send_time, TimeInternal * recv_time,
        offset_from_master_filter * ofm_filt, RunTimeOpts * rtOpts, PtpClock * ptpClock, TimeInternal * correctionField);
    
    void servo_perform_clock_step(RunTimeOpts * rtOpts, PtpClock * ptpClock);
    
    void warn_operator_fast_slewing(RunTimeOpts * rtOpts, PtpClock * ptpClock, Integer32 adj);
    
    void warn_operator_slow_slewing(RunTimeOpts * rtOpts, PtpClock * ptpClock );
    
    void adjTickRate_wrapper(RunTimeOpts * rtOpts, PtpClock * ptpClock, Integer32 adj);
    
    void updateClock(RunTimeOpts * rtOpts, PtpClock * ptpClock);

    bool syntonizeFrequency(RunTimeOpts * rtOpts, PtpClock * ptpClock);

};

#endif // _SERVO_H__


