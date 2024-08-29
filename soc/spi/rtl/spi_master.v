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
 *  Description : SPI master
 *                Transmit and receive in units of one byte each time.
 *  File        : spi_master.v
-*/

module spi_master
(
    input          clk        ,
    input          rst_n      ,
    input          sw_reset_i ,

    input          cpol_i     ,
    input          cpha_i     ,
    input          spi_loop_i ,
    input  [15:0]  sck_ratio_i,

    input          req_i      ,
    input          start_i    ,
    output         done_o     ,
    output         busy_o     ,
    input  [ 7:0]  data_i     ,
    output [ 7:0]  data_o     ,

    output         spi_clk_o  ,
    output         spi_mosi_o ,
    input          spi_miso_i ,
    output         spi_cs_o   
);

    //-----------------------------------------------------------------
    // Registers
    //-----------------------------------------------------------------
    reg        active_q;
    reg [ 5:0] edge_cnt_q;
    reg [ 7:0] shift_reg_q;
    reg [16:0] clk_div_q;
    reg        done_q;    

    reg        spi_clk_q;
    reg        spi_mosi_q;

    //-----------------------------------------------------------------
    // Implementation
    //-----------------------------------------------------------------
    wire start_w = start_i & req_i;

    // Loopback more or normal
    wire miso_w = spi_loop_i ? spi_mosi_o : spi_miso_i;

    // SPI Clock Generator
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            clk_div_q <= 16'd0;
        else if (start_w || sw_reset_i || clk_div_q == 16'd0)
            clk_div_q <= sck_ratio_i;
        else
            clk_div_q <= clk_div_q - 16'd1;
    end
    
    wire clk_en_w = (clk_div_q == 16'd0);

    //-----------------------------------------------------------------
    // Sample, Drive pulse generation
    //-----------------------------------------------------------------
    reg    sample_r;
    reg    drive_r;
    
    always @(*) begin
        sample_r = 1'b0;
        drive_r  = 1'b0;
        
        // SPI = IDLE
        if (start_w)    
            drive_r  = ~cpha_i; // Drive initial data 
        // SPI = ACTIVE
        else if (active_q && clk_en_w)
        begin
            // Sample
            // CPHA=0, sample on the first edge
            // CPHA=1, sample on the second edge
            if (edge_cnt_q[0] == cpha_i)
                sample_r = 1'b1;
            // Drive (CPHA = 1)
            else if (cpha_i)
                drive_r = 1'b1;
            // Drive (CPHA = 0)
            else 
                drive_r = (edge_cnt_q != 6'b0) && (edge_cnt_q != 6'd15);
        end
    end

    //-----------------------------------------------------------------
    // Shift register
    //-----------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_q    <= 8'b0;
            spi_clk_q      <= 1'b0;
            spi_mosi_q     <= 1'b0;
        end
        else begin
            // SPI Software RESET 
            if (sw_reset_i) begin
                shift_reg_q <= 8'b0;
                spi_clk_q   <= cpol_i;
            end
            // SPI = IDLE
            else if (start_w) begin
                spi_clk_q   <= cpol_i;
        
                // CPHA = 0
                if (drive_r) begin
                    spi_mosi_q  <= data_i[7];
                    shift_reg_q <= {data_i[6:0], 1'b0};
                end
                // CPHA = 1
                else
                    shift_reg_q <= data_i;
            end
            // SPI = ACTIVE
            else if (active_q && clk_en_w) begin
                // Toggle SPI clock output
                if (!spi_loop_i)
                    spi_clk_q <= ~spi_clk_q;
        
                // Drive MOSI
                if (drive_r) begin
                    spi_mosi_q  <= shift_reg_q[7];
                    shift_reg_q <= {shift_reg_q[6:0],1'b0};
                end
                // Sample MISO
                else if (sample_r)
                    shift_reg_q[0] <= miso_w;
            end
        end
    end //always

    //-----------------------------------------------------------------
    // Edge counter--one bit <--> two edges
    //-----------------------------------------------------------------
    always @(posedge clk or posedge rst_n) begin
        if (!rst_n) begin
            edge_cnt_q <= 6'b0;
            active_q   <= 1'b0;
            done_q     <= 1'b0;
        end
        else if (sw_reset_i) begin
            edge_cnt_q <= 6'b0;
            active_q   <= 1'b0;
            done_q     <= 1'b0;
        end
        else if (start_w) begin
            edge_cnt_q <= 6'b0;
            active_q   <= 1'b1;
            done_q     <= 1'b0;
        end
        else if (active_q && clk_en_w) begin
            // End of SPI transfer reached
            if (edge_cnt_q == 6'd15) begin
                // Go back to IDLE active_q
                active_q <= 1'b0;
        
                // Set transfer complete flags
                done_q   <= 1'b1;
            end
            // Increment cycle counter
            else 
                edge_cnt_q <= edge_cnt_q + 6'd1;
        end
        else
            done_q  <= 1'b0;
    end // always
        
    // Outputs
    assign spi_clk_o  = spi_clk_q;
    assign spi_mosi_o = spi_mosi_q;
    assign spi_cs_o   = ~req_i;
    assign done_o     = done_q;
    assign busy_o     = active_q;
    assign data_o     = shift_reg_q;

endmodule

