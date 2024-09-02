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
 * top for MyTarget and verilated verilog module Vptp_top
-*/

#ifndef __TARGET_TOP_H__
#define __TARGET_TOP_H__

#include "MyTarget.h"
#include "Vptp_top.h"

class target_top
:     public sc_core::sc_module                 // inherit from SC module base clase
{
public:
    // PORTS
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
    
    sc_in<bool>      rtc_clk;
    sc_in<bool>      rtc_rst_n;
    sc_out<bool>     int_ptp_o;
    sc_in<bool>      pps_i;
    sc_out<bool>     pps_o;

    // connection signals
    sc_signal<bool>      bus2ip_rd_ce;
    sc_signal<bool>      bus2ip_wr_ce;
    sc_signal<uint32_t>  bus2ip_addr;
    sc_signal<uint32_t>  bus2ip_data;
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

