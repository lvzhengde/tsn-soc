/*
 * This module performs:
 *   1. Instantiation of the controller and the MyInitiator 
 *      and the interconnecting sc_fifo's
 *   2. Binding of the Interconnect for the components
*/

#include "initiator_top.h"                         // this header file
#include "reporting.h"                             // reporting macro helpers

static const char *filename = "initiator_top.cpp"; ///< filename for reporting

/// Constructor

initiator_top::initiator_top    		       
( sc_core::sc_module_name name                    
, const unsigned int    ID                        
, const unsigned int    sw_type          /// software type, 0: loopback test; 1: PTPd protocol test
, const unsigned int    clock_id         ///< corresponding to clockIdentity
) 
  :sc_module           (name) 	         /// module instance name
  ,top_initiator_socket                  /// Init the socket
    ("top_initiator_socket")             
  ,m_ID                (ID)              /// initiator ID
  ,m_clock_id          (clock_id)        /// Clock ID
  ,m_initiator                           /// Init initiator
    ("m_initiator"                                            
    ,ID                                  /// ID for reporting                                        
    ,clock_id
    )
  ,m_controller                          /// Init controller
    ("m_controller"                              
    ,ID                                  /// ID for reporting
    ,sw_type                             /// software type
    ,clock_id                            /// Clock ID 
    )
{
  /// Bind ports to m_request_fifo between m_initiator and m_controller
  m_controller.request_out_port   (m_request_fifo);
  m_initiator.request_in_port     (m_request_fifo);
  
  /// Bind ports to m_response_fifo between m_initiator and m_controller
  m_initiator.response_out_port   (m_response_fifo);
  m_controller.response_in_port   (m_response_fifo);

  /// Bind initiator-socket to initiator-socket hierarchical connection 
  m_initiator.initiator_socket(top_initiator_socket);

  /// Bind int_ptp_i to int_ptp_i hierarchical connection
  m_controller.int_ptp_i(int_ptp_i);

  /// Bind proc_rst_n to proc_rst_n hierarchical connection
  m_controller.proc_rst_n(proc_rst_n);
}

