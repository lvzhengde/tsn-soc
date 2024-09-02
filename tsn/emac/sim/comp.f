//rtl files
../rtl/emac_clk_ctrl.v
../rtl/emac_phy_intf.v
../rtl/emac_registers.v
../rtl/emac_top.v
../rtl/emac_tx.v
../rtl/emac_rmon.v
../rtl/emac_rx.v
../rtl/eth_miim.v
../rtl/eth_register.v
../rtl/miim/eth_clockgen.v
../rtl/miim/eth_outputcontrol.v
../rtl/miim/eth_shiftreg.v
../rtl/tech/clk_div2.v
../rtl/tech/clk_switch.v
../rtl/tech/dpram.v
../rtl/tx/emac_crc_gen.v
../rtl/tx/emac_flow_ctrl.v
../rtl/tx/emac_random_gen.v
../rtl/tx/emac_tx_ctrl.v
../rtl/tx/emac_tx_fifo.v
../rtl/rx/emac_broadcast_filter.v
../rtl/rx/emac_crc_chk.v
../rtl/rx/emac_rx_addr_chk.v
../rtl/rx/emac_rx_ctrl.v
../rtl/rx/emac_rx_fifo.v
../rtl/rmon/emac_rmon_addr_gen.v
../rtl/rmon/emac_rmon_ctrl.v
../rtl/rmon/emac_rmon_dpram.v

//testbench files
../tb/bus_master.v
../tb/ephy_model.v
../tb/tb_emac.v
../tb/emac_user_agent.v

//simulation top level
../sim/sim_emac.v

//include files
+incdir+../rtl/inc+../tb+../tc                                           

