/*
 * controller.cpp
 */

//#include "ptpd.h"
#include "loop_back.h"
#include "reporting.h"               	 // reporting macros

#define CONTROLLER_ITSELF              // it's controller itself
#include "common.h"

using namespace std;

static const char *filename = "controller.cpp";  ///< filename for reporting

/// Constructor
SC_HAS_PROCESS(controller);

controller::controller            
( sc_core::sc_module_name name                  // instance name
, const unsigned int    ID                      // initiator ID
, const unsigned int    sw_type                 // software type, 0: loopback test; 1: PTPd protocol test
, const unsigned int    clock_id                // corresponding to clockIdentity
)

: sc_module           ( name              )     /// instance name
, m_ID                ( ID                )     /// initiator ID
, m_sw_type           ( sw_type           )     /// software type
, m_clock_id          ( clock_id          )     /// Clock ID
, m_has_reset         ( false             )     /// reset state or not
, m_bus_mutex         ( "bus_mutex"       )     ///initialize and unlock the mutex
{ 
    SC_THREAD(controller_thread);

    SC_THREAD(isr_thread);
    //sensitive << int_ptp_i.pos();

    // build transaction pool 
    m_ptxn = new tlm::tlm_generic_payload;
    m_data_ptr = new unsigned char [512];
    m_ptxn->set_data_ptr(m_data_ptr);

    ptr_ptp_timer = NULL;
    pApp = NULL;
}

/// Destructor
controller::~controller()
{
    delete [] m_data_ptr;
    delete m_ptxn;

    if(pApp != NULL)
      delete pApp;
}

/// SystemC thread for generation of GP traffic
void controller::controller_thread(void)
{
    std::ostringstream  msg;                      ///< log message

    pApp = NULL;
    
    if(m_sw_type == 0) //loop back test
        pApp = new loop_back(this);
    else if(m_sw_type == 1) //protocol test
        pApp = new ptpd(this);
    else
        sc_stop();

    //don't use (async_)reset_signal_is()
    //to prevent chaos caused by sc_mutex in the same thread
    if(m_has_reset == false) 
    {
        uint32_t addr = RESET_ADDR;
        uint32_t data = 0;

        wait(proc_rst_n.negedge_event()); //wait for activate
        REG_WRITE(addr, data);            //reset peripheral bus
        wait(proc_rst_n.posedge_event()); //wait for release

        m_has_reset = true;
    }

    //run application
    pApp->exec();

    //wait for finish
    wait(100, SC_NS);

    //delete application instance
    delete pApp;

    //stop simulation
    //for loop-back test only
    //as to protocol test, look up testbench/sim_proc()
    if(m_sw_type == 0)
    {
        sc_stop();
    }

} // end controller_thread

//interrupt service routine thread 
void controller::isr_thread (void)
{
    std::ostringstream  msg;                      ///< log message

    for(;;)
    {
        if(int_ptp_i.read() == true) { //judge by signal level, no miss
            msg.str ("");
            msg << "Clock ID: " << m_clock_id
                << " Controller: " << m_ID << "  Interrupt received! ";
            REPORT_INFO(filename, __FUNCTION__, msg.str());

            uint32_t addr = INT_BASE_ADDR + INT_STS_OFT;
            uint32_t data = 0;
            REG_READ(addr, data);

            msg.str ("");
            msg << "Clock ID: " << dec << m_clock_id
                << " Controller: " << m_ID << "  Interrupt status register value =  0x" 
                << hex << data;
            REPORT_INFO(filename, __FUNCTION__, msg.str());

            uint32_t mask = 1;
            if(data & mask)        //notify tx interrupt
            {
                m_ev_tx.notify();

                msg.str ("");
                msg << "Clock ID: " << dec << m_clock_id
                    << " Controller: " << m_ID << " PTP TX  Interrupt received! ";
                REPORT_INFO(filename, __FUNCTION__, msg.str());
            }

            bool ptp_rcved = false;
            if(data & (mask << 1)) //notify rx interrupt
            {
                m_ev_rx.notify();

                ptp_rcved = true;

                msg.str ("");
                msg << "Clock ID: " << dec << m_clock_id
                    << " Controller: " << m_ID << " PTP RX  Interrupt received! ";
                REPORT_INFO(filename, __FUNCTION__, msg.str());
            }

            if(data & (mask << 2)) //notify xms interrupt
            {
                m_ev_xms.notify();

                msg.str ("");
                msg << "Clock ID: " << dec << m_clock_id
                    << " Controller: " << m_ID << " xms Timer Interrupt received! ";
                REPORT_INFO(filename, __FUNCTION__, msg.str());

                if(ptr_ptp_timer != NULL) {
                    ptr_ptp_timer->catch_alarm(0);
                }
            }

            if((data & (mask << 3)) && ptp_rcved == false)  //notify normal frame except ptp message received interrupt
            {
                m_ev_rx_all.notify();

                msg.str ("");
                msg << "Clock ID: " << dec << m_clock_id
                    << " Controller: " << m_ID << " Normal Frame Interrupt received! ";
                REPORT_INFO(filename, __FUNCTION__, msg.str());
            }
        } //if interrupt input active

        wait(1.0, SC_US, int_ptp_i.posedge_event()); //wait for posedge of interrup or timeout (1.0 microsecond)
    } //infinite for loop
} 

// manipulate transaction through sc_fifo in/out interface
void controller::transaction_manip(tlm::tlm_generic_payload *ptxn)
{
    std::ostringstream  msg;                      ///< log message
    tlm::tlm_generic_payload  *transaction_ptr;  

    msg.str ("");
    msg << "Clock ID: " << m_clock_id
        << " Controller: " << m_ID << " Starting Bus Traffic";
    REPORT_INFO(filename, __FUNCTION__, msg.str());

    // send I/O access request
    request_out_port->write(ptxn);

    // get response
    response_in_port->read(transaction_ptr);

    // check validation
    if ((transaction_ptr ->get_response_status() != tlm::TLM_OK_RESPONSE)
        || (transaction_ptr ->get_command() != ptxn->get_command())
        || (transaction_ptr ->get_address() != ptxn->get_address()))
    {
        msg.str ("");
        msg << "Clock ID: " << m_clock_id
            << " Controller: " << m_ID << " Transaction ERROR";
        REPORT_FATAL(filename, __FUNCTION__, msg.str());   
    }
}

// emulate memory I/O for application SW
void controller::reg_read(const uint32_t addr, uint32_t &data)
{
    //lock shared resources(gp and fifo)
    m_bus_mutex.lock();

    //set transaction
    m_ptxn->set_command          ( tlm::TLM_READ_COMMAND        );
    m_ptxn->set_address          ( addr                  );
    m_ptxn->set_data_length      ( 4              );
    m_ptxn->set_streaming_width  ( 4              );
    m_ptxn->set_response_status  ( tlm::TLM_INCOMPLETE_RESPONSE );

    //access bus through sc_fifo
    transaction_manip(m_ptxn);

    //convert data
    data = (m_data_ptr[3]<<24) | (m_data_ptr[2]<<16) | (m_data_ptr[1]<<8) | m_data_ptr[0];

    //unlock shared resources
    m_bus_mutex.unlock();
}

void controller::reg_write(const uint32_t addr, const uint32_t data)
{
    //lock shared resources(gp and fifo)
    m_bus_mutex.lock();

    //set transaction
    m_ptxn->set_command          ( tlm::TLM_WRITE_COMMAND        );
    m_ptxn->set_address          ( addr                  );
    m_ptxn->set_data_length      ( 4              );
    m_ptxn->set_streaming_width  ( 4              );
    m_ptxn->set_response_status  ( tlm::TLM_INCOMPLETE_RESPONSE );

    //convert write data
    m_data_ptr[0] = data & 0xff;
    m_data_ptr[1] = (data >> 8) & 0xff;
    m_data_ptr[2] = (data >> 16) & 0xff;
    m_data_ptr[3] = (data >> 24) & 0xff;

    //access bus through sc_fifo
    transaction_manip(m_ptxn);

    //unlock shared resources
    m_bus_mutex.unlock();
}

void controller::burst_read(const uint32_t addr, unsigned char *data, const unsigned  int length)
{
    std::ostringstream  msg;
    msg.str("");
    if (length > 512)
    {
        msg << "Clock ID: " << m_clock_id
            << " Controller: " << m_ID 
            << " Burst read length > 512 is not supported";
        REPORT_WARNING(filename, __FUNCTION__, msg.str());
        return;
    }

    //lock shared resources(gp and fifo)
    m_bus_mutex.lock();

    //set transaction
    m_ptxn->set_command          ( tlm::TLM_READ_COMMAND        );
    m_ptxn->set_address          ( addr                  );
    m_ptxn->set_data_length      ( length              );
    m_ptxn->set_streaming_width  ( length              );
    m_ptxn->set_response_status  ( tlm::TLM_INCOMPLETE_RESPONSE );

    //access bus through sc_fifo
    transaction_manip(m_ptxn);

    //convert data
    for (unsigned int i = 0; i < length; i++)
    {
        data[i] = m_data_ptr[i];         // move data to read buffer
    }  

    //unlock shared resources
    m_bus_mutex.unlock();
}

void controller::burst_write(const uint32_t addr, const unsigned char *data, const unsigned  int length) 
{
    std::ostringstream  msg;
    msg.str("");
    if (length > 512)
    {
        msg << "Clock ID: " << m_clock_id
            << " Controller: " << m_ID 
            << " Burst write length > 512 is not supported";
        REPORT_WARNING(filename, __FUNCTION__, msg.str());
        return;
    }

    //lock shared resources(gp and fifo)
    m_bus_mutex.lock();

    //set transaction
    m_ptxn->set_command          ( tlm::TLM_WRITE_COMMAND        );
    m_ptxn->set_address          ( addr                  );
    m_ptxn->set_data_length      ( length              );
    m_ptxn->set_streaming_width  ( length              );
    m_ptxn->set_response_status  ( tlm::TLM_INCOMPLETE_RESPONSE );

    //convert data
    for (unsigned int i = 0; i < length; i++)
    {
        m_data_ptr[i] = data[i];         // move data to the generic payload data array
    }  

    //access bus through sc_fifo
    transaction_manip(m_ptxn);

    //unlock shared resources
    m_bus_mutex.unlock();
}
