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
 * special LT target to illustrate bus access to memory mapped peripheral
 * adapted from SystemC TLM example
-*/

#ifndef __MYTARGET_H__
#define __MYTARGET_H__

#include <systemc.h>
#include "tlm.h"                                // TLM headers
#include "memory.h"
#include "tlm_utils/simple_target_socket.h"

class MyTarget
:     public sc_core::sc_module                 // inherit from SC module base clase
, virtual public tlm::tlm_fw_transport_if<>     /// inherit from TLM "forward interface"
{
public:
    // PORTS
    // The target writes and reads these signals to
    // access registers of peripheral
    sc_in<bool> bus2ip_clk;
    sc_in<bool> bus2ip_rst_n;
    sc_out<bool> bus2ip_rd_ce_o;
    sc_out<bool> bus2ip_wr_ce_o;
    sc_out<uint32_t> bus2ip_addr_o;
    sc_out<uint32_t> bus2ip_data_o;
    sc_in<uint32_t>  ip2bus_data_i;

public:
    // Constructor for LT target
    MyTarget
    ( sc_core::sc_module_name   module_name           ///< SC module name
    , const unsigned int        ID                    ///< target ID
    , const unsigned int        clock_id              ///< corresponding to clockIdentity
    , const sc_core::sc_time    accept_delay          ///< accept delay (SC_TIME, SC_NS)
    );

private:
    // thread to initialize and reset peripheral bus
    void reset_pbus(void);

    // task to write register
    void write_reg(const uint32_t addr, const uint32_t data);

    // task to read register
    void read_reg(const uint32_t addr, uint32_t &data); 

    // b_transport() - Blocking Transport
    void                                                // returns nothing
    b_transport
    ( tlm::tlm_generic_payload  &payload                // ref to payload
    , sc_core::sc_time          &delay_time             // delay time
    );
 
    /// Not implemented for this example but required by interface
    tlm::tlm_sync_enum                                // sync status
     nb_transport_fw                    
     ( tlm::tlm_generic_payload &gp                    ///< generic payoad pointer
     , tlm::tlm_phase           &phase                 ///< transaction phase
     , sc_core::sc_time         &delay_time            ///< time taken for transport
     )
     {
         return tlm::TLM_COMPLETED;
     }

    /// Not implemented for this example but required by interface
    bool                                              // success / failure
    get_direct_mem_ptr                       
    ( tlm::tlm_generic_payload   &payload,            // address + extensions
      tlm::tlm_dmi               &dmi_data            // DMI data
    )
    {
        return false;
    }

    
    /// Not implemented for this example but required by interface
    unsigned int                                      // result
    transport_dbg                            
    ( tlm::tlm_generic_payload  &payload              // debug payload
    )
    {
        return 0;
    }

    // Member Variables ===================================================

    public:

    typedef tlm::tlm_generic_payload  *gp_ptr;        ///< generic payload pointer

    //for hierarchical parent-to-child binding, simple_target_socket is not allowed
    tlm::tlm_target_socket<>  m_target_socket; ///<  target socket

    private:

    const unsigned int        m_ID;                   ///< target ID, corresponding to port id in fact
    const unsigned int        m_clock_id;             ///< corresponding to clockIdentity
    const sc_core::sc_time    m_accept_delay;         ///< accept delay
};


#endif /* __MYTARGET_H__ */
