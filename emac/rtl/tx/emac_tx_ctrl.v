/*+
 * Copyright (c) 2022-2023 Zhengde
 *
 * Copyright (c) 2001 Jon Gao (gaojon@yahoo.com) 
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
 * EMAC transmit control 
-*/

module emac_tx_ctrl (  
    input               rst_n               ,
    input               clk                 ,
    input               xmt_en_i            , //transmit enable
    //CRC generator Interface 
    output reg          crc_init_o          ,
    output [7:0]        frame_data_o        ,
    output              data_en_o           ,
    output reg          crc_rd_o            ,
    input               crc_end_i           ,
    input  [7:0]        crc_out_i           ,
    //random generator interface
    output reg          random_init_o         ,
    output reg [3:0]    retry_cnt_o            ,
    input               random_time_meet_i    ,//levle hight indicate random time passed away
    //flow control
    input               pause_apply_i         ,
    output reg          pause_quanta_sub_o    ,
    input               xoff_gen_i            ,
    output reg          xoff_gen_complete_o   ,
    input               xon_gen_i             ,
    output reg          xon_gen_complete_o    ,               
    //MAC TX FIFO interface
    input  [7:0]        fifo_data_i           ,
    output reg          fifo_rd_o             ,
    input               fifo_eop_i            ,
    input               fifo_da_i             ,
    output reg          fifo_rd_finish_o      ,
    output reg          fifo_rd_retry_o       ,
    input               fifo_ra_i             ,
    input               fifo_data_err_empty_i ,
    input               fifo_data_err_full_i  ,
    //GMII/MII
    output reg[7:0]     TxD_o               ,
    output reg          TxEn_o              ,   
    output reg          TxErr_o             ,
    input               CRS_i               ,  //carrier sense
    input               COL_i               ,  //collision
    //RMON
    output reg [2:0]    tx_pkt_type_rmon_o    ,
    output reg [15:0]   tx_pkt_length_rmon_o  ,
    output reg          tx_apply_rmon_o       ,
    output reg [2:0]    tx_pkt_err_type_rmon_o,   
    //Host interface
    input               r_pause_frame_send_en_i ,               
    input  [15:0]       r_pause_quanta_set_i    ,
    input               r_txMacAddr_en_i       ,               
    input   [47:0]      r_txMacAddr_i          , 
    input               r_FullDuplex_i          ,
    input  [3:0]        r_MaxRetry_i            ,
    input  [5:0]        r_IFGSet_i              
);
    //++
    //parameters defined for state machine
    //--
    parameter       StateIdle           =4'd00;
    parameter       StatePreamble       =4'd01;
    parameter       StateSFD            =4'd02;
    parameter       StateData           =4'd03;
    parameter       StatePause          =4'd04;
    parameter       StatePAD            =4'd05;
    parameter       StateFCS            =4'd06;
    parameter       StateIFG            =4'd07;
    parameter       StateJam            =4'd08;
    parameter       StateBackOff        =4'd09;
    parameter       StateJamDrop        =4'd10;
    parameter       StateFFEmptyDrop    =4'd11;
    parameter       StateSwitchNext     =4'd12;
    parameter       StateDefer          =4'd13;
    parameter       StateSendPauseFrame =4'd14;

    //internal signals                                                              
    reg [3:0]       Current_state   /*synthesis syn_keep=1 */;
    reg [3:0]       Next_state;
    reg [5:0]       IFG_counter;
    reg [4:0]       Preamble_counter;//
    reg [7:0]       TxD_tmp             ;   
    reg             TxEn_tmp            ;   
    reg             Tx_apply_rmon_tmp   ;
    reg             Tx_apply_rmon_tmp_pl1;
    reg             MAC_header_slot     ;
    reg             MAC_header_slot_tmp ;
    wire            Collision           ; 
    reg             Src_MAC_ptr         ;
    reg [7:0]       IPLengthCounter     ;//for pad append
    reg [1:0]       PADCounter          ;
    reg [7:0]       JamCounter          ;
    reg             PktDrpEvenPtr       ;
    reg [7:0]       pause_counter       ;

    //++
    //boundery signal processing, synchronization between clock domains                                                             
    //--

    always @(posedge clk or negedge rst_n)
        if (!rst_n)
            begin  
            end
        else
            begin  
            end     
//******************************************************************************    
//state machine                                                             
//****************************************************************************** 
assign Collision=TxEn&CRS_i;

always @(posedge clk or negedge rst_n)
    if (!rst_n)
        pause_counter   <=0;
    else if (Current_state!=StatePause)
        pause_counter   <=0;
    else 
        pause_counter   <=pause_counter+1;
        
always @(posedge clk or negedge rst_n)
    if (!rst_n)
        IPLengthCounter     <=0;
    else if (Current_state==StateDefer)
        IPLengthCounter     <=0;    
    else if (IPLengthCounter!=8'hff&&(Current_state==StateData||Current_state==StateSendPauseFrame||Current_state==StatePAD))
        IPLengthCounter     <=IPLengthCounter+1;

always @(posedge clk or negedge rst_n)
    if (!rst_n)
        PADCounter      <=0;
    else if (Current_state!=StatePAD)
        PADCounter      <=0;
    else
        PADCounter      <=PADCounter+1;

always @(posedge clk or negedge rst_n)
    if (!rst_n)
        Current_state       <=StateDefer;
    else 
        Current_state       <=Next_state;    
        
always @ (*)
        case (Current_state)   
            StateDefer:
                if ((r_FullDuplex_i)||(!r_FullDuplex_i&&!CRS_i))
                    Next_state=StateIFG;
                else
                    Next_state=Current_state;   
            StateIFG:
                if (!r_FullDuplex_i&&CRS_i)
                    Next_state=StateDefer;
                else if ((r_FullDuplex_i&&IFG_counter==r_IFGSet_i-4)||(!r_FullDuplex_i&&!CRS_i&&IFG_counter==r_IFGSet_i-4))//remove some additional time
                    Next_state=StateIdle;
                else
                    Next_state=Current_state;           
            StateIdle:
                if (!r_FullDuplex_i&&CRS_i)
                    Next_state=StateDefer;
                else if (pause_apply_i)
                    Next_state=StatePause;          
                else if ((r_FullDuplex_i&&fifo_ra_i)||(!r_FullDuplex_i&&!CRS_i&&fifo_ra_i)||(r_pause_frame_send_en_i&&(xoff_gen_i||xon_gen_i)))
                    Next_state=StatePreamble;
                else
                    Next_state=Current_state;   
            StatePause:
                if (pause_counter==512/8)
                    Next_state=StateDefer;
                else
                    Next_state=Current_state;               
            StatePreamble:
                if (!r_FullDuplex_i&&Collision)
                    Next_state=StateJam;
                else if ((r_FullDuplex_i&&Preamble_counter==6)||(!r_FullDuplex_i&&!Collision&&Preamble_counter==6))
                    Next_state=StateSFD;
                else
                    Next_state=Current_state;
            StateSFD:
                if (!r_FullDuplex_i&&Collision)
                    Next_state=StateJam;
                else if (r_pause_frame_send_en_i&&(xoff_gen_i||xon_gen_i))
                    Next_state=StateSendPauseFrame;
                else 
                    Next_state=StateData;
            StateSendPauseFrame:
                if (IPLengthCounter==17)
                    Next_state=StatePAD;
                else
                    Next_state=Current_state;
            StateData:
                if (!r_FullDuplex_i&&Collision)
                    Next_state=StateJam;
                else if (fifo_data_err_empty_i)
                    Next_state=StateFFEmptyDrop;                
                else if (fifo_eop_i&&IPLengthCounter>=59)//IP+MAC+TYPE=60 ,start from 0
                    Next_state=StateFCS;
                else if (fifo_eop_i)
                    Next_state=StatePAD;
                else 
                    Next_state=StateData;       
            StatePAD:
                if (!r_FullDuplex_i&&Collision)
                    Next_state=StateJam; 
                else if (IPLengthCounter>=59)
                    Next_state=StateFCS;        
                else 
                    Next_state=Current_state;
            StateJam:
                if (retry_cnt_o<=r_MaxRetry_i&&JamCounter==16) 
                    Next_state=StateBackOff;
                else if (retry_cnt_o>r_MaxRetry_i)
                    Next_state=StateJamDrop;
                else
                    Next_state=Current_state;
            StateBackOff:
                if (random_time_meet_i)
                    Next_state  =StateDefer;
                else 
                    Next_state  =Current_state;
            StateFCS:
                if (!r_FullDuplex_i&&Collision)
                    Next_state  =StateJam;
                else if (crc_end_i)
                    Next_state  =StateSwitchNext;
                else
                    Next_state  =Current_state;
            StateFFEmptyDrop:
                if (fifo_eop_i)
                    Next_state  =StateSwitchNext;
                else
                    Next_state  =Current_state;             
            StateJamDrop:
                if (fifo_eop_i)
                    Next_state  =StateSwitchNext;
                else
                    Next_state  =Current_state;
            StateSwitchNext:
                    Next_state  =StateDefer;            
            default:
                Next_state  =StateDefer;
        endcase

 
        
always @ (posedge clk or negedge rst_n)
    if (!rst_n)
        JamCounter      <=0;
    else if (Current_state!=StateJam)
        JamCounter      <=0;
    else if (Current_state==StateJam)
        JamCounter      <=JamCounter+1;
        
             
always @ (posedge clk or negedge rst_n)
    if (!rst_n)
        retry_cnt_o        <=0;
    else if (Current_state==StateSwitchNext)
        retry_cnt_o        <=0;
    else if (Current_state==StateJam&&Next_state==StateBackOff)
        retry_cnt_o        <=retry_cnt_o + 1;
            
always @ (posedge clk or negedge rst_n)
    if (!rst_n)
        IFG_counter     <=0;
    else if (Current_state!=StateIFG)
        IFG_counter     <=0;
    else 
        IFG_counter     <=IFG_counter + 1;

always @ (posedge clk or negedge rst_n)
    if (!rst_n)
        Preamble_counter    <=0;
    else if (Current_state!=StatePreamble)
        Preamble_counter    <=0;
    else
        Preamble_counter    <=Preamble_counter+ 1;
        
always @ (posedge clk or negedge rst_n)
    if (!rst_n)      
        PktDrpEvenPtr       <=0;
    else if(Current_state==StateJamDrop||Current_state==StateFFEmptyDrop)
        PktDrpEvenPtr       <=~PktDrpEvenPtr;
//******************************************************************************    
//generate output signals                                                           
//****************************************************************************** 
//CRC related
always @(Current_state)
    if (Current_state==StateSFD)
        crc_init_o    =1;
    else
        crc_init_o    =0;
        
assign frame_data_o=TxD_tmp;

always @(Current_state)
    if (Current_state==StateData||Current_state==StateSendPauseFrame||Current_state==StatePAD)
        data_en_o     =1;
    else
        data_en_o     =0;
        
always @(Current_state)
    if (Current_state==StateFCS)
        crc_rd_o      =1;
    else
        crc_rd_o      =0;     
    
//random_gen interface
always @(Current_state or Next_state)
    if (Current_state==StateJam&&Next_state==StateBackOff)
        random_init_o =1;
    else
        random_init_o =0; 

//MAC_rx_FF
//data have one cycle delay after fifo read signals  
always @ (*)
    if (Current_state==StateData ||
        Current_state==StateSFD&&!(r_pause_frame_send_en_i&&(xoff_gen_i||xon_gen_i))  ||
        Current_state==StateJamDrop&&PktDrpEvenPtr||
        Current_state==StateFFEmptyDrop&&PktDrpEvenPtr )
        fifo_rd_o     =1;
    else
        fifo_rd_o     =0; 
        
always @ (Current_state)
    if (Current_state==StateSwitchNext)     
        fifo_rd_finish_o  =1;
    else
        fifo_rd_finish_o  =0;
        
always @ (Current_state)
    if (Current_state==StateJam)        
        fifo_rd_retry_o   =1;
    else
        fifo_rd_retry_o   =0;     
//RMII
always @(Current_state)
    if (Current_state==StatePreamble||Current_state==StateSFD||
        Current_state==StateData||Current_state==StateSendPauseFrame||
        Current_state==StateFCS||Current_state==StatePAD||Current_state==StateJam)
        TxEn_tmp    =1;
    else
        TxEn_tmp    =0;

//gen txd data      
always @(*)
    case (Current_state)
        StatePreamble:
            TxD_tmp =8'h55;
        StateSFD:
            TxD_tmp =8'hd5;
        StateData:
            if (Src_MAC_ptr&&r_txMacAddr_en_i)       
                TxD_tmp =MAC_tx_addr_data;
            else
                TxD_tmp =fifo_data_i;
        StateSendPauseFrame:
            if (Src_MAC_ptr&&r_txMacAddr_en_i)       
                TxD_tmp =MAC_tx_addr_data;
            else 
                case (IPLengthCounter)
                    7'd0:   TxD_tmp =8'h01;
                    7'd1:   TxD_tmp =8'h80;
                    7'd2:   TxD_tmp =8'hc2;
                    7'd3:   TxD_tmp =8'h00;
                    7'd4:   TxD_tmp =8'h00;
                    7'd5:   TxD_tmp =8'h01;
                    7'd12:  TxD_tmp =8'h88;//type
                    7'd13:  TxD_tmp =8'h08;//
                    7'd14:  TxD_tmp =8'h00;//opcode
                    7'd15:  TxD_tmp =8'h01;
                    7'd16:  TxD_tmp =xon_gen?8'b0:r_pause_quanta_set_i[15:8];
                    7'd17:  TxD_tmp =xon_gen?8'b0:r_pause_quanta_set_i[7:0];
//                    7'd60:  TxD_tmp =8'h26;
//                    7'd61:  TxD_tmp =8'h6b;
//                    7'd62:  TxD_tmp =8'hae;
//                    7'd63:  TxD_tmp =8'h0a;
                    default:TxD_tmp =0;
                endcase
        
        StatePAD:
                TxD_tmp =8'h00; 
        StateJam:
                TxD_tmp =8'h01; //jam sequence
        StateFCS:
            TxD_tmp =crc_out_i;
        default:
            TxD_tmp =2'b0;
    endcase
always @ (posedge clk or negedge rst_n)
    if (!rst_n)
        begin
        TxD_o     <=0;
        TxEn_o    <=0;
        TxErr_o   <=0;
        end
    else
        begin
        TxD_o     <=TxD_tmp;
        TxEn_o    <=TxEn_tmp;
        TxErr_o   <= 0;
        end     
//RMON


always @ (posedge clk or negedge rst_n)
    if (!rst_n)
        tx_pkt_length_rmon_o      <=0;
    else if (Current_state==StateSFD)
        tx_pkt_length_rmon_o      <=0;
    else if (Current_state==StateData||Current_state==StateSendPauseFrame||Current_state==StatePAD||Current_state==StateFCS)
        tx_pkt_length_rmon_o      <=tx_pkt_length_rmon_o+1;
        
always @ (posedge clk or negedge rst_n)
    if (!rst_n)
        Tx_apply_rmon_tmp       <=0;
    else if ((fifo_eop_i&&Current_state==StateJamDrop)||
             (fifo_eop_i&&Current_state==StateFFEmptyDrop)||
             crc_end_i)
        Tx_apply_rmon_tmp       <=1;
    else
        Tx_apply_rmon_tmp       <=0; 

always @ (posedge clk or negedge rst_n)
    if (!rst_n)
        Tx_apply_rmon_tmp_pl1   <=0;
    else
        Tx_apply_rmon_tmp_pl1   <=Tx_apply_rmon_tmp;
        
always @ (posedge clk or negedge rst_n)
    if (!rst_n)
        tx_apply_rmon_o       <=0;
    else if ((fifo_eop_i&&Current_state==StateJamDrop)||
             (fifo_eop_i&&Current_state==StateFFEmptyDrop)||
             crc_end_i)
        tx_apply_rmon_o       <=1;
    else if (Tx_apply_rmon_tmp_pl1)
        tx_apply_rmon_o       <=0;
        
always @ (posedge clk or negedge rst_n)
    if (!rst_n)
        tx_pkt_err_type_rmon_o    <=0;    
    else if(fifo_eop_i&&Current_state==StateJamDrop)
        tx_pkt_err_type_rmon_o    <=3'b001;//
    else if(fifo_eop_i&&Current_state==StateFFEmptyDrop)
        tx_pkt_err_type_rmon_o    <=3'b010;//underflow
    else if(fifo_eop_i&&fifo_data_err_full_i)
        tx_pkt_err_type_rmon_o    <=3'b011;//overflow
    else if(crc_end_i)
        tx_pkt_err_type_rmon_o    <=3'b100;//normal
        
always @ (posedge clk or negedge rst_n)
    if (!rst_n)
        MAC_header_slot_tmp <=0;
    else if(Current_state==StateSFD&&Next_state==StateData)
        MAC_header_slot_tmp <=1;    
    else
        MAC_header_slot_tmp <=0;
        
always @ (posedge clk or negedge rst_n)
    if (!rst_n)
        MAC_header_slot     <=0;
    else 
        MAC_header_slot     <=MAC_header_slot_tmp;

always @ (posedge clk or negedge rst_n)
    if (!rst_n)
        tx_pkt_type_rmon_o    <=0;
    else if (Current_state==StateSendPauseFrame)
        tx_pkt_type_rmon_o    <=3'b100;
    else if(MAC_header_slot)
        tx_pkt_type_rmon_o    <={1'b0,TxD_o[7:6]};

       
always @(tx_pkt_length_rmon_o)
    if (tx_pkt_length_rmon_o>=6&&tx_pkt_length_rmon_o<=11)
        Src_MAC_ptr         =1;
    else
        Src_MAC_ptr         =0;        

//MAC_tx_addr_add  
always @ (posedge clk or negedge rst_n)
    if (!rst_n)
        MAC_tx_addr_rd  <=0;
    else if ((tx_pkt_length_rmon_o>=4&&tx_pkt_length_rmon_o<=9)&&(r_txMacAddr_en_i||Current_state==StateSendPauseFrame))
        MAC_tx_addr_rd  <=1;
    else
        MAC_tx_addr_rd  <=0;

always @ (tx_pkt_length_rmon_o or fifo_rd_o)
    if ((tx_pkt_length_rmon_o==3)&&fifo_rd_o)
        MAC_tx_addr_init=1;
    else
        MAC_tx_addr_init=0;

//flow control
always @ (posedge clk or negedge rst_n)
    if (!rst_n)
        pause_quanta_sub_o    <=0;
    else if(pause_counter==512/8)
        pause_quanta_sub_o    <=1;
    else
        pause_quanta_sub_o    <=0;

 
always @ (posedge clk or negedge rst_n)
    if (!rst_n) 
        xoff_gen_complete_o   <=0;
    else if(Current_state==StateDefer&&xoff_gen)
        xoff_gen_complete_o   <=1;
    else
        xoff_gen_complete_o   <=0;
    
    
always @ (posedge clk or negedge rst_n)
    if (!rst_n) 
        xon_gen_complete_o    <=0;
    else if(Current_state==StateDefer&&xon_gen_i)
        xon_gen_complete_o    <=1;
    else
        xon_gen_complete_o    <=0;

endmodule

