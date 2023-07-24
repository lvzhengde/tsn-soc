/*
 * MyInitiator.cpp
 */

#include "reporting.h"                            //< Reporting convenience macros
#include "MyInitiator.h"                          //< Our header

using namespace sc_core;
static const char *filename = "MyInitiator.cpp"; //< filename for reporting

// class constructor.
SC_HAS_PROCESS(MyInitiator);
MyInitiator::MyInitiator                          // constructor
( sc_module_name name                             // module name
, const unsigned int  ID                          // initiator ID
, const unsigned int  clock_id                    // corresponding to clockIdentity
)
: sc_module           (name)                      // initialize module name
, initiator_socket    ("initiator_socket")        // initiator socket
, m_delay             (0,sc_core::SC_NS)
, m_ID                (ID)                        // initialize initiator ID
, m_clock_id          (clock_id)                  // Clock ID
{                
  tlm_utils::tlm_quantumkeeper::set_global_quantum(sc_core::sc_time(500,sc_core::SC_NS));
  // register thread process
  SC_THREAD(initiator_thread);                  
}

/*==============================================================================
///  @fn MyInitiator::initiator_thread
///
///  @brief initiates non-blocking transport
///
///  @details
/// 
==============================================================================*/
void MyInitiator::initiator_thread(void)        ///< initiator thread
{  
  tlm::tlm_generic_payload *transaction_ptr;    ///< transaction pointer
  std::ostringstream       msg;                 ///< log message
    

  while (true) 
  {
//=============================================================================
// Read FIFO to Get new transaction GP from the controller
//=============================================================================
    transaction_ptr = request_in_port->read();  // get request from input fifo
    
    msg.str("");

    m_delay = m_quantum_keeper.get_local_time();
    
    msg << "Clock ID: " << m_clock_id
        << " Initiator: " << m_ID               
        << " b_transport(GP, " 
        << m_delay << ")";
    REPORT_INFO(filename,  __FUNCTION__, msg.str());

    initiator_socket->b_transport(*transaction_ptr, m_delay);
    
    gp_status = transaction_ptr->get_response_status();
    
    if(gp_status == tlm::TLM_OK_RESPONSE)
    {
       msg.str("");
       msg << "Clock ID: " << m_clock_id
           << " Initiator: " << m_ID               
           << " b_transport returned delay = " 
           << m_delay << " and quantum keeper to be set"
           << endl << "      ";
       REPORT_INFO(filename, __FUNCTION__, msg.str());
 
       m_quantum_keeper.set(m_delay);
       if(m_quantum_keeper.need_sync())
         {
           msg.str("");
           msg << "Clock ID: " << m_clock_id
               << " Initiator: " << m_ID               
               << " the quantum keeper needs synching";
           REPORT_INFO(filename, __FUNCTION__, msg.str());  
           
           m_quantum_keeper.sync();
           
           msg.str("");
           msg << "Clock ID: " << m_clock_id
               << " Initiator: " << m_ID               
               << " return from quantum keeper synch";
           REPORT_INFO(filename, __FUNCTION__, msg.str());
         }
    }
    else
    {
      msg << "Clock ID: " << m_clock_id
          << " Initiator: " << m_ID               
          << " Bad GP status returned = " << gp_status;
       REPORT_WARNING(filename,  __FUNCTION__, msg.str());
    }
    
    response_out_port->write(transaction_ptr);  // return txn to traffic gen
  } // end while true
} // end initiator_thread 

