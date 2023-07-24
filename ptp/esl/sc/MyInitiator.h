/*
 * Loosley Timed Initiator
 * This module only implements the blocking interface.
 * The  nb_transport_bw and invalidate_direct_memory_ptr are implemented
 * within the covenience socket
 */

#ifndef __MY_INITIATOR_H__
#define __MY_INITIATOR_H__

#include "tlm.h"      // TLM headers
#include "tlm_utils/tlm_quantumkeeper.h"
#include "tlm_utils/simple_initiator_socket.h"

class MyInitiator                                 // MyInitiator 
  :  public sc_core::sc_module                    // module base class 
{
public:
// Constructor ================================================================= 
    MyInitiator                                   // constructor
    ( sc_core::sc_module_name name                // module name
    , const unsigned int  ID                      // initiator ID
    , const unsigned int  clock_id                // corresponding to clockIdentity
    );
     
// Method Declarations =========================================================
    
//==============================================================================
//     @brief SC_THREAD that performs blocking call (lt call)
//
//     @details
//        This SC_THREAD takes transactions from controller via the 
//        sc_fifo attached to the request_in_port. Performs the blocking call.
//        After completing the blocking call the transactions are returned to
//        the controller for checking via the response_out_port
//
//============================================================================== 
  void initiator_thread (void);                    
  
  
// Variable and Object Declarations ============================================
public:
  
   typedef tlm::tlm_generic_payload  *gp_ptr;        // generic payload
   tlm_utils::simple_initiator_socket<MyInitiator> initiator_socket;
 
   sc_core::sc_port<sc_core::sc_fifo_in_if  <gp_ptr> > request_in_port;  
   sc_core::sc_port<sc_core::sc_fifo_out_if <gp_ptr> > response_out_port;
   
   sc_core::sc_time      m_delay;

private:
  tlm::tlm_response_status gp_status;
  unsigned int            m_ID;                     // initiator ID
  const unsigned int      m_clock_id;               // corresponding to clockIdentity
  sc_core::sc_time        m_end_rsp_delay;          // end response delay
  tlm_utils::tlm_quantumkeeper m_quantum_keeper;
  
}; 
 #endif /* __MY_INITIATOR_H__ */

