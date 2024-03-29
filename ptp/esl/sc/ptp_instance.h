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
 * Top level interconnect and instantiation for PTP instance
 * including initiator_top, MyBus, target_top
-*/

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
    sc_in<bool>      bus2ip_clk;
    sc_in<bool>      bus2ip_rst_n;

    sc_in<bool>      tx_clk;
    sc_in<bool>      tx_rst_n;
    sc_out<bool>     tx_en_o;
    sc_out<bool>     tx_er_o;
    sc_out<uint32_t> txd_o;

    sc_in<bool>      rx_clk;
    sc_in<bool>      rx_rst_n;
    sc_in<bool>      rx_dv_i;
    sc_in<bool>      rx_er_i;
    sc_in<uint32_t>  rxd_i;
    
    sc_in<bool>  rtc_clk;
    sc_in<bool>  rtc_rst_n;
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

