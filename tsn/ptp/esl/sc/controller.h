/*
 * emulated controller for ptpd software
 */

#ifndef __CONTROLLER_H__
#define __CONTROLLER_H__

#include <systemc.h>
#include "tlm.h"                        // TLM headers
#include "ptp_memmap.h"

class ptp_timer;
class MyApp;

class controller                        // controller
: public sc_core::sc_module             // sc_module
{
public:
    // Member Methods  ==================================================== 

    // controller constructor
    controller                                
    ( sc_core::sc_module_name name                ///< module name for SC
    , const unsigned int  ID                      ///< initiator ID
    , const unsigned int  sw_type               ///< software type, 0: loopback test; 1: PTPd protocol test
    , const unsigned int  clock_id              ///< corresponding to clockIdentity
    );

    // destructor
    ~controller();

    // Method actually called by SC simulator to run ptpd software 
    void controller_thread (void); 

    //emulate interrupt service routine
    void isr_thread(void);

    // manipulate transaction through sc_fifo in/out interface
    void transaction_manip(tlm::tlm_generic_payload *ptxn);

    // emulate memory I/O for application SW
    void reg_read(const uint32_t addr, uint32_t &data);

    void reg_write(const uint32_t addr, const uint32_t data);

    void burst_read(const uint32_t addr, unsigned char *data, const unsigned  int length);

    void burst_write(const uint32_t addr, const unsigned char *data, const unsigned  int length); 

    //pointer to the ptp_timer object
    ptp_timer *ptr_ptp_timer;

    //pointer to application object
    MyApp *pApp;

public:   
    //=============================================================================
    // Member Variables 

    const unsigned int  m_ID;                         // initiator ID

    const unsigned int  m_sw_type;                    // 0: loopback test; 1: PTPd protocol test

    const unsigned int  m_clock_id;                   // corresponding to clockIdentity

private:
      
    typedef tlm::tlm_generic_payload  *gp_ptr;        // pointer to a generic payload
    

    tlm::tlm_generic_payload *m_ptxn;                 // pointer to the unique transaction generic payload

    unsigned char *m_data_ptr;                        // data buffer pointer for transaction, allocated large enough

    sc_mutex m_bus_mutex;                             // mutex to bus access through sc_fifo

    bool m_has_reset;                                 // has reset or not


public:

    sc_event m_ev_rx_all; //event for all received except ptp messages 

    sc_event m_ev_xms;    //event for xms interrupt

    sc_event m_ev_rx;     //event for ptp rx interrupt

    sc_event m_ev_tx;     //event for ptp tx interrupt

public:

    /// port for resetting the processor, active low
    sc_in<bool> proc_rst_n;

    /// Port for interrupt request input
    sc_in<bool> int_ptp_i;

    /// Port for requests to the initiator
    sc_core::sc_port<sc_core::sc_fifo_out_if <gp_ptr> > request_out_port; 
    
    /// Port for responses from the initiator
    sc_core::sc_port<sc_core::sc_fifo_in_if  <gp_ptr> > response_in_port;
};
#endif /* __CONTROLLER_H__ */


