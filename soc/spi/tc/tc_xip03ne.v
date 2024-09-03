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
 *  Description : Test case for XIP (eXecute In Place) read,
 *                using normal read instruction (03h, EXTADD=1),
 *                4-byte address.
 *                XIP is determined by address decoding.
 *  File        : tc_xip03ne.v
-*/

`include "spi_defines.v"
`include "tb_spi_defines.v"

module tc_xip03ne;

    tb_top tb();

    integer  seed    = 20;
    integer  xip_len = 16; //xip_len <= 16
    integer  idx ;
    integer  i, j;

    reg  [31:0] wr_data[0:255];
    reg  [31:0] rd_data[0:255];
    reg  [31:0] temp      ;
    reg  [31:0] cr_reg    ;
    reg  [31:0] ecr_reg   ;
    reg  [31:0] addr      ; 
    reg  [31:0] fifo_data ;

    reg lsb_first  = 1'b0;
    reg inhibit    = 1'b0;
    reg msse       = 1'b0;
    reg rxfifo_rst = 1'b1;
    reg txfifo_rst = 1'b1;
    reg cpha       = 1'b0;
    reg cpol       = 1'b0;
    reg master     = 1'b1;
    reg spe        = 1'b1;
    reg loop       = 1'b0;    

    reg  [15:0] sck_ratio     = `SCK_RATIO_DEFAULT;
    reg  [ 7:0] xip_read_code = 8'h03;
    reg         extadd        = 1'b1 ;
    reg         dummy_cycles  = 1'b0 ;

    initial begin
        temp    = 0;   
        addr    = 0; 
    
        #10;
        $display($time,, "XIP (eXecute In Place) of SPI Nor Flash Memory, Simulation Start!");

        $display($time,, "Reset testbench...");
        tb.reset;
        #10;

        //-----------------------------------------------------------------
        // Prepare Flash Memory Data
        //-----------------------------------------------------------------        
        for (idx = 0; idx < xip_len; idx = idx+1) begin
            wr_data[idx] = $random(seed);
            temp = wr_data[idx];
            for (i = 0; i < 4; i = i+1) begin
                j = (idx << 2) + i;
                tb.u_flash_model.flash_mem[j] = temp[7:0];
                temp = temp >> 8;
            end
            $display($time,, "%m idx = %d, prepare flash memory data = 0x%08x", idx, wr_data[idx]);
        end

        //-----------------------------------------------------------------
        // Initialize SPI Control
        //-----------------------------------------------------------------        
        cr_reg = {22'b0, lsb_first, inhibit, msse, rxfifo_rst, txfifo_rst, cpha, cpol, master, spe, loop};
        addr = `SPI_REG_BASEADDR + `SPI_CR;
        tb.u_axi4_master.wdata[0] = cr_reg;
        tb.u_axi4_master.axi_master_write(addr, 1, 1, 0);  
        #100;

        //-----------------------------------------------------------------
        // Set SPI Extended Control Register
        //-----------------------------------------------------------------        
        ecr_reg = {6'b0, dummy_cycles, extadd, xip_read_code[7:0], sck_ratio[15:0]};
        addr = `SPI_REG_BASEADDR + `SPI_ECR;
        tb.u_axi4_master.wdata[0] = ecr_reg;
        tb.u_axi4_master.axi_master_write(addr, 1, 1, 0);  
        #100;

        //-----------------------------------------------------------------
        // Write Enable SPI Flash
        //-----------------------------------------------------------------        
        //slave select, active low
        addr = `SPI_REG_BASEADDR + `SPI_SSR;
        tb.u_axi4_master.wdata[0] = 32'b0;
        tb.u_axi4_master.axi_master_write(addr, 1, 1, 0);  
        #100;

        //Write instruction code to tx fifo
        addr = `SPI_REG_BASEADDR + `SPI_DTR;
        tb.u_axi4_master.wdata[0] = {24'h0, `WREN};
        tb.u_axi4_master.axi_master_write(addr, 1, 1, 0);  

        $display($time,, "Write enable SPI flash... ");

        wait_txfifo_empty;

        //Slave de-select
        addr = `SPI_REG_BASEADDR + `SPI_SSR;
        tb.u_axi4_master.wdata[0] = 32'b1;
        tb.u_axi4_master.axi_master_write(addr, 1, 1, 0);  
        #100;

        reset_spi_fifo;
        $display($time,, "Reset TX/RX FIFO of SPI Master...");

        //-----------------------------------------------------------------
        // Set Bank Address of SPI Nor Flash
        //-----------------------------------------------------------------        
        //slave select, active low
        addr = `SPI_REG_BASEADDR + `SPI_SSR;
        tb.u_axi4_master.wdata[0] = 32'b0;
        tb.u_axi4_master.axi_master_write(addr, 1, 1, 0);  
        #100;

        //Write instruction code to tx fifo
        addr = `SPI_REG_BASEADDR + `SPI_DTR;
        tb.u_axi4_master.wdata[0] = {24'h0, `WRBRV};
        tb.u_axi4_master.axi_master_write(addr, 1, 1, 0);  

        //Write register data to tx fifo
        addr = `SPI_REG_BASEADDR + `SPI_DTR;
        tb.u_axi4_master.wdata[0] = 8'h80;
        tb.u_axi4_master.axi_master_write(addr, 1, 1, 0); 
        #100; 

        $display($time,, "Write Bank Address Register of SPI Nor Flash... ");

        wait_txfifo_empty;

        //Slave de-select
        addr = `SPI_REG_BASEADDR + `SPI_SSR;
        tb.u_axi4_master.wdata[0] = 32'b1;
        tb.u_axi4_master.axi_master_write(addr, 1, 1, 0);  
        #100;

        reset_spi_fifo;
        $display($time,, "Reset TX/RX FIFO of SPI Master...");

        //-----------------------------------------------------------------
        // XIP Read From SPI Nor Flash Memory
        //-----------------------------------------------------------------        
        $display($time,, "\n XIP read from SPI Nor Flash Memory...\n");

        for (idx = 0; idx < xip_len; idx = idx+1) begin
            addr = `SPI_FLASH_BASEADDR + (idx << 2);
            tb.u_axi4_master.axi_master_read (addr, 1, 1, 0);
            rd_data[idx] = tb.u_axi4_master.rdata[0];
            $display($time,, "%m idx = %d, XIP read data = 0x%02x", idx, rd_data[idx]);
        end

        //Enable AXI statistics
        tb.test_busy = 1'b0;

        #200;

        //Scoreboard
        $display("\n\n SCOREBOARD...");
        for (idx = 0; idx < xip_len; idx = idx+1) begin
            $display("idx = %d, flash memory data = 0x%08x, XIP read data = 0x%08x", idx, wr_data[idx], rd_data[idx]);
            if (rd_data[idx] !== wr_data[idx]) begin
                    $display("ERROR: XIP read data not equal to flash memory data!");
                    $finish(2);                
            end
        end

        #5000;
        $display("SIMULATION PASS!!!");
        $finish;
    end
    
    initial
    begin
        $dumpfile("xip03ne.fst");
        $dumpvars(0, tc_xip03ne);
        $dumpon;
        //$dumpoff;
    end

    task reset_spi_fifo;
        begin
            addr = `SPI_REG_BASEADDR + `SPI_CR;
            tb.u_axi4_master.wdata[0] = cr_reg;
            tb.u_axi4_master.axi_master_write(addr, 1, 1, 0);  
            #100;
        end
    endtask
 
    task wait_txfifo_empty;
        begin
            addr = `SPI_REG_BASEADDR + `SPI_SR;
            tb.u_axi4_master.axi_master_read (addr, 1, 1, 0);
            temp = tb.u_axi4_master.rdata[0];
            //wait tx fifo empty
            while (temp[2] == 0) begin  
                #500;
                tb.u_axi4_master.axi_master_read (addr, 1, 1, 0);
                temp = tb.u_axi4_master.rdata[0];
            end
            #200;
        end
    endtask

    task wait_txfifo_accept;
        begin
            addr = `SPI_REG_BASEADDR + `SPI_SR;
            tb.u_axi4_master.axi_master_read (addr, 1, 1, 0);
            temp = tb.u_axi4_master.rdata[0];
            //wait tx fifo not full
            while (temp[3] == 1) begin  
                #500;
                tb.u_axi4_master.axi_master_read (addr, 1, 1, 0);
                temp = tb.u_axi4_master.rdata[0];
            end
            #200;
        end
    endtask

    task get_rxfifo_data;
        output [31:0] data;
        begin
            addr = `SPI_REG_BASEADDR + `SPI_DRR;
            tb.u_axi4_master.axi_master_read (addr, 1, 1, 0);
            temp = tb.u_axi4_master.rdata[0];
            while (temp[8] == 1) begin //rx fifo empty
                #500;
                tb.u_axi4_master.axi_master_read (addr, 1, 1, 0);
                temp = tb.u_axi4_master.rdata[0];
            end
            
            data = temp;
        end
    endtask

endmodule




