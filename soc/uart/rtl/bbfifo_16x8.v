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
 *  Description : Synchronous FIFO
 *  File        : bbfifo_16x8.v
-*/

module bbfifo_16x8(
    input          clk   ,
    input          rst_n ,      //active low reset
                                  
    input          read_i    ,      //read enable, active high
    input          write_i   ,      //write enable, active high
    input  [7:0]   data_in_i ,
                                  
    output [7:0]   data_out_o      ,    
    output         data_present_o  ,

    output         full_o    ,
    output         hfull_o   ,  //half full
    output         afull_o   ,  //almost full
    output         aempty_o     //almost empty
);

    //wires
    reg [4:0] rptr;
    reg [4:0] wptr;
    
    wire  full ;
    wire  empty;
    wire  hfull;
    wire  aempty;
    wire  afull ;
    
    assign full_o     = full;
    assign hfull_o    = hfull;
    assign data_present_o = ~empty;
    
    assign afull_o  = afull;
    assign aempty_o = aempty;

    //memory
    bbfifo_16x8_mem bbfifo_16x8_mem (
        .clk        (clk ),
        .rst_n      (rst_n ),    
                    
        .wen_i      (write_i&(~full) ), 
        .wdata_i    (data_in_i ), 
        .waddr_i    (wptr[3:0] ), 
        .raddr_i    (rptr[3:0] ), 
        .rdata_o    (data_out_o )
    );

    // misc logics
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)	
        	rptr <= 5'b0;
        else if(read_i && (!empty))
        	rptr <= rptr + 5'b1;
    end
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
    	    wptr <= 5'b0;
        else if(write_i && (!full))
        	wptr <= wptr + 5'b1;
    end

    //full & empty flags
    assign full      = ((wptr[3:0] == rptr[3:0]) && (wptr[4] != rptr[4]));
    assign empty     = (wptr[4:0] == rptr[4:0]);
    
    wire [4:0] rptr_pl1 = rptr + 5'b1;
    wire [4:0] wptr_pl8 = wptr + 5'h8;
    wire [4:0] wptr_pl1 = wptr + 5'b1;
    
    assign hfull    = ((wptr_pl8[3:0] == rptr[3:0]) && (wptr_pl8[4] != rptr[4]));  //write pointer + 8 catch read pointer
    assign afull  = ((wptr_pl1[3:0] == rptr[3:0]) && (wptr_pl1[4] != rptr[4]));
    assign aempty = (wptr[4:0] == rptr_pl1[4:0]);

endmodule

