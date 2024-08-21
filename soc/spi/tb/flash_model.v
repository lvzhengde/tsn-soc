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

module flash_model  
(
    input          rst_n      ,
    input          spi_clk_i  ,
    input          spi_cs_i   ,    
    input          spi_mosi_i ,
    output         spi_miso_o 
);
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


endmodule
