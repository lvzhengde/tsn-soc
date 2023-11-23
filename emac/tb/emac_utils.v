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
 * utility functions include crc, bit reverse, etc.
 * Note: functions should be defined within modules, otherwise will cause syntax error
 * 
 *  polynomial: (0 1 2 4 5 7 8 10 11 12 16 22 23 26 32)
 *  data width: 8
 *  convention: the first serial data bit is msb i.e. D[7]
-*/

function [31:0]  nextCRC32_D8;
    input [7:0]  Data;
    input [31:0] currentCRC;

    reg [7:0]    data_in;
    reg [31:0]   lfsr_q ;
    reg [31:0]   lfsr_c;

    begin
        data_in = Data;
        lfsr_q = currentCRC;

        lfsr_c[0] = lfsr_q[24] ^ lfsr_q[30] ^ data_in[0] ^ data_in[6];
        lfsr_c[1] = lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_in[0] ^ data_in[1] ^ data_in[6] ^ data_in[7];
        lfsr_c[2] = lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_in[0] ^ data_in[1] ^ data_in[2] ^ data_in[6] ^ data_in[7];
        lfsr_c[3] = lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[27] ^ lfsr_q[31] ^ data_in[1] ^ data_in[2] ^ data_in[3] ^ data_in[7];
        lfsr_c[4] = lfsr_q[24] ^ lfsr_q[26] ^ lfsr_q[27] ^ lfsr_q[28] ^ lfsr_q[30] ^ data_in[0] ^ data_in[2] ^ data_in[3] ^ data_in[4] ^ data_in[6];
        lfsr_c[5] = lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[27] ^ lfsr_q[28] ^ lfsr_q[29] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_in[0] ^ data_in[1] ^ data_in[3] ^ data_in[4] ^ data_in[5] ^ data_in[6] ^ data_in[7];
        lfsr_c[6] = lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[28] ^ lfsr_q[29] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_in[1] ^ data_in[2] ^ data_in[4] ^ data_in[5] ^ data_in[6] ^ data_in[7];
        lfsr_c[7] = lfsr_q[24] ^ lfsr_q[26] ^ lfsr_q[27] ^ lfsr_q[29] ^ lfsr_q[31] ^ data_in[0] ^ data_in[2] ^ data_in[3] ^ data_in[5] ^ data_in[7];
        lfsr_c[8] = lfsr_q[0] ^ lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[27] ^ lfsr_q[28] ^ data_in[0] ^ data_in[1] ^ data_in[3] ^ data_in[4];
        lfsr_c[9] = lfsr_q[1] ^ lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[28] ^ lfsr_q[29] ^ data_in[1] ^ data_in[2] ^ data_in[4] ^ data_in[5];
        lfsr_c[10] = lfsr_q[2] ^ lfsr_q[24] ^ lfsr_q[26] ^ lfsr_q[27] ^ lfsr_q[29] ^ data_in[0] ^ data_in[2] ^ data_in[3] ^ data_in[5];
        lfsr_c[11] = lfsr_q[3] ^ lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[27] ^ lfsr_q[28] ^ data_in[0] ^ data_in[1] ^ data_in[3] ^ data_in[4];
        lfsr_c[12] = lfsr_q[4] ^ lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[28] ^ lfsr_q[29] ^ lfsr_q[30] ^ data_in[0] ^ data_in[1] ^ data_in[2] ^ data_in[4] ^ data_in[5] ^ data_in[6];
        lfsr_c[13] = lfsr_q[5] ^ lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[27] ^ lfsr_q[29] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_in[1] ^ data_in[2] ^ data_in[3] ^ data_in[5] ^ data_in[6] ^ data_in[7];
        lfsr_c[14] = lfsr_q[6] ^ lfsr_q[26] ^ lfsr_q[27] ^ lfsr_q[28] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_in[2] ^ data_in[3] ^ data_in[4] ^ data_in[6] ^ data_in[7];
        lfsr_c[15] = lfsr_q[7] ^ lfsr_q[27] ^ lfsr_q[28] ^ lfsr_q[29] ^ lfsr_q[31] ^ data_in[3] ^ data_in[4] ^ data_in[5] ^ data_in[7];
        lfsr_c[16] = lfsr_q[8] ^ lfsr_q[24] ^ lfsr_q[28] ^ lfsr_q[29] ^ data_in[0] ^ data_in[4] ^ data_in[5];
        lfsr_c[17] = lfsr_q[9] ^ lfsr_q[25] ^ lfsr_q[29] ^ lfsr_q[30] ^ data_in[1] ^ data_in[5] ^ data_in[6];
        lfsr_c[18] = lfsr_q[10] ^ lfsr_q[26] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_in[2] ^ data_in[6] ^ data_in[7];
        lfsr_c[19] = lfsr_q[11] ^ lfsr_q[27] ^ lfsr_q[31] ^ data_in[3] ^ data_in[7];
        lfsr_c[20] = lfsr_q[12] ^ lfsr_q[28] ^ data_in[4];
        lfsr_c[21] = lfsr_q[13] ^ lfsr_q[29] ^ data_in[5];
        lfsr_c[22] = lfsr_q[14] ^ lfsr_q[24] ^ data_in[0];
        lfsr_c[23] = lfsr_q[15] ^ lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[30] ^ data_in[0] ^ data_in[1] ^ data_in[6];
        lfsr_c[24] = lfsr_q[16] ^ lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[31] ^ data_in[1] ^ data_in[2] ^ data_in[7];
        lfsr_c[25] = lfsr_q[17] ^ lfsr_q[26] ^ lfsr_q[27] ^ data_in[2] ^ data_in[3];
        lfsr_c[26] = lfsr_q[18] ^ lfsr_q[24] ^ lfsr_q[27] ^ lfsr_q[28] ^ lfsr_q[30] ^ data_in[0] ^ data_in[3] ^ data_in[4] ^ data_in[6];
        lfsr_c[27] = lfsr_q[19] ^ lfsr_q[25] ^ lfsr_q[28] ^ lfsr_q[29] ^ lfsr_q[31] ^ data_in[1] ^ data_in[4] ^ data_in[5] ^ data_in[7];
        lfsr_c[28] = lfsr_q[20] ^ lfsr_q[26] ^ lfsr_q[29] ^ lfsr_q[30] ^ data_in[2] ^ data_in[5] ^ data_in[6];
        lfsr_c[29] = lfsr_q[21] ^ lfsr_q[27] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_in[3] ^ data_in[6] ^ data_in[7];
        lfsr_c[30] = lfsr_q[22] ^ lfsr_q[28] ^ lfsr_q[31] ^ data_in[4] ^ data_in[7];
        lfsr_c[31] = lfsr_q[23] ^ lfsr_q[29] ^ data_in[5];

        nextCRC32_D8 = lfsr_c;
    end 
endfunction 

//bit reverse for CRC operation
function [7:0] reverse_8b;
    input [7:0]   data;
    integer        i;

    begin
        for (i = 0; i < 8; i = i + 1) begin
            reverse_8b[i] = data[7 - i];
        end
    end
endfunction

function [31:0] reverse_32b;
    input [31:0]   data;
    integer        i;

    begin
        for (i = 0; i < 32; i = i + 1) begin
            reverse_32b[i] = data[31 - i];
        end
    end
endfunction

//function to assemble Ethernet Frame
reg   [7:0]  frameBuffer[0:16383];
reg   [7:0]  payloadBuffer[0:16366];

function integer AssembleFrame(input [47:0] dstMacAddr, input [47:0] srcMacAddr, 
                     input [15:0] lengthType, input integer payloadLen,  input crcEn);
    integer len;
    integer i;
    integer m;
    integer pad_len;
    reg [31:0] frame_crc;

    begin
        len = 0;

        //destination address
        for(i = 0; i < 6; i = i+1) begin
            frameBuffer[len] = dstMacAddr[(47-i*8)-:8];
            len = len + 1;
        end

        //source address
        for(i = 0; i < 6; i = i+1) begin
            frameBuffer[len] = srcMacAddr[(47-i*8)-:8];
            len = len + 1;
        end

        //Length/Type
        frameBuffer[len+0] = lengthType[15:8]; frameBuffer[len+1] = lengthType[7:0]; 
        len = len + 2;

        //payload
        for(i = 0; i < payloadLen; i = i+1) begin
            frameBuffer[len] = payloadBuffer[i];
            len = len + 1;
        end

        //padding and calculate CRC
        if(crcEn == 1) begin
            pad_len = 64 - (len + 4);

            if(pad_len > 0) begin
                for(m = 0; m < pad_len; m = m+1) begin
                    frameBuffer[len] = 8'h00;
                    len = len + 1;
                end
            end

            //crc octets
            frame_crc = CalculateFrameFCS(len);
            frameBuffer[len+0] = frame_crc[7:0];    frameBuffer[len+1] = frame_crc[15:8];  
            frameBuffer[len+2] = frame_crc[23:16];  frameBuffer[len+3] = frame_crc[31:24];
            len = len + 4; 
        end  //crcEn

        AssembleFrame = len;
    end
endfunction

//calculate FCS for frameBuffer
function [31:0] CalculateFrameFCS(input integer dataLen);
    integer i;
    reg [31:0] current_crc;
    reg [31:0] next_crc;

    begin
        current_crc = 32'hffff_ffff;
        for(i = 0; i < dataLen; i = i + 1) begin
            next_crc = nextCRC32_D8(reverse_8b(frameBuffer[i]), current_crc);
            current_crc = next_crc; 
        end

        CalculateFrameFCS = ~reverse_32b(current_crc);
    end
endfunction
    

