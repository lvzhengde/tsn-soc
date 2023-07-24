/*****************************************************************************
 * Implements LT target
 */

#include "MyTarget.h"                      // our header
#include "reporting.h"                     // reporting macros
#include "ptp_memmap.h"                    // note: use memory address map only

using namespace  std;

static const char *filename = "MyTarget.cpp"; ///< filename for reporting

SC_HAS_PROCESS(MyTarget);
///Constructor
MyTarget::MyTarget
( sc_core::sc_module_name module_name               // module name
, const unsigned int        ID                      // target ID, corresponding to port id in fact
, const unsigned int        clock_id                ///< corresponding to clockIdentity
, const sc_core::sc_time    accept_delay            // accept delay (SC_TIME)
)
: sc_module               (module_name)             /// init module name
, m_target_socket         ("m_target_socket")
, m_ID                    (ID)                      /// init target ID
, m_clock_id              (clock_id)
, m_accept_delay          (accept_delay)            /// init accept delay
{
  /// Bind the socket's export to the interface
  m_target_socket.bind(*this);
}

//++
//peripheral bus operation functions
//--

// reset peripheral bus
void MyTarget::reset_pbus(void)
{
  bus2ip_rd_ce_o.write(0);
  bus2ip_wr_ce_o.write(0);
  bus2ip_addr_o.write(0);
  bus2ip_data_o.write(0);

  std::ostringstream  msg;                      ///< log message
  msg.str ("");
  msg << "Clock ID: " << m_clock_id
      << " Target: " << m_ID << " Reset Peripheral Bus!";
  REPORT_INFO(filename, __FUNCTION__, msg.str());
}

// task to write register
void MyTarget::write_reg(const uint32_t addr, const uint32_t data)
{
  bus2ip_wr_ce_o.write(0);
  bus2ip_addr_o.write(0);
  bus2ip_data_o.write(0);
  
  wait(bus2ip_clk.posedge_event());
  bus2ip_wr_ce_o.write(1);
  bus2ip_addr_o.write(addr);
  bus2ip_data_o.write(data);
  
  wait(bus2ip_clk.posedge_event());
  wait(bus2ip_clk.posedge_event());
  
  bus2ip_wr_ce_o.write(0);
  bus2ip_addr_o.write(0);
  bus2ip_data_o.write(0);
}

// task to read register
void MyTarget::read_reg(const uint32_t addr, uint32_t &data)
{
  bus2ip_rd_ce_o.write(0);
  bus2ip_addr_o.write(0);
  
  wait(bus2ip_clk.posedge_event());
  bus2ip_rd_ce_o.write(1);
  bus2ip_addr_o.write(addr);
  
  wait(bus2ip_clk.posedge_event());
  wait(bus2ip_clk.posedge_event());
  wait(bus2ip_clk.posedge_event());

  data = ip2bus_data_i.read();
  
  wait(bus2ip_clk.posedge_event());
  bus2ip_rd_ce_o.write(0);
  bus2ip_addr_o.write(0);
} 

//==============================================================================
//  b_transport implementation calls from initiators
//
//=============================================================================
void
MyTarget::b_transport
( tlm::tlm_generic_payload  &payload                // ref to  Generic Payload
, sc_core::sc_time          &delay_time             // delay time
)
{
  /// Access the required attributes from the payload
  sc_dt::uint64    address   = payload.get_address();     // memory address
  tlm::tlm_command command   = payload.get_command();     // memory command
  unsigned char    *data     = payload.get_data_ptr();    // data pointer
  unsigned  int     length   = payload.get_data_length(); // data length

  std::ostringstream  msg;
  msg.str("");
  tlm::tlm_response_status response_status = tlm::TLM_OK_RESPONSE;

  if (payload.get_byte_enable_ptr())
    response_status = tlm::TLM_BYTE_ENABLE_ERROR_RESPONSE;
  else if (payload.get_streaming_width() != payload.get_data_length())
    response_status = tlm::TLM_BURST_ERROR_RESPONSE;

  switch (command)
  {
    /// Setup a TLM_WRITE_COMMAND Informational Message and Write the Data from
    /// the Generic Payload Data pointer to peripheral registers
    case tlm::TLM_WRITE_COMMAND:
    {
      if (response_status == tlm::TLM_OK_RESPONSE)
      {
        if(address == RESET_ADDR)
        {
          reset_pbus();
        }
        else
        {
          for (unsigned int i = 0; i < length; i += 4)
          {
            uint32_t wr_addr = address + i; 
            uint32_t wr_data = 0; 

            if((i+4) <= length)
              wr_data = (data[i+3]<<24) | (data[i+2]<<16) | (data[i+1]<<8) | data[i];
            else if((i+3) == length)
              wr_data = (data[i+2]<<16) | (data[i+1]<<8) | data[i];
            else if((i+2) == length)
              wr_data = (data[i+1]<<8) | data[i];
            else if((i+1) == length)
              wr_data = data[i];

            write_reg(wr_addr, wr_data);   //write to register
          }
        }
        delay_time = delay_time + m_accept_delay;
        report::print(m_ID, payload, filename);
      }
      break;
    }

    /// Setup a TLM_READ_COMMAND Informational Message and read the Data from
    /// the peripheral registers to Generic Payload Data pointer
    case tlm::TLM_READ_COMMAND:
    {
      if (response_status == tlm::TLM_OK_RESPONSE)
      {
        for (unsigned int i = 0; i < length; i += 4)
        {
            uint32_t rd_addr = address + i; 
            uint32_t rd_data = 0; 

            read_reg(rd_addr, rd_data);  //read from register

            if((i+4) <= length)
            {
              data[i] = rd_data & 0xff;
              data[i+1] = (rd_data >> 8) & 0xff;
              data[i+2] = (rd_data >> 16) & 0xff;
              data[i+3] = (rd_data >> 24) & 0xff;
            }
            else if((i+3) == length)
            {
              data[i] = rd_data & 0xff;
              data[i+1] = (rd_data >> 8) & 0xff;
              data[i+2] = (rd_data >> 16) & 0xff;
            }
            else if((i+2) == length)
            {
              data[i] = rd_data & 0xff;
              data[i+1] = (rd_data >> 8) & 0xff;
            }
            else if((i+1) == length)
            {
              data[i] = rd_data & 0xff;
            }
        }
        delay_time = delay_time + m_accept_delay;
        report::print(m_ID, payload, filename);
      }
      break;
    }
    default:
    {
      msg << "Clock ID: " << m_clock_id
          << " Target: " << m_ID
          << " Unsupported Command Extension";
      REPORT_INFO(filename, __FUNCTION__, msg.str());
      response_status = tlm::TLM_COMMAND_ERROR_RESPONSE;
      delay_time = sc_core::SC_ZERO_TIME;
    }
  } // end switch

  payload.set_response_status(response_status);

  msg << "Clock ID: " << m_clock_id
      << " Target: " << m_ID
      << " Access peripheral registers through Mybus, access delay =  "
      << delay_time;
  REPORT_INFO(filename,  __FUNCTION__, msg.str());

  return;
}
