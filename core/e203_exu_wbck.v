 /*                                                                      
 Copyright 2017 Silicon Integrated Microelectronics, Inc.                
                                                                         
 Licensed under the Apache License, Version 2.0 (the "License");         
 you may not use this file except in compliance with the License.        
 You may obtain a copy of the License at                                 
                                                                         
     http://www.apache.org/licenses/LICENSE-2.0                          
                                                                         
  Unless required by applicable law or agreed to in writing, software    
 distributed under the License is distributed on an "AS IS" BASIS,       
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and     
 limitations under the License.                                          
 */                                                                      
                                                                         
                                                                         
                                                                         
//=====================================================================
//--        _______   ___
//--       (   ____/ /__/
//--        \ \     __
//--     ____\ \   / /
//--    /_______\ /_/   MICROELECTRONICS
//--
//=====================================================================
//
// Designer   : Bob Hu
//
// Description:
//  The Write-Back module to arbitrate the write-back request to regfile
//
// ====================================================================

`include "e203_defines.v"

module e203_exu_wbck(

  //////////////////////////////////////////////////////////////
  // The ALU Write-Back Interface
  input  alu_wbck_i_valid, // Handshake valid
  output alu_wbck_i_ready, // Handshake ready
  input  [`E203_XLEN-1:0] alu_wbck_i_wdat,
  input  [`E203_RFIDX_WIDTH-1:0] alu_wbck_i_rdidx,
  // If ALU have error, it will not generate the wback_valid to wback module
      // so we dont need the alu_wbck_i_err here

  //////////////////////////////////////////////////////////////
  // The Longp Write-Back Interface
  input  longp_wbck_i_valid, // Handshake valid
  output longp_wbck_i_ready, // Handshake ready
  input  [`E203_FLEN-1:0] longp_wbck_i_wdat,
  input  [5-1:0] longp_wbck_i_flags,
  input  [`E203_RFIDX_WIDTH-1:0] longp_wbck_i_rdidx,
  input  longp_wbck_i_rdfpu,

  //////////////////////////////////////////////////////////////
  // The Final arbitrated Write-Back Interface to Regfile
  output  rf_wbck_o_ena,
  output  [`E203_XLEN-1:0] rf_wbck_o_wdat,
  output  [`E203_RFIDX_WIDTH-1:0] rf_wbck_o_rdidx,


  
  input  clk,
  input  rst_n
  );

  wire [`E203_XLEN-1:0] alu_wbck_i_wdat_;
  wire [`E203_RFIDX_WIDTH-1:0] alu_wbck_i_rdidx_;
  wire [`E203_FLEN-1:0] longp_wbck_i_wdat_;
  wire [5-1:0] longp_wbck_i_flags_;
  wire [`E203_RFIDX_WIDTH-1:0] longp_wbck_i_rdidx_;
  wire longp_wbck_i_rdfpu_;
  wire alu_wbck_i_valid_;
  wire longp_wbck_i_valid_;

  sirv_gnrl_dfflr #(`E203_XLEN) alu_iwdat(1, alu_wbck_i_wdat[`E203_XLEN-1:0], alu_wbck_i_wdat_, clk, rst_n);
  sirv_gnrl_dfflr #(`E203_RFIDX_WIDTH) alu_rdidx(1, alu_wbck_i_rdidx[`E203_RFIDX_WIDTH-1:0], alu_wbck_i_rdidx_, clk, rst_n);
  sirv_gnrl_dfflr #(`E203_FLEN) longp_wdat(1, longp_wbck_i_wdat[`E203_FLEN-1:0], longp_wbck_i_wdat_, clk, rst_n);
  sirv_gnrl_dfflr #(5) longp_flags(1, longp_wbck_i_flags[5-1:0], longp_wbck_i_flags_, clk, rst_n);
  sirv_gnrl_dfflr #(`E203_RFIDX_WIDTH) longp_rdidx(1, longp_wbck_i_rdidx[`E203_RFIDX_WIDTH-1:0], longp_wbck_i_rdidx_, clk, rst_n);
  sirv_gnrl_dfflr #(1) longp_rdfpu(1, longp_wbck_i_rdfpu, longp_wbck_i_rdfpu_, clk, rst_n);
  sirv_gnrl_dfflr #(1) longp_valid(1, longp_wbck_i_valid, longp_wbck_i_valid_, clk, rst_n);
  sirv_gnrl_dfflr #(1) alu_valid(1, alu_wbck_i_valid, alu_wbck_i_valid_, clk, rst_n);

  // The ALU instruction can write-back only when there is no any 
  //  long pipeline instruction writing-back
  //    * Since ALU is the 1 cycle instructions, it have lowest 
  //      priority in arbitration
  wire wbck_ready4alu = (~longp_wbck_i_valid_);
  wire wbck_sel_alu = alu_wbck_i_valid_ & wbck_ready4alu;
  // The Long-pipe instruction can always write-back since it have high priority 
  wire wbck_ready4longp = 1'b1;
  wire wbck_sel_longp = longp_wbck_i_valid_ & wbck_ready4longp;


  //////////////////////////////////////////////////////////////
  // The Final arbitrated Write-Back Interface
  wire rf_wbck_o_ready = 1'b1; // Regfile is always ready to be write because it just has 1 w-port

  wire wbck_i_ready;
  wire wbck_i_valid;
  wire [`E203_FLEN-1:0] wbck_i_wdat;
  wire [5-1:0] wbck_i_flags;
  wire [`E203_RFIDX_WIDTH-1:0] wbck_i_rdidx;
  wire wbck_i_rdfpu;

  assign alu_wbck_i_ready = ~longp_wbck_i_valid;
  assign longp_wbck_i_ready = 1'b1;
  // assign alu_wbck_i_ready   = wbck_ready4alu   & wbck_i_ready;
  // assign longp_wbck_i_ready = wbck_ready4longp & wbck_i_ready;

  assign wbck_i_valid = wbck_sel_alu ? alu_wbck_i_valid_ : longp_wbck_i_valid_;
  `ifdef E203_FLEN_IS_32//{
  assign wbck_i_wdat  = wbck_sel_alu ? alu_wbck_i_wdat_  : longp_wbck_i_wdat_;
  `else//}{
  assign wbck_i_wdat  = wbck_sel_alu ? {{`E203_FLEN-`E203_XLEN{1'b0}},alu_wbck_i_wdat_}  : longp_wbck_i_wdat_;
  `endif//}
  assign wbck_i_flags = wbck_sel_alu ? 5'b0  : longp_wbck_i_flags_;
  assign wbck_i_rdidx = wbck_sel_alu ? alu_wbck_i_rdidx_ : longp_wbck_i_rdidx_;
  assign wbck_i_rdfpu = wbck_sel_alu ? 1'b0 : longp_wbck_i_rdfpu_;

  // If it have error or non-rdwen it will not be send to this module
  //   instead have been killed at EU level, so it is always need to 
  //   write back into regfile at here
  assign wbck_i_ready = rf_wbck_o_ready;
  wire rf_wbck_o_valid = wbck_i_valid;

  wire wbck_o_ena = rf_wbck_o_valid & rf_wbck_o_ready;
  
  wire enable = wbck_o_ena & (~wbck_i_rdfpu);
  // sirv_gnrl_dfflr #(`E203_XLEN) wbck_data(1, wbck_i_wdat[`E203_XLEN-1:0], rf_wbck_o_wdat, clk, rst_n);
  // sirv_gnrl_dfflr #(`E203_RFIDX_WIDTH) wbck_rdidx(1, wbck_i_rdidx, rf_wbck_o_rdidx, clk, rst_n);
  // sirv_gnrl_dfflr #(1) wbck_enable(1, enable, rf_wbck_o_ena, clk, rst_n);
  assign rf_wbck_o_ena   = wbck_o_ena & (~wbck_i_rdfpu);
  assign rf_wbck_o_wdat  = wbck_i_wdat[`E203_XLEN-1:0];
  assign rf_wbck_o_rdidx = wbck_i_rdidx;


endmodule                                      
                                               
                                               
                                               
