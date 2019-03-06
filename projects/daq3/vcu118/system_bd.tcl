
## FIFO depth is 4Mb - 250k samples
set adc_fifo_address_width 16

## FIFO depth is 4Mb - 250k samples
set dac_fifo_address_width 15


source $ad_hdl_dir/projects/common/vcu118/vcu118_system_bd.tcl
source $ad_hdl_dir/projects/common/xilinx/adcfifo_bd.tcl
source $ad_hdl_dir/projects/common/xilinx/dacfifo_bd.tcl
source ../common/daq3_bd.tcl

ad_ip_parameter axi_ad9152_xcvr CONFIG.XCVR_TYPE 4
ad_ip_parameter axi_ad9680_xcvr CONFIG.XCVR_TYPE 4

ad_ip_parameter util_daq3_xcvr CONFIG.XCVR_TYPE 4
ad_ip_parameter util_daq3_xcvr CONFIG.QPLL_FBDIV 20
ad_ip_parameter util_daq3_xcvr CONFIG.QPLL_REFCLK_DIV 1

