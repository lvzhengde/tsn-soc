/*
 * top for MyInitiator and controller
 */

#ifndef __INITIATOR_TOP_H__
#define __INITIATOR_TOP_H__

#include "tlm.h"                                // TLM headers
#include "MyInitiator.h"               
#include "controller.h"                  

class initiator_top                          		       
  : public sc_core::sc_module    
{

public:
//Member Methods  
  initiator_top 	                                   
  ( sc_core::sc_module_name name                 ///< module name
  , const unsigned int  ID                       ///< initiator ID
  , const unsigned int  sw_type                  ///< software type, 0: loopback test; 1: PTPd protocol test
  , const unsigned int  clock_id                 ///< corresponding to clockIdentity
  );

  
public:
  
//Member Variables/Objects  ====================================================
  
  tlm::tlm_initiator_socket< > top_initiator_socket;

  /// port for resetting the processor, active low
  sc_in<bool> proc_rst_n;

  // Port for interrupt request input
  sc_in<bool> int_ptp_i;

public:
  
  typedef tlm::tlm_generic_payload  *gp_ptr;   ///< Generic Payload pointer
  
  sc_core::sc_fifo <gp_ptr>  m_request_fifo;   ///< request SC FIFO
  sc_core::sc_fifo <gp_ptr>  m_response_fifo;  ///< response SC FIFO
  
  const unsigned int         m_ID;             ///< initiator ID
  const unsigned int         m_clock_id;       ///< corresponding to clockIdentity

  MyInitiator                m_initiator;      ///< TLM initiator instance
  controller                 m_controller;     ///< controller instance

};

#endif /* __INITIATOR_TOP_H__ */

