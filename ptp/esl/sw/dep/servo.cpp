/*-
 * Copyright (c) 2022-2023 Zhengde
 *
 * Copyright (c) 2011-2012 George V. Neville-Neil,
 *                         Steven Kreuzer, 
 *                         Martin Burnicki, 
 *                         Jan Breuer,
 *                         Gael Mace, 
 *                         Alexandre Van Kempen,
 *                         Inaqui Delgado,
 *                         Rick Ratzel,
 *                         National Instruments.
 * Copyright (c) 2009-2010 George V. Neville-Neil, 
 *                         Steven Kreuzer, 
 *                         Martin Burnicki, 
 *                         Jan Breuer,
 *                         Gael Mace, 
 *                         Alexandre Van Kempen
 *
 * Copyright (c) 2005-2008 Kendall Correll, Aidan Williams
 *
 * All Rights Reserved
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE AUTHORS ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE AUTHORS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
 * IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @file   servo.c
 * @date   Tue Jul 20 16:19:19 2010
 * 
 * @brief  Code which implements the clock servo in software.
 * 
 * 
 */

#include "common.h"


//constructor
servo::servo(ptpd *pApp)
{
    BASE_MEMBER_ASSIGN 

    if(m_pApp->m_pController->m_clock_id == 1) {
        m_initial_tick = INITIAL_TICK;
    }
    else {
        m_initial_tick = LP_INITIAL_TICK;
    }
}

void servo::reset_operator_messages(RunTimeOpts * rtOpts, PtpClock * ptpClock)
{
    ptpClock->warned_operator_slow_slewing = 0;
    ptpClock->warned_operator_fast_slewing = 0;

    //ptpClock->seen_servo_stable_first_time = FALSE;
}

void 
servo::initClock(RunTimeOpts * rtOpts, PtpClock * ptpClock)
{
    DBG("initClock\n");

    uint32_t base, addr, data = 0;
    base = RTC_BLK_ADDR << 8;

    //stop RTC
    m_pApp->m_ptr_sys->adjTickRate(0);

    //clear RTC
    addr = base + RTC_CTL_ADDR;
    REG_READ(addr, data);
    data |= 0x2;
    REG_WRITE(addr, data);

    //initial RTC using OS time
    TimeInternal  time;
    m_pApp->m_ptr_sys->getOsTime(&time);

    if (ptpClock->currentUtcOffsetValid) {
        time.seconds += ptpClock->currentUtcOffset;
    }

    uint64_t seconds = time.seconds;
    uint32_t nanoseconds = time.nanoseconds;

#ifdef PTPD_TLM_SIM
    //intentionally set large time difference between MASTER and SLAVE
    seconds += (int64_t)100.0 * (m_pController->m_clock_id + m_pApp->m_ptr_sys->getRand())
                    + (m_pController->m_clock_id - 1) * 7200;

    if(m_pController->m_clock_id == 1) {
        nanoseconds = (uint32_t)2.13235e8;
    }
    else {
        nanoseconds = (uint32_t)6.57916e8;
    }
#endif

    //write RTC offset registers
    addr = base + SC_OFST_ADDR0;
    data = (seconds >> 32) & 0xffff;
    REG_WRITE(addr, data);

    addr = base + SC_OFST_ADDR1;
    data = seconds & 0xffffffff;
    REG_WRITE(addr, data);

    addr = base + NS_OFST_ADDR;
    data = nanoseconds;
    REG_WRITE(addr, data);

    //cause adjustment to take effect
    addr = base + RTC_CTL_ADDR;
    REG_READ(addr, data);
    data |= 0x1;
    REG_WRITE(addr, data);

    //start RTC, set to initial tick increment value
    m_pApp->m_ptr_sys->adjTickRate(m_initial_tick);
    
    /* clear vars */
    ptpClock->owd_filt.s_exp = 0;   /* clears one-way delay filter */
    ptpClock->observed_drift = 0;

    /* clean more original filter variables */
    m_pApp->m_ptr_arith->clearTime(&ptpClock->offsetFromMaster);
    m_pApp->m_ptr_arith->clearTime(&ptpClock->meanPathDelay);
    m_pApp->m_ptr_arith->clearTime(&ptpClock->peerMeanPathDelay); //FIXME
    m_pApp->m_ptr_arith->clearTime(&ptpClock->delaySM);
    m_pApp->m_ptr_arith->clearTime(&ptpClock->delayMS);

    ptpClock->ofm_filt.y           = 0;
    ptpClock->ofm_filt.nsec_prev   = -1; /* AKB: -1 used for non-valid nsec time */
    ptpClock->ofm_filt.nsec_prev   = 0;

    ptpClock->owd_filt.s_exp       = 0;  /* clears one-way delay filter */
    rtOpts->offset_first_updated   = FALSE;

    ptpClock->char_last_msg='I';

    m_updateOffset_count = 0;
    memset(m_ofm_zline, 0, sizeof(m_ofm_zline));
    m_frequency_syntonized    = false;
    m_frequency_syntonized_z1 = false;
    m_frequency_syntonized_z2 = false;

    reset_operator_messages(rtOpts, ptpClock);
}

void 
servo::updateDelay(one_way_delay_filter * owd_filt, RunTimeOpts * rtOpts, PtpClock * ptpClock, TimeInternal * correctionField)
{
    /* todo: do all intermediate calculations on temp vars */
    TimeInternal prev_meanPathDelay = ptpClock->meanPathDelay;

    ptpClock->char_last_msg='D';

    {
    //perform basic checks, using local variables only
    TimeInternal slave_to_master_delay;

    
    /* calc 'slave_to_master_delay' */
    m_pApp->m_ptr_arith->subTime(&slave_to_master_delay, &ptpClock->delay_req_receive_time, 
        &ptpClock->delay_req_send_time);

    if (rtOpts->maxDelay && /* If maxDelay is 0 then it's OFF */
        rtOpts->offset_first_updated) {
        if ((slave_to_master_delay.nanoseconds < 0) &&
            (abs(slave_to_master_delay.nanoseconds) > rtOpts->maxDelay)) {
            INFO("updateDelay aborted, delay (sec: %d ns: %d) "
                 "is negative\n",
                 slave_to_master_delay.seconds,
                 slave_to_master_delay.nanoseconds);
            INFO("send (sec: %d ns: %d)\n   ",
                 ptpClock->delay_req_send_time.seconds,
                 ptpClock->delay_req_send_time.nanoseconds);
            INFO("recv (sec: %d n   s: %d)\n",
                 ptpClock->delay_req_receive_time.seconds,
                 ptpClock->delay_req_receive_time.nanoseconds);
            ptpClock->discardedPacketCount++;
            goto autotune;
        }

        if (slave_to_master_delay.seconds && rtOpts->maxDelay) {
            INFO("updateDelay aborted, delay greater than 1"
                 " second.\n");
            if (rtOpts->displayPackets)
                m_pApp->m_ptr_msg->msgDump(ptpClock);
            ptpClock->discardedPacketCount++;
            goto autotune;
        }

        if (slave_to_master_delay.nanoseconds > rtOpts->maxDelay) {
            INFO("updateDelay aborted, delay %d greater than "
                 "administratively set maximum %d\n",
                 slave_to_master_delay.nanoseconds, 
                 rtOpts->maxDelay);
            if (rtOpts->displayPackets)
                m_pApp->m_ptr_msg->msgDump(ptpClock);
            ptpClock->discardedPacketCount++;
            goto autotune;
            }
        }
    }

    /*
     * The packet has passed basic checks, so we'll:
     *   - update the global delaySM variable
     *   - calculate a new filtered MPD
     */
    if (rtOpts->offset_first_updated) {
        Integer16 s;

        ptpClock->discardedPacketCount--;
            
        /*
         * calc 'slave_to_master_delay' (Master to Slave delay is
         * already computed in updateOffset )
         */

        DBG("==> UpdateDelay():   %s\n",
            m_pApp->m_ptr_sys->dump_TimeInternal2("Req_RECV:", &ptpClock->delay_req_receive_time, "Req_SENT:", &ptpClock->delay_req_send_time));

        
        m_pApp->m_ptr_arith->subTime(&ptpClock->delaySM, &ptpClock->delay_req_receive_time, 
            &ptpClock->delay_req_send_time);

        /* update 'one_way_delay' */
        m_pApp->m_ptr_arith->addTime(&ptpClock->meanPathDelay, &ptpClock->delaySM, 
            &ptpClock->delayMS);

        /* Substract correctionField */
        m_pApp->m_ptr_arith->subTime(&ptpClock->meanPathDelay, &ptpClock->meanPathDelay, 
            correctionField);

        /* Compute one-way delay */
        m_pApp->m_ptr_arith->div2Time(&ptpClock->meanPathDelay);


        
        if (ptpClock->meanPathDelay.seconds) {
            DBG(" update delay: cannot filter with large OWD, clearing filter \n");
            INFO("Servo: Ignoring delayResp because of large OWD\n");
            
            owd_filt->s_exp = owd_filt->nsec_prev = 0;
            ptpClock->meanPathDelay = prev_meanPathDelay;   /* revert back to previous value */

            goto display;
        }


        if(ptpClock->meanPathDelay.nanoseconds < 0){
            DBG(" updatedelay: found negative value for OWD, so ignoring this value\n");
            ptpClock->meanPathDelay = prev_meanPathDelay;   /* revert back to previous value */

            goto display;
        }

        
        /* avoid overflowing filter */
        s = rtOpts->s;
        while (abs(owd_filt->y) >> (31 - s))
            --s;

        /* crank down filter cutoff by increasing 's_exp' */
        if (owd_filt->s_exp < 1)
            owd_filt->s_exp = 1;
        else if (owd_filt->s_exp < 1 << s)
            ++owd_filt->s_exp;
        else if (owd_filt->s_exp > 1 << s)
            owd_filt->s_exp = 1 << s;

        /* filter 'meanPathDelay' */
        owd_filt->y = (owd_filt->s_exp - 1) * 
            owd_filt->y / owd_filt->s_exp +
            (ptpClock->meanPathDelay.nanoseconds / 2 + 
             owd_filt->nsec_prev / 2) / owd_filt->s_exp;

        if(owd_filt->nsec_prev) {
            owd_filt->nsec_prev = ptpClock->meanPathDelay.nanoseconds;
            ptpClock->meanPathDelay.nanoseconds = owd_filt->y;
        }
        else {
            owd_filt->nsec_prev = ptpClock->meanPathDelay.nanoseconds;
        }    

        DBGV("delay filter %d, %d\n", owd_filt->y, owd_filt->s_exp);
    } else {
        INFO("Ignoring delayResp because we didn't receive any sync yet\n");
    }

autotune:

    if (rtOpts->maxDelayAutoTune) {
        if (ptpClock->discardedPacketCount >= 
            rtOpts->discardedPacketThreshold) {
            ptpClock->discardedPacketCount = 0;
            m_pApp->m_ptr_sys->increaseMaxDelayThreshold();
            goto display;
        } 
        if (ptpClock->discardedPacketCount <
            (rtOpts->discardedPacketThreshold * -1)) {
            ptpClock->discardedPacketCount = 0;
            m_pApp->m_ptr_sys->decreaseMaxDelayThreshold();
        }
    }

display:
    m_pApp->m_ptr_sys->displayStats(rtOpts, ptpClock);

}

void 
servo::updatePeerDelay(one_way_delay_filter * owd_filt, RunTimeOpts * rtOpts, PtpClock * ptpClock, 
        TimeInternal * correctionField, Boolean twoStep)
{
    Integer16 s;

    DBGV("updatePeerDelay\n");

    if (twoStep) {
        /* calc 'slave_to_master_delay' */
        m_pApp->m_ptr_arith->subTime(&ptpClock->pdelayMS, 
            &ptpClock->pdelay_resp_receive_time, 
            &ptpClock->pdelay_resp_send_time);
        m_pApp->m_ptr_arith->subTime(&ptpClock->pdelaySM, 
            &ptpClock->pdelay_req_receive_time, 
            &ptpClock->pdelay_req_send_time);

        /* update 'one_way_delay' */
        m_pApp->m_ptr_arith->addTime(&ptpClock->peerMeanPathDelay, 
            &ptpClock->pdelayMS, 
            &ptpClock->pdelaySM);

        /* Substract correctionField */
        m_pApp->m_ptr_arith->subTime(&ptpClock->peerMeanPathDelay, 
            &ptpClock->peerMeanPathDelay, correctionField);

        /* Compute one-way delay */
        m_pApp->m_ptr_arith->div2Time(&ptpClock->peerMeanPathDelay);
    } 
    else {
        /* One step clock */

        m_pApp->m_ptr_arith->subTime(&ptpClock->peerMeanPathDelay, 
            &ptpClock->pdelay_resp_receive_time, 
            &ptpClock->pdelay_req_send_time);

        /* Substract correctionField */
        m_pApp->m_ptr_arith->subTime(&ptpClock->peerMeanPathDelay, 
            &ptpClock->peerMeanPathDelay, correctionField);

        /* Compute one-way delay */
        m_pApp->m_ptr_arith->div2Time(&ptpClock->peerMeanPathDelay);
    }

    if (ptpClock->peerMeanPathDelay.seconds) {
        /* cannot filter with secs, clear filter */
        owd_filt->s_exp = owd_filt->nsec_prev = 0;
        return;
    }
    /* avoid overflowing filter */
    s = rtOpts->s;
    while (abs(owd_filt->y) >> (31 - s))
        --s;

    /* crank down filter cutoff by increasing 's_exp' */
    if (owd_filt->s_exp < 1)
        owd_filt->s_exp = 1;
    else if (owd_filt->s_exp < 1 << s)
        ++owd_filt->s_exp;
    else if (owd_filt->s_exp > 1 << s)
        owd_filt->s_exp = 1 << s;

    /* filter 'meanPathDelay' */
    owd_filt->y = (owd_filt->s_exp - 1) * 
        owd_filt->y / owd_filt->s_exp +
        (ptpClock->peerMeanPathDelay.nanoseconds / 2 + 
         owd_filt->nsec_prev / 2) / owd_filt->s_exp;

    if(owd_filt->nsec_prev) {
        owd_filt->nsec_prev = ptpClock->peerMeanPathDelay.nanoseconds;
        ptpClock->peerMeanPathDelay.nanoseconds = owd_filt->y;
    }
    else {
        owd_filt->nsec_prev = ptpClock->peerMeanPathDelay.nanoseconds;
    }

    DBGV("delay filter %d, %d\n", owd_filt->y, owd_filt->s_exp);
}

void 
servo::updateOffset(TimeInternal * send_time, TimeInternal * recv_time,
    offset_from_master_filter * ofm_filt, RunTimeOpts * rtOpts, PtpClock * ptpClock, TimeInternal * correctionField)
{
    DBGV("==> updateOffset\n");

    //perform basic checks, using only local variables
    TimeInternal master_to_slave_delay;

    /* calc 'master_to_slave_delay' */
    m_pApp->m_ptr_arith->subTime(&master_to_slave_delay, recv_time, send_time);

    if (rtOpts->maxDelay) { /* If maxDelay is 0 then it's OFF */
        if (master_to_slave_delay.seconds && rtOpts->maxDelay) {
            INFO("Warning: updateOffset, delay greater than 1"
                 " second.\n");
            /* msgDump(ptpClock); */
            //return;
        }

        if (abs(master_to_slave_delay.nanoseconds) > rtOpts->maxDelay) {
            INFO("Warning: updateOffset, abs(delay) %d greater than "
                 "administratively set maximum %d\n",
                 abs(master_to_slave_delay.nanoseconds), 
                 rtOpts->maxDelay);
            /* msgDump(ptpClock); */
            //return;
        }
    }

    // used for stats feedback 
    ptpClock->char_last_msg='S';
    ptpClock->last_packet_was_sync = TRUE;

    /*
     * The packet has passed basic checks, so we'll:
     *   - update the global delayMS variable
     *   - calculate a new filtered OFM
     */
    m_pApp->m_ptr_arith->subTime(&ptpClock->delayMS, recv_time, send_time);
    /* Used just for End to End mode. */

    /* Take care about correctionField */
    m_pApp->m_ptr_arith->subTime(&ptpClock->delayMS,
        &ptpClock->delayMS, correctionField);


    /* update 'offsetFromMaster' */
    if(m_frequency_syntonized == true) {
        if (ptpClock->delayMechanism == P2P) {
            m_pApp->m_ptr_arith->subTime(&ptpClock->offsetFromMaster, 
                &ptpClock->delayMS, 
                &ptpClock->peerMeanPathDelay);
        } else if (ptpClock->delayMechanism == E2E) {
            /* (End to End mode) */
            m_pApp->m_ptr_arith->subTime(&ptpClock->offsetFromMaster, 
                &ptpClock->delayMS, 
                &ptpClock->meanPathDelay);
        }
    }
    else {
        TimeInternal fixed_delay = {0, 0};
        m_pApp->m_ptr_arith->subTime(&ptpClock->offsetFromMaster, 
            &ptpClock->delayMS, 
            &fixed_delay);
    }

    if (ptpClock->offsetFromMaster.seconds || 
            abs(ptpClock->offsetFromMaster.nanoseconds) > rtOpts->maxDelay) {
        /* cannot filter with secs, or delay greater than maximum set, clear filter */
        ofm_filt->nsec_prev = 0;
        rtOpts->offset_first_updated = TRUE;
        return;
    }

    /* filter 'offsetFromMaster' */
    if(m_frequency_syntonized_z1 == true || m_frequency_syntonized == false) {
        ofm_filt->y = ptpClock->offsetFromMaster.nanoseconds / 2 + 
            ofm_filt->nsec_prev / 2;
        ofm_filt->nsec_prev = ptpClock->offsetFromMaster.nanoseconds;
        ptpClock->offsetFromMaster.nanoseconds = ofm_filt->y;
    }

    DBGV("offset filter %d\n", ofm_filt->y);

    /*
     * Offset must have been computed at least one time before 
     * computing end to end delay
     */
    rtOpts->offset_first_updated = TRUE;

    //update offsetFromMaster delayline
    for(int i = OFM_DELAY_LEN-1; i > 0; i--) {
        m_ofm_zline[i] = m_ofm_zline[i-1];
    }
    m_ofm_zline[0] = ptpClock->offsetFromMaster.nanoseconds;

    m_frequency_syntonized_z2 = m_frequency_syntonized_z1;
    m_frequency_syntonized_z1 = m_frequency_syntonized;
    m_frequency_syntonized    = syntonizeFrequency(rtOpts, ptpClock);

    m_updateOffset_count++;
}

void servo::servo_perform_clock_step(RunTimeOpts * rtOpts, PtpClock * ptpClock)
{
    if(rtOpts->noAdjust){
        WARNING("     Clock step blocked because of option -t\n");
        return;
    }

    //m_pApp->m_ptr_sys->adjTickRate(m_initial_tick);
    //ptpClock->observed_drift = 0;

    int64_t sec_offset = - ptpClock->offsetFromMaster.seconds;
    int32_t ns_offset  = - ptpClock->offsetFromMaster.nanoseconds;

    m_pApp->m_ptr_sys->setRtcValue(sec_offset, ns_offset);
}


void servo::warn_operator_fast_slewing(RunTimeOpts * rtOpts, PtpClock * ptpClock, Integer32 adj)
{
    if(ptpClock->warned_operator_fast_slewing == 0){
        if ((adj >= ADJ_FREQ_MAX) || ((adj <= -ADJ_FREQ_MAX))){
            ptpClock->warned_operator_fast_slewing = 1;

            NOTICE("Servo: Going to slew the clock with the maximum frequency adjustment\n");
        }
    }

}

void servo::warn_operator_slow_slewing(RunTimeOpts * rtOpts, PtpClock * ptpClock )
{
    if(ptpClock->warned_operator_slow_slewing == 0){
        ptpClock->warned_operator_slow_slewing = 1;
        ptpClock->warned_operator_fast_slewing = 1;

        /* 100 PPM frequency deviation, slewing at the maximum speed took 0.1ms per second */
        Integer32 adj = ptpClock->observed_drift;

        float estimated = (((abs(ptpClock->offsetFromMaster.seconds)) + 0.0) 
                           / (abs(adj+0.0) / m_initial_tick) / 3600.0);

        ALERT("Servo: %d seconds offset detected, will take %.1f hours to slew\n",
            ptpClock->offsetFromMaster.seconds,
            estimated
        );
    }
}


/*
 * this is a wrapper around adjTickRate to abstract extra operations
 */
void servo::adjTickRate_wrapper(RunTimeOpts * rtOpts, PtpClock * ptpClock, Integer32 adj)
{
    if (rtOpts->noAdjust){
        DBGV("adjTickRate2: noAdjust on, returning\n");
        return;
    }

    // compute corresponding PPM value 
    DBG2("     adjTickRate2: call adjTickRate to %f PPM \n", adj / PPM_DIV);

    m_pApp->m_ptr_sys->adjTickRate(m_initial_tick + adj);

    warn_operator_fast_slewing(rtOpts, ptpClock, adj);
}

void 
servo::updateClock(RunTimeOpts * rtOpts, PtpClock * ptpClock)
{
    Integer32 adj;

    DBGV("==> updateClock\n");


    if (rtOpts->maxReset) { /* If maxReset is 0 then it's OFF */
        if (ptpClock->offsetFromMaster.seconds && rtOpts->maxReset) {
            INFO("updateClock aborted, offset greater than 1"
                 " second.");
            if (rtOpts->displayPackets)
                m_pApp->m_ptr_msg->msgDump(ptpClock);
            goto display;
        }

        if (abs(ptpClock->offsetFromMaster.nanoseconds) > rtOpts->maxReset) {
            INFO("updateClock aborted, abs(offset) %d greater than "
                 "administratively set maximum %d\n",
                 abs(ptpClock->offsetFromMaster.nanoseconds), 
                 rtOpts->maxReset);
            if (rtOpts->displayPackets)
                m_pApp->m_ptr_msg->msgDump(ptpClock);
            goto display;
        }
    }


    if (ptpClock->offsetFromMaster.seconds || 
            abs(ptpClock->offsetFromMaster.nanoseconds) > rtOpts->maxDelay
            || (m_frequency_syntonized_z2 == false && m_frequency_syntonized_z1 == true)) {
        /* if secs or delay greater than maximum, reset clock or set freq adjustment to max */
        
        /* 
          if offset from master seconds is non-zero, then this is a "big jump:
          in time.  Check Run Time options to see if we will reset the clock or
          set frequency adjustment to max to adjust the time
        */

        /*
         * noAdjust     = cannot do any change to clock
         * noResetClock = if can change the clock, can we also step it?
         */
        if (!rtOpts->noAdjust) {
            /* */
            if (!rtOpts->noResetClock) {

                servo_perform_clock_step(rtOpts, ptpClock);
            } 
            else {
                /*
                 * potential problem:    "-1.1" is   a) -1:0.1 or b) -1:-0.1?
                 * if this code is right it implies the second case
                 */
                adj = ptpClock->offsetFromMaster.nanoseconds
                    > 0 ? ADJ_FREQ_MAX : -ADJ_FREQ_MAX;

                // does this hurt when the clock gets close to zero again?
                ptpClock->observed_drift = adj;

                warn_operator_slow_slewing(rtOpts, ptpClock);
                adjTickRate_wrapper(rtOpts, ptpClock, -adj);

                /* its not clear how the APPLE case works for large jumps */
            }
        }
    } 
    else {
        /* these variables contain the actual ai and ap to be used below */
        Integer32 ap = rtOpts->ap;
        Integer32 ai = rtOpts->ai;

        /* the PI controller */
        /* Offset from master is less than one second.  Use the the PI controller
         * to adjust the time
         */

        /* no negative or zero attenuation */
        /* FIXME: for strict analysis in PLL theory*/
        if (ap < PI_UNIT)
            ap = PI_UNIT;
        if (ai < PI_UNIT)
            ai = PI_UNIT;

        /* the accumulator for the I component */
        // original PI servo
        ptpClock->observed_drift += 
            ptpClock->offsetFromMaster.nanoseconds / ai;

        /* clamp the accumulator to ADJ_FREQ_MAX for sanity */
        if (ptpClock->observed_drift > ADJ_FREQ_MAX)
            ptpClock->observed_drift = ADJ_FREQ_MAX;
        else if (ptpClock->observed_drift < -ADJ_FREQ_MAX)
            ptpClock->observed_drift = -ADJ_FREQ_MAX;

        adj = ptpClock->offsetFromMaster.nanoseconds / ap +
            ptpClock->observed_drift;

        DBG("     Observed_drift with AI component: %d\n",
            ptpClock->observed_drift  );

        DBG("     After PI: Adj: %d   Drift: %d   OFM %d\n",
            adj, ptpClock->observed_drift , ptpClock->offsetFromMaster.nanoseconds);

        adjTickRate_wrapper(rtOpts, ptpClock, -adj);
    }

display:
    m_pApp->m_ptr_sys->displayStats(rtOpts, ptpClock);

    DBGV("\n--Offset Correction-- \n");
    DBGV("Raw offset from master:  %10ds %11dns\n",
        ptpClock->delayMS.seconds,
        ptpClock->delayMS.nanoseconds);

    DBGV("\n--Offset and Delay filtered-- \n");

    if (ptpClock->delayMechanism == P2P) {
        DBGV("one-way delay averaged (P2P):  %10ds %11dns\n",
            ptpClock->peerMeanPathDelay.seconds, 
            ptpClock->peerMeanPathDelay.nanoseconds);
    } else if (ptpClock->delayMechanism == E2E) {
        DBGV("one-way delay averaged (E2E):  %10ds %11dns\n",
            ptpClock->meanPathDelay.seconds, 
            ptpClock->meanPathDelay.nanoseconds);
    }

    DBGV("offset from master:      %10ds %11dns\n",
        ptpClock->offsetFromMaster.seconds, 
        ptpClock->offsetFromMaster.nanoseconds);
    DBGV("observed drift:    %10d,     %f PPM \n", ptpClock->observed_drift, 
                ptpClock->observed_drift / PPM_DIV);
}


bool servo::syntonizeFrequency(RunTimeOpts * rtOpts, PtpClock * ptpClock)
{
    if(m_frequency_syntonized == true) {
        return true;
    }

    if(m_updateOffset_count < (OFM_DELAY_LEN+1)) {
        return false;
    }

    bool syntonized = false;
    int32_t max_ofm = 0;
    int32_t max_pos = 0;

    //find extreme value and its position
    for(int32_t i = 0; i < OFM_DELAY_LEN; i++) {
        int32_t abs_ofm = abs(m_ofm_zline[i]);

        if(abs_ofm > max_ofm) {
            max_ofm = abs_ofm;
            max_pos = i;
        }
        else if(abs_ofm == max_ofm && i < OFM_DELAY_LEN/2) {
            max_pos = i;
        }
    }

    //achieve syntonized state or not
    int32_t time_dev = (int32_t)6.0 * CLOCK_PERIOD;
    if(max_ofm < time_dev && max_pos > 1 && max_pos < (OFM_DELAY_LEN-2)) {
        syntonized = true;
    }

    return syntonized;
}