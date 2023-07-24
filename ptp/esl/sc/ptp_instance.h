/*
 * Top level interconnect and instantiation for PTP instance
 * including initiator_top, MyBus, target_top
*/

#ifndef __PTP_INSTANCE_H__
#define __PTP_INSTANCE_H__

#include "target_top.h"                       // target
#include "initiator_top.h"                    // processor abstraction initiator
#include "MyBus.h"                            // Bus/Router Implementation

class ptp_instance                                  // Declare SC_MODULE
: public sc_core::sc_module                   
{
public:
	
/// Constructor	
  ptp_instance 
  ( sc_core::sc_module_name name
  , const unsigned int  sw_type                  ///< software type, 0: loopback test; 1: PTPd protocol test
  , const unsigned int  clock_id                 ///< corresponding to clockIdentity
  ); 

//ports and signals
  sc_in<bool> bus2ip_clk;
  sc_in<bool> bus2ip_rst_n;

  sc_in<bool> tx_clk;
  sc_in<bool> tx_rst_n;
  sc_out<uint32_t> xge_txc_o;
  sc_out<uint64_t> xge_txd_o;

  sc_in<bool> rx_clk;
  sc_in<bool> rx_rst_n;
  sc_in<uint32_t> xge_rxc_i;
  sc_in<uint64_t> xge_rxd_i;
  
  sc_in<bool> rtc_clk;
  sc_in<bool> rtc_rst_n;
  sc_in<bool>  pps_i;
  sc_out<bool> pps_o;

  /// port for resetting the processor, active low
  sc_in<bool> proc_rst_n;

  sc_signal<bool> int_ptp;

//Member Variables  ===========================================================
  public:
  MyBus<1, 1>             m_bus;                  ///< my simple bus
  target_top              m_target_top;           ///< combined target and ptp hardware top
  initiator_top           m_initiator_top;        ///< initiator emulate processor

  const unsigned int      m_clock_id;             ///< corresponding to clockIdentity
};
#endif /*__PTP_INSTANCE_H_ */

