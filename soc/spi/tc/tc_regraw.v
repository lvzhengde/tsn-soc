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
 *  Description : test case for read after write of flash register
 *  File        : tc_regraw.v
-*/

`include "spi_defines.v"
`include "tb_spi_defines.v"

module tc_regraw;

    tb_top tb();

    integer  seed;

    reg  [31:0] wr_data;
    reg  [31:0] rd_data;
    reg  [31:0] temp   ;
    reg  [31:0] addr   ; 
    reg  [31:0] cr_reg ;

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

    initial begin
        wr_data = 0;
        rd_data = 1;
        temp    = 0;   
        addr    = 0; 
        seed    = 100;
    
        #10;
        $display($time,, "Read after Write of SPI Nor Flash Register, Simulation Start!");

        $display($time,, "Reset testbench...");
        tb.reset;
        #10;

        //-----------------------------------------------------------------
        // Initialize SPI Control
        //-----------------------------------------------------------------        
        cr_reg = {22'b0, lsb_first, inhibit, msse, rxfifo_rst, txfifo_rst, cpha, cpol, master, spe, loop};
        addr = `SPI_REG_BASEADDR + `SPI_CR;
        tb.u_axi4_master.wdata[0] = cr_reg;
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

        //Poll tx fifo status
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

        //Slave de-select
        addr = `SPI_REG_BASEADDR + `SPI_SSR;
        tb.u_axi4_master.wdata[0] = 32'b1;
        tb.u_axi4_master.axi_master_write(addr, 1, 1, 0);  
        #100;

        //-----------------------------------------------------------------
        // Reset RX/TX FIFO
        //-----------------------------------------------------------------        
        addr = `SPI_REG_BASEADDR + `SPI_CR;
        tb.u_axi4_master.wdata[0] = cr_reg;
        tb.u_axi4_master.axi_master_write(addr, 1, 1, 0);  
        #100;

        $display($time,, "Reset TX/RX FIFO of SPI Master...");

        //-----------------------------------------------------------------
        // Write Register of SPI Flash
        //-----------------------------------------------------------------        
        //slave select, active low
        addr = `SPI_REG_BASEADDR + `SPI_SSR;
        tb.u_axi4_master.wdata[0] = 32'b0;
        tb.u_axi4_master.axi_master_write(addr, 1, 1, 0);  
        #100;

        //Write instruction code to tx fifo
        addr = `SPI_REG_BASEADDR + `SPI_DTR;
        tb.u_axi4_master.wdata[0] = {24'h0, `WRSR};
        tb.u_axi4_master.axi_master_write(addr, 1, 1, 0);  

        //Write register data to tx fifo
        wr_data = 32'hfc; //$random(seed) & 32'hfc; 
        tb.u_axi4_master.wdata[0] = wr_data;
        tb.u_axi4_master.axi_master_write(addr, 1, 1, 0); 
        #100; 

        $display($time,, "Write flash status register, write data = 0x%02x", wr_data[7:0]);

        //Poll tx fifo status
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

        //Slave de-select
        addr = `SPI_REG_BASEADDR + `SPI_SSR;
        tb.u_axi4_master.wdata[0] = 32'b1;
        tb.u_axi4_master.axi_master_write(addr, 1, 1, 0);  
        #100;

        //-----------------------------------------------------------------
        // Reset RX/TX FIFO
        //-----------------------------------------------------------------        
        addr = `SPI_REG_BASEADDR + `SPI_CR;
        tb.u_axi4_master.wdata[0] = cr_reg;
        tb.u_axi4_master.axi_master_write(addr, 1, 1, 0);  
        #100;

        $display($time,, "Reset TX/RX FIFO of SPI Master...");

        //-----------------------------------------------------------------
        // Read Register of SPI Flash
        //-----------------------------------------------------------------        
        //slave select, active low
        addr = `SPI_REG_BASEADDR + `SPI_SSR;
        tb.u_axi4_master.wdata[0] = 32'b0;
        tb.u_axi4_master.axi_master_write(addr, 1, 1, 0);  
        #100;

        //Write instruction code to tx fifo
        addr = `SPI_REG_BASEADDR + `SPI_DTR;
        tb.u_axi4_master.wdata[0] = {24'h0, `RDSR};
        tb.u_axi4_master.axi_master_write(addr, 1, 1, 0);  

        //Write stuff data to tx fifo
        tb.u_axi4_master.wdata[0] = 32'h0;
        tb.u_axi4_master.axi_master_write(addr, 1, 1, 0); 
        #100; 

        //Poll tx fifo status
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

        //Slave de-select
        addr = `SPI_REG_BASEADDR + `SPI_SSR;
        tb.u_axi4_master.wdata[0] = 32'b1;
        tb.u_axi4_master.axi_master_write(addr, 1, 1, 0);  
        #100;

        $display($time,, "Read flash status register...");

        //Read first data of RX FIFO
        addr = `SPI_REG_BASEADDR + `SPI_DRR;
        tb.u_axi4_master.axi_master_read (addr, 1, 1, 0);
        temp = tb.u_axi4_master.rdata[0];
        while (temp[8] == 1) begin //rx fifo empty
            #500;
            tb.u_axi4_master.axi_master_read (addr, 1, 1, 0);
            temp = tb.u_axi4_master.rdata[0];
        end

        //Read second data of RX FIFO
        addr = `SPI_REG_BASEADDR + `SPI_DRR;
        tb.u_axi4_master.axi_master_read (addr, 1, 1, 0);
        temp = tb.u_axi4_master.rdata[0];
        while (temp[8] == 1) begin //rx fifo empty
            #500;
            tb.u_axi4_master.axi_master_read (addr, 1, 1, 0);
            temp = tb.u_axi4_master.rdata[0];
        end
        rd_data = temp & 32'hfc;

        //Enable AXI statistics
        tb.test_busy = 1'b0;

        //Scoreboard
        if (rd_data !== wr_data) begin
            $display("ERROR: rd_data = 0x%02x, not equal to wr_data = 0x%02x!", rd_data[7:0], wr_data[7:0]);
            $finish(2);
        end

        #5000;
        $display("rd_data = 0x%02x equal to wr_data = 0x%02x", rd_data[7:0], wr_data[7:0]);
        $display("SIMULATION PASS!!!");
        $finish;
    end
    
    initial
    begin
        $dumpfile("regraw.fst");
        $dumpvars(0, tc_regraw);
        $dumpon;
        //$dumpoff;
    end
 
endmodule


