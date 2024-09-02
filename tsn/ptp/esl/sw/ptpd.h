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
 * PTPv2 protocol test application
-*/

#ifndef _PTPD_H__
#define _PTPD_H__

#include "MyApp.h"
#include "datatypes.h"


class ptpd: public MyApp
{
public:
    //member variables
    ptpd   *m_pApp;

    RunTimeOpts m_rtOpts;         //configuration data     

    PtpClock    *m_ptr_ptpClock;

    volatile sig_atomic_t  m_end_sim; 
    
    msg         *m_ptr_msg       ; 
    net         *m_ptr_net       ;
    ptp_timer   *m_ptr_ptp_timer ;
    servo       *m_ptr_servo     ; 
    startup     *m_ptr_startup   ; 
    sys         *m_ptr_sys       ; 
    arith       *m_ptr_arith     ;  
    bmc         *m_ptr_bmc       ; 
    display     *m_ptr_display   ; 
    management  *m_ptr_management; 
    protocol    *m_ptr_protocol  ; 
    transport   *m_ptr_transport ;

public:
    //member methods
    ptpd(controller *pController);
    
    virtual ~ptpd();
    
    virtual void init();
    
    virtual void exec();
    
    virtual void quit();

};

#endif // _PTPD_H__

