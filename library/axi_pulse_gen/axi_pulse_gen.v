// ***************************************************************************
// ***************************************************************************
// Copyright 2014 - 2019 (c) Analog Devices, Inc. All rights reserved.
//
// In this HDL repository, there are many different and unique modules, consisting
// of various HDL (Verilog or VHDL) components. The individual modules are
// developed independently, and may be accompanied by separate and unique license
// terms.
//
// The user should read each of these license terms, and understand the
// freedoms and responsibilities that he or she has by using this source/core.
//
// This core is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE.
//
// Redistribution and use of source or resulting binaries, with or without modification
// of this file, are permitted under one of the following two license terms:
//
//   1. The GNU General Public License version 2 as published by the
//      Free Software Foundation, which can be found in the top level directory
//      of this repository (LICENSE_GPL2), and also online at:
//      <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>
//
// OR
//
//   2. An ADI specific BSD license, which can be found in the top level directory
//      of this repository (LICENSE_ADIBSD), and also on-line at:
//      https://github.com/analogdevicesinc/hdl/blob/master/LICENSE_ADIBSD
//      This will allow to generate bit files and not release the source code,
//      as long as it attaches to an ADI device.
//
// ***************************************************************************
// ***************************************************************************
`timescale 1ns/100ps

module axi_pulse_gen #(

  parameter [0:0] ASYNC_CLK_EN = 1,
  parameter       PULSE_WIDTH = 7,
  parameter       PULSE_PERIOD = 10 )(

  // axi interface

  input                   s_axi_aclk,
  input                   s_axi_aresetn,
  input                   s_axi_awvalid,
  input       [15:0]      s_axi_awaddr,
  input       [ 2:0]      s_axi_awprot,
  output                  s_axi_awready,
  input                   s_axi_wvalid,
  input       [31:0]      s_axi_wdata,
  input       [ 3:0]      s_axi_wstrb,
  output                  s_axi_wready,
  output                  s_axi_bvalid,
  output      [ 1:0]      s_axi_bresp,
  input                   s_axi_bready,
  input                   s_axi_arvalid,
  input       [15:0]      s_axi_araddr,
  input       [ 2:0]      s_axi_arprot,
  output                  s_axi_arready,
  output                  s_axi_rvalid,
  output      [ 1:0]      s_axi_rresp,
  output      [31:0]      s_axi_rdata,
  input                   s_axi_rready,
  input                   ext_clk,
  output                  pulse);

  // internal registers

  reg             up_wack = 'd0;
  reg     [31:0]  up_rdata = 'd0;
  reg             up_rack = 'd0;
  reg     [31:0]  up_pulse_width = 'd0;
  reg     [31:0]  up_pulse_period = 'd0;
  reg             up_load_config = 1'b0;
  reg             up_resetn;

  // internal signals

  wire            clk;
  wire            up_clk;
  wire            up_rstn;
  wire            up_rreq_s;
  wire    [ 1:0]  up_raddr_s;
  wire            up_wreq_s;
  wire    [ 1:0]  up_waddr_s;
  wire    [31:0]  up_wdata_s;
  wire    [31:0]  pulse_width_s;
  wire    [31:0]  pulse_period_s;
  wire            load_config_s;
  wire            resetn_pulse_gen;

  assign up_clk = s_axi_aclk;
  assign up_rstn = s_axi_aresetn;

  always @(posedge up_clk) begin
    if (up_rstn == 0) begin
      up_wack <= 'd0;
      up_pulse_period <= 'd0;
      up_pulse_width <= 'd0;
      up_load_config <= 1'b0;
      up_resetn <= 1'b1;
    end else begin
      up_wack <= up_wreq_s;
      if ((up_wreq_s == 1'b1) && (up_waddr_s == 2'h0)) begin
        up_resetn <= up_wdata_s[0];
        up_load_config <= up_wdata_s[1];
      end else begin
        up_load_config <= 1'b0;
      end
      if ((up_wreq_s == 1'b1) && (up_waddr_s == 2'h1)) begin
        up_pulse_period <= up_wdata_s;
      end
      if ((up_wreq_s == 1'b1) && (up_waddr_s == 2'h2)) begin
        up_pulse_width <= up_wdata_s;
      end
    end
  end

  always @(posedge up_clk) begin
    if (up_rstn == 0) begin
      up_rack <= 'd0;
      up_rdata <= 'd0;
    end else begin
      up_rack <= up_rreq_s;
      if (up_rreq_s == 1'b1) begin
        case (up_raddr_s)
          2'h0: up_rdata <= up_resetn;
          2'h1: up_rdata <= up_pulse_period;
          2'h2: up_rdata <= up_pulse_width;
          default: up_rdata <= 0;
        endcase
      end else begin
        up_rdata <= 32'd0;
      end
    end
  end

  generate
  if (ASYNC_CLK_EN) begin : counter_external_clock

    assign clk = ext_clk;

    ad_rst i_d_rst_reg (
      .rst_async (up_resetn),
      .clk (clk),
      .rstn (resetn_pulse_gen),
      .rst ());

    sync_data #(
      .NUM_OF_BITS (32),
      .ASYNC_CLK (1))
    i_pulse_period_sync (
      .in_clk (up_clk),
      .in_data (up_pulse_period),
      .out_clk (clk),
      .out_data (pulse_period_s));

    sync_data #(
      .NUM_OF_BITS (32),
      .ASYNC_CLK (1))
    i_pulse_width_sync (
      .in_clk (up_clk),
      .in_data (up_pulse_width),
      .out_clk (clk),
      .out_data (pulse_width_s));

    sync_event #(
      .NUM_OF_EVENTS (1),
      .ASYNC_CLK (1))
    i_load_config_sync (
      .in_clk (up_clk),
      .in_event (up_load_config),
      .out_clk (clk),
      .out_event (load_config_s));

  end else begin : counter_sys_clock        // counter is running on system clk

    assign clk = up_clk;
    assign resetn_pulse_gen = up_resetn;
    assign pulse_period_s = up_pulse_period;
    assign pulse_width_s = up_pulse_width;
    assign load_config_s = up_load_config;

  end
  endgenerate

  util_pulse_gen  #(
    .PULSE_WIDTH(PULSE_WIDTH),
    .PULSE_PERIOD(PULSE_PERIOD))
  util_pulse_gen_i(
    .clk (clk),
    .rstn (resetn_pulse_gen),
    .pulse_width (pulse_width_s),
    .pulse_period (pulse_period_s),
    .load_config (load_config_s),
    .pulse (pulse));

  up_axi #(
    .ADDRESS_WIDTH(2))
  i_up_axi (
    .up_rstn (up_rstn),
    .up_clk (up_clk),
    .up_axi_awvalid (s_axi_awvalid),
    .up_axi_awaddr (s_axi_awaddr),
    .up_axi_awready (s_axi_awready),
    .up_axi_wvalid (s_axi_wvalid),
    .up_axi_wdata (s_axi_wdata),
    .up_axi_wstrb (s_axi_wstrb),
    .up_axi_wready (s_axi_wready),
    .up_axi_bvalid (s_axi_bvalid),
    .up_axi_bresp (s_axi_bresp),
    .up_axi_bready (s_axi_bready),
    .up_axi_arvalid (s_axi_arvalid),
    .up_axi_araddr (s_axi_araddr),
    .up_axi_arready (s_axi_arready),
    .up_axi_rvalid (s_axi_rvalid),
    .up_axi_rresp (s_axi_rresp),
    .up_axi_rdata (s_axi_rdata),
    .up_axi_rready (s_axi_rready),
    .up_wreq (up_wreq_s),
    .up_waddr (up_waddr_s),
    .up_wdata (up_wdata_s),
    .up_wack (up_wack),
    .up_rreq (up_rreq_s),
    .up_raddr (up_raddr_s),
    .up_rdata (up_rdata),
    .up_rack (up_rack));

endmodule
