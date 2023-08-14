/*+
 * Copyright (c) 2022-2023 Zhengde
 * 
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * 1 Redistributions of source code must retain the above copyright notice, this
 *   list of conditions and the following disclaimer.
 * 
 * 2 Redistributions in binary form must reproduce the above copyright notice,
 *   this list of conditions and the following disclaimer in the documentation
 *   and/or other materials provided with the distribution.
 * 
 * 3 Neither the name of the copyright holder nor the names of its
 *   contributors may be used to endorse or promote products derived from
 *   this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-*/

/*+
 * Testbench instantiate the ptp_instances and delay channels
 * according to the setting of m_sw_type. 
-*/

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

    sc_signal<bool>     tx_en;
    sc_signal<bool>     tx_er;
    sc_signal<uint32_t> txd;
    sc_signal<bool>     rx_dv;
    sc_signal<bool>     rx_er;
    sc_signal<uint32_t> rxd;
    sc_signal<bool> pps_in;
    sc_signal<bool> pps_out;

    sc_signal<bool>     lp_tx_en;
    sc_signal<bool>     lp_tx_er;
    sc_signal<uint32_t> lp_txd;
    sc_signal<bool>     lp_rx_dv;
    sc_signal<bool>     lp_rx_er;
    sc_signal<uint32_t> lp_rxd;
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

