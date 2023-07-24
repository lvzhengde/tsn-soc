//rtl files
../rtl/rtc/ptp_rtc.v
../rtl/rtc/rtc_rgs.v
../rtl/rtc/rtc_unit.v
../rtl/rtc/sync_io.v

../rtl/tsu/timestamp_unit.v
../rtl/tsu/tsu_rgs.v
../rtl/tsu/tsu_mx.v
../rtl/tsu/rx_tse.v
../rtl/tsu/tx_tse.v
../rtl/tsu/rx_parse.v
../rtl/tsu/rx_emb_ts.v
../rtl/tsu/rx_rcst.v
../rtl/tsu/xge_crc.v
../rtl/tsu/tx_parse.v
../rtl/tsu/tx_emb_ts.v
../rtl/tsu/tx_rcst.v
../rtl/tsu/ipv6_udp_chksum.v

../rtl/cvt/gfe_cvt.v
../rtl/cvt/xgmii_dr2sr.v

../rtl/top/pbus_bridge.v
../rtl/top/ptpv2_core_wrapper.v
../rtl/top/ptpv2_core.v

//testbench files
../tb/channel_model.v
../tb/clkgen.v
../tb/frame_monitor.v
../tb/harness.v
../tb/ptp_agent.v
../tb/ptpv2_endpoint.v

//testcase files
../tc/tc_rtc.v
../tc/tc_rapid_ptp_test.v

//include files
+incdir+../rtl/inc
