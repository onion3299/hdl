# ip

source ../scripts/adi_env.tcl
source $ad_hdl_dir/library/scripts/adi_ip.tcl

adi_ip_create axi_pulse_gen
adi_ip_files axi_pulse_gen [list \
  "$ad_hdl_dir/library/common/ad_rst.v" \
  "$ad_hdl_dir/library/common/up_axi.v" \
  "$ad_hdl_dir/library/xilinx/common/ad_rst_constr.xdc" \
  "$ad_hdl_dir/library/common/util_pulse_gen.v" \
  "axi_pulse_gen.v"]

adi_ip_properties axi_pulse_gen

adi_ip_add_core_dependencies { \
	analog.com:user:util_cdc:1.0 \
}

ipx::save_core [ipx::current_core]
