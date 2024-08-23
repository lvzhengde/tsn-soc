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
    reg         sr_srwd = 0;           //Status Register Write disable (ignored as WP# = 1)

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
    reg  [ 7:0] instr_code_q;
    reg  [ 7:0] instr_byte1_6_q[1:6];
    wire [ 7:0] instr_code_w;
    wire [ 7:0] instr_byte1_6_w[1:6];

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
            instr_code_q <= 8'h0;
        else if ((!spi_cs_i) && posedge_count == 32'd7 )
            instr_code_q <= {shift_in[6:0], spi_mosi_i};
    end

    assign instr_code_w = (posedge_count == 32'd7) ? {shift_in[6:0], spi_mosi_i} : instr_code_q;

    // Byte1--Byte6 after Instruction code
    always @(posedge spi_clk_i or negedge rst_spi_n) begin
        if (!rst_spi_n) begin
            instr_byte1_6_q[1] <= 8'h0;
            instr_byte1_6_q[2] <= 8'h0;
            instr_byte1_6_q[3] <= 8'h0;
            instr_byte1_6_q[4] <= 8'h0;
            instr_byte1_6_q[5] <= 8'h0;
            instr_byte1_6_q[6] <= 8'h0;
        end
        else if ((!spi_cs_i) && posedge_count[2:0] == 3'd7 ) begin
            if (posedge_count[31:3] = 29'd1) instr_byte1_6_q[1] <= {shift_in[6:0], spi_mosi_i};
            if (posedge_count[31:3] = 29'd2) instr_byte1_6_q[2] <= {shift_in[6:0], spi_mosi_i};
            if (posedge_count[31:3] = 29'd3) instr_byte1_6_q[3] <= {shift_in[6:0], spi_mosi_i};
            if (posedge_count[31:3] = 29'd4) instr_byte1_6_q[4] <= {shift_in[6:0], spi_mosi_i};
            if (posedge_count[31:3] = 29'd5) instr_byte1_6_q[5] <= {shift_in[6:0], spi_mosi_i};
            if (posedge_count[31:3] = 29'd6) instr_byte1_6_q[6] <= {shift_in[6:0], spi_mosi_i};
        end
    end

    assign instr_byte1_6_w[1] = (posedge_count[31:0] = 32'd15) ? {shift_in[6:0], spi_mosi_i} : instr_byte1_6_q[1];
    assign instr_byte1_6_w[2] = (posedge_count[31:0] = 32'd23) ? {shift_in[6:0], spi_mosi_i} : instr_byte1_6_q[2];
    assign instr_byte1_6_w[3] = (posedge_count[31:0] = 32'd31) ? {shift_in[6:0], spi_mosi_i} : instr_byte1_6_q[3];
    assign instr_byte1_6_w[4] = (posedge_count[31:0] = 32'd39) ? {shift_in[6:0], spi_mosi_i} : instr_byte1_6_q[4];
    assign instr_byte1_6_w[5] = (posedge_count[31:0] = 32'd47) ? {shift_in[6:0], spi_mosi_i} : instr_byte1_6_q[5];
    assign instr_byte1_6_w[6] = (posedge_count[31:0] = 32'd55) ? {shift_in[6:0], spi_mosi_i} : instr_byte1_6_q[6];

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

    //--------------------------------------------------------------------
    // Status Register
    //--------------------------------------------------------------------

    //Write status register (WRSR)
    initial
    begin
        sr_wip  = 0;         
        sr_wel  = 0;            
        sr_bp   = 4'b0;      
        sr_qe   = 0;         
        sr_srwd = 0;         

        forever @(posedge spi_clk_i)
        begin
            if ((!spi_cs_i) && sr_wel && instr_code_w == `WRSR) begin
                sr_wip = 1;

                if (posedge_count == 32'd15) begin
                    sr_bp[3:0] = instr_byte1_6_w[1][5:2];
                    sr_qe      = instr_byte1_6_w[1][6]  ;
                    sr_srwd    = instr_byte1_6_w[1][7]  ;

                    wait(spi_cs_i == 1'b1);
                    sr_wip = 0;
                    wr_wel = 0;
                end
            end
        end //forever
    end

    //Write Enalbe (WREN)
    always @(posedge spi_clk_i) begin
        if ((!spi_cs_i) && instr_code_w == `WREN) begin
            wr_wel = 1;
        end
    end
    
    //Write Disable (WRDI)
    always @(posedge spi_clk_i) begin
        if ((!spi_cs_i) && instr_code_w == `WRDI) begin
            wr_wel = 0;
        end
    end

    //Read Status Register (RDSR), darray_out[0]
    initial 
    begin
        darray_out[0] = 8'h0;

        forever @(posedge spi_clk_i)
        begin
            if ((!spi_cs_i) && instr_code_w == `RDSR) begin
                darray_out[0][0]   = sr_wip;
                darray_out[0][1]   = wr_wel;
                darray_out[0][5:2] = sr_bp[3:0];
                darray_out[0][6]   = sr_qe;
                darray_out[0][7]   = sr_srwd;

                wait(spi_cs_i == 1'b1);
                darray_out[0] = 8'h0;
            end
        end //forever
    end
    
    //--------------------------------------------------------------------
    // Function Register
    //--------------------------------------------------------------------
    
    //Write Function Register (WRFR)
    initial
    begin
        fr_drstd = 0;         
        fr_tbs   = 0;         
        fr_psus  = 0;         
        fr_esus  = 0;         
        fr_irl   = 4'b0;      

        forever @(posedge spi_clk_i)
        begin
            if ((!spi_cs_i) && sr_wel && instr_code_w == `WRFR) begin
                sr_wip = 1;

                if (posedge_count == 32'd15) begin //OTP
                    if (!fr_drstd)    fr_drstd  = instr_byte1_6_w[1][0]  ;
                    if (!fr_tbs)      fr_tbs    = instr_byte1_6_w[1][1]  ;
                    if (!fr_irl[0])   fr_irl[0] = instr_byte1_6_w[1][4]  ;
                    if (!fr_irl[1])   fr_irl[1] = instr_byte1_6_w[1][5]  ;
                    if (!fr_irl[2])   fr_irl[2] = instr_byte1_6_w[1][6]  ;
                    if (!fr_irl[3])   fr_irl[3] = instr_byte1_6_w[1][7]  ;

                    wait(spi_cs_i == 1'b1);
                    sr_wip = 0;
                    wr_wel = 0;
                end
            end
        end //forever
    end

    //Read Function Register (RDFR), darray_out[1]
    initial 
    begin
        darray_out[1] = 8'h0;

        forever @(posedge spi_clk_i)
        begin
            if ((!spi_cs_i) && instr_code_w == `RDFR) begin
                darray_out[1][0]   = fr_drstd;
                darray_out[1][1]   = fr_tbs;
                darray_out[1][2]   = fr_psus;
                darray_out[1][3]   = fr_esus;
                darray_out[1][7:4] = fr_irl[3:0];

                wait(spi_cs_i == 1'b1);
                darray_out[1] = 8'h0;
            end
        end //forever
    end

    //--------------------------------------------------------------------
    // Read Register
    //--------------------------------------------------------------------

    //Set Read Parameters (SRPNV, SRPV)
    initial
    begin
        rr_blen    = 2'b0;   
        rr_blen_en = 0;      
        rr_dcycles = 4'h0;      
        rr_holdrst = 0;      

        forever @(posedge spi_clk_i)
        begin
            if ((!spi_cs_i) && sr_wel && (instr_code_w == `SRPNV || instr_code_w == `SRPV)) begin
                sr_wip = 1;

                if (posedge_count == 32'd15) begin 
                    rr_blen[1:0]    = instr_byte1_6_w[1][1:0]  ;
                    rr_blen_en      = instr_byte1_6_w[1][2]  ;
                    rr_dcycles[3:0] = instr_byte1_6_w[1][6:3]  ;
                    rr_holdrst      = instr_byte1_6_w[1][7]  ;

                    wait(spi_cs_i == 1'b1);
                    sr_wip = 0;
                    wr_wel = 0;
                end
            end
        end //forever
    end

    //Read Read Parameters (RDRP),  darray_out[2]
    initial 
    begin
        darray_out[2] = 8'h0;

        forever @(posedge spi_clk_i)
        begin
            if ((!spi_cs_i) && instr_code_w == `RDRP) begin
                darray_out[2][1:0] = rr_blen[1:0];
                darray_out[2][2]   = rr_blen_en;
                darray_out[2][6:3] = rr_dcycles[3:0];
                darray_out[2][7]   = rr_holdrst;

                wait(spi_cs_i == 1'b1);
                darray_out[2] = 8'h0;
            end
        end //forever
    end

    //--------------------------------------------------------------------
    // Extended Read Parameters 
    //--------------------------------------------------------------------

    //Set Extended Read Parameters (SERPNV, SERPV)
    initial
    begin
        err_prot_e = 0;      
        err_p_err  = 0;      
        err_e_err  = 0;      
        err_dlpen  = 0;      
        err_ods = 3'b111;    

        forever @(posedge spi_clk_i)
        begin
            if ((!spi_cs_i) && sr_wel && (instr_code_w == `SERPNV || instr_code_w == `SERPV)) begin
                sr_wip = 1;

                if (posedge_count == 32'd15) begin 
                    err_dlpen    = instr_byte1_6_w[1][4]  ;
                    err_ods[2:0] = instr_byte1_6_w[1][7:5]; 

                    wait(spi_cs_i == 1'b1);
                    sr_wip = 0;
                    wr_wel = 0;
                end
            end
        end //forever
    end

    //Read Extended Read Parameters (RDERP),  darray_out[3]
    initial 
    begin
        darray_out[3] = 8'h0;

        forever @(posedge spi_clk_i)
        begin
            if ((!spi_cs_i) && instr_code_w == `RDERP) begin
                darray_out[3][1]   = err_prot_e;
                darray_out[3][2]   = err_p_err;
                darray_out[3][3]   = err_e_err;
                darray_out[3][4]   = err_dlpen;
                darray_out[3][7:5] = err_ods[2:0];

                wait(spi_cs_i == 1'b1);
                darray_out[3] = 8'h0;
            end
        end //forever
    end

    //Clear Extended Read Register (CLERP)
    always @(posedge spi_clk_i) begin
        if ((!spi_cs_i) && instr_code_w == `CLERP) begin
            err_prot_e = 0;      
            err_p_err  = 0;      
            err_e_err  = 0;      
        end
    end

    //--------------------------------------------------------------------
    // Bank Address Register 
    //--------------------------------------------------------------------

    //Write Bank Address Register (WRBRNV, WRBRV)
    initial
    begin
        bar_ba24   = 1'b0;       
        bar_ba25   = 1'b0;       
        bar_extadd = 1'b0;     

        forever @(posedge spi_clk_i)
        begin
            if ((!spi_cs_i) && sr_wel && (instr_code_w == `WRBRNV || instr_code_w == `WRBRV)) begin
                sr_wip = 1;

                if (posedge_count == 32'd15) begin
                    bar_ba24      = instr_byte1_6_w[1][0]  ;
                    bar_ba25      = instr_byte1_6_w[1][1]  ;
                    bar_extadd    = instr_byte1_6_w[1][7]  ;

                    wait(spi_cs_i == 1'b1);
                    sr_wip = 0;
                    wr_wel = 0;
                end
            end
        end //forever
    end

    //Read Bank Address Register (RDBR),  darray_out[4]
    initial 
    begin
        darray_out[4] = 8'h0;

        forever @(posedge spi_clk_i)
        begin
            if ((!spi_cs_i) && instr_code_w == `RDBR) begin
                darray_out[4][0] = bar_ba24;
                darray_out[4][1] = bar_ba25;
                darray_out[4][7] = bar_extadd;

                wait(spi_cs_i == 1'b1);
                darray_out[4] = 8'h0;
            end
        end //forever
    end

    //Enter 4-byte Address Mode (EN4B)
    always @(posedge spi_clk_i) begin
        if ((!spi_cs_i) && instr_code_w == `EN4B) begin
            bar_extadd = 1'b1;
        end
    end

    //Exit 4-byte Address Mode (EX4B)
    always @(posedge spi_clk_i) begin
        if ((!spi_cs_i) && instr_code_w == `EX4B) begin
            bar_extadd = 1'b0;
        end
    end






endmodule
