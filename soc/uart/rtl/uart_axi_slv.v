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

module uart_axi_slv 
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
    output          axi_rlast_o     ,

    output [ 31:0]  waddr_o  , 
    output [ 31:0]  wdata_o  , 
    output [  3:0]  wstrb_o  , 
    output          wen_o    , 
    output [ 31:0]  raddr_o  , 
    input  [ 31:0]  rdata_i  , 
    output [  3:0]  rstrb_o  ,
    output          ren_o            
);
    //-----------------------------------------------------------
    // write case
    //-----------------------------------------------------------
    reg  [31:0]  t_waddr_q ;
    reg  [31:0]  t_wdata_q ;
    reg  [ 3:0]  t_wstrb_q ;
    reg          t_wen_q   ;

    reg  [31:0]  axi_awaddr_q    ;
    reg  [ 3:0]  axi_awid_q      ;
    reg  [ 7:0]  axi_awlen_q     ;
    reg  [ 1:0]  axi_awburst_q   ;

    reg          axi_awready_q   ;
    reg          axi_wready_q    ;
    reg          axi_bvalid_q    ;
    reg  [ 1:0]  axi_bresp_q     ;
    reg  [ 3:0]  axi_bid_q       ;

    reg  [31:0]  waddr_q;
    reg  [ 7:0]  wbeat_q;

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
            wstate_q      <= STW_IDLE;
        end 
        else begin
            case (wstate_q)
            STW_IDLE: 
            begin
                if ((axi_awvalid_i == 1'b1) && (axi_awready_o == 1'b1)) begin
                    axi_awaddr_q  <= axi_awaddr_i ;
                    axi_awid_q    <= axi_awid_i   ;
                    axi_awlen_q   <= axi_awlen_i  ;
                    axi_awburst_q <= axi_awburst_i;
                    axi_awready_q <= 1'b0 ;
                    axi_wready_q  <= 1'b1 ;
                    axi_bvalid_q  <= 1'b0 ;
                    axi_bresp_q   <= 2'b00 ; //Okay
                    waddr_q       <= axi_awaddr_i;
                    wbeat_q       <= 'h0;
                    wstate_q      <= STW_WRITE;
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
            default:  wstate_q <= STW_IDLE;
            endcase
        end //if
    end //always

    // AXI write outputs
    assign axi_awready_o =  axi_awready_q ;
    assign axi_wready_o  =  axi_wready_q  ;
    assign axi_bvalid_o  =  axi_bvalid_q  ;
    assign axi_bresp_o   =  axi_bresp_q   ;
    assign axi_bid_o     =  axi_bid_q     ;

    // Register write ports
    assign waddr_o  = t_waddr_q ; 
    assign wdata_o  = t_wdata_q ; 
    assign wstrb_o  = t_wstrb_q ; 
    assign wen_o    = t_wen_q   ; 

    //-----------------------------------------------------------
    // read case
    //-----------------------------------------------------------
    reg  [ADDR_LENGTH-1:0]  t_raddr_q ;
    wire [31:0]   t_rdata_w ;
    reg  [ 3:0]   t_rstrb_q ;
    reg           t_ren_q   ; 
    reg  [ADDR_LENGTH-1:0]  t_raddr ;
    reg  [ 3:0]   t_rstrb ;
    reg           t_ren   ; 

    reg  [ 31:0]  axi_araddr_q    ;
    reg  [  7:0]  axi_arlen_q     ;
    reg  [  1:0]  axi_arburst_q   ;
    
    reg           axi_arready_q   ;
    reg           axi_rvalid_q    ;
    reg  [ 31:0]  axi_rdata_q     ;
    reg  [  1:0]  axi_rresp_q     ;
    reg  [  3:0]  axi_rid_q       ;
    reg           axi_rlast_q     ;
    
    reg  [ADDR_LENGTH-1:0] raddr_q; // address of each transfer within a burst
    reg  [ 7:0]   rbeat_q; // keeps num of transfers within a burst

    localparam STR_IDLE   = 2'h0,
               STR_READ   = 2'h1,
               STR_END    = 2'h2;
    
    reg  [ 1:0]   rstate_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            axi_araddr_q  <= 32'h0 ;
            axi_arlen_q   <= 8'h0  ;
            axi_arburst_q <= 2'b0  ;
            axi_arready_q <= 1'b0  ;
            axi_rvalid_q  <= 1'b0  ;
            axi_rdata_q   <= 32'h0 ;
            axi_rresp_q   <= 2'b10 ; //Slave Error
            axi_rid_q     <= 4'h0  ;
            axi_rlast_q   <= 1'b0  ;
            raddr_q       <= 'h0 ; 
            rbeat_q       <= 8'h0; 
            rstate_q      <= STR_IDLE;
        end 
        else begin
            case (rstate_q)
            STR_IDLE: 
            begin
                if ((axi_arvalid_i == 1'b1) && (axi_arready_q == 1'b1)) begin
                    axi_araddr_q  <= axi_araddr_i  ;
                    axi_arlen_q   <= axi_arlen_i   ;
                    axi_arburst_q <= axi_arburst_i ;
                    axi_arready_q <= 1'b0;
                    axi_rid_q     <= axi_arid_i ;
                    axi_rresp_q   <= 2'b00  ; // Okay
                    axi_rlast_q   <= 1'b0  ;
                    raddr_q       <= get_next_addr(axi_araddr_i[ADDR_LENGTH-1:0], axi_arburst_i, axi_arlen_i);; 
                    rbeat_q       <= 8'h0; 

                    rstate_q      <= STR_READ;
                end 
                else begin
                    axi_arready_q <= 1'b1;
                end
            end // STR_IDLE
            STR_READ :
            begin
                if (axi_rready_i == 1'b1) begin
                    axi_rvalid_q  <= 1'b1  ;
                    axi_rdata_q   <= t_rdata_w ;
                    rbeat_q  <= rbeat_q + 1;
                    raddr_q  <= get_next_addr(raddr_q, axi_arburst_q, axi_arlen_q); 

                    if (rbeat_q >= axi_arlen_q) begin
                        axi_rresp_q <= 2'b00  ;
                        axi_rlast_q <= 1'b1   ;
                        rstate_q    <= STR_END;
                    end
                end

            end // STR_READ
            STR_END: 
            begin 
                if (axi_rready_i == 1'b1) begin
                    axi_rvalid_q  <= 1'b0  ;
                    axi_rlast_q   <= 1'b0  ;
                    axi_rdata_q   <= 32'h0 ;
                    axi_rresp_q   <= 2'b10 ;  //Slave Error

                    axi_arready_q <= 1'b1  ;
                    rstate_q      <= STR_IDLE;
                end
            end // STR_END
            default: rstate_q <= STR_IDLE;
            endcase
        end //if
    end // always

    // AXI read outputs
    assign axi_arready_o = axi_arready_q ;
    assign axi_rvalid_o  = axi_rvalid_q  ;
    assign axi_rdata_o   = axi_rdata_q   ;
    assign axi_rresp_o   = axi_rresp_q   ;
    assign axi_rid_o     = axi_rid_q     ;
    assign axi_rlast_o   = axi_rlast_q   ;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            t_raddr_q     <= 'h0 ;
            t_rstrb_q     <= 4'h0;
            t_ren_q       <= 1'b0; 
        end
        else begin
            t_raddr_q     <= t_raddr;
            t_rstrb_q     <= t_rstrb;
            t_ren_q       <= t_ren  ; 
        end
    end

    always @(*) begin
        t_raddr = t_raddr_q ;
        t_rstrb = t_rstrb_q ;
        t_ren   = t_ren_q   ;

        if ((rstate_q == STR_IDLE) && (axi_arvalid_i == 1'b1) && (axi_arready_q == 1'b1)) begin
            t_raddr = axi_araddr_i[ADDR_LENGTH-1:0] ;
            t_rstrb = get_strb(axi_araddr_i[ADDR_LENGTH-1:0]);
            t_ren   = 1'b1; 
        end
        else if ((rstate_q == STR_READ) && (axi_rready_i == 1'b1)) begin
            t_raddr = raddr_q;
            t_rstrb = get_strb(raddr_q);
            t_ren   = 1'b1; 
        end
        else if ((rstate_q == STR_END) && (axi_rready_i == 1'b1)) begin
            t_raddr = 'h0;
            t_rstrb = 4'h0;
            t_ren   = 1'b0; 
        end
    end

    // a sort of dual-port memory with write-first feature
    mem_axi_dpram_sync 
    #(
        .WIDTH_AD   (ADDR_LENGTH ),  // size of memory in byte
        .WIDTH_DA   (32          )   // width of a line in bytes
    )
    u_dpram
    (
        .RESETn    (rst_n     ) ,
        .CLK       (clk       ) ,
        .WADDR     (t_waddr_q ) ,
        .WDATA     (t_wdata_q ) ,
        .WSTRB     (t_wstrb_q ) ,
        .WEN       (t_wen_q   ) ,
        .RADDR     (t_raddr   ) ,
        .RDATA     (t_rdata_w ) ,
        .RSTRB     (t_rstrb   ) ,
        .REN       (t_ren     ) 
    );

    function  [31:0] get_next_addr;
        input [31:0] addr ;
        input [ 1:0] burst; // burst type
        input [ 7:0] len  ; // burst length

        reg   [29:0] naddr;
        reg   [31:0]   mask ;
    begin
        case (burst)
            2'b00: 
                get_next_addr = addr;
            2'b01: 
            begin
                naddr = addr[31:2];
                naddr = naddr + 1;
                get_next_addr = {naddr,2'b00};
            end
            2'b10: 
            begin
                mask  = 4*(len+1) - 1;
                get_next_addr = (addr & ~mask) | ((addr + 4) & mask);
            end
            2'b11: 
                get_next_addr = addr + 4;
        endcase
    end
    endfunction

    function  [ 3:0] get_strb;
        input [31:0] addr;
        reg   [ 3:0] offset;
    begin
         offset   = addr[1:0]; //offset = addr%4;
         get_strb = {4{1'b1}} << offset;
    end
    endfunction

endmodule

