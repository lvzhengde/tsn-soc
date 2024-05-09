/*+
 * Copyright (c) 2022-2024 Zhengde
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
 * Emulate RISC-V JTAG debugger in SystemC
-*/

#ifndef __JTAG_DEBUGGER_H__
#define __JTAG_DEBUGGER_H__

#include <systemc.h>
#include "Vriscv_top__Dpi.h"

class jtag_debugger : public sc_module
{
public:
    sc_in  <bool> rst_n;
    sc_out <bool> tck_o;
    sc_out <bool> tms_o;
    sc_out <bool> tdi_o;
    sc_in  <bool> tdo_i;

    //-------------------------------------------------------------
    // Constructor
    //-------------------------------------------------------------
    SC_HAS_PROCESS(jtag_debugger);
    jtag_debugger(sc_module_name name);

    // Threads
    void jtag_test(void);

    //-------------------------------------------------------------
    // Trace
    //-------------------------------------------------------------
    virtual void add_trace(sc_trace_file *vcd, std::string prefix)
    {
        #undef  TRACE_SIGNAL
        #define TRACE_SIGNAL(s) sc_trace(vcd,s,prefix + #s)

        TRACE_SIGNAL(rst_n);
        TRACE_SIGNAL(tck_o);
        TRACE_SIGNAL(tms_o);
        TRACE_SIGNAL(tdi_o);
        TRACE_SIGNAL(tdo_i);

        #undef  TRACE_SIGNAL
    }

    //-------------------------------------------------------------
    // Tasks / Functions
    //-------------------------------------------------------------
    void write_ir(char ir);

    void write_dmi(uint32_t abits, uint32_t data, uint32_t op);

    void read_dmi(uint32_t& abits, uint32_t& data, uint32_t& op);

    uint64_t read_dr(uint32_t ir);

    //set DPI scope
    void set_dpi_scope(const std::string dpi_scope)
    {
        //set scope for DPI functions
        const svScope scope = svGetScopeFromName(dpi_scope.c_str());
        assert(scope); // Check for nullptr if scope not found
        svSetScope(scope);
    }

    //-------------------------------------------------------------
    // Signals / Variables
    //-------------------------------------------------------------
private:

};

#endif /* __JTAG_DEBUGGER_H__ */
