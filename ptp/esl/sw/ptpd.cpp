#include "common.h"


//constructor
ptpd::ptpd(controller *pController)
  : MyApp(pController)
{
    m_pApp = this;
    m_ptr_ptpClock = NULL;
    m_end_sim = 0;
}

//destructor
ptpd::~ptpd()
{

}

//initialize related variables
void ptpd::init()
{
    m_end_sim = 0;

    m_ptr_msg        = new msg       (this); 
    m_ptr_net        = new net       (this);
    m_ptr_ptp_timer  = new ptp_timer (this);
    m_ptr_servo      = new servo     (this); 
    m_ptr_startup    = new startup   (this); 
    m_ptr_sys        = new sys       (this); 
    m_ptr_arith      = new arith     (this);  
    m_ptr_bmc        = new bmc       (this); 
    m_ptr_display    = new display   (this); 
    m_ptr_management = new management(this); 
    m_ptr_protocol   = new protocol  (this); 
    m_ptr_transport  = new transport (this);

    m_cpu_str = "Clock ID: " + to_string(m_pController->m_clock_id);
    
    cout << "\r\n                "<< m_cpu_str  << "\r\n"
         << "=========================================================" << "\r\n" 
         << "            ####  PTPv2 Protocol Test Start!  #### " << "\r\n" << "\r\n";

    wait(200, SC_NS);
}

//run loop back test
void ptpd::exec()
{
    init();

    PtpClock *ptpClock;
    Integer16 ret;

    /* initialize run-time options to default values */
    m_rtOpts.announceInterval = DEFAULT_ANNOUNCE_INTERVAL;
    m_rtOpts.syncInterval = DEFAULT_SYNC_INTERVAL;

    m_rtOpts.clockQuality.clockAccuracy = DEFAULT_CLOCK_ACCURACY;
    m_rtOpts.clockQuality.clockClass = DEFAULT_CLOCK_CLASS;
    m_rtOpts.clockQuality.offsetScaledLogVariance = DEFAULT_CLOCK_VARIANCE;
    m_rtOpts.priority1 = DEFAULT_PRIORITY1;
    m_rtOpts.priority2 = DEFAULT_PRIORITY2;
    m_rtOpts.domainNumber = DEFAULT_DOMAIN_NUMBER;
    
    m_rtOpts.currentUtcOffset = DEFAULT_UTC_OFFSET;
    m_rtOpts.ifaceName[0] = '\0';
    m_rtOpts.do_unicast_mode = 0;

    m_rtOpts.noAdjust = NO_ADJUST;  // false
    // rtOpts.displayStats = FALSE;
    /* Deep display of all packets seen by the daemon */
    m_rtOpts.displayPackets = FALSE;
    m_rtOpts.ap = DEFAULT_AP;
    m_rtOpts.ai = DEFAULT_AI;
    m_rtOpts.s = DEFAULT_DELAY_S;
    m_rtOpts.inboundLatency.nanoseconds = DEFAULT_INBOUND_LATENCY;
    m_rtOpts.outboundLatency.nanoseconds = DEFAULT_OUTBOUND_LATENCY;
    m_rtOpts.max_foreign_records = DEFAULT_MAX_FOREIGN_RECORDS;
    // rtOpts.offset_first_updated = FALSE;
    // rtOpts.file[0] = 0;
    m_rtOpts.maxDelayAutoTune = FALSE;
    m_rtOpts.discardedPacketThreshold = 60;
    m_rtOpts.logFd = -1;
    m_rtOpts.recordFP = NULL;
    m_rtOpts.do_log_to_file = FALSE;
    m_rtOpts.do_record_quality_file = FALSE;
    m_rtOpts.nonDaemon = TRUE;

    /*
     * defaults for new options
     */
    m_rtOpts.slaveOnly = FALSE;
    m_rtOpts.ignore_delayreq_interval_master = FALSE;
    m_rtOpts.do_IGMP_refresh = FALSE;
    m_rtOpts.useSysLog       = FALSE;
    m_rtOpts.syslog_startup_messages_also_to_stdout = TRUE;     /* used to print inital messages both to syslog and screen */
    m_rtOpts.announceReceiptTimeout  = DEFAULT_ANNOUNCE_RECEIPT_TIMEOUT;
#ifdef RUNTIME_DEBUG
    m_rtOpts.debug_level = LOG_DEBUGV; //LOG_INFO;            /* by default debug messages as disabled, but INFO messages and below are printed */
#endif

    m_rtOpts.ttl = 1;
    m_rtOpts.delayMechanism   = DEFAULT_DELAY_MECHANISM;
    m_rtOpts.noResetClock     = DEFAULT_NO_RESET_CLOCK;
    m_rtOpts.log_seconds_between_message = 0;

    m_rtOpts.initial_delayreq = DEFAULT_DELAYREQ_INTERVAL;
    m_rtOpts.subsequent_delayreq = DEFAULT_DELAYREQ_INTERVAL;      // this will be updated if -g is given

    //HW engine related options
    m_rtOpts.networkProtocol  = IEEE_802_3;   
    m_rtOpts.layer2Encap      = 0;       //0: ether2, 1: SNAP, 2: PPPoE
    m_rtOpts.vlanTag          = 0;       //0: no vlan, 1: single vlan, 2: double vlan
    m_rtOpts.int7_8125ms      = 1;       //0: 10 ms interval, 1: 7.8125 ms interval 
    m_rtOpts.one_step         = (!TWO_STEP_FLAG) ? 1 : 0;       //0: two step, 1: one step
    m_rtOpts.emb_ingressTime  = 1;       //0: unchanged, 1: embed ingress time in received event frame

    m_rtOpts.maxDelay         = 300000;   //300us
    m_rtOpts.maxReset         = 0;        

    /* Initialize run time options with command line arguments */
    int argc = 3;
    char *argv[] = {(char *)"ptpv2d", (char *)"-e", (char *)"-z"};
    if (!(ptpClock = m_ptr_startup->ptpdStartup(argc, argv, &ret, &m_rtOpts)))
    {
        NOTIFY("ptpdv2 startup error, return value: %d\n", ret);
        return ;
    }

    /* member variable for message()*/
    m_ptr_ptpClock = ptpClock;

    /* do the protocol engine */
    m_ptr_protocol->protocolExec(&m_rtOpts, ptpClock);
    /* forever loop.. */

    m_ptr_startup->ptpdShutdown(ptpClock);

    NOTIFY("self shutdown completed!\n");

    //exit app and clean up
    quit();
}

//exit test and clean up
void ptpd::quit()
{
    m_pController->ptr_ptp_timer = NULL; 
    
    if(m_ptr_msg        != NULL) delete m_ptr_msg       ; 
    if(m_ptr_net        != NULL) delete m_ptr_net       ;
    if(m_ptr_ptp_timer  != NULL) delete m_ptr_ptp_timer ;
    if(m_ptr_servo      != NULL) delete m_ptr_servo     ; 
    if(m_ptr_startup    != NULL) delete m_ptr_startup   ; 
    if(m_ptr_sys        != NULL) delete m_ptr_sys       ; 
    if(m_ptr_arith      != NULL) delete m_ptr_arith     ;  
    if(m_ptr_bmc        != NULL) delete m_ptr_bmc       ; 
    if(m_ptr_display    != NULL) delete m_ptr_display   ; 
    if(m_ptr_management != NULL) delete m_ptr_management; 
    if(m_ptr_protocol   != NULL) delete m_ptr_protocol  ; 
    if(m_ptr_transport  != NULL) delete m_ptr_transport ; 

    wait(200, SC_NS);

    cout << "\r\n                  "<< m_cpu_str  << "\r\n"
         << "=========================================================" << "\r\n" 
         << "            ####  PTPv2 Protocol Test Complete!  #### " << "\r\n";
}

