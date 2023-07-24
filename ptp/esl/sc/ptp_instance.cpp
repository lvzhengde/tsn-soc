/*
 * This class instantiates components that compose the PTP instance 
 * See the constructor for companents instatntiated.
*/

#include "ptp_instance.h"    

ptp_instance::ptp_instance  
( sc_core::sc_module_name name             
  , const unsigned int  sw_type             ///< software type, 0: loopback test; 1: PTPd protocol test
  , const unsigned int  clock_id            ///< corresponding to clockIdentity
)
  : sc_core::sc_module                      /// Init SC base
    ( name                                 
    )
  , m_clock_id
    (
     clock_id
    )
  , m_bus                                   /// Init Simple Bus
    ( "m_bus"                              
    )
  , m_target_top                            /// Initiatlize at/lt target
    ( "m_target_top"                        /// module instance name
    , 201                                   /// Target ID is 201, also used as port id 
    , clock_id                              /// clockIdentity
    , sc_core::sc_time(20, sc_core::SC_NS)  /// accept delay
    )
  , m_initiator_top                         /// Init Instance 1 of LT initiator
    ( "m_initiator_top"                     /// module instance name
    , 101                                   /// Initiator ID is 101
    , sw_type                               /// software type
    , clock_id                              /// clockIdentity
    )
{
  /// bind TLM2 initiators to TLM2 target sockets on MyBus
  m_initiator_top.top_initiator_socket(m_bus.target_socket[0]);

  /// bind TLM2 targets to TLM2 initiator sockets on MyBus
  m_bus.initiator_socket[0](m_target_top.top_target_socket);

  /// hierarchical port connections
  m_target_top.bus2ip_clk   (bus2ip_clk  );
  m_target_top.bus2ip_rst_n (bus2ip_rst_n);
  m_target_top.tx_clk       (tx_clk   );
  m_target_top.tx_rst_n     (tx_rst_n );
  m_target_top.xge_txc_o    (xge_txc_o);
  m_target_top.xge_txd_o    (xge_txd_o);
  m_target_top.rx_clk       (rx_clk   );
  m_target_top.rx_rst_n     (rx_rst_n );
  m_target_top.xge_rxc_i    (xge_rxc_i);
  m_target_top.xge_rxd_i    (xge_rxd_i);
  m_target_top.rtc_clk      (rtc_clk  );
  m_target_top.rtc_rst_n    (rtc_rst_n);
  m_target_top.pps_i        (pps_i    );
  m_target_top.pps_o        (pps_o    );

  ///connect interrupt signal
  m_target_top.int_ptp_o    (int_ptp);
  m_initiator_top.int_ptp_i (int_ptp);

  /// Bind proc_rst_n to proc_rst_n hierarchical connection
  m_initiator_top.proc_rst_n(proc_rst_n);
}

