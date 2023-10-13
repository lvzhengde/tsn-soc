/*+
 * Copyright (c) 2022-2023 Zhengde
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
 * Ethernet MAC testbench
-*/

`include "emac_defines.v"
`include "ephy_defines.v"
`include "tb_emac_defines.v"
`define VCD

// open dump files
initial begin
    tb.tb_log_file = $fopen("./log/tb_emac.log");
    if (tb.tb_log_file < 2)
    begin
        $display("*E Could not open/create testbench log file in ./log/ directory!");
        $finish;
    end
    $fdisplay(tb.tb_log_file, "========================== ETHERNET MAC IP Core Testbench results ===========================");
    $fdisplay(tb.tb_log_file, " ");
  
    tb.phy_log_file_desc = $fopen("./log/ephy_model.log");
    if (tb.phy_log_file_desc < 2)
    begin
        $fdisplay(tb.tb_log_file, "*E Could not open/create ephy_model.log file in ./log/ directory!");
        $finish;
    end
    $fdisplay(tb.phy_log_file_desc, "================ PHY Model Testbench access log ================");
    $fdisplay(tb.phy_log_file_desc, " ");
  
  `ifdef VCD
     $dumpfile("./log/ethmac.vcd");
     $dumpvars(0);
  `endif
end
integer      tests_successfull;
integer      tests_failed;
reg [799:0]  test_name; // used for tb_log_file

reg   [3:0]  wbm_init_waits; // initial wait cycles between CYC_O and STB_O of WB Master
reg   [3:0]  wbm_subseq_waits; // subsequent wait cycles between STB_Os of WB Master
reg   [3:0]  wbs_waits; // wait cycles befor WB Slave responds
reg   [7:0]  wbs_retries; // if RTY response, then this is the number of retries before ACK

reg          wbm_working; // tasks wbm_write and wbm_read set signal when working and reset it when stop working

// main simulation thread
initial begin
    wait(tb.StartTB);  // Start of testbench
  
    // Initial global values
    tests_successfull = 0;
    tests_failed = 0;
    
    //  Call tests
    //  ----------
    //test_access_to_mac_reg(0, 4);           // 0 - 4
    //test_mii(0, 17);                        // 0 - 17

    // Finish test's logs
    //test_summary;
    $display("\n\n END of SIMULATION");
    $fclose(tb.tb_log_file | tb.phy_log_file_desc);
  
    $stop;
end

