`timescale 1ns / 1ps
/* Copyright (c) 2021 by the author(s)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * =============================================================================
 *
 * This file implements the Arbiter on the Switching Stage.
 *   - This Arbiter is the first structure in Output Port.
 *   - This Arbiter is set between the Switching Structure and the Ouput FIFO.
 * This file is used to replace the "lisnoc_router_arbiter.sv" file
 *
 * Author(s):
 *   <stevenway-s> at GitHub,
 *   Stefan Wallentowitz <stefan.wallentowitz@tum.de> (original work).
 *   
 * Modified by <stevenway-s> at GitHub. 
 *   Modifications: Redesign the structure logic, 
 *                  while keeping the original I/O interfaces.
 *
 */

`include "lisnoc_def.vh"

module lisnoc_switch_arbiter(
    // CLK and RST signals
    clk, rst,
    // Output Side: Output FIFO
    flit_o, valid_o, ready_o,
    // Input Side: Switching Structure
    flit_i, request_i, read_i
   );


// Parameter List
   parameter flit_data_width = 32;
   parameter flit_type_width = 2;
   localparam flit_width = flit_data_width+flit_type_width;
   // parameter vchannels = 1; // not used in this design
   parameter ports = 5;
   localparam ports_width = $clog2(ports);
   
   
// I/O Interfaces 
   input clk;
   input rst;
   // Input Side : Input FIFO
   input      [ports*flit_width-1:0]  flit_i; // flit data from all input ports
   input      [ports-1:0]             request_i; // request signal from each vc of each input port
   output     [ports-1:0]             read_i; // select signal for each vc of each input port
   // Output Side : Output FIFO
   output reg [flit_width-1:0]        flit_o;
   output                             valid_o;  // request a place in FIFO
   input                              ready_o;  // There is an available place in FIFO


// Internal Wiring   
    // State Pointer
   reg [ports_width-1:0]      port_selc;  // Specify the port that is currently Selected
   reg [ports_width-1:0]      prev_port;  // The port selection from the previous clock cycle (memory)
   // Split the concatenated input flit and signals
   wire [flit_width-1:0]      flit_i_array [0:ports-1];
   wire [flit_type_width-1:0] flit_type;
   genvar p;
   generate
      for (p=0; p<ports; p=p+1)
         assign flit_i_array[p] = flit_i[(p+1)*flit_width-1:p*flit_width];
   endgenerate


// Wire Connection: Logic Design 
    // output flit
    //assign flit_o = flit_i_array[port_selc];
    //assign flit_type = flit_i_array[port_selc][flit_width-1 : flit_width-flit_type_width];
    // output signals
    assign valid_o = request_i ? 1'b1 : 1'b0;
    assign read_i = request_i & {ports{ready_o}};


// Function Blcoks : Functional Design
   // Function #1: Select input flit from the concatenated input data, based on the signal 'request_i'
    always @(rst,request_i) begin
        if(rst)
            port_selc = 0;
        else begin
            port_selc = prev_port;
            for (int i=0; i<ports; i=i+1) begin: Select_Input_Flit
                if(request_i[i]) begin  // if more than one bit is '1', then congestion happens
                    port_selc = i;
                    break;  // for congestions, only select one input, and abandon all others
                end // if
            end // for
        end // else    
    end // always
    
    // Function #2: Sychronouly update the current port selection, and the output flit
    always @(posedge clk) begin
        prev_port <= port_selc;
        flit_o <= flit_i_array[port_selc];
    end

endmodule // noc_switch_arbiter

`include "lisnoc_undef.vh"
    

