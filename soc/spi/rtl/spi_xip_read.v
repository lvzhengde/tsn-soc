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
 *  Description : SPI XIP (Execute In Place) read
 *                XIP read processing is based on address decoding and read
 *                signal. Read one word (4 bytes) each time.
 *  File        : spi_xip_read.v
-*/

`include "spi_defines.v"

module spi_xip_read 
(
    //32 bits IPBus interface
    input               bus2ip_clk     ,         //clock 
    input               bus2ip_rst_n   ,         //active low reset
    input  [31:0]       bus2ip_addr_i  ,
    input  [31:0]       bus2ip_data_i  ,         //(Not used)
    input  [ 3:0]       bus2ip_wstrb_i ,         //(Not used)
    input               bus2ip_rd_ce_i ,         //active high
    input               bus2ip_wr_ce_i ,         //active high
    output [31:0]       ip2bus_data_o  , 
    output              ip2bus_ready_o ,

    //SPI control and FIFO interface
    output              flush_spi_o    ,         //flush TX/RX FIFO and SPI interface
    input               tx_accept_i    ,
    input               rx_ready_i     ,
    output              spi_dtr_wr_o   ,          //Transmit FIFO write enable 
    output [ 7:0]       spi_dtr_data_o ,          //Transmit FIFO write data 
    output              spi_drr_rd_o   ,          //Receive FIFO read enable
    input  [ 7:0]       spi_drr_data_i ,          //Receive FIFO read data 

    input               spi_cr_cpol_i  ,          //SPI clock polarity
    input               spi_cr_cpha_i  ,          //SPI clock phase
    input [ 7:0]        spi_ecr_xip_read_code_i , // XIP read instruction code
    input               spi_ecr_extadd_i        , // 0: 3-byte address; 1: 4-byte address
    input               spi_ecr_dummy_cycles_i  , // 0: no dummy cycles; 1: add 8-bit dummy cycles

    output              spi_xip_ss_o              //SPI chip select in XIP mode
);

    parameter TSL_CYCLES = 1;     // Select to SPI clock rising 
    parameter TDS_CYCLES = 4;     // Deselect to next select 

    //-----------------------------------------------------------------
    // Registers / Wires
    //-----------------------------------------------------------------
    wire [ 7:0] word_len = 8'd1;    //TODO: get word burst length from input port
    wire [ 9:0] byte_len = {word_len, 2'b00};

    reg  [ 9:0] rcvd_cnt_q;  
    wire [ 9:0] instr_paylen_r; 
    wire [ 9:0] rxd_count_w = rcvd_cnt_q - instr_paylen_r;
    wire [ 9:0] total_len_w = byte_len + instr_paylen_r;

    wire        cs_blocked_w;
    
    wire  blk_sel_w  = ((bus2ip_addr_i & `SPI_ADDR_MASK) == `SPI_FLASH_BASEADDR);
    wire  error_w    = (spi_cr_cpol_i != spi_cr_cpha_i) | (bus2ip_wr_ce_i); //{cpol, cpha} support (0,0) (1,1) only
    wire  xip_req_w  = blk_sel_w & bus2ip_rd_ce_i & (!error_w);

    always @(*) begin
        instr_paylen_r = 10'd4;

        if (spi_ecr_extadd_i && spi_ecr_dummy_cycles_i)
            instr_paylen_r = 10'd6;
        else if (spi_ecr_extadd_i || spi_ecr_dummy_cycles_i)
            instr_paylen_r = 10'd5;
    end


    //-----------------------------------------------------------------
    // XIP Read State Machine
    //-----------------------------------------------------------------
    localparam STATE_W           = 4;
    localparam STATE_IDLE        = 4'd0 ;
    localparam STATE_FLUSH       = 4'd1 ;
    localparam STATE_CS_SELECT   = 4'd2 ;
    localparam STATE_CMD         = 4'd3 ;
    localparam STATE_ADDR1       = 4'd4 ;
    localparam STATE_ADDR2       = 4'd5 ;
    localparam STATE_ADDR3       = 4'd6 ;
    localparam STATE_ADDR4       = 4'd7 ;
    localparam STATE_DUMMY       = 4'd8 ;
    localparam STATE_DATA        = 4'd9 ;
    localparam STATE_CS_DESELECT = 4'd10;

    reg [STATE_W-1:0]           cstate_q;
    reg [STATE_W-1:0]           nstate_r;

    //-----------------------------------------------------------------
    // Next State Logic
    //-----------------------------------------------------------------
    always @(*) begin
        nstate_r = cstate_q;
    
        case (cstate_q)
            STATE_IDLE : 
            begin
                if (xip_req_w) // xip read request (and transfer in-active)
                    nstate_r = STATE_FLUSH;
            end
            STATE_FLUSH :
            begin
                nstate_r = STATE_CS_SELECT;
            end
            STATE_CS_SELECT : 
            begin 
                if ((!cs_blocked_w) && tx_accept_i)
                    nstate_r = STATE_CMD;
            end
            STATE_CMD :
            begin
                if (tx_accept_i)
                    nstate_r = STATE_ADDR1;
            end
            STATE_ADDR1 :
            begin
                if (tx_accept_i)
                    nstate_r = STATE_ADDR2;
            end
            STATE_ADDR2 :
            begin
                if (tx_accept_i)
                    nstate_r = STATE_ADDR3;
            end
            STATE_ADDR3 :
            begin
                if (tx_accept_i && spi_ecr_extadd_i)
                    nstate_r = STATE_ADDR4;
                else if (tx_accept_i && spi_ecr_dummy_cycles_i)
                    nsate_r = STATE_DUMMY;
                else if (tx_accept_i)
                    nstate_r = STATE_DATA;
            end
            STATE_ADDR4 :
            begin
                if (tx_accept_i && spi_ecr_dummy_cycles_i)
                    nsate_r = STATE_DUMMY;
                else if (tx_accept_i)
                    nstate_r = STATE_DATA;
            end
            STATE_DUMMY :
            begin
                if (tx_accept_i)
                    nstate_r = STATE_DATA;
            end
            STATE_DATA :
            begin
                if (rcvd_cnt_q != total_len_w)
                    nstate_r = STATE_DATA;
                else // Last byte
                    nstate_r = STATE_CS_DESELECT;
            end
            STATE_CS_DESELECT : 
            begin
                if (!cs_blocked_w)
                    nstate_r = STATE_IDLE;
            end
            default :
                ;
        endcase
    end //always

    // Update state
    always @(posedge bus2ip_clk or posedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n)
            cstate_q <= STATE_IDLE;
        else
            cstate_q <= nstate_r;
    end
    
    //-----------------------------------------------------------------
    // Generate TX data 
    //-----------------------------------------------------------------
    reg               spi_dtr_wr_r  ;          
    reg  [ 7:0]       spi_dtr_data_r;         
    reg  [ 9:0]       txd_count_r   ;

    reg               spi_dtr_wr_q  ;          
    reg  [ 7:0]       spi_dtr_data_q;         
    reg  [ 9:0]       txd_count_q   ;

    always @(*) begin
        spi_dtr_wr_r   = 1'b0;  
        spi_dtr_data_r = 8'h0;
        txd_count_r    = txd_count_q;

        case (cstate_q)
            STATE_CS_SELECT : 
            begin 
                if ((!cs_blocked_w) && tx_accept_i) 
                begin
                    spi_dtr_wr_r   = 1'b1;  
                    spi_dtr_data_r = spi_ecr_xip_read_code_i[7:0]; //Read command
                end
            end
            STATE_CMD :
            begin
                if (tx_accept_i)
                begin
                    spi_dtr_wr_r   = 1'b1;  
                    if (spi_ecr_extadd_i)
                        spi_dtr_data_r = bus2ip_addr_i[31:24];
                    else 
                        spi_dtr_data_r = bus2ip_addr_i[23:16];
                end
                txd_count_r = byte_len;
            end
            STATE_ADDR1 :
            begin
                if (tx_accept_i)
                begin
                    spi_dtr_wr_r   = 1'b1;  
                    if (spi_ecr_extadd_i)
                        spi_dtr_data_r = bus2ip_addr_i[23:16];
                    else 
                        spi_dtr_data_r = bus2ip_addr_i[15: 8];
                end
            end
            STATE_ADDR2 :
            begin
                if (tx_accept_i)
                begin
                    spi_dtr_wr_r   = 1'b1;  
                    if (spi_ecr_extadd_i)
                        spi_dtr_data_r = bus2ip_addr_i[15: 8];
                    else 
                        spi_dtr_data_r = bus2ip_addr_i[ 7: 0];
                end
            end
            STATE_ADDR3 :
            begin
                if (tx_accept_i && spi_ecr_extadd_i)
                begin
                    spi_dtr_wr_r   = 1'b1;  
                    spi_dtr_data_r = bus2ip_addr_i[ 7: 0];
                end
                else if (tx_accept_i && spi_ecr_dummy_cycles_i)
                begin
                    spi_dtr_wr_r   = 1'b1;  
                    spi_dtr_data_r = 8'hff;
                end
                else if (tx_accept_i)
                begin
                    spi_dtr_wr_r   = 1'b1;  
                    spi_dtr_data_r = 8'hff;
                    txd_count_r    = txd_count_q - 10'd1;
                end
            end
            STATE_ADDR4 :
            begin
                if (tx_accept_i && spi_ecr_dummy_cycles_i)
                begin
                    spi_dtr_wr_r   = 1'b1;  
                    spi_dtr_data_r = 8'hff;
                end
                if (tx_accept_i)
                begin
                    spi_dtr_wr_r   = 1'b1;  
                    spi_dtr_data_r = 8'hff;
                    txd_count_r    = txd_count_q - 10'd1;
                end
            end
            STATE_DUMMY :
            begin
                if (tx_accept_i)
                begin
                    spi_dtr_wr_r   = 1'b1;  
                    spi_dtr_data_r = 8'hff;
                    txd_count_r    = txd_count_q - 10'd1;
                end
            end
            STATE_DATA :
            begin
                if (tx_accept_i && txd_count_q != 10'd0)
                begin
                    spi_dtr_wr_r   = 1'b1;  
                    spi_dtr_data_r = 8'hff;
                    txd_count_r    = txd_count_q - 10'd1;
                end
            end
            default :
                ;
        endcase
    end //always

    always @(posedge bus2ip_clk or posedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n) begin
            spi_dtr_wr_q   <= 1'b0;  
            spi_dtr_data_q <= 8'h0;
            txd_count_q    <= 10'd0;
        end
        else begin
            spi_dtr_wr_q   <= spi_dtr_wr_r  ;  
            spi_dtr_data_q <= spi_dtr_data_r;
            txd_count_q    <= txd_count_r   ;
        end
    end

    assign spi_dtr_wr_o   = spi_dtr_wr_q  ;  
    assign spi_dtr_data_o = spi_dtr_data_q;
     
    //-----------------------------------------------------------------
    // Receive data from RX FIFO
    //-----------------------------------------------------------------
    reg         spi_drr_rd_q;         
    reg  [31:0] data_q;      

    always @(posedge bus2ip_clk or posedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n) begin
            spi_drr_rd_q <= 1'b0 ;
            data_q       <= 32'h0;      
            rcvd_cnt_q   <= 10'd0;  
        end
        else if ((!spi_xip_ss_o) && bus2ip_rd_ce_i) begin
            if (rx_ready_i && (!ip2bus_ready_o) begin
                data_q       <= {spi_drr_data_i, data_q[31:8]};
                spi_drr_rd_q <= 1'b1 ;
                rcvd_cnt_q   <= rcvd_cnt_q + 10'd1;
            end
        end
        else if (spi_xip_ss_o)begin
            spi_drr_rd_q <= 1'b0 ;
            data_q       <= 32'h0;      
            rcvd_cnt_q   <= 10'd0;  
        end
    end

    assign spi_drr_rd_o = spi_drr_rd_q;

    //-----------------------------------------------------------------
    // SPI Chip Select
    //-----------------------------------------------------------------
    reg        spi_ss_q;
    reg  [7:0] cs_delay_q;
    
    always @(posedge bus2ip_clk or posedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n) 
        begin
            spi_ss_q   <= 1'b1;
            cs_delay_q <= 8'b0;
        end
        else if (cstate_q == STATE_IDLE)
            cs_delay_q <= TSL_CYCLES;
        else if (cstate_q == STATE_CS_SELECT && cs_blocked_w)
        begin
            spi_ss_q   <= 1'b0;
            cs_delay_q <= cs_delay_q - 8'd1;
        end
        else if (cstate_q == STATE_DATA)
            cs_delay_q <= TDS_CYCLES;
        else if (cstate_q == STATE_CS_DESELECT && cs_blocked_w)
        begin
            spi_ss_q   <= 1'b1;
            cs_delay_q <= cs_delay_q - 8'd1;
        end
    end
    
    assign cs_blocked_w = (cs_delay_q != 8'b0);
    
    assign spi_xip_ss_o = spi_ss_q;

    //-----------------------------------------------------------------
    // Flush SPI TX/RX FIFO and serial interface
    //-----------------------------------------------------------------
    reg   flush_spi_q;

    always @(posedge bus2ip_clk or posedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n)
            flush_spi_q <= 1'b0;
        else if (nstate_r == STATE_FLUSH)
            flush_spi_q <= 1'b1;
        else
            flush_spi_q <= 1'b0;
    end

    assign flush_spi_o = flush_spi_q;

    //-----------------------------------------------------------------
    // IPBus data ready
    //-----------------------------------------------------------------
    reg [31:0] rd_data_q;
    reg        ip2bus_ready_q;

    always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n) 
        begin
            ip2bus_ready_q <= 1'b0;
            rd_data_q      <= 32'b0;
        end
        else if (ip2bus_ready_o & (bus2ip_rd_ce_i | bus2ip_wr_ce_i))
        begin
            ip2bus_ready_q <= 1'b0;
            rd_data_q      <= 32'b0;
        end
        else if (bus2ip_wr_ce_i)
        begin
            ip2bus_ready_q <= 1'b1;
        end
        else if (bus2ip_rd_ce_i && (spi_cr_cpol_i != spi_cr_cpha_i))
        begin
            ip2bus_ready_q <= 1'b1;
            rd_data_q      <= 32'hBADE_BADE;
        end
        else if (bus2ip_rd_ce_i && (!blk_sel_w))
        begin
            ip2bus_ready_q <= 1'b1;
            rd_data_q      <= 32'b0;
        end
        else if (bus2ip_rd_ce_i && rcvd_cnt_q > instr_paylen_r && rxd_count_w[1:0] = 2'b11)
        begin
            ip2bus_ready_q <= 1'b1;
            rd_data_q      <= data_q;
        end
    end

    assign ip2bus_data_o  = rd_data_q;
    assign ip2bus_ready_o = ip2bus_ready_q;

endmodule

