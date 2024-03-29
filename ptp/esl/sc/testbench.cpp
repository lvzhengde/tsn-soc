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

#include "testbench.h"
#include "reporting.h"                     // reporting macros
#include "common.h"

using namespace  std;

static const char *filename = "testbench.cpp"; ///< filename for reporting

SC_HAS_PROCESS(testbench);
///constructor
testbench::testbench 
( sc_core::sc_module_name name
, const unsigned int  sw_type                  ///< software type, 0: loopback test; 1: PTPd protocol test
) 
: sc_module               (name)               /// init module name
, m_sw_type               (sw_type)
, clk("clk", CLOCK_PERIOD, SC_NS, 0.5, 2, SC_NS, true)       
, lp_clk("lp_clk", CLOCK_PERIOD, SC_NS, 0.5, 2, SC_NS, true) 
{
    pInstance    = NULL;
    pInstance_lp = NULL;
    pChannel     = NULL;
    pChannel_lp  = NULL;

    if(sw_type == 0)
    {
        pInstance = new ptp_instance("ptp_instance", m_sw_type, 1);
        pChannel  = new Vchannel_model("delay_channel");
    
        //bind ptp_instance ports
        pInstance->bus2ip_clk    (clk  );
        pInstance->bus2ip_rst_n  (rst_n);
        pInstance->tx_clk        (clk  );
        pInstance->tx_rst_n      (rst_n);
        pInstance->tx_en_o       (tx_en);
        pInstance->tx_er_o       (tx_er);
        pInstance->txd_o         (txd);
        pInstance->rx_clk        (clk  );
        pInstance->rx_rst_n      (rst_n);
        pInstance->rx_dv_i       (rx_dv);
        pInstance->rx_er_i       (rx_er);
        pInstance->rxd_i         (rxd);
        pInstance->rtc_clk       (clk  );
        pInstance->rtc_rst_n     (rst_n);
        pInstance->pps_i         (pps_in);
        pInstance->pps_o         (pps_out);
        pInstance->proc_rst_n    (rst_n);

        //bind delay channel ports
        pChannel->clk(clk);
        pChannel->rx_dv_i        (tx_en);
        pChannel->rx_er_i        (tx_er);
        pChannel->rxd_i          (txd);
        pChannel->tx_en_o        (rx_dv);
        pChannel->tx_er_o        (rx_er);
        pChannel->txd_o          (rxd);

        //declare sc thread
        SC_THREAD(reset_gen); 
    }
    else if(sw_type == 1)
    {
        pInstance = new ptp_instance("ptp_instance", m_sw_type, 1);
        pChannel  = new Vchannel_model("delay_channel");

        pInstance_lp = new ptp_instance("lp_ptp_instance", m_sw_type, 2);
        pChannel_lp  = new Vchannel_model("lp_delay_channel");
    
        //bind delay channel ports for local device
        pChannel->clk            (clk);
        pChannel->rx_dv_i        (tx_en);
        pChannel->rx_er_i        (tx_er);
        pChannel->rxd_i          (txd);
        pChannel->tx_en_o        (lp_rx_dv);
        pChannel->tx_er_o        (lp_rx_er);
        pChannel->txd_o          (lp_rxd);

        //bind delay channel ports for link partner 
        pChannel_lp->clk         (lp_clk);
        pChannel_lp->rx_dv_i     (lp_tx_en);
        pChannel_lp->rx_er_i     (lp_tx_er);
        pChannel_lp->rxd_i       (lp_txd);
        pChannel_lp->tx_en_o     (rx_dv);
        pChannel_lp->tx_er_o     (rx_er);
        pChannel_lp->txd_o       (rxd);

        //bind ptp_instance ports for local device
        pInstance->bus2ip_clk    (clk  );
        pInstance->bus2ip_rst_n  (rst_n);
        pInstance->tx_clk        (clk  );
        pInstance->tx_rst_n      (rst_n);
        pInstance->tx_en_o       (tx_en);
        pInstance->tx_er_o       (tx_er);
        pInstance->txd_o         (txd);
        pInstance->rx_clk        (lp_clk  );
        pInstance->rx_rst_n      (lp_rst_n);
        pInstance->rx_dv_i       (rx_dv);
        pInstance->rx_er_i       (rx_er);
        pInstance->rxd_i         (rxd);
        pInstance->rtc_clk       (clk  );
        pInstance->rtc_rst_n     (rst_n);
        pInstance->pps_i         (pps_in);
        pInstance->pps_o         (pps_out);
        pInstance->proc_rst_n    (rst_n);

        //bind ptp_instance ports for link partner
        pInstance_lp->bus2ip_clk    (lp_clk  );
        pInstance_lp->bus2ip_rst_n  (lp_rst_n);
        pInstance_lp->tx_clk        (lp_clk  );
        pInstance_lp->tx_rst_n      (lp_rst_n);
        pInstance_lp->tx_en_o       (lp_tx_en);
        pInstance_lp->tx_er_o       (lp_tx_er);
        pInstance_lp->txd_o         (lp_txd);
        pInstance_lp->rx_clk        (clk  );
        pInstance_lp->rx_rst_n      (rst_n);
        pInstance_lp->rx_dv_i       (lp_rx_dv);
        pInstance_lp->rx_er_i       (lp_rx_er);
        pInstance_lp->rxd_i         (lp_rxd);
        pInstance_lp->rtc_clk       (lp_clk  );
        pInstance_lp->rtc_rst_n     (lp_rst_n);
        pInstance_lp->pps_i         (lp_pps_in);
        pInstance_lp->pps_o         (lp_pps_out);
        pInstance_lp->proc_rst_n    (lp_rst_n);

        //declare sc thread
        SC_THREAD(reset_gen); 

        SC_THREAD(lp_reset_gen); 

        SC_THREAD(sim_proc); 
    }
}

///destructor
testbench::~testbench()
{
    if(pInstance    != NULL)
        delete pInstance;

    if(pInstance_lp != NULL)
        delete pInstance_lp; 

    if(pChannel     != NULL)
    {
        pChannel->final();
        delete pChannel; 
    }

    if(pChannel_lp  != NULL)
    {
        pChannel_lp->final();
        delete pChannel_lp; 
    }
}

///generate reset for local PTP instance
void testbench::reset_gen()
{
    //initialize to inactive
    rst_n.write(true); 

    wait(55, SC_NS);
    rst_n.write(false);

    wait(40*5000, SC_NS);
    wait(355, SC_NS);

    rst_n.write(true);
}

///generate reset for link partner PTP instance
void testbench::lp_reset_gen()
{
    //initialize to inactive
    lp_rst_n.write(true); 

    wait(55, SC_NS);
    lp_rst_n.write(false);

    wait(40*5000, SC_NS);
    wait(355, SC_NS);

    lp_rst_n.write(true);
}

//monitor execution of ptpd software on controller
//and decide whether stop simulation or not
void testbench::sim_proc()
{
    ptpd* pApp = NULL;
    ptpd* pApp_lp = NULL;

    PtpClock * pClk = NULL;
    PtpClock * pClk_lp = NULL;

    wait(SC_ZERO_TIME);

    if(m_sw_type == 1) {
        int time_elapsed = 0;

        //wait program starting up, 100 milliseconds
        for(int i = 0; i < 100; i++){
            wait(1, SC_MS);  

            time_elapsed++;
            if((time_elapsed%10) == 0) {
                printf(" Simulation: %d milliseconds elapsed! \n", time_elapsed);
            }
        }
    
        pApp = (ptpd*)pInstance->m_initiator_top.m_controller.pApp;
        pApp_lp = (ptpd*)pInstance_lp->m_initiator_top.m_controller.pApp;

        pClk = pApp->m_ptr_ptpClock;
        pClk_lp = pApp_lp->m_ptr_ptpClock;

        //infinite loop to monitor simulation
        for(;;) {

            //pClk is slave, check synchronization state converged or not
            double drift = pClk->observed_drift;
            drift = abs(abs(drift / PPM_DIV) - FREQ_DIFF);

            if(pClk->portState == PTP_SLAVE && drift < 0.05 && time_elapsed > 500 &&
                    pClk->offsetFromMaster.seconds == 0 && abs(pClk->offsetFromMaster.nanoseconds) < 25 &&
                    ((pClk->peerMeanPathDelay.nanoseconds > 50 && pClk->peerMeanPathDelay.nanoseconds < 2000)
                     ||(pClk->meanPathDelay.nanoseconds > 50 && pClk->meanPathDelay.nanoseconds < 2000))
                    ) {
                pApp->m_end_sim = 1;
                pApp_lp->m_end_sim = 1;

                printf(" PTP Slave, Clock ID 1, reach synchronized convergence state,  Stop! \n");
                break;
            }

            //pClk_lp is slave, check synchronization state converged or not 
            double drift_lp = pClk_lp->observed_drift;
            drift_lp = abs(abs(drift_lp / PPM_DIV) - FREQ_DIFF);

            if(pClk_lp->portState == PTP_SLAVE && drift_lp < 0.05 &&  time_elapsed > 500 &&
                    pClk_lp->offsetFromMaster.seconds == 0 && abs(pClk_lp->offsetFromMaster.nanoseconds) < 25 &&
                    ((pClk_lp->peerMeanPathDelay.nanoseconds > 50 && pClk_lp->peerMeanPathDelay.nanoseconds < 2000)
                     ||(pClk_lp->meanPathDelay.nanoseconds > 50 && pClk_lp->meanPathDelay.nanoseconds < 2000))
                    ) {
                pApp->m_end_sim = 1;
                pApp_lp->m_end_sim = 1;

                printf(" PTP Slave, Clock ID 2, reach synchronized convergence state,  Stop! \n");
                break;
            }

            //sleep 1 millisecond
            wait(1, SC_MS);

            time_elapsed++;
            if((time_elapsed%10) == 0) {
                printf(" Simulation: %d milliseconds elapsed! \n", time_elapsed);
            }

            //force to exit loop, not converged in 30 seconds
            if(time_elapsed > 30000) {
                pApp->m_end_sim = 1;
                pApp_lp->m_end_sim = 1;

                printf(" Simulation time elapsed: %d ms exceeds the limit, Stop! \n", time_elapsed);
                break;
            }
        }
        //wait for cleaning up
        wait(100, SC_NS);

        //stop simulation
        sc_stop();
    }
}
