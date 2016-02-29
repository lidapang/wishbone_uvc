//*******************************************************************
// Copyright 2016 Opening Vision  (Shanghai) Inc
// All Rights Reserved.
// THIS WORK CONTAINS TRADE SECRET AND PROPRIETARY INFORMATION WHICH IS THE PROPERTY OF
// OPENING VISION INC OR ITS LICENSORS AND IS SUBJECT TO LICENSE TERMS.
//
//  Language : SystemVerilog 
//  Version  : 2.3
//  Author   : Alex Zhang
//  Date     : 02-26-2016
// (begin source code)
`ifndef WISHBONE_DRIVER__SVH
`define WISHBONE_DRIVER__SVH
class wb_master_dirver #(
  int WB_ADDR_W = 32,
  int WB_DATA_W = 32,
  int WB_TGD_W  = 8,
  int WB_TGA_W  = 4,
  int WB_TGC_W  = 2
)extends uvm_driver#(wb_master_rw_transaction#(WB_ADDR_W, WB_DATA_W, WB_TGD_W, WB_TGA_W, WB_TGC_W));
  typedef wb_master_dirver#(WB_ADDR_W, WB_DATA_W, WB_TGD_W, WB_TGA_W, WB_TGC_W) wb_master_driver_t;
  `uvm_component_param_utils(wb_master_driver_t)
 
 typedef wb_master_rw_transaction#(WB_ADDR_W, WB_DATA_W, WB_TGD_W, WB_TGA_W, WB_TGC_W)  wb_master_txn_t;
 typedef virtual ovi_wishbone #(
   .WB_ADDR_W (WB_ADDR_W),
   .WB_DATA_W (WB_DATA_W),
   .WB_TGD_W  (WB_TGD_W ),
   .WB_TGA_W  (WB_TGA_W ),
   .WB_TGC_W  (WB_TGC_W )
 ) wb_vif_t;
 wb_vif_t  wb_if;
 function new (string name, uvm_component parent);
   super.new(name, parent);
 endfunction 
 
 function void build_phase (uvm_phase phase);
   super.build_phase (phase);
   uvm_config_db #(wb_vif_t)::get(this, "", "WISHBONE_IF", wb_if);
   if (wb_if == null)
     `uvm_error("Wishbone Driver", "Interface for the wb_driver is no set before use")

 endfunction 
 
 task run_phase (uvm_phase phase);
   forever begin 
     seq_item_port.get_next_item(req);
     send (req);
     seq_item_port.item_done();
   end 
 endtask

 task  send (wb_master_txn_t txn);
   begin 
     if (txn.len_bursts==1) begin 
         @(posedge wb_if.wb_clk);
         if (txn.delay >0) 
           repeat (txn.delay) @(posedge wb_if.wb_clk);
         wb_if.wb_adr_o <= txn.addr;
         wb_if.wb_dat_o <= txn.data[0]; 
         wb_if.wb_sel_o <= txn.sel[0];
         wb_if.wb_tgd_o <= txn.tgd[0];
         wb_if.wb_cyc_o <= 1'b1   ;
         wb_if.wb_stb_o <= 1'b1   ;
         wb_if.wb_cti_o <= txn.cti;
         wb_if.wb_bte_o <= txn.bte;
         wb_if.wb_we_o  <= txn.read_or_write==WB_WRITE ? 1'b1 : 1'b0 ;
         wb_if.wb_tgc_o <= txn.tgc;
         wb_if.wb_tga_o <= txn.tga;
         wait (wb_if.wb_ack_i==1'b1);
     end else begin 
       //Wrapper address will be back to back
       for (int i =0; i< txn.len_bursts; i= i+1) begin 
         @(posedge wb_if.wb_clk);
         wb_if.wb_adr_o <= txn.addr_bursts[i];
         wb_if.wb_dat_o <= txn.data[i]; 
         wb_if.wb_sel_o <= txn.sel[i];
         wb_if.wb_tgd_o <= txn.tgd[i];
         wb_if.wb_cyc_o <= 1'b1   ;
         wb_if.wb_stb_o <= 1'b1   ;
         wb_if.wb_cti_o <= txn.cti[i];
         wb_if.wb_bte_o <= txn.bte[i];
         wb_if.wb_we_o  <= txn.read_or_write==WB_WRITE ? 1'b1 : 1'b0 ;
         wb_if.wb_tgc_o <= txn.tgc ;
         wb_if.wb_tga_o <= txn.tga ;
         wait (wb_if.wb_ack_i==1'b1);
       end
       if (txn.delay >0) 
         repeat (txn.delay) @(posedge wb_if.wb_clk);
     end    
   end 
 endtask 
endclass

`endif
