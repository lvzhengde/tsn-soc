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
 * Modified from matrix/rtl/axi4_ipbus_bridge.v
 * TODO: support burst length read on IPBus side.
-*/

module spi_axi
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

    //standard ip access bus interface
    output          bus2ip_clk      ,
    output          bus2ip_rst_n    ,
    output [ 31:0]  bus2ip_addr_o   ,
    output [ 31:0]  bus2ip_data_o   ,
    output [ 3:0]   bus2ip_wstrb_o  ,    
    output          bus2ip_rd_ce_o  ,  //active high
    output          bus2ip_wr_ce_o  ,  //active high
    input  [ 31:0]  ip2bus_data_i   ,    
    input           ip2bus_ready_i    
);
    //-----------------------------------------------------------------
    // Registers / Wires
    //-----------------------------------------------------------------
    reg          grant_write_q;
    reg          grant_read_q ;

    reg          req_r;
    reg          ack_q;
    reg  [31:0]  addr_r;
    reg          wr_r;
    reg  [31:0]  wdata_r;  
    reg  [31:0]  rdata_q; 
    reg  [ 3:0]  be_r;

    reg  [31:0]  t_waddr_q ;
    reg  [31:0]  t_wdata_q ;
    reg  [ 3:0]  t_wstrb_q ;
    reg          t_wen_q   ;

    reg  [31:0]  t_raddr_q ;
    wire [31:0]  t_rdata_w = rdata_q;
    wire [ 3:0]  t_rstrb_w = 4'hf;
    reg          t_ren_q   ;

    always @(*) begin
        case ({grant_write_q,grant_read_q})
            2'b10: 
            begin // write-case
                   req_r   = t_wen_q  ;
                   addr_r  = t_waddr_q;
                   wr_r    = 1'b1  ;
                   wdata_r = t_wdata_q; // WDATA (AXI)
                   be_r    = t_wstrb_q;
            end
            2'b01: 
            begin // read-case
                   req_r   = t_ren_q  ;
                   addr_r  = t_raddr_q;
                   wr_r    = 1'b0  ;
                   wdata_r = 32'h0 ;
                   be_r    = t_rstrb_w;
            end
            2'b00, 
            2'b11: 
            begin
                   req_r   = 1'b0  ;
                   addr_r  = 32'h0 ;
                   wr_r    = 1'b0  ;
                   wdata_r = 32'h0 ; 
                   be_r    = 4'b0  ;
            end
        endcase
    end

    //-----------------------------------------------------------------
    // AXI write case, write first
    // AXI write state machine
    //-----------------------------------------------------------------
    localparam STW_IDLE        = 3'h0,
               STW_RUN         = 3'h1,
               STW_WRITE0      = 3'h2,
               STW_WRITE1      = 3'h3,
               STW_WRITE       = 3'h4,
               STW_RSP         = 3'h5;

    reg  [ 31:0]  axi_awaddr_q ; 
    reg  [  3:0]  axi_awid_q   ; 
    reg  [  7:0]  axi_awlen_q  ; 
    reg  [  1:0]  axi_awburst_q; 
           
    reg           axi_awready_q; 
    reg           axi_wready_q ; 
    reg           axi_bvalid_q ; 
    reg  [  1:0]  axi_bresp_q  ; 
    reg  [  3:0]  axi_bid_q    ; 

    reg  [  7:0]  wbeat_q      ;
    reg  [  2:0]  wstate_q     ;
    reg  [  2:0]  next_wstate_r;

    always @(*) begin
        next_wstate_r = wstate_q;
    
        case (wstate_q)
            STW_IDLE :
            begin
                if (axi_awvalid_i == 1'b1 && grant_read_q == 1'b0)
                    next_wstate_r = STW_RUN;
            end    
            STW_RUN :
            begin
                next_wstate_r = STW_WRITE0;
            end
            STW_WRITE0 :
            begin
                if (axi_wvalid_i==1'b1) 
                    next_wstate_r = STW_WRITE1;
            end
            STW_WRITE1 :
            begin
                if (ack_q == 1'b1) 
                begin
                    if (wbeat_q >= axi_awlen_q)
                        next_wstate_r = STW_RSP;
                    else
                        next_wstate_r = STW_WRITE;
                end
            end
            STW_WRITE: 
            begin
                if (ack_q == 1'b0) 
                begin
                    next_wstate_r = STW_WRITE0;
                end
            end 
            STW_RSP: 
            begin
                if (ack_q == 1'b0) 
                begin
                    if (axi_bready_i == 1'b1 && axi_bvalid_q == 1'b1) 
                        next_wstate_r = STW_IDLE;
                end
            end 
            default: next_wstate_r = STW_IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            wstate_q   <= STW_IDLE;
        else
            wstate_q   <= next_wstate_r;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            grant_write_q   <= 1'b0;
        else if (wstate_q == STW_IDLE && next_wstate_r == STW_RUN)
            grant_write_q   <= 1'b1;
        else if (wstate_q == STW_RSP && ack_q == 1'b0)
            grant_write_q   <= 1'b0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            axi_awready_q   <= 1'b0;
        else if (wstate_q == STW_IDLE && next_wstate_r == STW_RUN)
            axi_awready_q   <= 1'b1;
        else if (wstate_q == STW_RUN)
            axi_awready_q   <= 1'b0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            axi_wready_q   <= 1'b0;
        else if (wstate_q == STW_RUN)
            axi_wready_q   <= 1'b1;
        else if (wstate_q == STW_WRITE0 && axi_wvalid_i==1'b1)
            axi_wready_q   <= 1'b0;
        else if (wstate_q == STW_WRITE && ack_q==1'b0)
            axi_wready_q   <= 1'b1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            axi_awaddr_q  <= 32'h0; 
            axi_awid_q    <= 4'h0; 
            axi_awlen_q   <= 8'h0; 
            axi_awburst_q <= 2'h0; 
        end
        else if (wstate_q == STW_IDLE && next_wstate_r == STW_RUN) begin
            axi_awaddr_q  <= axi_awaddr_i ; 
            axi_awid_q    <= axi_awid_i   ; 
            axi_awlen_q   <= axi_awlen_i  ; 
            axi_awburst_q <= axi_awburst_i; 
        end
    end

    reg  [31:0]  next_waddr_q ;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            next_waddr_q   <= 32'h0;
            wbeat_q        <= 8'h0 ;
        end
        else if (wstate_q == STW_RUN) begin
            next_waddr_q   <= axi_awaddr_q;
            wbeat_q        <= 8'h0 ;
        end
        else if (wstate_q == STW_WRITE1 && ack_q == 1'b1) begin
            next_waddr_q   <= calculate_addr_next(next_waddr_q, axi_awburst_q, axi_awlen_q);
            wbeat_q        <= wbeat_q + 1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            t_waddr_q <= 32'h0;
            t_wdata_q <= 32'h0;
            t_wstrb_q <= 4'h0 ;
            t_wen_q   <= 1'b0 ;
        end
        else if (wstate_q == STW_WRITE0 && axi_wvalid_i==1'b1) begin
            t_waddr_q <= next_waddr_q;
            t_wdata_q <= axi_wdata_i;
            t_wstrb_q <= axi_wstrb_i;
            t_wen_q   <= 1'b1 ;
        end
        else if (wstate_q == STW_WRITE1 && ack_q == 1'b1) begin
            t_wen_q   <= 1'b0 ;
        end
        else if(wstate_q == STW_RSP && next_wstate_r == STW_IDLE) begin
            t_waddr_q <= 32'h0;
            t_wdata_q <= 32'h0;
            t_wstrb_q <= 4'h0 ;
            t_wen_q   <= 1'b0 ;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            axi_bid_q    <= 4'h0; 
        else if (wstate_q == STW_WRITE1 && ack_q == 1'b1 && wbeat_q >= axi_awlen_q) 
            axi_bid_q    <= axi_awid_q; 
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            axi_bresp_q  <= 2'b10;    // Slave Error 
        else if (wstate_q == STW_RUN) 
            axi_bresp_q  <= 2'b00;    // Okay 
        else if (wstate_q == STW_WRITE0 && axi_wvalid_i==1'b1) begin
            if (wbeat_q >= axi_awlen_q) begin
                if (axi_wlast_i == 1'b0)  axi_bresp_q  <= 2'b10;    // Slave Error - missing last
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            axi_bvalid_q <= 1'b0; 
        else if (wstate_q == STW_RSP && ack_q == 1'b0) begin
            if (axi_bready_i == 1'b1 && axi_bvalid_q == 1'b1)
                axi_bvalid_q <= 1'b0;
            else
                axi_bvalid_q <= 1'b1;
        end 
    end

    //AXI write outputs
    assign axi_awready_o   =  axi_awready_q ;
    assign axi_wready_o    =  axi_wready_q  ;
    assign axi_bvalid_o    =  axi_bvalid_q  ;
    assign axi_bresp_o     =  axi_bresp_q   ;
    assign axi_bid_o       =  axi_bid_q     ;


    //-----------------------------------------------------------------
    // AXI read case
    // AXI read state machine
    //-----------------------------------------------------------------
    localparam STR_IDLE    = 3'h0,
               STR_RUN     = 3'h1,
               STR_WAIT    = 3'h2,
               STR_READ0   = 3'h3,
               STR_READ1   = 3'h4,
               STR_END     = 3'h5;

    reg  [  7:0]  axi_arlen_q   ; 
    reg  [  1:0]  axi_arburst_q ; 

    reg           axi_arready_q ; 
    reg           axi_rvalid_q  ; 
    reg  [ 31:0]  axi_rdata_q   ; 
    reg  [  1:0]  axi_rresp_q   ; 
    reg  [  3:0]  axi_rid_q     ; 
    reg           axi_rlast_q   ; 

    reg  [  7:0]  rbeat_q       ;
    reg  [  2:0]  rstate_q      ;
    reg  [  2:0]  next_rstate_r ;

    always @(*) begin
        next_rstate_r = rstate_q;
    
        case (rstate_q)
            STR_IDLE :
            begin
                if (axi_arvalid_i == 1'b1 && axi_awvalid_i == 1'b0 && grant_write_q == 1'b0)
                    next_rstate_r = STR_RUN;
            end    
            STR_RUN :
            begin
                next_rstate_r = STR_WAIT;
            end
            STR_WAIT :
            begin
                if (ack_q == 1'b1)
                    next_rstate_r = STR_READ0;

            end
            STR_READ0 :
            begin
                if (ack_q == 1'b0) begin
                    if (rbeat_q >= axi_arlen_q)
                        next_rstate_r = STR_END;
                    else
                        next_rstate_r = STR_READ1;
                end
            end
            STR_READ1 :
            begin
                if (axi_rready_i == 1'b1)
                    next_rstate_r = STR_WAIT;
            end
            STR_END :
            begin
                if (axi_rready_i == 1'b1)
                    next_rstate_r = STR_IDLE;
            end
            default: next_rstate_r = STR_IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rstate_q   <= STR_IDLE;
        else
            rstate_q   <= next_rstate_r;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            grant_read_q   <= 1'b0;
        else if (rstate_q == STR_IDLE && next_rstate_r == STR_RUN)
            grant_read_q   <= 1'b1;
        else if (rstate_q == STR_READ0 && ack_q == 1'b0 && rbeat_q >= axi_arlen_q)
            grant_read_q   <= 1'b0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            axi_arready_q   <= 1'b0;
        else if (rstate_q == STR_IDLE && next_rstate_r == STR_RUN)
            axi_arready_q   <= 1'b1;
        else if (rstate_q == STR_RUN)
            axi_arready_q   <= 1'b0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            axi_arlen_q   <= 8'h0; 
            axi_arburst_q <= 2'h0; 
        end
        else if (rstate_q == STR_IDLE && next_rstate_r == STR_RUN) begin
            axi_arlen_q   <= axi_arlen_i  ; 
            axi_arburst_q <= axi_arburst_i; 
        end
    end

    reg  [31:0]  next_raddr_q ;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            next_raddr_q   <= 32'h0;
        else if (rstate_q == STR_IDLE && next_rstate_r == STR_RUN) 
            next_raddr_q   <= axi_araddr_i;
        else if (rstate_q == STR_WAIT && ack_q == 1'b1) 
            next_raddr_q   <= calculate_addr_next(next_raddr_q, axi_arburst_q, axi_arlen_q);
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            rbeat_q        <= 8'h0 ;
        else if (rstate_q == STR_RUN) 
            rbeat_q        <= 8'h0 ;
        else if (rstate_q == STR_READ1 && axi_rready_i == 1'b1) 
            rbeat_q        <= rbeat_q + 1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            t_raddr_q <= 32'h0;
            t_ren_q   <= 1'b0;
        end
        else if (rstate_q == STR_RUN) begin
            t_raddr_q <= next_raddr_q;
            t_ren_q   <= 1'b1;
        end
        else if (rstate_q == STR_WAIT && ack_q == 1'b1) begin
            t_ren_q   <= 1'b0;
        end
        else if (rstate_q == STR_READ1 && axi_rready_i == 1'b1) begin
            t_raddr_q <= next_raddr_q;
            t_ren_q   <= 1'b1;
        end
        else if(rstate_q == STR_END && next_rstate_r == STR_IDLE) begin
            t_raddr_q <= 32'h0;
            t_ren_q   <= 1'b0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            axi_rvalid_q  <= 1'b0; 
            axi_rdata_q   <= 32'h0; 
            axi_rresp_q   <= 2'b01;  //Slave Error 
            axi_rid_q     <= 4'h0; 
            axi_rlast_q   <= 1'b0; 
        end
        else if (rstate_q == STR_RUN) begin
            axi_rdata_q   <= 32'h0; 
            axi_rid_q     <= axi_arid_i; 
        end
        else if (rstate_q == STR_WAIT && ack_q == 1'b1) begin
            axi_rdata_q   <= t_rdata_w; 
        end
        else if (rstate_q == STR_READ0 && ack_q == 1'b0) begin
            if (rbeat_q >= axi_arlen_q) begin
                axi_rvalid_q  <= 1'b1; 
                axi_rresp_q   <= 2'b0; 
                axi_rlast_q   <= 1'b1; 
            end else begin
                axi_rvalid_q  <= 1'b1; 
                axi_rresp_q   <= 2'b0; 
                axi_rlast_q   <= 1'b0; 
            end
        end
        else if (rstate_q == STR_READ1 && axi_rready_i == 1'b1) begin
            axi_rvalid_q  <= 1'b0; 
            axi_rdata_q   <= 32'h0; 
        end
        else if (rstate_q == STR_END && axi_rready_i == 1'b1) begin
            axi_rvalid_q  <= 1'b0; 
            axi_rlast_q   <= 1'b0; 
        end
    end

    //AXI read outputs
    assign axi_arready_o = axi_arready_q ; 
    assign axi_rvalid_o  = axi_rvalid_q  ; 
    assign axi_rdata_o   = axi_rdata_q   ; 
    assign axi_rresp_o   = axi_rresp_q   ; 
    assign axi_rid_o     = axi_rid_q     ; 
    assign axi_rlast_o   = axi_rlast_q   ; 


    //-----------------------------------------------------------------
    // IPBus read/write
    // IPBus state machine
    //-----------------------------------------------------------------
    localparam ST_IDLE  = 2'h0,
               ST_ADDR  = 2'h1,
               ST_WAIT  = 2'h2,
               ST_END   = 2'h3;

    reg  [  1:0]  pstate_q      ;
    reg  [  1:0]  next_pstate_r ;

    reg  [ 31:0]  bus2ip_addr_q ; 
    reg  [  3:0]  bus2ip_wstrb_q;   
    reg  [ 31:0]  bus2ip_data_q ; 
    reg           bus2ip_wr_ce_q; 

    always @(*) begin
        next_pstate_r = pstate_q;
    
        case (pstate_q)
            ST_IDLE :
            begin
                if (req_r == 1'b1)
                    next_pstate_r = ST_ADDR;
            end
            ST_ADDR :
            begin
                next_pstate_r = ST_WAIT;
            end
            ST_WAIT :
            begin
                if (ip2bus_ready_i)
                    next_pstate_r = ST_END; 
            end
            ST_END :
            begin
                if (req_r == 1'b0) 
                    next_pstate_r = ST_IDLE;
            end
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pstate_q   <= ST_IDLE;
        else
            pstate_q   <= next_pstate_r;
    end

    //address
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            bus2ip_addr_q <= 32'h0;
        else if (pstate_q == ST_IDLE && req_r == 1'b1)
            bus2ip_addr_q <= addr_r;
        else if (pstate_q == ST_END && req_r == 1'b0)
            bus2ip_addr_q <= 32'h0;
    end

    //write data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bus2ip_wstrb_q <= 4'h0;   
            bus2ip_data_q  <= 32'h0;
            bus2ip_wr_ce_q <= 1'b0;
        end
        else if (ip2bus_ready_i && bus2ip_wr_ce_q) 
            bus2ip_wr_ce_q <= 1'b0;
        else if (pstate_q == ST_ADDR && wr_r == 1'b1) begin
            bus2ip_wstrb_q <= be_r;   
            bus2ip_data_q  <= wdata_r;
            bus2ip_wr_ce_q <= 1'b1;
        end
        else if (pstate_q == ST_END && req_r == 1'b0) begin
            bus2ip_wstrb_q <= 4'h0;   
            bus2ip_data_q  <= 32'h0;
            bus2ip_wr_ce_q <= 1'b0;
        end
    end

    //IPBus read enable 
    reg  bus2ip_rd_ce_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            bus2ip_rd_ce_q <= 1'b0;
        else if (ip2bus_ready_i && bus2ip_rd_ce_q)
            bus2ip_rd_ce_q <= 1'b0;
        else if (pstate_q == ST_ADDR && req_r == 1'b1 && grant_read_q == 1'b1)
            bus2ip_rd_ce_q <= 1'b1;
        else if (pstate_q == ST_END && req_r == 1'b0)
            bus2ip_rd_ce_q <= 1'b0;
    end

    //IPBus read data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rdata_q <= 32'h0;
        else if (pstate_q == ST_WAIT && ip2bus_ready_i == 1'b1)
            rdata_q <= ip2bus_data_i;
        else if (pstate_q == ST_END && req_r == 1'b0)
            rdata_q <= 32'h0;
    end

    //acknowledge
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ack_q <= 1'b0;
        else if (pstate_q == ST_WAIT && ip2bus_ready_i == 1'b1)
            ack_q <= 1'b1;
        else if (pstate_q == ST_END && req_r == 1'b0)
            ack_q <= 1'b0;
    end

    //IPBus outputs
    assign bus2ip_clk     = clk;
    assign bus2ip_rst_n   = rst_n;
    assign bus2ip_addr_o  = bus2ip_addr_q ;
    assign bus2ip_wstrb_o = bus2ip_wstrb_q;
    assign bus2ip_data_o  = bus2ip_data_q ;
    assign bus2ip_rd_ce_o = bus2ip_rd_ce_q;            
    assign bus2ip_wr_ce_o = bus2ip_wr_ce_q;  

    //-------------------------------------------------------------
    // calculate_addr_next
    //-------------------------------------------------------------
    function [31:0] calculate_addr_next;
        input [31:0] addr;
        input [1:0]  axtype;
        input [7:0]  axlen;
    
        reg [31:0]   mask;
    begin
        mask = 0;
    
        case (axtype)
            2'd0: // AXI4_BURST_FIXED
            begin
                calculate_addr_next = addr;
            end
            2'd2: // AXI4_BURST_WRAP
            begin
                case (axlen)
                8'd0:      mask = 32'h03;
                8'd1:      mask = 32'h07;
                8'd3:      mask = 32'h0F;
                8'd7:      mask = 32'h1F;
                8'd15:     mask = 32'h3F;
                default:   mask = 32'h3F;
                endcase
    
                calculate_addr_next = (addr & ~mask) | ((addr + 4) & mask);
            end
            default: // AXI4_BURST_INCR
                calculate_addr_next = addr + 4;
        endcase
    end
    endfunction

endmodule
