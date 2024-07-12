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
 *    P_SIZE_IN_BYTES - size of memory in bytes
 *    P_DELAY_WRITE_SETUP - delay to the first data from address cycle.
 *    P_DELAY_WRITE_BURST - delay between consecutive data cycles.
 *    P_DELAY_READ_SETUP  - delay to the first data from address cycle.
 *    P_DELAY_READ_BURST  - delay between consecutive data cycles.
 * Note:
 *    read-first (not write-through)
-*/

module mem_axi4_beh
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
    parameter P_SIZE_IN_BYTES      = 1024 ,  
    parameter ID                   = 0    , 
    parameter P_DELAY_WRITE_SETUP  = 0    ,
    parameter P_DELAY_WRITE_BURST  = 0    ,
    parameter P_DELAY_READ_SETUP   = 0    ,
    parameter P_DELAY_READ_BURST   = 0    
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
    output          axi_rlast_o     ,

    input           done_i

);
    // internal memory
    localparam ADDR_LENGTH = $clog2(P_SIZE_IN_BYTES);
    localparam DEPTH = (1 << (ADDR_LENGTH - 2));
    
    reg  [31:0] mem[0:DEPTH-1]; // synthesis syn_ramstyle="block_ram"; 

    integer num_reads ;
    integer num_writes;

    //-------------------------------------------------------------------------
    // write case
    //-------------------------------------------------------------------------
    reg  [ 31:0]  axi_awaddr_q    ;
    reg  [  3:0]  axi_awid_q      ;
    reg  [  7:0]  axi_awlen_q     ;
    reg  [  1:0]  axi_awburst_q   ;

    reg           axi_awready_q   ;
    reg           axi_wready_q    ;
    reg           axi_bvalid_q    ;
    reg  [  1:0]  axi_bresp_q     ;
    reg  [  3:0]  axi_bid_q       ;

    reg  [ADDR_LENGTH-1:0] waddr_q ; // address of each transfer within a burst
    reg  [ 7:0]            wbeat_q ; // keeps num of transfers within a burst
    reg  [ 7:0]            wdelay_q;

    integer idz;

    localparam STW_IDLE   = 2'h0,
               STW_DELAY  = 2'h1,
               STW_WRITE  = 2'h2,
               STW_RSP    = 2'h3;

    reg  [ 1:0]   wstate_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            axi_awaddr_q  <= 32'h0 ;
            axi_awid_q    <= 4'h0 ;
            axi_awlen_q   <= 8'h0 ;
            axi_awburst_q <= 2'h0 ;
            axi_awready_q <= 1'b0 ;
            axi_wready_q  <= 1'b0 ;
            axi_bvalid_q  <= 1'b0 ;
            axi_bresp_q   <= 2'b10 ; //Slave Error
            axi_bid_q     <= 4'h0 ;
            waddr_q       <= 'h0; 
            wbeat_q       <= 'h0; 
            wdelay_q      <= 'h0;
            num_writes    <=   0;
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
                    axi_bresp_q   <= 2'b00 ; // Okay

                    waddr_q       <= axi_awaddr_i[ADDR_LENGTH-1:0]; 
                    wbeat_q       <= 'h0; 
                    num_writes    <= num_writes + 1;

                    if (P_DELAY_WRITE_SETUP == 0) begin
                        axi_wready_q  <= 1'b1 ;
                        wdelay_q      <= P_DELAY_WRITE_BURST;
                        wstate_q      <= STW_WRITE;
                    end 
                    else begin
                        axi_wready_q  <= 1'b0 ;
                        wdelay_q      <= P_DELAY_WRITE_SETUP-1;
                        wstate_q      <= STW_DELAY;
                    end
                end 
                else begin
                    axi_awready_q <= 1'b1 ;
                end
            end // STW_IDLE
            STW_DELAY: 
            begin
                wdelay_q <= wdelay_q - 1;
                if (wdelay_q == 0) begin
                    axi_wready_q  <= 1'b1 ;
                    wstate_q      <= STW_WRITE;
                end
            end // STW_DELAY
            STW_WRITE: 
            begin
                if (axi_wvalid_i == 1'b1) begin
                    for (idz = 0; idz < 4; idz = idz+1) begin
                        if (axi_wstrb_i[idz]) 
                            mem[waddr_q[ADDR_LENGTH-1:2]][8*idz +: 8] <= axi_wdata_i[8*idz +: 8];
                    end
                    wbeat_q  <= wbeat_q + 1;
                    waddr_q  <= get_next_addr(waddr_q, axi_awburst_q, axi_awlen_q);

                    if (wbeat_q >= axi_awlen_q) begin
                        axi_wready_q  <= 1'b0 ;
                        axi_bvalid_q  <= 1'b1 ;
                        axi_bid_q     <= axi_awid_q ;

                        if (axi_wlast_i == 1'b0) axi_bresp_q <= 2'b10; // SLVERR - missing last
                        wstate_q <= STW_RSP;
                    end 
                    else begin
                        if (P_DELAY_WRITE_BURST != 0) begin
                            axi_wready_q  <= 1'b0 ;
                            wdelay_q      <= P_DELAY_WRITE_BURST-1;
                            wstate_q      <= STW_DELAY;
                        end
                    end
                end
            end // STW_WRITE
            STW_RSP: 
            begin
                if (axi_bready_i == 1'b1) begin
                    axi_bvalid_q  <= 1'b0 ;
                    axi_awready_q <= 1'b1 ;
                    wbeat_q       <= 'h0; 
                    wstate_q      <= STW_IDLE;
                end
            end // STW_RSP
            endcase
        end // if
    end // always

    // AXI write outputs
    assign axi_awready_o = axi_awready_q ;
    assign axi_wready_o  = axi_wready_q  ;
    assign axi_bvalid_o  = axi_bvalid_q  ;
    assign axi_bresp_o   = axi_bresp_q   ; 
    assign axi_bid_o     = axi_bid_q     ;

    // synthesis translate_off
    reg  [8*10-1:0] wstate_ascii = "IDLE";

    always @(*) begin
        case (wstate_q)
            STW_IDLE : wstate_ascii = "IDLE   ";
            STW_DELAY: wstate_ascii = "DELAY  ";
            STW_WRITE: wstate_ascii = "WRITE  ";
            STW_RSP  : wstate_ascii = "RSP    ";
            default  : wstate_ascii = "UNKNOWN";
        endcase
    end
    // synthesis translate_on


    //-------------------------------------------------------------------------
    // read case
    //-------------------------------------------------------------------------
    reg  [ 31:0]  axi_araddr_q    ;
    reg  [  7:0]  axi_arlen_q     ;
    reg  [  1:0]  axi_arburst_q   ;

    reg           axi_arready_q   ;
    reg           axi_rvalid_q    ;
    reg  [ 31:0]  axi_rdata_q     ;
    reg  [  1:0]  axi_rresp_q     ;
    reg  [  3:0]  axi_rid_q       ;
    reg           axi_rlast_q     ;


    reg  [ADDR_LENGTH-1:0]   raddr_q ; // address of each transfer within a burst
    reg  [ 7:0]              rbeat_q ; // keeps num of transfers within a burst
    reg  [ 7:0]              rdelay_q;
    //-------------------------------------------------------------------------
    localparam STR_IDLE = 2'h0,
               STR_DELAY= 2'h1,
               STR_READ = 2'h2,
               STR_END  = 2'h3;

    reg  [ 1:0]  rstate_q;

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
            rdelay_q      <= 8'h0;
            num_reads     <=    0;
            rstate_q      <= STR_IDLE;
        end 
        else begin
            case (rstate_q)
            STR_IDLE: 
            begin
                if ((axi_arvalid_i == 1'b1) && (axi_arready_o == 1'b1)) begin
                    axi_araddr_q  <= axi_araddr_i  ;
                    axi_arlen_q   <= axi_arlen_i   ;
                    axi_arburst_q <= axi_arburst_i ;
                    axi_arready_q <= 1'b0;
                    axi_rresp_q   <= 2'b00  ; //Okay 
                    axi_rid_q     <= axi_arid_i  ;
                    raddr_q       <= axi_araddr_i[ADDR_LENGTH-1:0]; 
                    num_reads     <= num_reads + 1;

                    if (P_DELAY_READ_SETUP == 0) begin
                        axi_rdata_q  <= mem[axi_araddr_i[ADDR_LENGTH-1:2]];
                        axi_rvalid_q <= 1'b1;
                        axi_rlast_q  <= (axi_arlen_i == 'h0) ? 1'b1 : 1'b0;
                        rbeat_q      <=  'h1;
                        raddr_q      <= get_next_addr(axi_araddr_i[ADDR_LENGTH-1:0], axi_arburst_i, axi_arlen_i);
                        rdelay_q     <= P_DELAY_READ_BURST;
                        rstate_q     <= (axi_arlen_i == 'h0) ? STR_END : STR_READ;
                    end 
                    else begin
                        rbeat_q      <= 'h0;
                        rdelay_q     <= P_DELAY_READ_SETUP - 1;
                        axi_rvalid_q <= 1'b0;
                        rstate_q     <= STR_DELAY;
                    end
                end 
                else begin
                    axi_arready_q <= 1'b1;
                end
            end // STR_IDLE
            STR_DELAY: 
            begin
                rdelay_q <= rdelay_q - 1;
                if (rdelay_q == 0) begin
                    axi_rdata_q  <= mem[raddr_q[ADDR_LENGTH-1:2]];
                    axi_rvalid_q <= 1'b1;
                    rbeat_q      <= rbeat_q + 1;
                    raddr_q      <= get_next_addr(raddr_q[ADDR_LENGTH-1:0], axi_arburst_q, axi_arlen_q);
                    if (rbeat_q == axi_arlen_q) begin
                        axi_rlast_q  <= 1'b1;
                        rstate_q     <= STR_END;
                    end 
                    else begin
                        rstate_q     <= STR_READ;
                    end
                end
            end // STR_DELAY
            STR_READ: 
            begin // address only
                if (axi_rready_i == 1'b1) begin
                    if (P_DELAY_READ_BURST == 0) begin
                        axi_rdata_q  <= mem[raddr_q[ADDR_LENGTH-1:2]];
                        axi_rvalid_q <= 1'b1;
                        rbeat_q      <= rbeat_q + 1;
                        raddr_q      <= get_next_addr(raddr_q[ADDR_LENGTH-1:0], axi_arburst_q, axi_arlen_q);
                        if (rbeat_q == axi_arlen_q) begin
                            axi_rlast_q  <= 1'b1;
                            rstate_q     <= STR_END;
                        end 
                    end 
                    else begin
                        axi_rvalid_q <= 1'b0;
                        rdelay_q     <= P_DELAY_READ_BURST - 1;
                        rstate_q     <= STR_DELAY;
                    end
                end
            end // STR_READ
            STR_END: 
            begin // data only
                if (axi_rready_i == 1'b1) begin
                    axi_rdata_q   <=  'h0;
                    axi_rresp_q   <= 2'b10; // SLVERR
                    axi_rlast_q   <= 1'b0;
                    axi_rvalid_q  <= 1'b0;
                    axi_arready_q <= 1'b1;
                    rdelay_q      <=  'h0;
                    rbeat_q       <=  'h0;
                    rstate_q      <= STR_IDLE;
                end
            end // STR_END
            endcase
        end // if
    end // always

    // AXI read outputs
    assign axi_arready_o =  axi_arready_q ;
    assign axi_rvalid_o  =  axi_rvalid_q  ;
    assign axi_rdata_o   =  axi_rdata_q   ;
    assign axi_rresp_o   =  axi_rresp_q   ;
    assign axi_rid_o     =  axi_rid_q     ;
    assign axi_rlast_o   =  axi_rlast_q   ;

     // synthesis translate_off
     reg  [8*10-1:0] rstate_ascii="IDLE";

     always @(*) begin
         case (rstate_q)
             STR_IDLE : rstate_ascii = "IDLE   ";
             STR_DELAY: rstate_ascii = "DELAY  ";
             STR_READ : rstate_ascii = "READ   ";
             STR_END  : rstate_ascii = "END    ";
             default  : rstate_ascii = "UNKNOWN";
         endcase
     end
     // synthesis translate_on

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

    // synopsys translate_off
    integer abits, depth;

    initial begin
        depth  = 1 << ADDR_LENGTH;
        $display("%m INFO %03dK (%06d) byte memory", depth/1024, depth);
        abits = ADDR_LENGTH - 2;
        //if (abits > 10) begin
        //       $display("%m INFO sdpram_8x%02dK should be used", 1<<(abits-10));
        //end else begin
        //       $display("%m INFO sdpram_8x%03d should be used", 1<<abits);
        //end
        wait (done_i == 1'b1);
        axi_statistics(ID);
    end

    task axi_statistics;
        input integer id;                                                            
    begin                                                                            
        $display("mem_axi[%2d] reads =%5d,  writes =%5d, mem_axi4_beh used", id, num_reads, num_writes );
    end                         
    endtask   
    // synopsys translate_on

endmodule
