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

