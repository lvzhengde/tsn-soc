/*+
 * Copyright (c) 2022-2025 Zhengde
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
 * Description : QBV Top Module
 *               Instantiates qbv_registers, qbv_stsm, and qbv_control_list.
 *               Connects admin ports of qbv_control_list to qbv_registers,
 *               and oper ports to qbv_stsm. 
 * File        : qbv_top.v
-*/

module qbv_top
#(
    parameter ADDR_WIDTH = 9,
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 512
)
(
    // Register (admin) clock domain
    input                   bus2ip_clk,
    input                   bus2ip_rst_n,
    input  [31:0]           bus2ip_addr_i,
    input  [31:0]           bus2ip_data_i,
    input  [3:0]            bus2ip_wstrb_i,
    input                   bus2ip_rd_ce_i,
    input                   bus2ip_wr_ce_i,
    output [31:0]           ip2bus_data_o,
    output                  ip2bus_ready_o,

    input  [ 7:0]           BEOverrunCount_i, // BE TX Overrun Count
    input  [ 7:0]           RSOverrunCount_i, // RES TX Overrun Count
    input  [ 7:0]           STOverrunCount_i, // ST TX Overrun Count
    input                   st_oco_i, // ST TX Overrun Count overflow
    input                   rt_oco_i, // RES TX Overrun Count overflow
    input                   bt_oco_i, // BE TX Overrun Count overflow

    // STSM (oper) clock domain
    input                   oper_clk,
    input                   oper_rst_n,
    input   [79:0]          CurrentTime_i,

    // Outputs from STSM
    output  [2:0]           OperGateStates_o,
    output  [19:0]          ExitTimer_o
);
    // Wires between modules
    wire [ 8:0]           OperControlListLength_w;  
    wire [ 2:0]           OperGateStates_w;         
    wire                  OperControlListPopulated_w; 
    wire                  ConfigPending_w; 
    wire [79:0]           ConfigChangeTime_w; 
    wire [31:0]           OperCycleTime_w;
    wire [31:0]           OperCycleTimeExtension_w;
    wire [79:0]           OperBaseTime_w; 

    wire                  GateEnabled_w;            
    wire                  ConfigChange_w;           
    wire [ 8:0]           AdminControlListLength_w; 
    wire [ 2:0]           AdminGateStates_w;        
    wire [31:0]           AdminCycleTime_w;
    wire [31:0]           AdminCycleTimeExtension_w;
    wire [79:0]           AdminBaseTime_w; 

    wire [ 8:0]           reg_admin_addr_w;
    wire [31:0]           reg_admin_wdata_w;
    wire [ 3:0]           reg_admin_wr_w;
    wire [31:0]           reg_admin_rdata_w;
    wire [ 8:0]           reg_oper_addr_w;
    wire [31:0]           reg_oper_rdata_w;

    wire                  cc_pr_w;  
    wire                  cc_err_w; 
    wire                  cp_clr_w; 
    wire                  cp_set_w;

    wire [ 1:0]           OperCycleTimeNumerator_w; 
    wire [ 8:0]           stsm_oper_addr_w;
    wire [31:0]           stsm_oper_rdata_w;

    //---------------------------------------------------------------------------
    // qbv_registers instance (admin domain)
    //---------------------------------------------------------------------------
    assign cp_clr_w = OperControlListPopulated_w;
    assign cp_set_w = ConfigPending_w;
    assign cp_err_w = 1'b0; // Not used

    qbv_registers u_qbv_registers
    (
        .bus2ip_clk                   (bus2ip_clk    ),
        .bus2ip_rst_n                 (bus2ip_rst_n  ),
        .bus2ip_addr_i                (bus2ip_addr_i ),
        .bus2ip_data_i                (bus2ip_data_i ),
        .bus2ip_wstrb_i               (bus2ip_wstrb_i),
        .bus2ip_rd_ce_i               (bus2ip_rd_ce_i),
        .bus2ip_wr_ce_i               (bus2ip_wr_ce_i),
        .ip2bus_data_o                (ip2bus_data_o ),
        .ip2bus_ready_o               (ip2bus_ready_o),

        // QBV specific inputs
        .TickGranularity_i            (6'd8                      ),        
        .OperControlListLength_i      (OperControlListLength_w   ),  
        .OperGateStates_i             (OperGateStates_w          ),         
        .OperControlListPopulated_i   (OperControlListPopulated_w), 
        .ConfigPending_i              (ConfigPending_w           ), 
        .ConfigChangeTime_i           (ConfigChangeTime_w        ), 
        .OperCycleTime_i              (OperCycleTime_w           ),
        .OperCycleTimeExtension_i     (OperCycleTimeExtension_w  ),
        .OperBaseTime_i               (OperBaseTime_w            ), 
        .BEOverrunCount_i             (BEOverrunCount_i          ),
        .RSOverrunCount_i             (RSOverrunCount_i          ),
        .STOverrunCount_i             (STOverrunCount_i          ),
    
        // QBV specific outputs 
        .GateEnabled_o                (GateEnabled_w            ),            
        .ConfigChange_o               (ConfigChange_w           ),           
        .AdminControlListLength_o     (AdminControlListLength_w ), 
        .AdminGateStates_o            (AdminGateStates_w        ),        
        .AdminCycleTime_o             (AdminCycleTime_w         ),
        .AdminCycleTimeExtension_o    (AdminCycleTimeExtension_w),
        .AdminBaseTime_o              (AdminBaseTime_w          ),

        // BRAM Access Interface
        .admin_addr_o                 (reg_admin_addr_w ),
        .admin_data_o                 (reg_admin_wdata_w),
        .admin_wr_o                   (reg_admin_wr_w   ),
        .admin_data_i                 (reg_admin_rdata_w),
        .oper_addr_o                  (reg_oper_addr_w  ),
        .oper_data_i                  (reg_oper_rdata_w ),

        // Interrupt event inputs
        .st_oco_i                     (st_oco_i), 
        .rt_oco_i                     (rt_oco_i), 
        .bt_oco_i                     (bt_oco_i), 
        .cc_pr_i                      (cc_pr_w ), 
        .cc_err_i                     (cc_err_w), 
        .cp_clr_i                     (cp_clr_w), 
        .cp_set_i                     (cp_set_w), 

        // Interrupt output
        .intr_o                       (intr_o  ),
    );

    //---------------------------------------------------------------------------
    // qbv_stsm instance (oper domain)
    //---------------------------------------------------------------------------
    qbv_stsm u_qbv_stsm
    (
        .clk                          (oper_clk  ),            
        .rst_n                        (oper_rst_n),          

        .GateEnabled_i                (GateEnabled_w            ),    
        .CurrentTime_i                (CurrentTime_i            ),    
        .ConfigChange_i               (ConfigChange_w           ),   
        .AdminBaseTime_i              (AdminBaseTime_w          ),  
        .AdminCycleTimeNumerator_i    (2'd1                     ), 
        .AdminCycleTime_i             (AdminCycleTime_w         ), 
        .AdminCycleTimeExtension_i    (AdminCycleTimeExtension_w),   
        .AdminGateStates_i            (AdminGateStates_w        ),
        .AdminControlListLength_i     (AdminControlListLength_w ),    
        .TickGranularity_i            (6'd8                     ),        

        .OperControlListLength_o      (OperControlListLength_w   ),
        .OperGateStates_o             (OperGateStates_w          ),
        .ExitTimer_o                  (ExitTimer_o               ),
        .OperControlListPopulated_o   (OperControlListPopulated_w),
        .ConfigPending_o              (ConfigPending_w           ),
        .ConfigChangeTime_o           (ConfigChangeTime_w        ),
        .OperCycleTimeNumerator_o     (OperCycleTimeNumerator_w  ),
        .OperCycleTime_o              (OperCycleTime_w           ),
        .OperCycleTimeExtension_o     (OperCycleTimeExtension_w  ),
        .OperBaseTime_o               (OperBaseTime_w            ),

        .cc_process_o                 (cc_pr_w                   ),
        .oper_addr_o                  (stsm_oper_addr_w          ),
        .oper_data_i                  (stsm_oper_rdata_w         ),
    );

    //---------------------------------------------------------------------------
    // qbv_control_list instance
    //---------------------------------------------------------------------------
    qbv_control_list 
    #(
        .ADDR_WIDTH    (ADDR_WIDTH),
        .DATA_WIDTH    (DATA_WIDTH),
        .DEPTH         (DEPTH     )
    ) 
    u_qbv_control_list 
    (
        // Admin port (registers domain)
        .admin_clk                  (bus2ip_clk       ),
        .admin_rst_n                (bus2ip_rst_n     ),
        .admin_addr_i               (reg_admin_addr_w ),
        .admin_data_i               (reg_admin_wdata_w),
        .admin_wr_i                 (reg_admin_wr_w   ),
        .admin_data_o               (reg_admin_rdata_w),
        .reg_oper_addr_i            (reg_oper_addr_w  ),
        .reg_oper_data_o            (reg_oper_rdata_w ),

        // Oper port (stsm domain)
        .oper_clk                   (oper_clk         ),
        .oper_rst_n                 (oper_rst_n       ),
        .oper_addr_i                (stsm_oper_addr_w ),
        .oper_data_o                (stsm_oper_rdata_w),

        .OperControlListPopulated_i (OperControlListPopulated_w)
    );

endmodule
