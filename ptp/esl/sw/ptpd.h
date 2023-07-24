/*
 * PTPv2 protocol test application
 */

#ifndef _PTPD_H__
#define _PTPD_H__

#include "MyApp.h"
#include "datatypes.h"


class ptpd: public MyApp
{
public:
    //member variables
    ptpd   *m_pApp;

    RunTimeOpts m_rtOpts;         //configuration data     

    PtpClock    *m_ptr_ptpClock;

    volatile sig_atomic_t  m_end_sim; 
    
    msg         *m_ptr_msg       ; 
    net         *m_ptr_net       ;
    ptp_timer   *m_ptr_ptp_timer ;
    servo       *m_ptr_servo     ; 
    startup     *m_ptr_startup   ; 
    sys         *m_ptr_sys       ; 
    arith       *m_ptr_arith     ;  
    bmc         *m_ptr_bmc       ; 
    display     *m_ptr_display   ; 
    management  *m_ptr_management; 
    protocol    *m_ptr_protocol  ; 
    transport   *m_ptr_transport ;

public:
    //member methods
    ptpd(controller *pController);
    
    virtual ~ptpd();
    
    virtual void init();
    
    virtual void exec();
    
    virtual void quit();

};

#endif // _PTPD_H__

