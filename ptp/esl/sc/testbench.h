/*
 * Testbench instantiate the ptp_instances and delay channels
 * according to the setting of m_sw_type. 
*/
#include "ptp_instance.h"
#include "Vchannel_model.h"

class testbench
:     public sc_core::sc_module                 // inherit from SC module base clase
{ 
public:

    ///pointers to the instantiated modules
    ptp_instance    *pInstance;
    ptp_instance    *pInstance_lp;
    Vchannel_model  *pChannel;
    Vchannel_model  *pChannel_lp;

    ///connection signals
    sc_clock clk    ; //{"clk", 6.4, SC_NS, 0.5, 2, SC_NS, true};       
    sc_clock lp_clk ; //{"lp_clk", 6.4, SC_NS, 0.5, 2, SC_NS, true}; 
    sc_signal<bool> rst_n;
    sc_signal<bool> lp_rst_n;

    sc_signal<uint64_t> xge_txd;
    sc_signal<uint32_t> xge_txc;
    sc_signal<uint64_t> xge_rxd;
    sc_signal<uint32_t> xge_rxc;
    sc_signal<bool> pps_in;
    sc_signal<bool> pps_out;

    sc_signal<uint64_t> lp_xge_txd;
    sc_signal<uint32_t> lp_xge_txc;
    sc_signal<uint64_t> lp_xge_rxd;
    sc_signal<uint32_t> lp_xge_rxc;
    sc_signal<bool> lp_pps_in;
    sc_signal<bool> lp_pps_out;

    ///constructor
    testbench 
    ( sc_core::sc_module_name name
    , const unsigned int  sw_type                  ///< software type, 0: loopback test; 1: PTPd protocol test
    ); 

    ///destructor
    ~testbench();

    ///threads
    void reset_gen();

    void lp_reset_gen();

    void sim_proc();

private:
    ///member variables
    const unsigned int  m_sw_type;

};  

