#include "loop_back.h"
#include "controller.h"
#include "ptp_memmap.h"

//constructor
loop_back::loop_back(controller *pController)
  : MyApp(pController)
{
  //m_pController = pController;
}

//destructor
loop_back::~loop_back()
{

}

//initialize related variables
void loop_back::init()
{
  m_cpu_str = "Clock ID: " + to_string(m_pController->m_clock_id) + " Controller: " + to_string(m_pController->m_ID);
  
  cout << "\r\n            "<< m_cpu_str  << "\r\n"
       << "=========================================================" << "\r\n" 
       << "            ####  Loop Back Test Start!  #### " << "\r\n" << "\r\n";

  wait(200, SC_NS);
}

//run loop back test
void loop_back::exec()
{
  init();

  //test register access
  register_test();

  //test frame transmit/receive
  frame_test();

  quit();
}

//exit test and clean up
void loop_back::quit()
{
  wait(200, SC_NS);

  cout << "\r\n            "<< m_cpu_str  << "\r\n"
       << "=========================================================" << "\r\n" 
       << "            ####  Loop Back Test Complete!  #### " << "\r\n";
}

//test register read/write
void loop_back::register_test()
{
  uint32_t base, addr, data;

  //test register access of the RTC unit
  base = RTC_BLK_ADDR << 8;

  //set RTC
  cout << "Set initial RTC Value second: 0x1112345678, nanosecond: 0x1500000" << "\r\n";
  addr = base + SC_OFST_ADDR0;
  data = 0x11;
  REG_WRITE(addr, data);

  addr = base + SC_OFST_ADDR1;
  data = 0x12345678;
  REG_WRITE(addr, data);

  addr = base + NS_OFST_ADDR;
  data = 0x1500000;
  REG_WRITE(addr, data);

  addr = base + RTC_CTL_ADDR;
  data = 0x5; //adjust rtc and set timer interval to 7.8125ms //0x1;
  REG_WRITE(addr, data);
  
  //tick increment value
  addr = base + TICK_INC_ADDR;
  data = 0x1999999a;
  REG_WRITE(addr, data);
  printf("Write to address : %#x, value : %#x \r\n", addr, data);

  data = 0;
  REG_READ(addr, data);
  printf("Read from address : %#x, value : %#x \r\n", addr, data);

  //read current value from RTC
  cout << "Read current RTC Value frome register" << "\r\n";
  uint64_t second;
  uint32_t nanosecond;

  wait(121, SC_NS); //intentionally added

  addr = base + CUR_TM_ADDR0;
  data = 0;
  REG_READ(addr, data);
  second = data;

  addr = base + CUR_TM_ADDR1;
  data = 0;
  REG_READ(addr, data);
  second = (second << 16) + ((data & 0xffff0000) >> 16);
  nanosecond = data & 0x0000ffff;

  addr = base + CUR_TM_ADDR2;
  data = 0;
  REG_READ(addr, data);
  nanosecond = (nanosecond << 16) + ((data & 0xffff0000) >> 16);
  
  //print uint64_t using format "%#llx"
  printf("Current RTC value second = %#llx, nanosecond = %#x \r\n", second, nanosecond);

  //test register access of the timestamp unit
  cout << "Test TSU configuration register, write value: 0x25" << "\r\n";
  base = TSU_BLK_ADDR << 8;

  addr = base + TSU_CFG_ADDR;
  data = 0x25;
  REG_WRITE(addr, data);
  printf("Write to address : %#x, value : %#x \r\n", addr, data);

  data = 0;
  REG_READ(addr, data);
  printf("Read from address : %#x, value : %#x \r\n", addr, data);

  wait(100, SC_NS);

  //wait xms timer event
  wait(20, SC_MS, m_pController->m_ev_xms);
  cout << "\r\n" << "xms timer event received in loop back test!" << "\r\n";
}

//test frame tx/rx
void loop_back::frame_test()
{
  uint32_t base, addr, data;

  const unsigned char frame_data[] = {
    0x01, 0x1b, 0x19, 0x00,
    0x00, 0x00, 0x00, 0x80,
    0x63, 0x00, 0x09, 0xba,
    0x88, 0xf7, 0x00, 0x02,
    0x00, 0x2c, 0x00, 0x00,
    0xfd, 0xff, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x33, 0x51, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x80,
    0x63, 0xff, 0xff, 0x00,
    0x09, 0xba, 0x00, 0x02,
    0x00, 0x01, 0x00, 0x00,
    0x3a, 0xbc, 0xde, 0xfc,
    0x79, 0x56, 0x12, 0x3b,
    0xf9, 0x64, 0x00, 0x00,
    0xb0, 0x56, 0x77, 0x6d
  };

  unsigned int frame_len = sizeof(frame_data);

  //transmit PTPv2 Sync message
  cout << "\r\n \r\n"
       << "Transmit PTPv2 Sync message, the frame data : \r\n";

  for(unsigned int i = 0; i < frame_len; i++)
  {
    printf("0x%02x, ", frame_data[i]);
    if((i+1) % 4 == 0) printf("\r\n");
  }

  cout << "\r\nthe frame length = " << frame_len << "\r\n";

  //write data to TX buffer
  base = TX_BUF_BADDR;
  BURST_WRITE(base, frame_data, frame_len);

  addr = base + TX_FLEN_OFT;
  data = frame_len + (1 << 15);
  REG_WRITE(addr, data);

  //read TX timestamp and identification
  wait(1000, SC_NS, m_pController->m_ev_tx);

  uint64_t second;
  uint32_t nanosecond;
  unsigned char messageType;
  uint16_t sequenceId;

  base = TSU_BLK_ADDR << 8;

  addr = base + TX_TS_ADDR0;
  data = 0;
  REG_READ(addr, data);
  second = data;

  addr = base + TX_TS_ADDR1;
  data = 0;
  REG_READ(addr, data);
  second = (second << 16) + ((data & 0xffff0000) >> 16);
  nanosecond = data & 0x0000ffff;

  addr = base + TX_TS_ADDR2;
  data = 0;
  REG_READ(addr, data);
  nanosecond = (nanosecond << 16) + ((data & 0xffff0000) >> 16);

  printf("Tx timestamp value second = 0x%llx, nanosecond = 0x%x \r\n", second, nanosecond);

  addr = base + TX_TVID_ADDR;
  data = 0;
  REG_READ(addr, data);
  messageType = (data >> 24) & 0xf;
  sequenceId = data & 0xffff;

  printf("Tx messageType = 0x%x, sequenceId = 0x%x \r\n", messageType, sequenceId);

  //RX direction test
  wait(1000, SC_NS, m_pController->m_ev_rx | m_pController->m_ev_rx_all);

  base = RX_BUF_BADDR;
  addr = base + RX_FLEN_OFT;
  data = 0;
  REG_READ(addr, data);
  printf("read from RX_FLEN_OFT register before reading buffer, value = 0x%x \r\n",  data);
  bool data_rdy = (data >> 15) & 0x1;
  unsigned int rx_frm_len = data & 0x1ff;

  if(rx_frm_len > 0 && data_rdy)
  {
    //read RX PTPv2 message from RX buffer
    unsigned char *rx_frm_data = new unsigned char[rx_frm_len];
    addr = base;
    BURST_READ(addr, rx_frm_data, rx_frm_len);

    cout << "\r\n \r\n"
         << "Receive PTPv2 message, the frame data : \r\n";

    for(unsigned int i = 0; i < rx_frm_len; i++)
    {
      printf("0x%02x, ", rx_frm_data[i]);
      if((i+1) % 4 == 0) printf("\r\n");
    }
    cout << "\r\nthe rx frame length = " << rx_frm_len << "\r\n";

    delete [] rx_frm_data;

    //read RX timestamp and identification
    base = TSU_BLK_ADDR << 8;

    addr = base + RX_TS_ADDR0;
    data = 0;
    REG_READ(addr, data);
    second = data;

    addr = base + RX_TS_ADDR1;
    data = 0;
    REG_READ(addr, data);
    second = (second << 16) + ((data & 0xffff0000) >> 16);
    nanosecond = data & 0x0000ffff;

    addr = base + RX_TS_ADDR2;
    data = 0;
    REG_READ(addr, data);
    nanosecond = (nanosecond << 16) + ((data & 0xffff0000) >> 16);

    printf("Rx timestamp value second = 0x%llx, nanosecond = 0x%x \r\n", second, nanosecond);

    addr = base + RX_TVID_ADDR;
    data = 0;
    REG_READ(addr, data);
    messageType = (data >> 24) & 0xf;
    sequenceId = data & 0xffff;

    printf("Rx messageType = 0x%x, sequenceId = 0x%x \r\n", messageType, sequenceId);
  }
  else
  {
    cout << "\r\n \r\n"
         << "There Is No PTPv2 Message Received, Error Occurred!! \r\n";
  }

  //verify read clearing operation
  base = RX_BUF_BADDR;
  addr = base + RX_FLEN_OFT;
  data = 0;
  REG_READ(addr, data);
  printf("read from RX_FLEN_OFT register after reading buffer, value = 0x%x \r\n",  data);
}
