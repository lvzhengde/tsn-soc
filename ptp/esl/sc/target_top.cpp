/*
 * 
 * This module performs:
 *   1. Instantiation of the MyTarget and the Vptp_top
 *   2. Binding of the Interconnect for the components
 */


#include "target_top.h"                         // this header file
#include "reporting.h"                             // reporting macro helpers

static const char *filename = "target_top.cpp"; ///< filename for reporting

/// Constructor
target_top::target_top    		       
( sc_core::sc_module_name name                    
  , const unsigned int        ID                    ///< target ID
  , const unsigned int        clock_id              ///< corresponding to clockIdentity
  , const sc_core::sc_time    accept_delay          ///< accept delay (SC_TIME, SC_NS)
) 
  :sc_module           (name) 	         // module instance name
  ,top_target_socket   ("top_target_socket")
  ,m_ID                (ID)              // target ID
  ,m_clock_id          (clock_id)
  ,m_accept_delay      (accept_delay)
  ,m_target
     ("m_target"
      ,ID
      ,clock_id
      ,accept_delay
     )
  ,m_ptp_top           ("m_ptp_top")
{

  // Bind target-socket to target-socket hierarchical connection 
  // binding direction must be parent-to-child
  top_target_socket.bind(m_target.m_target_socket);

  // port connections for m_target
  m_target.bus2ip_clk(bus2ip_clk);
  m_target.bus2ip_rst_n(bus2ip_rst_n);
  m_target.bus2ip_rd_ce_o(bus2ip_rd_ce);
  m_target.bus2ip_wr_ce_o(bus2ip_wr_ce);
  m_target.bus2ip_addr_o(bus2ip_addr);
  m_target.bus2ip_data_o(bus2ip_data);
  m_target.ip2bus_data_i(ip2bus_data);

  // port connections for m_ptp_top
  m_ptp_top.tx_clk(tx_clk);
  m_ptp_top.tx_rst_n(tx_rst_n);
  m_ptp_top.xge_txd_o(xge_txd_o);
  m_ptp_top.xge_txc_o(xge_txc_o);

  m_ptp_top.rx_clk(rx_clk);
  m_ptp_top.rx_rst_n(rx_rst_n);
  m_ptp_top.xge_rxd_i(xge_rxd_i);
  m_ptp_top.xge_rxc_i(xge_rxc_i);

  m_ptp_top.bus2ip_clk(bus2ip_clk);   
  m_ptp_top.bus2ip_rst_n(bus2ip_rst_n); 
  m_ptp_top.bus2ip_rd_ce_i(bus2ip_rd_ce);   
  m_ptp_top.bus2ip_wr_ce_i(bus2ip_wr_ce);  
  m_ptp_top.bus2ip_addr_i(bus2ip_addr);
  m_ptp_top.bus2ip_data_i(bus2ip_data);
  m_ptp_top.ip2bus_data_o(ip2bus_data);   

  m_ptp_top.rtc_clk(rtc_clk);
  m_ptp_top.rtc_rst_n(rtc_rst_n);    
  m_ptp_top.int_ptp_o(int_ptp_o);
  m_ptp_top.pps_i(pps_i);        
  m_ptp_top.pps_o(pps_o);           
}

// destructor
target_top::~target_top()
{
  // Final model cleanup
  m_ptp_top.final();
}
