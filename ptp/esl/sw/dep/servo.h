#ifndef _SERVO_H__
#define _SERVO_H__

#include "datatypes.h"


class servo : public base_data
{
public:
    //member variables
    uint32_t    m_initial_tick;

    uint32_t    m_updateOffset_count;

    int32_t     m_ofm_zline[OFM_DELAY_LEN];

    bool        m_frequency_syntonized;     //current syntonization state

    bool        m_frequency_syntonized_z1;  //1 sync delayed

    bool        m_frequency_syntonized_z2;  //2 sync delayed

 public: 
    //member methods
    servo(ptpd *pApp);

    void reset_operator_messages(RunTimeOpts * rtOpts, PtpClock * ptpClock);
    
    void initClock(RunTimeOpts * rtOpts, PtpClock * ptpClock);
    
    void updateDelay(one_way_delay_filter * owd_filt, RunTimeOpts * rtOpts, PtpClock * ptpClock, TimeInternal * correctionField);
    
    void updatePeerDelay(one_way_delay_filter * owd_filt, RunTimeOpts * rtOpts, 
        PtpClock * ptpClock, TimeInternal * correctionField, Boolean twoStep);
    
    void updateOffset(TimeInternal * send_time, TimeInternal * recv_time,
        offset_from_master_filter * ofm_filt, RunTimeOpts * rtOpts, PtpClock * ptpClock, TimeInternal * correctionField);
    
    void servo_perform_clock_step(RunTimeOpts * rtOpts, PtpClock * ptpClock);
    
    void warn_operator_fast_slewing(RunTimeOpts * rtOpts, PtpClock * ptpClock, Integer32 adj);
    
    void warn_operator_slow_slewing(RunTimeOpts * rtOpts, PtpClock * ptpClock );
    
    void adjTickRate_wrapper(RunTimeOpts * rtOpts, PtpClock * ptpClock, Integer32 adj);
    
    void updateClock(RunTimeOpts * rtOpts, PtpClock * ptpClock);

    bool syntonizeFrequency(RunTimeOpts * rtOpts, PtpClock * ptpClock);

};

#endif // _SERVO_H__


