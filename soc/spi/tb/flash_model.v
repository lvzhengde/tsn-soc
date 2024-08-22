/*+
 * Copyright (c) 2022-2024 Zhengde
 *
 * Copyright (c) 2002 Tadej Markovic, tadej@opencores.org 
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
 * Simplified SPI NOR Flash model
 * Based on ISSI IS25LP512M/IS25WP512M SERIAL FLASH MEMORY
 * Only SPI interface supported
 * The devices support either of two SPI modes:
 *     Mode 0 (0, 0)
 *     Mode 3 (1, 1)
-*/

`include "spi_defines.v"
`include "tb_spi_defines.v"

module flash_model  
(
    input          rst_n      ,
    input          spi_clk_i  ,
    input          spi_cs_i   ,    
    input          spi_mosi_i ,
    output         spi_miso_o 
);
    parameter MSIZE    = (1 << 26);    //Flash memory size in bytes
    parameter T_QDELAY = 0.5;

    //--------------------------------------------------------------------
    // Supported SPI NOR FLASH REGISTER definitions
    //--------------------------------------------------------------------
    // No.  | Register Name            | Instructions
    //--------------------------------------------------------------------
    //   0  | Status Register          | RDSR, WRSR, WREN, WRDI
    //   1  | Function Register        | RDFR, WRFR   
    //   2  | Read Register            | SPRNV, SPRV, RDRP
    //   3  | Extended Read Register   | SERPNV, SERPV, CLERP, RDERP    
    //   4  | Bank Address Register    | RDBR, WRBRV, WRBRNV, EN4B, EX4B
    //--------------------------------------------------------------------

    // Status register (sr)
    reg         sr_wip;                //Write In Progress
    reg         sr_wel;                //Write Enable Latch
    reg  [ 3:0] sr_bp   = 4'b0;        //Block Protection
    reg         sr_qe   = 0;           //Quad Enable
    reg         sr_srwd = 0;           //Status Register Write disable

    // Function register (fr)
    reg         fr_drstd = 0;          //Dedicated RESET# Disable
    reg         fr_tbs   = 0;          //Top/Bottom Selection
    reg         fr_psus;               //Program suspend
    reg         fr_esus;               //Erase suspend
    reg  [ 3:0] fr_irl ;               //Lock the Information Row

    // Read register (rr)
    reg  [ 1:0] rr_blen;               //Burst Length 
    reg         rr_blen_en = 0;        //Burst Length Set Enable
    reg  [ 3:0] rr_dcycles;            //Number of Dummy Cycles         
    reg         rr_holdrst = 0;        //HOLD#/RESET# fuction selection    

    // Extended read register (err)
    reg         err_eb0 = 0;           //Reserved
    reg         err_prot_e;            //Protection Error
    reg         err_p_err ;            //Program Error
    reg         err_e_err ;            //Erase Error
    reg         err_dlpen ;            //DLP Enable
    reg  [ 2:0] err_ods = 3'b111;      //Output Driver Strength

    // Bank Address register (bar)
    reg         bar_ba24;              //Enables 128Mb segment selection in 3-byte addressing, 512Mb : BA24
    reg         bar_ba25;              //512Mb : BA25
    reg  [ 4:0] bar_bit2_6 = 5'b0;     //Reserved
    reg         bar_extadd = 0;        //3-byte or 4-byte addressing mode selection

    //--------------------------------------------------------------------
    //
    // Flash Data MEMORY
    reg  [ 7:0] flash_mem [0:MSIZE-1]; // 64MB (512Mb) of 8-bit data width
    //
    //--------------------------------------------------------------------


    //--------------------------------------------------------------------
    // SPI serial interface, data shift in / shift out
    //--------------------------------------------------------------------
    wire rst_spi_n = rst_n & (~spi_cs_i);

    reg  [31:0] posedge_count;
    reg  [ 7:0] shift_in;
    reg  [ 7:0] shift_out;
    reg  [ 7:0] instr_code;
    reg  [ 7:0] instr_byte1_6[1:6];

    // Count rising edge
    always @(posedge spi_clk_i or negedge rst_spi_n) begin
        if (!rst_spi_n)
            posedge_count <= 32'h0;
        else if (!spi_cs_i)
            posedge_count <= posedge_count + 1;
    end

    // Sample on rising edge
    always @(posedge spi_clk_i or negedge rst_spi_n) begin
        if (!rst_spi_n)
            shift_in <= 8'h0;
        else if (!spi_cs_i)
            shift_in <= {shift_in[6:0], spi_mosi_i};
    end

    // Drive on falling edge
    reg    spi_miso_q;

    always @(negedge spi_clk_i or negedge rst_spi_n) begin
        if (!rst_spi_n) begin
            shift_out  <= 8'h0;
            spi_miso_q <= 1'b0;
        end
        else if (!spi_cs_i) begin
            spi_miso_q <= shift_out[7];
            shift_out  <= {shift_out[6:0], 1'b0};
        end
    end

    // Instruction code
    always @(posedge spi_clk_i or negedge rst_spi_n) begin
        if (!rst_spi_n)
            instr_code <= 8'h0;
        else if ((!spi_cs_i) && posedge_count == 32'd7 )
            instr_code <= {shift_in[6:0], spi_mosi_i};
    end

    // Byte1--Byte6 after Instruction code
    always @(posedge spi_clk_i or negedge rst_spi_n) begin
        if (!rst_spi_n) begin
            instr_byte1_6[1] <= 8'h0;
            instr_byte1_6[2] <= 8'h0;
            instr_byte1_6[3] <= 8'h0;
            instr_byte1_6[4] <= 8'h0;
            instr_byte1_6[5] <= 8'h0;
            instr_byte1_6[6] <= 8'h0;
        end
        else if ((!spi_cs_i) && posedge_count[2:0] == 3'd7 ) begin
            if (posedge_count[31:3] =29'd1) instr_byte1_6[1] <= {shift_in[6:0], spi_mosi_i};
            if (posedge_count[31:3] =29'd2) instr_byte1_6[2] <= {shift_in[6:0], spi_mosi_i};
            if (posedge_count[31:3] =29'd3) instr_byte1_6[3] <= {shift_in[6:0], spi_mosi_i};
            if (posedge_count[31:3] =29'd4) instr_byte1_6[4] <= {shift_in[6:0], spi_mosi_i};
            if (posedge_count[31:3] =29'd5) instr_byte1_6[5] <= {shift_in[6:0], spi_mosi_i};
            if (posedge_count[31:3] =29'd6) instr_byte1_6[6] <= {shift_in[6:0], spi_mosi_i};
        end
    end

    // Generate output data
    reg  [ 7:0] data_out;
    reg  [ 7:0] darray_out[0:100];
    integer i;

    initial 
    begin
        for (i = 0; i < 100; i = i+1)
            darray_out[i] = 8'h0;
    end

    always @(*) begin
        if ((!rst_n) || spi_cs_i) begin
            for (i = 0; i < 100; i = i+1)
                darray_out[i] = 8'h0;
        end

        for (i = 0; i < 100; i = i+1)
            data_out = darray_out[i] | data_out;
    end
    
    // Load output data after rising edge
    initial 
    begin
        shift_out = 8'h0;

        forever @(posedge spi_clk_i)
        begin
            #T_QDELAY
            if ((!spi_cs_i) && posedge_count == 32'd0 )
                shift_out = data_out;
        end
    end


endmodule
