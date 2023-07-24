/*
 * top for MyTarget and verilated verilog module Vptp_top
 */

#ifndef __TARGET_TOP_H__
#define __TARGET_TOP_H__

#include "MyTarget.h"
#include "Vptp_top.h"

class target_top
:     public sc_core::sc_module           	    // inherit from SC module base clase
{
public:
  // PORTS
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
  sc_out<bool> int_ptp_o;
  sc_in<bool>  pps_i;
  sc_out<bool> pps_o;

  // connection signals
  sc_signal<bool> bus2ip_rd_ce;
  sc_signal<bool> bus2ip_wr_ce;
  sc_signal<uint32_t> bus2ip_addr;
  sc_signal<uint32_t> bus2ip_data;
  sc_signal<uint32_t>  ip2bus_data;

public:
  // Constructor for LT target top
  target_top
  ( sc_core::sc_module_name   module_name           ///< SC module name
  , const unsigned int        ID                    ///< target ID
  , const unsigned int        clock_id              ///< corresponding to clockIdentity
  , const sc_core::sc_time    accept_delay          ///< accept delay (SC_TIME, SC_NS)
  );

  // destructor
  ~target_top();

  // Member Variables ===================================================

public:

  //for hierarchical parent-to-child binding refer to standard SystemC-1666-2011 16.1.1.2
  //and example in page 462 (section 13.2.5)
  tlm::tlm_target_socket<>  top_target_socket; ///<  target socket

  MyTarget m_target;
  Vptp_top m_ptp_top;

  const unsigned int        m_ID;                   ///< target ID
  const unsigned int        m_clock_id;             ///< corresponding to clockIdentity
  const sc_core::sc_time    m_accept_delay;         ///< accept delay
};

#endif /* __TARGET_TOP_H__ */

