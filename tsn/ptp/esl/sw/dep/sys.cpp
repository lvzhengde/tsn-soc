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
 * @file   sys.c
 * @date   Tue Jul 20 16:19:46 2010
 *
 * @brief  Code to call kernel time routines and also display server statistics.
 *
 *
 */

#include "common.h"


#if defined(PTPD_LSBF)
Integer16 flip16(Integer16 x)
{
    return (((x) >> 8) & 0x00ff) | (((x) << 8) & 0xff00);
}

Integer32 flip32(Integer32 x)
{
    return (((x) >> 24) & 0x000000ff) | (((x) >> 8 ) & 0x0000ff00) |
         (((x) << 8 ) & 0x00ff0000) | (((x) << 24) & 0xff000000);
}
#endif

//constructor
sys::sys(ptpd *pApp)
{
    BASE_MEMBER_ASSIGN 

    logOpened = FALSE;

    start = 1;
}

/*
 returns a static char * for the representation of time, for debug purposes
 DO NOT call this twice in the same printf!
*/
char *sys::dump_TimeInternal(const TimeInternal * p)
{
    snprint_TimeInternal(buf0, 100, p);
    return buf0;
}


/*
 displays 2 timestamps and their strings in sequence, and the difference between then
 DO NOT call this twice in the same printf!
*/
char *sys::dump_TimeInternal2(const char *st1, const TimeInternal * p1, const char *st2, const TimeInternal * p2)
{
    int n = 0;

    /* display Timestamps */
    if (st1) {
        n += snprintf(buf1 + n, BUF_SIZE - n, "%s ", st1);
    }
    n += snprint_TimeInternal(buf1 + n, BUF_SIZE - n, p1);
    n += snprintf(buf1 + n, BUF_SIZE - n, "    ");

    if (st2) {
        n += snprintf(buf1 + n, BUF_SIZE - n, "%s ", st2);
    }
    n += snprint_TimeInternal(buf1 + n, BUF_SIZE - n, p2);
    n += snprintf(buf1 + n, BUF_SIZE - n, " ");

    /* display difference */
    TimeInternal r;
    m_pApp->m_ptr_arith->subTime(&r, p1, p2);
    n += snprintf(buf1 + n, BUF_SIZE - n, "   (diff: ");
    n += snprint_TimeInternal(buf1 + n, BUF_SIZE - n, &r);
    n += snprintf(buf1 + n, BUF_SIZE - n, ") ");

    return buf1;
}

int 
sys::snprint_TimeInternal(char *s, int max_len, const TimeInternal * p)
{
    int len = 0;

    /* always print either a space, or the leading "-". This makes the stat files columns-aligned */
    len += snprintf(&s[len], max_len - len, "%c",
        m_pApp->m_ptr_arith->isTimeInternalNegative(p)? '-':' ');

    len += snprintf(&s[len], max_len - len, "%lld.%09d",
        abs(p->seconds), abs(p->nanoseconds));

    return len;
}


/* debug aid: convert a time variable into a static char */
char *sys::time2st(const TimeInternal * p)
{
    snprint_TimeInternal(buf2, sizeof(buf2), p);
    return buf2;
}



void sys::DBG_time(const char *name, const TimeInternal  p)
{
    DBG("             %s:   %s\n", name, time2st(&p));

}


string
sys::translatePortState(PtpClock *ptpClock)
{
    string s;
    switch(ptpClock->portState) {
        case PTP_INITIALIZING:  s = "init";  break;
        case PTP_FAULTY:        s = "flt";   break;
        case PTP_LISTENING:
            /* seperate init-reset from real resets */
            if(ptpClock->reset_count == 1){
                s = "lstn_init";
            } else {
                s = "lstn_reset";
            }
            break;
        case PTP_PASSIVE:       s = "pass";  break;
        case PTP_UNCALIBRATED:  s = "uncl";  break;
        case PTP_SLAVE:         s = "slv";   break;
        case PTP_PRE_MASTER:    s = "pmst";  break;
        case PTP_MASTER:        s = "mst";   break;
        case PTP_DISABLED:      s = "dsbl";  break;
        default:                s = "?";     break;
    }
    return s;
}


int 
sys::snprint_ClockIdentity(char *s, int max_len, const ClockIdentity id)
{
    int len = 0;
    int i;

    for (i = 0; ;) {
        len += snprintf(&s[len], max_len - len, "%02x", (unsigned char) id[i]);

        if (++i >= CLOCK_IDENTITY_LENGTH)
            break;
    }

    return len;
}


/* show the mac address in an easy way */
int
sys::snprint_ClockIdentity_mac(char *s, int max_len, const ClockIdentity id)
{
    int len = 0;
    int i;

    for (i = 0; ;) {
        /* skip bytes 3 and 4 */
        if(!((i==3) || (i==4))){
            len += snprintf(&s[len], max_len - len, "%02x", (unsigned char) id[i]);

            if (++i >= CLOCK_IDENTITY_LENGTH)
                break;

            /* print a separator after each byte except the last one */
            len += snprintf(&s[len], max_len - len, "%s", ":");
        } else {

            i++;
        }
    }

    return len;
}

int 
sys::snprint_PortIdentity(char *s, int max_len, const PortIdentity *id)
{
    int len = 0;

#ifdef PRINT_MAC_ADDRESSES
    len += snprint_ClockIdentity_mac(&s[len], max_len - len, id->clockIdentity);
#else   
    len += snprint_ClockIdentity(&s[len], max_len - len, id->clockIdentity);
#endif

    len += snprintf(&s[len], max_len - len, "/%02x", (unsigned) id->portNumber);

    return len;
}


/*
 * Prints a message, randing from critical to debug.
 * This either prints the message to syslog, or with timestamp+state to stderr
 * (which has possibly been redirected to a file, using logtofile()/dup2().
 */
void
sys::message(int priority, const char * format, ...)
{
#ifdef DISPLAY_CLOCK_ID_INFO_ONLY
    if(m_pApp->m_pController->m_clock_id != DISPLAY_CLOCK_ID_INFO_ONLY) {
        return;
    }
#endif

    va_list ap;
    va_start(ap, format);

#ifdef RUNTIME_DEBUG
    if ((priority >= LOG_DEBUG) && (priority > m_pApp->m_rtOpts.debug_level)) {
        return;
    }
#endif

    if (m_pApp->m_rtOpts.useSysLog) {
#ifdef RUNTIME_DEBUG
        /*
         *  Syslog only has 8 message levels (3 bits)
         *  important: messages will only appear if "*.debug /var/log/debug" is on /etc/rsyslog.conf
         */
        if(priority > LOG_DEBUG){
            priority = LOG_DEBUG;
        }
#endif

        if (!logOpened) {
            openlog(PTPD_PROGNAME, 0, LOG_DAEMON);
            logOpened = TRUE;
        }
        vsyslog(priority, format, ap);

        /* Also warn operator during startup only */
        if (m_pApp->m_rtOpts.syslog_startup_messages_also_to_stdout &&
            (priority <= LOG_WARNING)
            ){
            va_start(ap, format);
            vfprintf(stderr, format, ap);
        }
    } else {
        char time_str[MAXTIMESTR];
        struct timeval now;

        fprintf(stderr, "    %s   (ptpd %-9s ", m_pApp->m_cpu_str.c_str(),
            priority == LOG_EMERG   ? "emergency)" :
            priority == LOG_ALERT   ? "alert)" :
            priority == LOG_CRIT    ? "critical)" :
            priority == LOG_ERR     ? "error)" :
            priority == LOG_WARNING ? "warning)" :
            priority == LOG_NOTICE  ? "notice)" :
            priority == LOG_INFO    ? "info)" :
            priority == LOG_DEBUG   ? "debug1)" :
            priority == LOG_DEBUG2  ? "debug2)" :
            priority == LOG_DEBUGV  ? "debug3)" :
            "unk)");

        /*
         * select debug tagged with timestamps. This will slow down PTP itself if you send a lot of messages!
         * it also can cause problems in nested debug statements (which are solved by turning the signal
         *  handling synchronous, and not calling this function inside assycnhonous signal processing)
         */
        uint64_t seconds = 0;
        uint32_t nanoseconds = 0;

        getRtcValue(seconds, nanoseconds);

        now.tv_sec = seconds;
        now.tv_usec = nanoseconds / 1000;

        strftime(time_str, MAXTIMESTR, "%X", localtime(&now.tv_sec));
        fprintf(stderr, "%s.%06d ", time_str, (int)now.tv_usec  );
        fprintf(stderr, " (%s)  ", m_pApp->m_ptr_ptpClock ?
               translatePortState(m_pApp->m_ptr_ptpClock).c_str() : "____");

        vfprintf(stderr, format, ap);
    }
    va_end(ap);
}

void
sys::increaseMaxDelayThreshold()
{
    NOTIFY("Increasing maxDelay threshold from %i to %i\n", m_pApp->m_rtOpts.maxDelay, 
           m_pApp->m_rtOpts.maxDelay << 1);

    m_pApp->m_rtOpts.maxDelay <<= 1;
}

void
sys::decreaseMaxDelayThreshold()
{
    if ((m_pApp->m_rtOpts.maxDelay >> 1) < m_pApp->m_rtOpts.origMaxDelay)
        return;
    NOTIFY("Decreasing maxDelay threshold from %i to %i\n", 
           m_pApp->m_rtOpts.maxDelay, m_pApp->m_rtOpts.maxDelay >> 1);
    m_pApp->m_rtOpts.maxDelay >>= 1;
}

void 
sys::displayStats(RunTimeOpts * rtOpts, PtpClock * ptpClock)
{
    int len = 0;
    TimeInternal now;
    time_t time_s;

    char time_str[MAXTIMESTR];

    if (!rtOpts->displayStats) {
        return;
    }

    if (start) {
        start = 0;
        printf("# Timestamp, State, Clock ID, One Way Delay, "
               "Offset From Master, Slave to Master, "
               "Master to Slave, Drift, Discarded Packet Count, Last packet Received\n");
        fflush(stdout);
    }
    memset(sbuf, ' ', sizeof(sbuf));

    getRtcValue(&now);

    /*
     * print one log entry per X seconds, to reduce disk usage.
     * This only happens to SLAVE SYNC statistics lines, which are the bulk of the log.
     * All other lines are printed, including delayreqs.
     */

    if ((ptpClock->portState == PTP_SLAVE) && (rtOpts->log_seconds_between_message)) {
        if(ptpClock->last_packet_was_sync){
            ptpClock->last_packet_was_sync = FALSE;
            if((now.seconds - prev_now.seconds) < rtOpts->log_seconds_between_message){
                //leave early and do not print the log message to save disk space
                DBGV("Skipped printing of Sync message because of option -V\n");
                return;
            }
            prev_now = now;
        }
    }
    ptpClock->last_packet_was_sync = FALSE;

    time_s = now.seconds;
    strftime(time_str, MAXTIMESTR, "%Y-%m-%d %X", localtime(&time_s));
    len += snprintf(sbuf + len, sizeof(sbuf) - len, "%s.%06d, %s, ",
               time_str, (int)now.nanoseconds/1000, /* Timestamp */
               translatePortState(ptpClock).c_str()); /* State */

    if (ptpClock->portState == PTP_SLAVE) {
        len += snprint_PortIdentity(sbuf + len, sizeof(sbuf) - len,
             &ptpClock->parentPortIdentity); /* Clock ID */

        /* 
         * if grandmaster ID differs from parent port ID then
         * also print GM ID 
         */
        if (memcmp(ptpClock->grandmasterIdentity, 
               ptpClock->parentPortIdentity.clockIdentity,
               CLOCK_IDENTITY_LENGTH)) {
            len += snprint_ClockIdentity(sbuf + len,
                             sizeof(sbuf) - len,
                             ptpClock->grandmasterIdentity);
        }

        len += snprintf(sbuf + len, sizeof(sbuf) - len, ", ");

        if(rtOpts->delayMechanism == E2E) {
            len += snprint_TimeInternal(sbuf + len, sizeof(sbuf) - len,
                            &ptpClock->meanPathDelay);
        } else {
            len += snprint_TimeInternal(sbuf + len, sizeof(sbuf) - len,
                            &ptpClock->peerMeanPathDelay);
        }

        len += snprintf(sbuf + len, sizeof(sbuf) - len, ", ");

        len += snprint_TimeInternal(sbuf + len, sizeof(sbuf) - len,
            &ptpClock->offsetFromMaster);

        /* print MS and SM with sign */
        len += snprintf(sbuf + len, sizeof(sbuf) - len, ", ");
            
        len += snprint_TimeInternal(sbuf + len, sizeof(sbuf) - len,
                &(ptpClock->delaySM));

        len += snprintf(sbuf + len, sizeof(sbuf) - len, ", ");

        len += snprint_TimeInternal(sbuf + len, sizeof(sbuf) - len,
                &(ptpClock->delayMS));

        len += sprintf(sbuf + len, ", %d, %i, %c",
                   ptpClock->observed_drift,
                   ptpClock->discardedPacketCount,
                   ptpClock->char_last_msg);

    } else {
        if ((ptpClock->portState == PTP_MASTER) || (ptpClock->portState == PTP_PASSIVE)) {

            len += snprint_PortIdentity(sbuf + len, sizeof(sbuf) - len,
                 &ptpClock->parentPortIdentity);
                             
            //len += snprintf(sbuf + len, sizeof(sbuf) - len, ")");
        }

        /* show the current reset number on the log */
        if (ptpClock->portState == PTP_LISTENING) {
            len += snprintf(sbuf + len,
                             sizeof(sbuf) - len,
                             " %d ", ptpClock->reset_count);
        }
    }
    
    /* add final \n in normal status lines */
    len += snprintf(sbuf + len, sizeof(sbuf) - len, "\n");

#if 0   /* NOTE: Do we want this? */
    if (rtOpts->nonDaemon) {
        /* in -C mode, adding an extra \n makes stats more clear intermixed with debug comments */
        len += snprintf(sbuf + len, sizeof(sbuf) - len, "\n");
    }
#endif
    //write(1, sbuf, len);
    printf("%s", sbuf);
}


void
sys::recordSync(RunTimeOpts * rtOpts, UInteger16 sequenceId, TimeInternal * time)
{
    if (rtOpts->recordFP) 
        fprintf(rtOpts->recordFP, "%d %llu\n", sequenceId, 
          ((time->seconds * 1000000000ULL) + time->nanoseconds)
        );
}

void 
sys::getOsTime(TimeInternal * time)
{
    struct timeval tv;
    gettimeofday(&tv, 0);
    time->seconds = tv.tv_sec;
    time->nanoseconds = tv.tv_usec * 1000;
}

//set OS time
//not used in TLM simulation
void 
sys::setOsTime(TimeInternal * time)
{
    struct timeval tv;
 
    tv.tv_sec = time->seconds;
    tv.tv_usec = time->nanoseconds / 1000;
    WARNING("Going to step the operating system clock to %ds %dns\n",
           time->seconds, time->nanoseconds);
    settimeofday(&tv, 0);
    WARNING("Finished stepping the operating system clock to %ds %dns\n",
           time->seconds, time->nanoseconds);
}


/* returns a double beween 0.0 and 1.0 */
double 
sys::getRand(void)
{
    return ((rand() * 1.0) / RAND_MAX);
}

/*
 * In PTP hardware
 * the byte order of normal register is little endian
 * but rx/tx frame buffer store data in network order (big endian)
 * 
 */

Boolean sys::adjTickRate(Integer32 tick_inc)
{
    uint32_t base, addr, data = 0;

    int32_t max_tick = m_pApp->m_ptr_servo->m_initial_tick + ADJ_FREQ_MAX;
    int32_t min_tick = m_pApp->m_ptr_servo->m_initial_tick - ADJ_FREQ_MAX;

    if(tick_inc > max_tick){
        tick_inc = max_tick;
    }
    else if (tick_inc < min_tick) {
        tick_inc = min_tick;
    }

    base = RTC_BLK_ADDR << 8;
    addr = base + TICK_INC_ADDR;
    data = tick_inc;

    REG_WRITE(addr, data);

    return true;
}

/**
 * get the current value of RTC located in PTP hardware 
 */
void sys::getRtcValue(uint64_t &seconds, uint32_t &nanoseconds)
{
    uint32_t base, addr, data = 0;
    base = RTC_BLK_ADDR << 8;

    addr = base + CUR_TM_ADDR0;
    REG_READ(addr, data);
    seconds = data;

    addr = base + CUR_TM_ADDR1;
    REG_READ(addr, data);
    seconds = (seconds << 16) + ((data >> 16) & 0xffff);
    nanoseconds = data & 0xffff;

    addr = base + CUR_TM_ADDR2;
    REG_READ(addr, data);
    nanoseconds = (nanoseconds << 16) + ((data >> 16) & 0xffff);
}

void sys::getRtcValue(TimeInternal *time)
{
    uint64_t seconds;
    uint32_t nanoseconds;
    getRtcValue(seconds, nanoseconds);   

    time->seconds = seconds;
    time->nanoseconds = nanoseconds;
}

/**
 * adjust the value of RTC 
 *     new RTC value = Current RTC value + Offset Value
 * parameters
 * sec_offset : offset of seconds field
 * ns_offset:   offset of nanoseconds field
 */
void sys::setRtcValue(int64_t sec_offset, int32_t ns_offset)
{
    uint32_t base, addr, data = 0;

    base = RTC_BLK_ADDR << 8;

    //set RTC
    addr = base + SC_OFST_ADDR0;
    data = (sec_offset >> 32) & 0xffff;
    REG_WRITE(addr, data);

    addr = base + SC_OFST_ADDR1;
    data = sec_offset & 0xffffffff;
    REG_WRITE(addr, data);

    addr = base + NS_OFST_ADDR;
    data = ns_offset;
    REG_WRITE(addr, data);

    addr = base + RTC_CTL_ADDR;
    //adjust rtc and set timer interval to 7.8125ms/10ms;
    uint32_t intxms = (m_pApp->m_rtOpts.int7_8125ms != 0) ? 1 : 0;
    data = 0x1 | (intxms << 2); 
    REG_WRITE(addr, data);
}

void sys::setRtcValue(TimeInternal *time)
{
    setRtcValue(time->seconds, time->nanoseconds);
}

void sys::getTxTimestampIdentity(TimestampIdentity &tsId)
{
    uint32_t base, addr, data = 0;
    base = TSU_BLK_ADDR << 8;

    //get timestamp
    addr = base + TX_TS_ADDR0;
    REG_READ(addr, data);
    tsId.seconds = data;

    addr = base + TX_TS_ADDR1;
    REG_READ(addr, data);
    tsId.seconds = (tsId.seconds << 16) | ((data >> 16) & 0xffff);
    tsId.nanoseconds = data & 0xffff;

    addr = base + TX_TS_ADDR2;
    REG_READ(addr, data);
    tsId.nanoseconds = (tsId.nanoseconds << 16) | ((data >> 16) & 0xffff);
    tsId.frac_nanoseconds = data & 0xffff;

    //get sourcePortIdentity
    addr = base + TX_SPF_ADDR0;
    REG_READ(addr, data);
    tsId.sourcePortIdentity[0] = (data >> 24) & 0xff;
    tsId.sourcePortIdentity[1] = (data >> 16) & 0xff;
    tsId.sourcePortIdentity[2] = (data >> 8) & 0xff;
    tsId.sourcePortIdentity[3] = data & 0xff;

    addr = base + TX_SPF_ADDR1;
    REG_READ(addr, data);
    tsId.sourcePortIdentity[4] = (data >> 24) & 0xff;
    tsId.sourcePortIdentity[5] = (data >> 16) & 0xff;
    tsId.sourcePortIdentity[6] = (data >> 8) & 0xff;
    tsId.sourcePortIdentity[7] = data & 0xff;

    addr = base + TX_SPF_ADDR2;
    REG_READ(addr, data);
    tsId.sourcePortIdentity[8] = (data >> 24) & 0xff;
    tsId.sourcePortIdentity[9] = (data >> 16) & 0xff;
    tsId.flagField[0] = (data >> 8) & 0xff;
    tsId.flagField[1] = data & 0xff;

    addr = base + TX_TVID_ADDR;
    REG_READ(addr, data);
    tsId.majorSdoId  = (data >> 28) & 0xf;
    tsId.messageType = (data >> 24) & 0xf;
    tsId.minorVersionPTP = (data >> 20) & 0xf;
    tsId.versionPTP      = (data >> 16) & 0xf;
    tsId.sequenceId      = data & 0xffff;
}

void sys::getRxTimestampIdentity(TimestampIdentity &tsId)
{
    uint32_t base, addr, data = 0;
    base = TSU_BLK_ADDR << 8;

    //get timestamp
    addr = base + RX_TS_ADDR0;
    REG_READ(addr, data);
    tsId.seconds = data;

    addr = base + RX_TS_ADDR1;
    REG_READ(addr, data);
    tsId.seconds = (tsId.seconds << 16) | ((data >> 16) & 0xffff);
    tsId.nanoseconds = data & 0xffff;

    addr = base + RX_TS_ADDR2;
    REG_READ(addr, data);
    tsId.nanoseconds = (tsId.nanoseconds << 16) | ((data >> 16) & 0xffff);
    tsId.frac_nanoseconds = data & 0xffff;

    //get sourcePortIdentity
    addr = base + RX_SPF_ADDR0;
    REG_READ(addr, data);
    tsId.sourcePortIdentity[0] = (data >> 24) & 0xff;
    tsId.sourcePortIdentity[1] = (data >> 16) & 0xff;
    tsId.sourcePortIdentity[2] = (data >> 8) & 0xff;
    tsId.sourcePortIdentity[3] = data & 0xff;

    addr = base + RX_SPF_ADDR1;
    REG_READ(addr, data);
    tsId.sourcePortIdentity[4] = (data >> 24) & 0xff;
    tsId.sourcePortIdentity[5] = (data >> 16) & 0xff;
    tsId.sourcePortIdentity[6] = (data >> 8) & 0xff;
    tsId.sourcePortIdentity[7] = data & 0xff;

    addr = base + RX_SPF_ADDR2;
    REG_READ(addr, data);
    tsId.sourcePortIdentity[8] = (data >> 24) & 0xff;
    tsId.sourcePortIdentity[9] = (data >> 16) & 0xff;
    tsId.flagField[0] = (data >> 8) & 0xff;
    tsId.flagField[1] = data & 0xff;

    addr = base + RX_TVID_ADDR;
    REG_READ(addr, data);
    tsId.majorSdoId  = (data >> 28) & 0xf;
    tsId.messageType = (data >> 24) & 0xf;
    tsId.minorVersionPTP = (data >> 20) & 0xf;
    tsId.versionPTP      = (data >> 16) & 0xf;
    tsId.sequenceId      = data & 0xffff;
}

/**
 * compare the RX identity got from timestamp registers with that of received PTP header
 * parameters
 * pT : pointer to timestampidentity 
 * pH : pointer to PTP header
 * return
 *   TRUE： match 
 *   FALSE: not match
 */
Boolean sys::compareRxIdentity(TimestampIdentity *pT, MsgHeader *pH)
{
    Boolean isMatch = TRUE; 

    if(pT->messageType != pH->messageType) {
        isMatch = FALSE;
        return isMatch;
    }

    if(pT->sequenceId != pH->sequenceId) {
        isMatch = FALSE;
        return isMatch;
    }

    PortIdentity portId;
    m_pApp->m_ptr_msg->copyClockIdentity(portId.clockIdentity, (Octet*)pT->sourcePortIdentity);
    portId.portNumber = flip16(*(UInteger16 *) (pT->sourcePortIdentity + 8));   

    if(memcmp(portId.clockIdentity, pH->sourcePortIdentity.clockIdentity, CLOCK_IDENTITY_LENGTH) 
        || (portId.portNumber != pH->sourcePortIdentity.portNumber)) {
        isMatch = FALSE;
    }

    return isMatch;
}

void sys::getPreciseRxTime(MsgHeader *header, TimeInternal *time,  RunTimeOpts *rtOpts, string strPrompt)
{
    //check timestamp embedded in header or not
    if(rtOpts->emb_ingressTime){
        int32_t t_ns = header->reserved2;
    
        if(t_ns < time->nanoseconds) {
            time->nanoseconds = t_ns;
        }
        else {   //wrap around occurred in nanoseconds
            time->seconds -= 1;
            time->nanoseconds = t_ns;
        }
    }
    else {
        TimestampIdentity tsId;
    
        m_pApp->m_ptr_sys->getRxTimestampIdentity(tsId);
        if(m_pApp->m_ptr_sys->compareRxIdentity(&tsId, header)) {
            time->seconds = tsId.seconds;
            time->nanoseconds = tsId.nanoseconds;
        }
        else {
            DBGV("%s: Identity of timestamp mismatch \n", strPrompt.c_str());
        }
    }
    
    /* subtract the inbound latency adjustment */
    m_pApp->m_ptr_arith->subTime(time, time, &rtOpts->inboundLatency);
}
