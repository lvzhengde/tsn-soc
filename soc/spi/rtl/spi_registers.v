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
 *  Description : SPI control and status registers
 *  File        : spi_registers.v
-*/

`include "spi_defines.v"

module spi_registers 
(
    //32 bits IPBus interface
    input               bus2ip_clk     ,         //clock 
    input               bus2ip_rst_n   ,         //active low reset
    input  [31:0]       bus2ip_addr_i  ,
    input  [31:0]       bus2ip_data_i  ,
    input  [ 3:0]       bus2ip_wstrb_i ,     
    input               bus2ip_rd_ce_i ,         //active high
    input               bus2ip_wr_ce_i ,         //active high
    output [31:0]       ip2bus_data_o  , 
    output              ip2bus_ready_o ,

    //SPI control and status registers
    output              sw_reset_o     ,         //software reset output

    output              spi_cr_loop_o  ,         //SPI loop back
    output              spi_cr_spe_o   ,         //SPI system enable
    output              spi_cr_master_o,         //SPI master mode
    output              spi_cr_cpol_o  ,         //SPI clock polarity
    output              spi_cr_cpha_o  ,         //SPI clock phase
    output              spi_cr_txfifo_rst_o,     //Transmit FIFO reset
    output              spi_cr_rxfifo_rst_o,     //Receive FIFO reset
    output              spi_cr_trans_inhibit_o,  //Master transaction inhibit 
    output              spi_cr_lsb_first_o    ,  //LSB first

    output              spi_ssr_value_o,          //SPI manual slave select
    output              spi_dtr_wr_o   ,          //Transmit FIFO write enable 
    output [ 7:0]       spi_dtr_data_o ,          //Transmit FIFO write data 
    output              spi_drr_rd_o   ,          //Receive FIFO read enable
    input  [ 7:0]       spi_drr_data_i ,          //Receive FIFO read data 

    output [15:0]       spi_ecr_sck_ratio_o     , // clk/sclk ratio
    output [ 7:0]       spi_ecr_xip_read_code_o , // XIP read instruction code
    output              spi_ecr_extadd_o        , // 0: 3-byte address; 1: 4-byte address
    output              spi_ecr_dummy_cycles_o  , // 0: no dummy cycles; 1: add 8-bit dummy cycles

    input               tx_full_i          ,
    input               tx_empty_i         ,
    input               rx_full_i          ,
    input               rx_empty_i         ,
    input               txfifo_empty_int_i ,      //SPI TX FIFO empty, one cycle pulse
    input               rxfifo_full_int_i  ,      //SPI RX FIFO full, one cycle pulse

    output              intr_o                    //Interrupt request output
);

    wire  blk_sel_w  = ((bus2ip_addr_i & `SPI_ADDR_MASK) == `SPI_REG_BASEADDR);
    wire  write_en_w = bus2ip_wr_ce_i & ip2bus_ready_o;
    wire  read_en_w  = bus2ip_rd_ce_i & ip2bus_ready_o;

    //-----------------------------------------------------------------
    // Software Reset Register SPI_SRR
    //-----------------------------------------------------------------
    wire srr_sel_w = (bus2ip_addr_i[7:0] == `SPI_SRR) & blk_sel_w;
    reg  [31:0]  srr_reset_q;

    // auto clear after write operation
    always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n)
            srr_reset_q <= 32'd0;
        else if (write_en_w && srr_sel_w) begin
           if (bus2ip_wstrb_i[0]) srr_reset_q[ 7: 0] <= bus2ip_data_i[ 7: 0];
           if (bus2ip_wstrb_i[1]) srr_reset_q[15: 8] <= bus2ip_data_i[15: 8];
           if (bus2ip_wstrb_i[2]) srr_reset_q[23:16] <= bus2ip_data_i[23:16];
           if (bus2ip_wstrb_i[3]) srr_reset_q[31:24] <= bus2ip_data_i[31:24];
        end
        else
            srr_reset_q <= 32'd0;
    end 

    assign sw_reset_o = (srr_reset_q == 32'h0000_000a);


    //-----------------------------------------------------------------
    // SPI Control Register SPI_CR
    //-----------------------------------------------------------------
    wire cr_sel_w = (bus2ip_addr_i[7:0] == `SPI_CR) & blk_sel_w;

    //SPI cr_loop
    reg  cr_loop_q;

    always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n)
            cr_loop_q <= 1'b0;
        else if (write_en_w && cr_sel_w & bus2ip_wstrb_i[0]) 
            cr_loop_q <= bus2ip_data_i[0];
    end 

    assign spi_cr_loop_o = cr_loop_q;

    //SPI System Enable cr_spe
    reg  cr_spe_q;

    always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n)
            cr_spe_q <= 1'b1;
        else if (write_en_w && cr_sel_w & bus2ip_wstrb_i[0]) 
            cr_spe_q <= bus2ip_data_i[1];
    end 

    assign spi_cr_spe_o = cr_spe_q;

    //SPI master mode cr_master (only master supported)
    reg  cr_master_q;

    always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n)
            cr_master_q <= 1'b1;
        else if (write_en_w && cr_sel_w & bus2ip_wstrb_i[0]) 
            cr_master_q <= bus2ip_data_i[2];
    end 

    assign spi_cr_master_o = cr_master_q;

    //Clock polarity cr_cpol
    reg  cr_cpol_q;

    always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n)
            cr_cpol_q <= 1'b0;
        else if (write_en_w && cr_sel_w & bus2ip_wstrb_i[0]) 
            cr_cpol_q <= bus2ip_data_i[3];
    end 

    assign spi_cr_cpol_o = cr_cpol_q;

    //Clock phase cr_cpha
    reg  cr_cpha_q;

    always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n)
            cr_cpha_q <= 1'b0;
        else if (write_en_w && cr_sel_w & bus2ip_wstrb_i[0]) 
            cr_cpha_q <= bus2ip_data_i[4];
    end 

    assign spi_cr_cpha_o = cr_cpha_q;

    //Transmit FIFO reset cr_txfifo_rst
    reg  cr_txfifo_rst_q;

    //Auto clear after write
    always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n)
            cr_txfifo_rst_q <= 1'b0;
        else if (write_en_w && cr_sel_w & bus2ip_wstrb_i[0]) 
            cr_txfifo_rst_q <= bus2ip_data_i[5];
        else
            cr_txfifo_rst_q <= 1'b0;
    end 

    assign spi_cr_txfifo_rst_o = cr_txfifo_rst_q;

    //Receive FIFO reset cr_rxfifo_rst
    reg  cr_rxfifo_rst_q;

    //Auto clear after write
    always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n)
            cr_rxfifo_rst_q <= 1'b0;
        else if (write_en_w && cr_sel_w & bus2ip_wstrb_i[0]) 
            cr_rxfifo_rst_q <= bus2ip_data_i[6];
        else
            cr_rxfifo_rst_q <= 1'b0;
    end 

    assign spi_cr_rxfifo_rst_o = cr_rxfifo_rst_q;

    //Manual Slave Select Assertion Enable cr_manual_ss (not used)
    reg  cr_manual_ss_q;

    always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n)
            cr_manual_ss_q <= 1'b0;
        else if (write_en_w && cr_sel_w & bus2ip_wstrb_i[0]) 
            cr_manual_ss_q <= bus2ip_data_i[7];
    end 


    //Master Transaction Inhibit cr_trans_inhibit
    reg  cr_trans_inhibit_q;

    always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n)
            cr_trans_inhibit_q <= 1'b1;
        else if (write_en_w && cr_sel_w & bus2ip_wstrb_i[1]) 
            cr_trans_inhibit_q <= bus2ip_data_i[8];
    end 

    assign spi_cr_trans_inhibit_o = cr_trans_inhibit_q;

    //LSB First
    reg  cr_lsb_first_q;

    always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n)
            cr_lsb_first_q <= 1'b0;
        else if (write_en_w && cr_sel_w & bus2ip_wstrb_i[1]) 
            cr_lsb_first_q <= bus2ip_data_i[9];
    end 

    assign spi_cr_lsb_first_o = cr_lsb_first_q;


    //-----------------------------------------------------------------
    // SPI Data Transmit Register spi_dtr
    //-----------------------------------------------------------------
    wire dtr_sel_w = (bus2ip_addr_i[7:0] == `SPI_DTR) & blk_sel_w;

    reg         spi_dtr_wr_q;
    reg  [ 7:0] spi_dtr_data_q;

    always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n) begin
            spi_dtr_wr_q   <= 1'b0;
            spi_dtr_data_q <= 7'h0;
        end
        else if (write_en_w && dtr_sel_w & bus2ip_wstrb_i[0]) begin 
            spi_dtr_wr_q   <= 1'b1;
            spi_dtr_data_q <= bus2ip_data_i[ 7:0];
        end
        else begin
            spi_dtr_wr_q   <= 1'b0;
            spi_dtr_data_q <= 7'h0;
        end
    end 

    assign spi_dtr_wr_o   = spi_dtr_wr_q  ;
    assign spi_dtr_data_o = spi_dtr_data_q;

    //-----------------------------------------------------------------
    // SPI Slave Select Register spi_ssr
    //-----------------------------------------------------------------
    wire ssr_sel_w = (bus2ip_addr_i[7:0] == `SPI_SSR) & blk_sel_w;

    reg  ssr_value_q;

    always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n)
            ssr_value_q <= 1'b1;
        else if (write_en_w && ssr_sel_w & bus2ip_wstrb_i[0]) 
            ssr_value_q <= bus2ip_data_i[0];
    end 

    assign  spi_ssr_value_o = ssr_value_q;

    //-----------------------------------------------------------------
    // SPI Extended Control Register SPI_ECR
    //-----------------------------------------------------------------
    wire ecr_sel_w = (bus2ip_addr_i[7:0] == `SPI_ECR) & blk_sel_w;

    reg  [15:0] ecr_sck_ratio_q;
    reg  [ 7:0] ecr_xip_read_code_q;
    reg         ecr_extadd_q;
    reg         ecr_dummy_cycles_q;

    always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n) begin
            ecr_sck_ratio_q     <= `SCK_RATIO_DEFAULT;
            ecr_xip_read_code_q <= `XIP_READ_CODE_DEFAULT ;
            ecr_extadd_q        <= 1'b0 ;
            ecr_dummy_cycles_q  <= 1'b0 ;
        end
        else if (write_en_w && ecr_sel_w ) begin 
            if (bus2ip_wstrb_i[0]) ecr_sck_ratio_q[ 7: 0]   <= bus2ip_data_i[ 7: 0];
            if (bus2ip_wstrb_i[1]) ecr_sck_ratio_q[15: 8]   <= bus2ip_data_i[15: 8];
            if (bus2ip_wstrb_i[2]) ecr_xip_read_code_q[7:0] <= bus2ip_data_i[23:16];

            if (bus2ip_wstrb_i[3]) begin
                ecr_extadd_q        <=  bus2ip_data_i[24];
                ecr_dummy_cycles_q  <=  bus2ip_data_i[25];
            end
        end
    end 

    assign spi_ecr_sck_ratio_o     = ecr_sck_ratio_q    ;
    assign spi_ecr_xip_read_code_o = ecr_xip_read_code_q;
    assign spi_ecr_extadd_o        = ecr_extadd_q       ;
    assign spi_ecr_dummy_cycles_o  = ecr_dummy_cycles_q ;

    //-----------------------------------------------------------------
    // SPI Device Global Interrupt Enable Register SPI_DGIER
    //-----------------------------------------------------------------
    wire dgier_sel_w = (bus2ip_addr_i[7:0] == `SPI_DGIER) & blk_sel_w;

    reg  dgier_gie_q;

    always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n)
            dgier_gie_q <= 1'b0;
        else if (write_en_w && dgier_sel_w & bus2ip_wstrb_i[3]) 
            dgier_gie_q <= bus2ip_data_i[31];
    end 

    //-----------------------------------------------------------------
    // SPI Interrupt Status Register SPI_IPISR (read/write 1 clear)
    //-----------------------------------------------------------------
    wire ipisr_sel_w = (bus2ip_addr_i[7:0] == `SPI_IPISR) & blk_sel_w;

    reg  ipisr_tx_empty_q;
    reg  ipisr_rx_full_q ;

    always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n) begin
            ipisr_tx_empty_q <= 1'b0;
            ipisr_rx_full_q  <= 1'b0;
        end
        else if (write_en_w && ipisr_sel_w && bus2ip_wstrb_i[0]) begin //write 1 clear
            if (bus2ip_data_i[2])   ipisr_tx_empty_q <= 1'b0;
            if (bus2ip_data_i[4])   ipisr_rx_full_q  <= 1'b0;
        end
        else begin
            if (txfifo_empty_int_i) ipisr_tx_empty_q <= 1'b1;
            if (rxfifo_full_int_i ) ipisr_rx_full_q  <= 1'b1;
        end
    end 

    //-----------------------------------------------------------------
    // SPI Interrupt Enable Register SPI_IPIER (read/write 1 clear)
    //-----------------------------------------------------------------
    wire ipier_sel_w = (bus2ip_addr_i[7:0] == `SPI_IPIER) & blk_sel_w;

    reg  ipier_tx_empty_q;
    reg  ipier_rx_full_q ;

    always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n) begin
            ipier_tx_empty_q <= 1'b0;
            ipier_rx_full_q  <= 1'b0;
        end
        else if (write_en_w && ipier_sel_w && bus2ip_wstrb_i[0]) begin //write 1 clear
            ipier_tx_empty_q <= bus2ip_data_i[2];
            ipier_rx_full_q  <= bus2ip_data_i[4];
        end
    end 

    // Interrupt request output
    assign intr_o = dgier_gie_q & ((ipier_tx_empty_q & ipisr_tx_empty_q) | (ipier_rx_full_q & ipisr_rx_full_q));

    //-----------------------------------------------------------------
    // IPBus Read mux
    //-----------------------------------------------------------------
    reg  [31:0] data_r;
    
    always @(*) begin
        data_r = 32'b0;

        if (blk_sel_w) begin
            case (bus2ip_addr_i[7:0])
                `SPI_DGIER:
                    data_r = {dgier_gie_q, 31'b0};
                `SPI_IPISR:
                    data_r = {27'b0, ipisr_rx_full_q, 1'b0, ipisr_tx_empty_q, 2'b0};
                `SPI_IPIER:
                    data_r = {27'b0, ipier_rx_full_q, 1'b0, ipier_tx_empty_q, 2'b0};
                `SPI_SRR:
                    ;
                `SPI_CR:
                    data_r = {22'b0, cr_lsb_first_q, cr_trans_inhibit_q, cr_manual_ss_q, 2'b0, cr_cpha_q, cr_cpol_q, cr_master_q, cr_spe_q, cr_loop_q};
                `SPI_SR:
                    data_r = {28'b0, tx_full_i, tx_empty_i, rx_full_i, rx_empty_i};
                `SPI_DRR:
                    data_r = {20'b0, tx_full_i, tx_empty_i, rx_full_i, rx_empty_i, spi_drr_data_i[7:0]};  //mixed with status info
                `SPI_SSR:
                    data_r = {31'b0, ssr_value_q};
                `SPI_ECR:
                    data_r = {6'b0, ecr_dummy_cycles_q, ecr_extadd_q, ecr_xip_read_code_q[7:0], ecr_sck_ratio_q[15:0]};
                default :
                    data_r = 32'b0;
            endcase
        end //if
    end //always

    assign spi_drr_rd_o = read_en_w & (bus2ip_addr_i[7:0] == `SPI_DRR) & blk_sel_w;

    //-----------------------------------------------------------------
    // Retime response
    //-----------------------------------------------------------------
    reg [31:0] rd_data_q;
    reg        ip2bus_ready_q;
    
    always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n) 
            rd_data_q <= 32'b0;
        else 
            rd_data_q <= data_r;
    end

    always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n) 
            ip2bus_ready_q <= 1'b0;
        else if (ip2bus_ready_o & (bus2ip_rd_ce_i | bus2ip_wr_ce_i))
            ip2bus_ready_q <= 1'b0;
        else if (bus2ip_rd_ce_i | bus2ip_wr_ce_i)
            ip2bus_ready_q <= 1'b1;
    end

    assign ip2bus_data_o  = rd_data_q;
    assign ip2bus_ready_o = ip2bus_ready_q;

endmodule
