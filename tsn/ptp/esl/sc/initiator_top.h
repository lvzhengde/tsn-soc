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
 * top for MyInitiator and controller
-*/

#ifndef __INITIATOR_TOP_H__
#define __INITIATOR_TOP_H__

#include "tlm.h"                                // TLM headers
#include "MyInitiator.h"               
#include "controller.h"                  

class initiator_top                                        
  : public sc_core::sc_module    
{
public:
    //Member Methods  
    initiator_top                                        
    ( sc_core::sc_module_name name                 ///< module name
    , const unsigned int  ID                       ///< initiator ID
    , const unsigned int  sw_type                  ///< software type, 0: loopback test; 1: PTPd protocol test
    , const unsigned int  clock_id                 ///< corresponding to clockIdentity
    );
  
public:
    //Member Variables/Objects  ====================================================
    
    tlm::tlm_initiator_socket< > top_initiator_socket;

    /// port for resetting the processor, active low
    sc_in<bool> proc_rst_n;

    // Port for interrupt request input
    sc_in<bool> int_ptp_i;

public:
    typedef tlm::tlm_generic_payload  *gp_ptr;   ///< Generic Payload pointer
    
    sc_core::sc_fifo <gp_ptr>  m_request_fifo;   ///< request SC FIFO
    sc_core::sc_fifo <gp_ptr>  m_response_fifo;  ///< response SC FIFO
    
    const unsigned int         m_ID;             ///< initiator ID
    const unsigned int         m_clock_id;       ///< corresponding to clockIdentity

    MyInitiator                m_initiator;      ///< TLM initiator instance
    controller                 m_controller;     ///< controller instance

};

#endif /* __INITIATOR_TOP_H__ */

