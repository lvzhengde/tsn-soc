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

//DM register address
#define DMSTATUS_A   0x11
#define DMCONTROL_A  0x10
#define ABSTRACTCS_A 0x16
#define DATA0_A      0x04
#define DATA1_A      0x05
#define COMMAND_A    0x17

//CSR register address
#define CSR_DCSR           0x7b0
#define CSR_DPC            0x7b1
#define CSR_DSCRATCH0      0x7b2
#define CSR_DSCRATCH1      0x7b3

//--------------------------------------------------------------------
// CSR Registers - Simulation control
//--------------------------------------------------------------------
#define CSR_DSCRATCH       0x7b2
#define CSR_SIM_CTRL       0x8b2

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
    char ir = DMI_A;
    printf("Set JTAG DTM IR address: %#x \n", ir);
    write_ir(ir);
    char rd_ir = get_ir();
    if (rd_ir != ir) {
        printf("Error: IR is not set correctly! read IR = %#x \n", rd_ir);
        sc_stop();
    }

    // Read IDCODE
    write_ir(IDCODE_A);
    uint64_t idcode = read_dr(IDCODE_A);
    if (idcode != 0x11588603) {
        printf("Read idcode error! expected : 0x11588603, read : 0x%lx \n", idcode);
        sc_stop();
    } 
    else {
        printf("Read idcode = 0x%lx \n", idcode);
    }

    uint32_t addr;
    uint32_t value;
    uint32_t ret;

    // Write & Read CSR register
    addr = CSR_DSCRATCH1;
    value = 0xfedc1234;

    printf("Write CSR register, addr: %#x value: %#x \n", addr, value);
    write_csr(addr, value);

    ret = read_csr(addr);
    printf("Read CSR register, addr: %#x ret: %#x \n", addr, ret);

    if (ret != value) {
        printf("Error: Read / Write CSR Mismatch!! \n");
        sc_stop();
    }

    // Write & Read GPR register
    addr = 0x1f;
    value = 0xabcd5678;

    printf("Write GPR register, addr: %#x value: %#x \n", addr, value);
    write_gpr(addr, value);

    ret = read_gpr(addr);
    printf("Read GPR register, addr: %#x ret: %#x \n", addr, ret);

    if (ret != value) {
        printf("Error: Read / Write GPR Mismatch!! \n");
        sc_stop();
    }

    uint32_t haltreq;
    uint32_t resumereq;
    uint32_t hartreset;
    uint32_t dmactive;
    uint32_t dmcontrol;
    uint64_t dmi_ret;

    // Halt hart execution
    haltreq = 1;
    resumereq = 0;
    hartreset = 0;
    dmactive = 1;
    dmcontrol = (haltreq << 31) | (resumereq << 30) | (hartreset << 29) | dmactive;

    printf("\n Write to halt hart execution, dmcontrol = %#x \n", dmcontrol);
    dmi_ret = access_dmi(DMCONTROL_A, dmcontrol, DTM_OP_WRITE);
    if (dmi_ret & 0x3) {
        printf("Halt hart: access DMI busy / error ret = 0x%lx \n", dmi_ret);
        sc_stop();
    }

    // Should release haltreq
    haltreq = 0;
    dmcontrol = (haltreq << 31) | (resumereq << 30) | (hartreset << 29) | dmactive;

    printf("\n Write to release halt-request, dmcontrol = %#x \n", dmcontrol);
    dmi_ret = access_dmi(DMCONTROL_A, dmcontrol, DTM_OP_WRITE);
    if (dmi_ret & 0x3) {
        printf("Release halt-request: access DMI busy / error ret = 0x%lx \n", dmi_ret);
        sc_stop();
    }

    wait(10, SC_US);

    // Write & Read memory location
    addr = 0x80000600;
    value = 0x9a8bf532;

    printf("Write memory, addr: %#x value: %#x \n", addr, value);
    write_mem(addr, value);

    ret = read_mem(addr);
    printf("Read memory, addr: %#x ret: %#x \n", addr, ret);

    if (ret != value) {
        printf("Error: Read / Write memory Mismatch!! \n");
        sc_stop();
    }

    // Resume hart exectution
    haltreq = 0;
    resumereq = 1;
    hartreset = 0;
    dmactive = 1;
    dmcontrol = (haltreq << 31) | (resumereq << 30) | (hartreset << 29) | dmactive;

    printf("\n Write to resume hart execution, dmcontrol = %#x \n", dmcontrol);
    dmi_ret = access_dmi(DMCONTROL_A, dmcontrol, DTM_OP_WRITE);
    if (dmi_ret & 0x3) {
        printf("Resume hart: access DMI busy / error ret = 0x%lx \n", dmi_ret);
        sc_stop();
    }

    wait(50, SC_US);

    // Reset hart execution
    haltreq = 0;
    resumereq = 0;
    hartreset = 1;
    dmactive = 1;
    dmcontrol = (haltreq << 31) | (resumereq << 30) | (hartreset << 29) | dmactive;

    printf("\n\n Write to reset hart execution, dmcontrol = %#x \n", dmcontrol);
    dmi_ret = access_dmi(DMCONTROL_A, dmcontrol, DTM_OP_WRITE);
    if (dmi_ret & 0x3) {
        printf("Reset hart: access DMI busy / error ret = 0x%lx \n", dmi_ret);
        sc_stop();
    }

    // Deassert reset hart
    hartreset = 0;
    dmcontrol = (haltreq << 31) | (resumereq << 30) | (hartreset << 29) | dmactive;

    printf("\n Write to deassert reset, dmcontrol = %#x \n\n", dmcontrol);
    dmi_ret = access_dmi(DMCONTROL_A, dmcontrol, DTM_OP_WRITE);
    if (dmi_ret & 0x3) {
        printf("Deassert reset: access DMI busy / error ret = 0x%lx \n", dmi_ret);
        sc_stop();
    }

    wait(100, SC_US);

    printf("\n\n      TEST PASS!!!     \n");

    //write CSR_SIM_CTRL to exit simulation
    write_csr(CSR_SIM_CTRL, 0);
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
    int shift_len;
    
    switch (ir) {
        case IDCODE_A: 
        case DTMCS_A:
            shift_len = 32;
            break;
        case DMI_A:
            shift_len = DMI_ADDR_W+34;
            break;
        default:
            shift_len = 1;
    }

    uint64_t shift_reg = 0;

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
    for (int i = shift_len; i > 0; i--) {
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

        shift_reg = (shift_reg >> 1) | (in << (shift_len-1));
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

void jtag_debugger::write_csr(uint32_t addr, uint32_t value)
{
    uint64_t ret; 
    write_ir(DMI_A);

    // read DM abstractcs register
    ret = access_dmi(ABSTRACTCS_A, 0, DTM_OP_READ);
    if (ret & 0x3) {
        printf("Access DMI busy / error ret = 0x%lx \n", ret);
        return ;
    }
    ret = read_dr(DMI_A);
    uint64_t busy = (ret >> 12) & 0x1;
    uint64_t cmderr = (ret >> 8) & 0x7;
    if (busy != 0 || cmderr != 0) {
        printf("DM busy / error ret = 0x%lx \n", ret);
        return ;
    }

    // write data0
    ret = access_dmi(DATA0_A, value, DTM_OP_WRITE);

    // issue command
    uint32_t cmdtype = 0;
    uint32_t aarsize = 2;
    uint32_t transfer = 1;
    uint32_t write = 1;
    uint32_t regno = addr;

    uint32_t command = (cmdtype << 24) | (aarsize << 20) | (transfer << 17) | (write << 16) | regno ;
    ret = access_dmi(COMMAND_A, command, DTM_OP_WRITE);

    if (ret & 0x3)
        printf("Write DM command error, ret = 0x%lx \n", ret);

    return ;
}

uint32_t jtag_debugger::read_csr(uint32_t addr)
{
    uint64_t ret; 
    write_ir(DMI_A);

    // read DM abstractcs register
    ret = access_dmi(ABSTRACTCS_A, 0, DTM_OP_READ);
    if (ret & 0x3) {
        printf("Access DMI busy / error ret = 0x%lx \n", ret);
        return 0;
    }
    ret = read_dr(DMI_A);
    uint64_t busy = (ret >> 12) & 0x1;
    uint64_t cmderr = (ret >> 8) & 0x7;
    if (busy != 0 || cmderr != 0) {
        printf("DM busy / error ret = 0x%lx \n", ret);
        return 0;
    }

    // issue command
    uint32_t cmdtype = 0;
    uint32_t aarsize = 2;
    uint32_t transfer = 1;
    uint32_t write = 0;
    uint32_t regno = addr;

    uint32_t command = (cmdtype << 24) | (aarsize << 20) | (transfer << 17) | (write << 16) | regno ;
    ret = access_dmi(COMMAND_A, command, DTM_OP_WRITE);

    if (ret & 0x3) {
        printf("Write DM command error, ret = 0x%lx \n", ret);
        return 0;
    }

    // read data0
    ret = access_dmi(DATA0_A, 0, DTM_OP_READ);
    ret = read_dr(DMI_A);
    if (ret & 0x3) {
        printf("Read DM data0 error, ret = 0x%lx \n", ret);
        return 0;
    }

    ret = (ret >> 2) & 0xffffffff;

    return ret;
}

void jtag_debugger::write_gpr(uint32_t addr, uint32_t value)
{
    uint64_t ret; 
    write_ir(DMI_A);

    // read DM abstractcs register
    ret = access_dmi(ABSTRACTCS_A, 0, DTM_OP_READ);
    if (ret & 0x3) {
        printf("Access DMI busy / error ret = 0x%lx \n", ret);
        return ;
    }
    ret = read_dr(DMI_A);
    uint64_t busy = (ret >> 12) & 0x1;
    uint64_t cmderr = (ret >> 8) & 0x7;
    if (busy != 0 || cmderr != 0) {
        printf("DM busy / error ret = 0x%lx \n", ret);
        return ;
    }

    // write data0
    ret = access_dmi(DATA0_A, value, DTM_OP_WRITE);

    // issue command
    uint32_t cmdtype = 0;
    uint32_t aarsize = 2;
    uint32_t transfer = 1;
    uint32_t write = 1;
    uint32_t regno = addr + 0x1000;

    uint32_t command = (cmdtype << 24) | (aarsize << 20) | (transfer << 17) | (write << 16) | regno ;
    ret = access_dmi(COMMAND_A, command, DTM_OP_WRITE);

    if (ret & 0x3)
        printf("Write DM command error, ret = 0x%lx \n", ret);

    return ;
}

uint32_t jtag_debugger::read_gpr(uint32_t addr)
{
    uint64_t ret; 
    write_ir(DMI_A);

    // read DM abstractcs register
    ret = access_dmi(ABSTRACTCS_A, 0, DTM_OP_READ);
    if (ret & 0x3) {
        printf("Access DMI busy / error ret = 0x%lx \n", ret);
        return 0;
    }
    ret = read_dr(DMI_A);
    uint64_t busy = (ret >> 12) & 0x1;
    uint64_t cmderr = (ret >> 8) & 0x7;
    if (busy != 0 || cmderr != 0) {
        printf("DM busy / error ret = 0x%lx \n", ret);
        return 0;
    }

    // issue command
    uint32_t cmdtype = 0;
    uint32_t aarsize = 2;
    uint32_t transfer = 1;
    uint32_t write = 0;
    uint32_t regno = addr + 0x1000;

    uint32_t command = (cmdtype << 24) | (aarsize << 20) | (transfer << 17) | (write << 16) | regno ;
    ret = access_dmi(COMMAND_A, command, DTM_OP_WRITE);

    if (ret & 0x3) {
        printf("Write DM command error, ret = 0x%lx \n", ret);
        return 0;
    }

    // read data0
    ret = access_dmi(DATA0_A, 0, DTM_OP_READ);
    ret = read_dr(DMI_A);
    if (ret & 0x3) {
        printf("Read DM data0 error, ret = 0x%lx \n", ret);
        return 0;
    }

    ret = (ret >> 2) & 0xffffffff;

    return ret;
}

void jtag_debugger::write_mem(uint32_t addr, uint32_t value)
{
    uint64_t ret; 
    write_ir(DMI_A);

    // read DM abstractcs register
    ret = access_dmi(ABSTRACTCS_A, 0, DTM_OP_READ);
    if (ret & 0x3) {
        printf("Access DMI busy / error ret = 0x%lx \n", ret);
        return ;
    }
    ret = read_dr(DMI_A);
    uint64_t busy = (ret >> 12) & 0x1;
    uint64_t cmderr = (ret >> 8) & 0x7;
    if (busy != 0 || cmderr != 0) {
        printf("DM busy / error ret = 0x%lx \n", ret);
        return ;
    }

    // write data0--value
    ret = access_dmi(DATA0_A, value, DTM_OP_WRITE);

    // write data1--address
    ret = access_dmi(DATA1_A, addr, DTM_OP_WRITE);

    // issue command
    uint32_t cmdtype = 2;
    uint32_t aamsize = 2;
    uint32_t write = 1;

    uint32_t command = (cmdtype << 24) | (aamsize << 20) | (write << 16);
    ret = access_dmi(COMMAND_A, command, DTM_OP_WRITE);

    if (ret & 0x3)
        printf("Write DM command error, ret = 0x%lx \n", ret);

    return ;
}

uint32_t jtag_debugger::read_mem(uint32_t addr)
{
    uint64_t ret; 
    write_ir(DMI_A);

    // read DM abstractcs register
    ret = access_dmi(ABSTRACTCS_A, 0, DTM_OP_READ);
    if (ret & 0x3) {
        printf("Access DMI busy / error ret = 0x%lx \n", ret);
        return 0;
    }
    ret = read_dr(DMI_A);
    uint64_t busy = (ret >> 12) & 0x1;
    uint64_t cmderr = (ret >> 8) & 0x7;
    if (busy != 0 || cmderr != 0) {
        printf("DM busy / error ret = 0x%lx \n", ret);
        return 0;
    }

    // write data1--address
    ret = access_dmi(DATA1_A, addr, DTM_OP_WRITE);

    // issue command
    uint32_t cmdtype = 2;
    uint32_t aamsize = 2;
    uint32_t write = 0;

    uint32_t command = (cmdtype << 24) | (aamsize << 20) | (write << 16);
    ret = access_dmi(COMMAND_A, command, DTM_OP_WRITE);
    if (ret & 0x3) {
        printf("Write DM command error, ret = 0x%lx \n", ret);
        return 0;
    }

    // read data0
    ret = access_dmi(DATA0_A, 0, DTM_OP_READ);
    ret = read_dr(DMI_A);
    if (ret & 0x3) {
        printf("Read DM data0 error, ret = 0x%lx \n", ret);
        return 0;
    }

    ret = (ret >> 2) & 0xffffffff;

    return ret;
}
