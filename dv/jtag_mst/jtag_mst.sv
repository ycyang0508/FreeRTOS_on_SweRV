//----------------------------------------------------------------------
//  Module      : jtag_mst
//  Created     : Fri Jul  5 17:40:42 2019
//  Modified    : $Id$
//
//  Note        :
//
//----------------------------------------------------------------------
`timescale 1ns / 10ps

module jtag_mst #(
    parameter   JTAG_PERIOD = 1000,
    parameter   JTAG_IRLEN = 4)
(
  output logic   jtag_trst,
  output logic   jtag_tck,
  output logic   jtag_tms,
  output logic   jtag_tdi,
  input wire     jtag_tdo

);

`include "inc_jtag.v"


initial
begin

    jtag_trst = 1'b0;
    #5
    jtag_trst = 1'b1;
    #5
    jtag_trst = 1'b0;
    
    jtag_tdi = 1'b0;
    jtag_tms = 1'b0;
    jtag_tck = 1'b0;


   
end

endmodule : jtag_mst

