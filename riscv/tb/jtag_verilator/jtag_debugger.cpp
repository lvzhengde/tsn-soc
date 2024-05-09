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

#include "jtag_debugger.h"

//-------------------------------------------------------------
// Constructor
//-------------------------------------------------------------
jtag_debugger::jtag_debugger(sc_module_name name): sc_module(name)
{
    SC_THREAD(jtag_test);
}

void jtag_debugger::jtag_test(void)
{
    set_dpi_scope("tb.DUT.Vriscv_top.riscv_top.u_riscv_core.u_jtag_top.u_dtm");
    
    //initialize
    tck_o.write(1);
    tms_o.write(1);
    tdi_o.write(1);

    //wait reset release
    wait(1, SC_NS);
    wait(rst_n.posedge_event());

    //Set TAP to Test-Logic-Reset state
    tck_o.write(0);
    for (int i = 0; i < 8; i++) {
        tms_o.write(1);

        wait(100, SC_NS);
        tck_o.write(1);
        wait(100, SC_NS);
        tck_o.write(0);
    }

    sc_stop();

}

void jtag_debugger::write_ir(char ir)
{
    char shift_reg = ir;

    // Run-Test/Idle 
    tms_o.write(0);
    tck_o.write(0);

    wait(100, SC_NS);
    tck_o.write(1);
    wait(100, SC_NS);
    tck_o.write(0);

    // Select-DR-Scan
    tms_o.write(1);
    tck_o.write(0);

    wait(100, SC_NS);
    tck_o.write(1);
    wait(100, SC_NS);
    tck_o.write(0);

    // Select-IR-Scan
    tms_o.write(1);
    tck_o.write(0);

    wait(100, SC_NS);
    tck_o.write(1);
    wait(100, SC_NS);
    tck_o.write(0);

    // Capture-IR
    tms_o.write(0);
    tck_o.write(0);

    wait(100, SC_NS);
    tck_o.write(1);
    wait(100, SC_NS);
    tck_o.write(0);

    // Shift-IR
    tms_o.write(0);
    tck_o.write(0);

    wait(100, SC_NS);
    tck_o.write(1);
    wait(100, SC_NS);
    tck_o.write(0);

    // Shift-IR & Exit-1-IR
    for (int i = 5; i > 0; i--) {
        if (shift_reg & 0x1)
            tdi_o.write(1);
        else
            tdi_o.write(1);

        if (i == 1)
            tms_o.write(1);

        tck_o.write(0);

        wait(100, SC_NS);
        char in = tdo_i.read();
        tck_o.write(1);
        wait(100, SC_NS);
        tck_o.write(0);

        shift_reg = ((shift_reg >> 1) & 0xf) | ((in << 4) & 0x10);
    }
}

void jtag_debugger::write_dmi(uint32_t abits, uint32_t data, uint32_t op)
{

}

void jtag_debugger::read_dmi(uint32_t& abits, uint32_t& data, uint32_t& op)
{

}

uint64_t jtag_debugger::read_dr(uint32_t ir)
{

    return 0;
}
