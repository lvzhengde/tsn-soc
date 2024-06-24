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
 * MACROS:
 *    BURST_TYPE_WRAPP_ENABLED   - Burst wrapping type enabled
 * PARAMETERS:
 *    SIZE_IN_BYTES - size of memory in bytes
-*/

module mem_axi4
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
    parameter SIZE_IN_BYTES      = 1024 
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    input           clk             ,
    input           rst_n           ,

    // AXI4 interface
    input           axi_awvalid_i   ,
    input  [ 31:0]  axi_awaddr_i    ,
    input  [  3:0]  axi_awid_i      ,
    input  [  7:0]  axi_awlen_i     ,
    input  [  1:0]  axi_awburst_i   ,
    input           axi_wvalid_i    ,
    input  [ 31:0]  axi_wdata_i     ,
    input  [  3:0]  axi_wstrb_i     ,
    input           axi_wlast_i     ,
    input           axi_bready_i    ,
    input           axi_arvalid_i   ,
    input  [ 31:0]  axi_araddr_i    ,
    input  [  3:0]  axi_arid_i      ,
    input  [  7:0]  axi_arlen_i     ,
    input  [  1:0]  axi_arburst_i   ,
    input           axi_rready_i    ,

    output          axi_awready_o   ,
    output          axi_wready_o    ,
    output          axi_bvalid_o    ,
    output [  1:0]  axi_bresp_o     ,
    output [  3:0]  axi_bid_o       ,
    output          axi_arready_o   ,
    output          axi_rvalid_o    ,
    output [ 31:0]  axi_rdata_o     ,
    output [  1:0]  axi_rresp_o     ,
    output [  3:0]  axi_rid_o       ,
    output          axi_rlast_o     

);
    localparam ADDR_LENGTH = clogb2(SIZE_IN_BYTES);

    integer num_reads ;
    integer num_writes;

    reg  [ADDR_LENGTH-1:0]  t_waddr_q ;
    reg  [31:0] t_wdata_q ;
    reg  [ 3:0] t_wstrb_q ;
    reg         t_wen_q   ;
    reg  [ADDR_LENGTH-1:0]  t_raddr_q ;
    wire [31:0] t_rdata_w ;
    reg  [ 3:0] t_rstrb_q ;
    reg         t_ren_q   ; 

    //-----------------------------------------------------------
    // write case
    //-----------------------------------------------------------
    reg  [ 31:0]  axi_awaddr_q    ;
    reg  [  3:0]  axi_awid_q      ;
    reg  [  7:0]  axi_awlen_q     ;
    reg  [  1:0]  axi_awburst_q   ;

    reg           axi_awready_q   ;
    reg           axi_wready_q    ;
    reg           axi_bvalid_q    ;
    reg  [  1:0]  axi_bresp_q     ;
    reg  [  3:0]  axi_bid_q       ;

    reg  [ADDR_LENGTH-1:0] waddr_q;
    reg  [ 7:0]            wbeat_q;

    localparam STW_IDLE   = 2'h0,
               STW_WRITE  = 2'h1,
               STW_RSP    = 2'h2;

    reg  [ 1:0]  wstate_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            axi_awaddr_q  <= 32'h0 ;
            axi_awid_q    <= 4'h0 ;
            axi_awlen_q   <= 8'h0 ;
            axi_awburst_q <= 2'b0 ;
            axi_awready_q <= 1'b0 ;
            axi_wready_q  <= 1'b0 ;
            axi_bvalid_q  <= 1'b0 ;
            axi_bresp_q   <= 2'b10 ; //Slave Error
            axi_bid_q     <= 4'h0 ;
            waddr_q       <= 'h0;
            wbeat_q       <= 'h0;
            t_waddr_q     <= 'h0;
            t_wdata_q     <= 'h0;
            t_wstrb_q     <= 'h0;
            t_wen_q       <= 1'b0;
            num_writes    <=    0;
            wstate_q      <= STW_IDLE;
        end 
        else begin
            case (wstate_q)
            STW_IDLE: 
            begin
                if ((axi_awvalid_i == 1'b1) && (axi_awready_q == 1'b1)) begin
                    axi_awaddr_q  <= axi_awaddr_i ;
                    axi_awid_q    <= axi_awid_i   ;
                    axi_awlen_q   <= axi_awlen_i  ;
                    axi_awburst_q <= axi_awburst_i;
                    axi_awready_q <= 1'b0 ;
                    axi_wready_q  <= 1'b1 ;
                    axi_bvalid_q  <= 1'b0 ;
                    axi_bresp_q   <= 2'b00 ; //Okay
                    waddr_q       <= axi_awaddr_i[ADDR_LENGTH-1:0];
                    wbeat_q       <= 'h0;
                    wstate_q      <= STW_WRITE;
                    num_writes    <= num_writes + 1;
                end 
                else begin
                    axi_awready_q <= 1'b1;
                end
            end // STW_IDLE
            STW_WRITE: 
            begin
                if (axi_wvalid_i == 1'b1) begin
                    t_waddr_q <= waddr_q;
                    t_wdata_q <= axi_wdata_i;
                    t_wstrb_q <= axi_wstrb_i;
                    t_wen_q   <= 1'b1;
                    wbeat_q   <= wbeat_q + 1;
                    waddr_q   <= get_next_addr(waddr_q, axi_awburst_q, axi_awlen_q);
                    if (wbeat_q >= axi_awlen_q) begin
                        axi_wready_q  <= 1'b0 ;
                        axi_bvalid_q  <= 1'b1 ;
                        axi_bid_q     <= axi_awid_q ;
                        if (axi_wlast_i == 1'b0) axi_bresp_q <= 2'b10; // SLVERR - missing last
                        wstate_q      <= STW_RSP;
                    end 
                end 
                else begin
                    t_wen_q   <= 1'b0;
                end
            end // STW_WRITE
            STW_RSP: 
            begin
                t_wen_q   <= 1'b0;
                if (axi_bready_i == 1'b1) begin
                    axi_bvalid_q  <= 1'b0 ;
                    axi_awready_q <= 1'b1 ;
                    wstate_q      <= STW_IDLE;
                end
            end // STW_RSP
            endcase
        end //if
    end //always

    // AXI write outputs
    assign axi_awready_o =  axi_awready_q ;
    assign axi_wready_o  =  axi_wready_q  ;
    assign axi_bvalid_o  =  axi_bvalid_q  ;
    assign axi_bresp_o   =  axi_bresp_q   ;
    assign axi_bid_o     =  axi_bid_q     ;

    // synthesis translate_off
    reg  [8*10-1:0] wstate_ascii = "IDLE";
    always @(*) begin
        case (wstate_q)
            STW_IDLE  : wstate_ascii = "IDLE   ";
            STW_WRITE : wstate_ascii = "WRITE  ";
            STW_RSP   : wstate_ascii = "RSP    ";
            default   : wstate_ascii = "UNKNOWN";
        endcase
    end
    // synthesis translate_on


    //-----------------------------------------------------------
    // read case
    //-----------------------------------------------------------
    reg  [ 31:0]  axi_araddr_q    ;
    reg  [  3:0]  axi_arid_q      ;
    reg  [  7:0]  axi_arlen_q     ;
    reg  [  1:0]  axi_arburst_q   ;
    
    reg           axi_arready_q   ;
    reg           axi_rvalid_q    ;
    reg  [ 31:0]  axi_rdata_q     ;
    reg  [  1:0]  axi_rresp_q     ;
    reg  [  3:0]  axi_rid_q       ;
    reg           axi_rlast_q     ;
    
    reg  [ADDR_LENGTH-1:0] raddr_q; // address of each transfer within a burst
    reg  [31:0]   rdata_q;
    reg  [ 3:0]   rstrb_q; // strobe
    reg  [ 7:0]   rbeat_q; // keeps num of transfers within a burst

    localparam STR_IDLE   = 2'h0,
               STR_READ0  = 2'h1,
               STR_READ1  = 2'h2,
               STR_END    = 2'h3;
    
    reg  [ 1:0]   rstate_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            axi_araddr_q  <= 32'h0  ;
            axi_arid_q    <= 4'h0  ;
            axi_arlen_q   <= 8'h0  ;
            axi_arburst_q <= 2'b0  ;
            axi_arready_q <= 1'b0  ;
            axi_rvalid_q  <= 1'b0  ;
            axi_rdata_q   <= 32'h0  ;
            axi_rresp_q   <= 2'b0  ;
            axi_rid_q     <= 4'h0  ;
            axi_rlast_q   <= 1'b0  ;
            raddr_q       <= 'h0; 
            rdata_q       <= 32'h0;
            rstrb_q       <= 4'h0; 
            rbeat_q       <= 8'h0; 
            t_raddr_q     <= 'h0 ;
            t_rstrb_q     <= 4'h0;
            t_ren_q       <= 1'b0; 
            num_reads     <=    0;
            rstate_q      <= STR_IDLE;
        end 
        else begin
    
        end //if
    end // always





    function integer clogb2;
        input [31:0] value;
        reg   [31:0] tmp;
    begin
        tmp = value - 1;
        for (clogb2 = 0; tmp > 0; clogb2 = clogb2 + 1) tmp = tmp >> 1;
    end
    endfunction
    
    function [ADDR_LENGTH-1:0] get_next_addr;
        input [ADDR_LENGTH-1:0] addr ;
        input [ 1:0]            burst; // burst type
        input [ 7:0]            len  ; // burst length

        reg   [ADDR_LENGTH-2-1:0] naddr;
        reg   [ADDR_LENGTH-1:0]   mask ;
    begin
        case (burst)
            2'b00: get_next_addr = addr;
            2'b01: 
            begin
                naddr = addr[ADDR_LENGTH-1:2];
                naddr = naddr + 1;
                get_next_addr = {naddr,2'b00};
            end
            2'b10: 
            begin
                `ifdef BURST_TYPE_WRAPP_ENABLED
                mask  = 4*(len+1) - 1;
                get_next_addr = (addr & ~mask) | ((addr + 4) & mask);
                `else
                // synopsys translate_off
                $display($time,,"%m ERROR BURST WRAP not supported");
                // synopsys translate_on
                `endif
            end
            2'b11: 
            begin
                get_next_addr = addr + 4;
                // synopsys translate_off
                $display($time,,"%m ERROR un-defined BURST %01x", burst);
                // synopsys translate_on
            end
        endcase
    end
    endfunction

endmodule
