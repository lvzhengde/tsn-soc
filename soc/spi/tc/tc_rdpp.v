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
 *  Description : test case for read after page program
 *  File        : tc_rdpp.v
-*/

`include "spi_defines.v"
`include "tb_spi_defines.v"

module tc_rdpp;

    tb_top tb();

    integer  seed   = 20;
    integer  pp_len = 16; //pp_len <= 16
    integer  idx ;
    reg  [31:0] pp_addr = 32'h0000_0100; 

    reg  [31:0] wr_data[0:255];
    reg  [31:0] rd_data[0:255];
    reg  [31:0] temp      ;
    reg  [31:0] cr_reg    ;
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

    initial begin
        temp    = 0;   
        addr    = 0; 
    
        #10;
        $display($time,, "Read after Page Program of SPI Nor Flash Memory, Simulation Start!");

        $display($time,, "Reset testbench...");
        tb.reset;
        #10;

        //-----------------------------------------------------------------
        // Prepare Page Program Data
        //-----------------------------------------------------------------        
        for (idx = 0; idx < pp_len; idx = idx+1) begin
            wr_data[idx] = $random(seed) & 'hff;
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
        // Page Program of SPI Flash
        //-----------------------------------------------------------------        
        //slave select, active low
        addr = `SPI_REG_BASEADDR + `SPI_SSR;
        tb.u_axi4_master.wdata[0] = 32'b0;
        tb.u_axi4_master.axi_master_write(addr, 1, 1, 0);  
        #100;

        //Write instruction code to tx fifo
        addr = `SPI_REG_BASEADDR + `SPI_DTR;
        tb.u_axi4_master.wdata[0] = {24'h0, `PP};
        tb.u_axi4_master.axi_master_write(addr, 1, 1, 0);  

        //Write page program address to tx fifo
        addr = `SPI_REG_BASEADDR + `SPI_DTR;
        tb.u_axi4_master.wdata[0] = {24'b0, pp_addr[23:16]};
        tb.u_axi4_master.axi_master_write(addr, 1, 1, 0); 

        addr = `SPI_REG_BASEADDR + `SPI_DTR;
        tb.u_axi4_master.wdata[0] = {24'b0, pp_addr[15: 8]};
        tb.u_axi4_master.axi_master_write(addr, 1, 1, 0); 

        addr = `SPI_REG_BASEADDR + `SPI_DTR;
        tb.u_axi4_master.wdata[0] = {24'b0, pp_addr[ 7: 0]};
        tb.u_axi4_master.axi_master_write(addr, 1, 1, 0); 

        #100; 

        //Write page program data to tx fifo
        for (idx = 0; idx < pp_len; idx = idx+1) begin
            wait_txfifo_accept;
            
            addr = `SPI_REG_BASEADDR + `SPI_DTR;
            tb.u_axi4_master.wdata[0] = wr_data[idx];
            tb.u_axi4_master.axi_master_write(addr, 1, 1, 0); 

            $display($time,, "%m idx = %d, page program data = 0x%02x", idx, wr_data[idx][7:0]);
        end

        wait_txfifo_empty;

        //Slave de-select
        addr = `SPI_REG_BASEADDR + `SPI_SSR;
        tb.u_axi4_master.wdata[0] = 32'b1;
        tb.u_axi4_master.axi_master_write(addr, 1, 1, 0);  
        #100;

        reset_spi_fifo;
        $display($time,, "Reset TX/RX FIFO of SPI Master...");

        //-----------------------------------------------------------------
        // Read Page Programmed Data Out From SPI Nor Flash Memory
        //-----------------------------------------------------------------        
        wait(tb.u_flash_model.sr_wip == 0);  //wait page program finish

        //slave select, active low
        addr = `SPI_REG_BASEADDR + `SPI_SSR;
        tb.u_axi4_master.wdata[0] = 32'b0;
        tb.u_axi4_master.axi_master_write(addr, 1, 1, 0);  
        #100;

        //Write normal read instruction code to tx fifo
        addr = `SPI_REG_BASEADDR + `SPI_DTR;
        tb.u_axi4_master.wdata[0] = {24'h0, `NORD};
        tb.u_axi4_master.axi_master_write(addr, 1, 1, 0);  

        //Write page program address to tx fifo
        addr = `SPI_REG_BASEADDR + `SPI_DTR;
        tb.u_axi4_master.wdata[0] = {24'b0, pp_addr[23:16]};
        tb.u_axi4_master.axi_master_write(addr, 1, 1, 0); 

        addr = `SPI_REG_BASEADDR + `SPI_DTR;
        tb.u_axi4_master.wdata[0] = {24'b0, pp_addr[15: 8]};
        tb.u_axi4_master.axi_master_write(addr, 1, 1, 0); 

        addr = `SPI_REG_BASEADDR + `SPI_DTR;
        tb.u_axi4_master.wdata[0] = {24'b0, pp_addr[ 7: 0]};
        tb.u_axi4_master.axi_master_write(addr, 1, 1, 0); 

        //Read unused data from rx fifo
        $display($time,, "%m Read 4 bytes unused data from RX FIFO...");
        wait_txfifo_empty;
        #200; 
        for (idx = 0; idx < 4; idx = idx+1) 
        begin
            get_rxfifo_data(fifo_data);
        end

        //Write stuff data to tx fifo
        $display($time,, "%m Write pp_len bytes stuff data to TX FIFO...");
        for (idx = 0; idx < pp_len; idx = idx+1) 
        begin
            wait_txfifo_accept;
            addr = `SPI_REG_BASEADDR + `SPI_DTR;
            tb.u_axi4_master.wdata[0] = 32'h0;
            tb.u_axi4_master.wdata[0] = wr_data[idx];
            tb.u_axi4_master.axi_master_write(addr, 1, 1, 0); 
        end
        
        wait_txfifo_empty;
        #200;

        //Read data from rx fifo
        $display($time,, "%m Read pp_len bytes data from RX FIFO...");
        for (idx = 0; idx < pp_len; idx = idx+1) 
        begin
            get_rxfifo_data(fifo_data);
            rd_data[idx] = fifo_data & 'hff;
            $display($time,, "%m idx = %d, read data = 0x%02x", idx, rd_data[idx][7:0]);
        end

        #200;

        //Slave de-select
        addr = `SPI_REG_BASEADDR + `SPI_SSR;
        tb.u_axi4_master.wdata[0] = 32'b1;
        tb.u_axi4_master.axi_master_write(addr, 1, 1, 0);  
        #100;

        //Enable AXI statistics
        tb.test_busy = 1'b0;

        //Scoreboard
        $display("\n\n SCOREBOARD...");
        for (idx = 0; idx < pp_len; idx = idx+1) begin
            $display("idx = %d, page programmed data = 0x%02x, read data = 0x%02x", idx, wr_data[idx][7:0], rd_data[idx][7:0]);
            if (rd_data[idx][7:0] !== wr_data[idx][7:0]) begin
                    $display("ERROR: read data not equal to page programmed data!");
                    $finish(2);                
            end
        end

        #5000;
        $display("SIMULATION PASS!!!");
        $finish;
    end
    
    initial
    begin
        $dumpfile("rdpp.fst");
        $dumpvars(0, tc_rdpp);
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


