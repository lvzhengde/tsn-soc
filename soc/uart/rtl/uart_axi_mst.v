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
 * UART COMMAND in RX buffer
 * cmd[0] = REQ_WRITE/REQ_READ
 * cmd[1] = len           //length in bytes
 * cmd[2] = addr[31:24]
 * cmd[3] = addr[23:16] 
 * cmd[4] = addr[15: 8]
 * cmd[5] = addr[ 7: 0]
 * DATA in RX / TX buffer
 * data0[ 7: 0]
 * data0[15: 8]
 * data0[23:16]
 * data0[31:24]
 * data1[ 7: 0]
 * ......
 * address in big endian, data in little endian
 * Using single beat AXI transfer only
 * can be converted to AXI-lite simply
-*/

module uart_axi_mst 
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
    parameter AXI_ID = 4'd0
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    input           clk     ,
    input           rst_n   ,      

    // AXI4 bus master interface
    output          axi_awvalid_o ,  
    output [ 31:0]  axi_awaddr_o  ,   
    output [  3:0]  axi_awid_o    ,   
    output [  7:0]  axi_awlen_o   ,   
    output [  1:0]  axi_awburst_o ,  
    output          axi_wvalid_o  ,   
    output [ 31:0]  axi_wdata_o   ,  
    output [  3:0]  axi_wstrb_o   ,  
    output          axi_wlast_o   ,  
    output          axi_bready_o  ,   
    output          axi_arvalid_o ,    
    output [ 31:0]  axi_araddr_o  ,   
    output [  3:0]  axi_arid_o    ,   
    output [  7:0]  axi_arlen_o   ,  
    output [  1:0]  axi_arburst_o ,    
    output          axi_rready_o  ,   

    input           axi_awready_i ,   
    input           axi_wready_i  ,  
    input           axi_bvalid_i  ,  
    input  [  1:0]  axi_bresp_i   , 
    input  [  3:0]  axi_bid_i     ,
    input           axi_arready_i ,   
    input           axi_rvalid_i  ,  
    input  [ 31:0]  axi_rdata_i   , 
    input  [  1:0]  axi_rresp_i   , 
    input  [  3:0]  axi_rid_i     , 
    input           axi_rlast_i   , 

    // uart rx interface
    input  [  7:0] mst_rdata_i    ,
    output         mst_read_o     ,
    input          rx_buffer_data_present_i ,
    
    // uart tx interface
    output [  7:0] mst_wdata_o       ,
    output         mst_write_o       ,      
    input          tx_buffer_full_i  ,
    input          tx_buffer_afull_i 
);

    //-----------------------------------------------------------------
    // Defines
    //-----------------------------------------------------------------
    localparam REQ_WRITE        = 8'had;
    localparam REQ_READ         = 8'h5a;
    
    localparam STATE_IDLE       = 4'd0;
    localparam STATE_LEN        = 4'd2;
    localparam STATE_ADDR0      = 4'd3;
    localparam STATE_ADDR1      = 4'd4;
    localparam STATE_ADDR2      = 4'd5;
    localparam STATE_ADDR3      = 4'd6;
    localparam STATE_WRITE      = 4'd7;
    localparam STATE_READ       = 4'd8;
    localparam STATE_DATA0      = 4'd9;
    localparam STATE_DATA1      = 4'd10;
    localparam STATE_DATA2      = 4'd11;
    localparam STATE_DATA3      = 4'd12;

    //-----------------------------------------------------------------
    // Wires / Regs
    //-----------------------------------------------------------------
    wire       tx_valid_w;
    wire [7:0] tx_data_w;
    wire       tx_accept_w;
    wire       read_skip_w;
    
    wire       rx_valid_w;
    wire [7:0] rx_data_w;
    wire       rx_accept_w;
    
    reg [31:0] axi_addr_q;
    reg        axi_busy_q;
    reg        axi_wr_q;
    
    reg [7:0]  len_q;
    // Byte Index
    reg [1:0]  data_idx_q;
    // Word storage
    reg [31:0] data_q;

    // UART TX interface
    assign mst_write_o = tx_valid_w;
    assign mst_wdata_o = tx_data_w ;
    assign tx_accept_w = !tx_buffer_full_i;

    // UART RX interface
    assign rx_valid_w = rx_buffer_data_present_i; 
    assign mst_read_o = rx_accept_w;
    assign rx_data_w  = mst_rdata_i;

    //-----------------------------------------------------------------
    // States
    //-----------------------------------------------------------------
    reg [ 3:0] state_q;
    reg [ 3:0] next_state_r;

    // Next state logics
    always @(*) begin
        next_state_r = state_q;
    
        case (next_state_r)
        //-------------------------------------------------------------
        // IDLE:
        //-------------------------------------------------------------
        STATE_IDLE:
        begin
            if (rx_valid_w)
            begin
                case (rx_data_w)
                REQ_WRITE,
                REQ_READ:
                    next_state_r = STATE_LEN;
                default:
                    ;
                endcase
            end
        end
        //-----------------------------------------
        // STATE_LEN
        //-----------------------------------------
        STATE_LEN :
        begin
            if (rx_valid_w)
                next_state_r  = STATE_ADDR0;
        end
        //-----------------------------------------
        // STATE_ADDR
        //-----------------------------------------
        STATE_ADDR0 : if (rx_valid_w) next_state_r  = STATE_ADDR1;
        STATE_ADDR1 : if (rx_valid_w) next_state_r  = STATE_ADDR2;
        STATE_ADDR2 : if (rx_valid_w) next_state_r  = STATE_ADDR3;
        STATE_ADDR3 :
        begin
            if (rx_valid_w && axi_wr_q) 
                next_state_r  = STATE_WRITE;
            else if (rx_valid_w) 
                next_state_r  = STATE_READ;            
        end
        //-----------------------------------------
        // STATE_WRITE
        //-----------------------------------------
        STATE_WRITE :
        begin
            if (len_q == 8'b0 && (axi_bvalid_i))
                next_state_r  = STATE_IDLE;
            else
                next_state_r  = STATE_WRITE;
        end
        //-----------------------------------------
        // STATE_READ
        //-----------------------------------------
        STATE_READ :
        begin
            // Data ready
            if (axi_rvalid_i)
                next_state_r  = STATE_DATA0;
        end
        //-----------------------------------------
        // STATE_DATA
        //-----------------------------------------
        STATE_DATA0 :
        begin
            if (read_skip_w)
                next_state_r  = STATE_DATA1;
            else if (tx_accept_w && (len_q == 8'b0))
                next_state_r  = STATE_IDLE;
            else if (tx_accept_w)
                next_state_r  = STATE_DATA1;
        end
        STATE_DATA1 :
        begin
            if (read_skip_w)
                next_state_r  = STATE_DATA2;
            else if (tx_accept_w && (len_q == 8'b0))
                next_state_r  = STATE_IDLE;
            else if (tx_accept_w)
                next_state_r  = STATE_DATA2;
        end
        STATE_DATA2 :
        begin
            if (read_skip_w)
                next_state_r  = STATE_DATA3;
            else if (tx_accept_w && (len_q == 8'b0))
                next_state_r  = STATE_IDLE;
            else if (tx_accept_w)
                next_state_r  = STATE_DATA3;
        end
        STATE_DATA3 :
        begin
            if (tx_accept_w && (len_q != 8'b0))
                next_state_r  = STATE_READ;
            else if (tx_accept_w)
                next_state_r  = STATE_IDLE;
        end
        default:
            ;
        endcase
    end

    // State switch
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state_q <= STATE_IDLE;
        else
            state_q <= next_state_r;
    end

    //-----------------------------------------------------------------
    // RD/WR to and from UART
    //-----------------------------------------------------------------
    
    // Write to UART Tx buffer in the following states
    assign tx_valid_w = ((state_q == STATE_DATA0) |
                         (state_q == STATE_DATA1) |
                         (state_q == STATE_DATA2) |
                         (state_q == STATE_DATA3)) && !read_skip_w;
    
    // Accept data in the following states
    assign rx_accept_w = (state_q == STATE_IDLE)  |
                         (state_q == STATE_LEN)   |
                         (state_q == STATE_ADDR0) |
                         (state_q == STATE_ADDR1) |
                         (state_q == STATE_ADDR2) |
                         (state_q == STATE_ADDR3) |
                         (state_q == STATE_WRITE && !axi_busy_q);

    //-----------------------------------------------------------------
    // Capture length
    //-----------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            len_q       <= 8'd0;
        else if (state_q == STATE_LEN && rx_valid_w)
            len_q[7:0]  <= rx_data_w;
        else if (state_q == STATE_WRITE && rx_valid_w && !axi_busy_q)
            len_q       <= len_q - 8'd1;
        else if (state_q == STATE_READ && (axi_busy_q && axi_rvalid_i))
            len_q       <= len_q - 8'd1;
        else if (((state_q == STATE_DATA0) || (state_q == STATE_DATA1) || (state_q == STATE_DATA2)) && (tx_accept_w && !read_skip_w))
            len_q       <= len_q - 8'd1;
    end

    
    //-----------------------------------------------------------------
    // Capture address
    //-----------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            axi_addr_q        <= 'd0;
        else if (state_q == STATE_ADDR0 && rx_valid_w)
            axi_addr_q[31:24] <= rx_data_w;
        else if (state_q == STATE_ADDR1 && rx_valid_w)
            axi_addr_q[23:16] <= rx_data_w;
        else if (state_q == STATE_ADDR2 && rx_valid_w)
            axi_addr_q[15:8]  <= rx_data_w;
        else if (state_q == STATE_ADDR3 && rx_valid_w)
            axi_addr_q[7:0]   <= rx_data_w;
        // Address increment on every access issued
        else if (state_q == STATE_WRITE && (axi_busy_q && axi_bvalid_i))
            axi_addr_q        <= {axi_addr_q[31:2], 2'b0} + 'd4;
        else if (state_q == STATE_READ && (axi_busy_q && axi_rvalid_i))
            axi_addr_q        <= {axi_addr_q[31:2], 2'b0} + 'd4;
    end
        
    //-----------------------------------------------------------------
    // Data Index
    //-----------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_idx_q <= 2'b0;
        else if (state_q == STATE_ADDR3)
            data_idx_q <= rx_data_w[1:0];
        else if (state_q == STATE_WRITE && rx_valid_w && !axi_busy_q)
            data_idx_q <= data_idx_q + 2'd1;
        else if (((state_q == STATE_DATA0) || (state_q == STATE_DATA1) || (state_q == STATE_DATA2)) && tx_accept_w && (data_idx_q != 2'b0))
            data_idx_q <= data_idx_q - 2'd1;
    end
    
    assign read_skip_w = (data_idx_q != 2'b0);

    //-----------------------------------------------------------------
    // Data Sample
    //-----------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_q <= 32'b0;
        // Write to AXI memory/register
        else if (state_q == STATE_WRITE && rx_valid_w && !axi_busy_q)
        begin
            case (data_idx_q)
                2'd0: data_q[7:0]   <= rx_data_w;
                2'd1: data_q[15:8]  <= rx_data_w;
                2'd2: data_q[23:16] <= rx_data_w;
                2'd3: data_q[31:24] <= rx_data_w;
            endcase  
        end
        // Read from AXI memory/register
        else if (state_q == STATE_READ && axi_rvalid_i)
            data_q <= axi_rdata_i;
        // Shift data out (read response -> UART)
        else if (((state_q == STATE_DATA0) || (state_q == STATE_DATA1) || (state_q == STATE_DATA2)) && (tx_accept_w || read_skip_w))
            data_q <= {8'b0, data_q[31:8]};
    end

    assign tx_data_w   = data_q[7:0];                  
    assign axi_wdata_o = data_q;

    //-----------------------------------------------------------------
    // AXI: Write Request
    //-----------------------------------------------------------------
    reg axi_awvalid_q;
    reg axi_awvalid_r;
    
    reg axi_wvalid_q;
    reg axi_wvalid_r;
    
    always @(*) begin
        axi_awvalid_r = 1'b0;
        axi_wvalid_r  = 1'b0;
    
        // Hold
        if (axi_awvalid_o && !axi_awready_i)
            axi_awvalid_r = axi_awvalid_q;
        else if (axi_awvalid_o)
            axi_awvalid_r = 1'b0;
        // Every 4th byte, issue bus access
        else if (state_q == STATE_WRITE && rx_valid_w && (data_idx_q == 2'd3 || len_q == 1))
            axi_awvalid_r = 1'b1;
    
        // Hold
        if (axi_wvalid_o && !axi_wready_i)
            axi_wvalid_r = axi_wvalid_q;
        else if (axi_wvalid_o)
            axi_wvalid_r = 1'b0;
        // Every 4th byte, issue bus access
        else if (state_q == STATE_WRITE && rx_valid_w && (data_idx_q == 2'd3 || len_q == 1))
            axi_wvalid_r = 1'b1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
        begin
            axi_awvalid_q <= 1'b0;
            axi_wvalid_q  <= 1'b0;
        end
        else
        begin
            axi_awvalid_q <= axi_awvalid_r;
            axi_wvalid_q  <= axi_wvalid_r;
        end
    end
    
    assign axi_awvalid_o = axi_awvalid_q;
    assign axi_wvalid_o  = axi_wvalid_q;
    assign axi_awaddr_o  = {axi_addr_q[31:2], 2'b0};
    assign axi_awid_o    = AXI_ID;
    assign axi_awlen_o   = 8'b0;
    assign axi_awburst_o = 2'b01;
    assign axi_wlast_o   = 1'b1;
    
    assign axi_bready_o  = 1'b1;

    //-----------------------------------------------------------------
    // AXI: Read Request
    //-----------------------------------------------------------------
    reg axi_arvalid_q;
    reg axi_arvalid_r;
    
    always @(*) begin
        axi_arvalid_r = 1'b0;
    
        // Hold
        if (axi_arvalid_o && !axi_arready_i)
            axi_arvalid_r = axi_arvalid_q;
        else if (axi_arvalid_o)
            axi_arvalid_r = 1'b0;
        else if (state_q == STATE_READ && !axi_busy_q)
            axi_arvalid_r = 1'b1;
    end
    
    always @(posedge clk or negedge rst_n)
    if (!rst_n)
        axi_arvalid_q <= 1'b0;
    else
        axi_arvalid_q <= axi_arvalid_r;
    
    assign axi_arvalid_o = axi_arvalid_q;
    assign axi_araddr_o  = {axi_addr_q[31:2], 2'b0};
    assign axi_arid_o    = AXI_ID;
    assign axi_arlen_o   = 8'b0;
    assign axi_arburst_o = 2'b01;
    
    assign axi_rready_o  = 1'b1;

    //-----------------------------------------------------------------
    // Write mask
    //-----------------------------------------------------------------
    reg [3:0] axi_sel_q;
    reg [3:0] axi_sel_r;
    
    always @(*) begin
        axi_sel_r = 4'b1111;
    
        case (data_idx_q)
            2'd0: axi_sel_r = 4'b0001;
            2'd1: axi_sel_r = 4'b0011;
            2'd2: axi_sel_r = 4'b0111;
            2'd3: axi_sel_r = 4'b1111;
        endcase
    
        case (axi_addr_q[1:0])
            2'd0: axi_sel_r = axi_sel_r & 4'b1111;
            2'd1: axi_sel_r = axi_sel_r & 4'b1110;
            2'd2: axi_sel_r = axi_sel_r & 4'b1100;
            2'd3: axi_sel_r = axi_sel_r & 4'b1000;
        endcase
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            axi_sel_q    <= 4'b0;
        // Idle - reset for read requests
        else if (state_q == STATE_IDLE)
            axi_sel_q   <= 4'b1111;
        // Every 4th byte, issue bus access
        else if (state_q == STATE_WRITE && rx_valid_w && (data_idx_q == 2'd3 || len_q == 8'd1))
            axi_sel_q   <= axi_sel_r;
    end
    
    assign axi_wstrb_o  = axi_sel_q;

    //-----------------------------------------------------------------
    // Write enable
    //-----------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            axi_wr_q    <= 1'b0;
        else if (state_q == STATE_IDLE && rx_valid_w)
            axi_wr_q    <= (rx_data_w == REQ_WRITE);
    end

    //-----------------------------------------------------------------
    // Access in progress
    //-----------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n == 1'b1)
            axi_busy_q <= 1'b0;
        else if (axi_arvalid_o || axi_awvalid_o)
            axi_busy_q <= 1'b1;
        else if (axi_bvalid_i || axi_rvalid_i)
            axi_busy_q <= 1'b0;
    end

endmodule
