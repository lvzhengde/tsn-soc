/*
 *  DESCRIPTION: Top level main for invoking SystemC model
 *  adapted from Verilator SystemC Example
*/

// SystemC global header
#include <systemc.h>

// Include testbench header
#include "testbench.h"

#define REPORT_DEFINE_GLOBALS
#include "reporting.h"  // reporting utilities

#define TLM_TRACE 0     // dump vcd waveform or not

int sc_main(int argc, char* argv[]) 
{
  // Prevent unused variable warnings
  if (false && argc && argv) {}

  REPORT_ENABLE_ALL_REPORTING ();
  
  REPORT_DISABLE_INFO_REPORTING();

  unsigned int  sw_type;

  // Select the application to run
  char func_sel;
  cout << "\r\n";
  cout << "Select the Application" << "\r\n";
  cout << "0 : Loop Back Test for Local Device" << "\r\n";
  cout << "1 : PTPv2 Protocol Test" << "\r\n";
  cout << "Please Input the Selection: "; 
  cin >> func_sel;

  if(func_sel == '0')
  {
    sw_type = 0;
  }
  else if(func_sel == '1')
  {
    sw_type = 1;
  }
  else 
  {
    cout << "Input Error, Exit!" << "\r\n";
    exit(1);
  }

  // Construct the testbench model
	testbench* pTb = new testbench("tb", sw_type);

#if TLM_TRACE
  Vptp_top* pVtop = &pTb->pInstance->m_target_top.m_ptp_top;
  
	//检查logs目录是否存在，不存在则创建
	if(access("logs", 0) != 0)
		system("mkdir logs");

  sc_trace_file *fp = sc_create_vcd_trace_file("logs/ptpv2_tlm");

  sc_trace(fp, pVtop->tx_clk   , "tx_clk"   );
  sc_trace(fp, pVtop->tx_rst_n , "tx_rst_n" );
  sc_trace(fp, pVtop->xge_txd_o, "xge_txd_o");
  sc_trace(fp, pVtop->xge_txc_o, "xge_txc_o");

  sc_trace(fp, pVtop->rx_clk   , "rx_clk"   );
  sc_trace(fp, pVtop->rx_rst_n , "rx_rst_n" );
  sc_trace(fp, pVtop->xge_rxd_i, "xge_rxd_i");
  sc_trace(fp, pVtop->xge_rxc_i, "xge_rxc_i");

  sc_trace(fp, pVtop->bus2ip_clk    , "bus2ip_clk"    );   
  sc_trace(fp, pVtop->bus2ip_rst_n  , "bus2ip_rst_n"  ); 
  sc_trace(fp, pVtop->bus2ip_rd_ce_i, "bus2ip_rd_ce_i");   
  sc_trace(fp, pVtop->bus2ip_wr_ce_i, "bus2ip_wr_ce_i");  
  sc_trace(fp, pVtop->bus2ip_addr_i , "bus2ip_addr_i" );
  sc_trace(fp, pVtop->bus2ip_data_i , "bus2ip_data_i" );
  sc_trace(fp, pVtop->ip2bus_data_o , "ip2bus_data_o" );   

  sc_trace(fp, pVtop->rtc_clk  , "rtc_clk"  );
  sc_trace(fp, pVtop->rtc_rst_n, "rtc_rst_n");    
  sc_trace(fp, pVtop->int_ptp_o, "int_ptp_o");
  sc_trace(fp, pVtop->pps_i    , "pps_i"    );        
  sc_trace(fp, pVtop->pps_o    , "pps_o"    );           
#endif

  //Initialize SystemC
  sc_start(SC_ZERO_TIME);

  sc_start(); // Run until no more activity
  //sc_start(1, SC_MS); 

  if (sc_get_status() == SC_PAUSED) {
      SC_REPORT_INFO("", "sc_stop called to terminate a paused simulation");
      sc_stop();
  }

#if TLM_TRACE
  sc_close_vcd_trace_file(fp);
#endif

  // Return good completion status
  return 0;
}
