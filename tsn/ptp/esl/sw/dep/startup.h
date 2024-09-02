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

#ifndef _STARTUP_H__
#define _STARTUP_H__

#include "datatypes.h"


class startup : public base_data 
{
public:
    //member variables

    /*
     * The following variables are not used in SystemC TLM simulation
     * listed here as references
     * Synchronous signal processing:
     * original idea: http://www.openbsd.org/cgi-bin/cvsweb/src/usr.sbin/ntpd/ntpd.c?rev=1.68;content-type=text%2Fplain
     */
    volatile sig_atomic_t  sigint_received ;
    volatile sig_atomic_t  sigterm_received;
    volatile sig_atomic_t  sighup_received ;
    volatile sig_atomic_t  sigusr1_received;
    volatile sig_atomic_t  sigusr2_received;

    //member methods
    //constructor
    startup(ptpd *pApp);

    void catch_signals(int sig); //in real system, should be static
    
    void do_signal_close(PtpClock * ptpClock);
    
    void do_signal_sighup(RunTimeOpts * rtOpts);
    
    void check_signals(RunTimeOpts * rtOpts, PtpClock * ptpClock);
    
    #ifdef RUNTIME_DEBUG
    void enable_runtime_debug(void );
    
    void disable_runtime_debug(void );
    #endif
    
    int lockfile(int fd);
    
    int daemon_already_running(void);
    
    int pgrep_matches(char *name);
    
    int query_shell(char *command, char *answer, int answer_size);
    
    int check_parallel_daemons(string name, int expected, int strict, RunTimeOpts * rtOpts);
    
    int logToFile(RunTimeOpts * rtOpts);
    
    int recordToFile(RunTimeOpts * rtOpts);
    
    void ptpdShutdown(PtpClock * ptpClock);
    
    void dump_command_line_parameters(int argc, char **argv);
    
    void display_short_help(string error);
    
    PtpClock *ptpdStartup(int argc, char **argv, Integer16 * ret, RunTimeOpts * rtOpts);

};

#endif // _STARTUP_H__

