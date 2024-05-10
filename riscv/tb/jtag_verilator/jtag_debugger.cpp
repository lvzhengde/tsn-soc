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

#define DMI_ADDR_W  7

// DTM TAP register addresses
#define BYPASS_A    0x1f
#define IDCODE_A    0x01
#define DMI_A       0x11
#define DTMCS_A     0x10

// DTM OPCODE
#define DTM_OP_NOP   0 
#define DTM_OP_READ  1 
#define DTM_OP_WRITE 2 
#define OP_SUCCESS   0 
#define OP_FAIL      2 

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

    // wait reset release
    wait(1, SC_NS);
    wait(rst_n.posedge_event());

    // Set TAP to Test-Logic-Reset 
    tck_o.write(0);
    for (int i = 0; i < 8; i++) {
        tms_o.write(1);

        wait(100, SC_NS);
        tck_o.write(1);
        wait(100, SC_NS);
        tck_o.write(0);
    }

    // Set IR (DTM register address)
    char addr = DMI_A;
    printf("Set JTAG DTM IR address: %#x \n", addr);
    write_ir(addr);
    char rd_ir = get_ir();
    if (rd_ir != addr) {
        printf("IR is not set correctly! read IR = %#x \n", rd_ir);
    }

    sc_stop();

}

void jtag_debugger::write_ir(char ir)
{
    char shift_reg = ir;

    // Run-Test/Idle 
    tms_o.write(0);

    wait(100, SC_NS);
    tck_o.write(1);
    wait(100, SC_NS);
    tck_o.write(0);

    // Select-DR-Scan
    tms_o.write(1);

    wait(100, SC_NS);
    tck_o.write(1);
    wait(100, SC_NS);
    tck_o.write(0);

    // Select-IR-Scan
    tms_o.write(1);

    wait(100, SC_NS);
    tck_o.write(1);
    wait(100, SC_NS);
    tck_o.write(0);

    // Capture-IR
    tms_o.write(0);

    wait(100, SC_NS);
    tck_o.write(1);
    wait(100, SC_NS);
    tck_o.write(0);

    // Shift-IR
    tms_o.write(0);

    wait(100, SC_NS);
    tck_o.write(1);
    wait(100, SC_NS);
    tck_o.write(0);

    // Shift-IR / Exit-1-IR
    for (int i = 5; i > 0; i--) {
        if (shift_reg & 0x1)
            tdi_o.write(1);
        else
            tdi_o.write(0);

        if (i == 1)
            tms_o.write(1);

        wait(100, SC_NS);
        char in = tdo_i.read();
        tck_o.write(1);
        wait(100, SC_NS);
        tck_o.write(0);

        shift_reg = ((shift_reg >> 1) & 0xf) | ((in << 4) & 0x10);
    }

    // Pause-IR
    tms_o.write(0);

    wait(100, SC_NS);
    tck_o.write(1);
    wait(100, SC_NS);
    tck_o.write(0);

    // Exit-2-IR
    tms_o.write(1);

    wait(100, SC_NS);
    tck_o.write(1);
    wait(100, SC_NS);
    tck_o.write(0);

    // Update-IR
    tms_o.write(1);

    wait(100, SC_NS);
    tck_o.write(1);
    wait(100, SC_NS);
    tck_o.write(0);

    // Run-Test/Idle 
    tms_o.write(0);

    wait(100, SC_NS);
    tck_o.write(1);
    wait(100, SC_NS);
    tck_o.write(0);

    // stay in IDLE state
    // generate extra TCK pulses
    for (int i = 0; i < 8; i++) {
        wait(100, SC_NS);
        tck_o.write(1);
        wait(100, SC_NS);
        tck_o.write(0);
    }
}

// Set IR = DMI_A before call 
uint64_t jtag_debugger::access_dmi(uint64_t addr, uint64_t data, uint64_t op)
{
    uint64_t shift_reg;
    op = op & 0x3;
    data = data & 0xffffffff;
    addr = addr & 0x7f;
    shift_reg = op | (data << 2) | (addr << 34);

    // Run-Test/Idle 
    tms_o.write(0);

    wait(100, SC_NS);
    tck_o.write(1);
    wait(100, SC_NS);
    tck_o.write(0);

    // Select-DR-Scan
    tms_o.write(1);

    wait(100, SC_NS);
    tck_o.write(1);
    wait(100, SC_NS);
    tck_o.write(0);

    // Capture-DR
    tms_o.write(0);

    wait(100, SC_NS);
    tck_o.write(1);
    wait(100, SC_NS);
    tck_o.write(0);

    // Shift-DR
    tms_o.write(0);

    wait(100, SC_NS);
    tck_o.write(1);
    wait(100, SC_NS);
    tck_o.write(0);

    // Shift-DR / Exit-1-DR
    for (int i = (DMI_ADDR_W+34); i > 0; i--) {
        if (shift_reg & 0x1)
            tdi_o.write(1);
        else
            tdi_o.write(0);

        if (i == 1)
            tms_o.write(1);

        wait(100, SC_NS);
        uint64_t in = tdo_i.read();
        tck_o.write(1);
        wait(100, SC_NS);
        tck_o.write(0);

        shift_reg = (shift_reg >> 1) | (in << (DMI_ADDR_W+34-1));
    }

    // Pause-DR
    tms_o.write(0);

    wait(100, SC_NS);
    tck_o.write(1);
    wait(100, SC_NS);
    tck_o.write(0);

    // Exit-2-DR
    tms_o.write(1);

    wait(100, SC_NS);
    tck_o.write(1);
    wait(100, SC_NS);
    tck_o.write(0);

    // Update-DR
    tms_o.write(1);

    wait(100, SC_NS);
    tck_o.write(1);
    wait(100, SC_NS);
    tck_o.write(0);

    // Run-Test/Idle 
    tms_o.write(0);

    wait(100, SC_NS);
    tck_o.write(1);
    wait(100, SC_NS);
    tck_o.write(0);

    // stay in IDLE state
    // generate extra TCK pulses
    for (int i = 0; i < 8; i++) {
        wait(100, SC_NS);
        tck_o.write(1);
        wait(100, SC_NS);
        tck_o.write(0);
    }

    return shift_reg;
}

// Set related IR before call 
uint64_t jtag_debugger::read_dr(char ir)
{

    return 0;
}
