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
 * This file implements the Routing Structure on the input ports.
 *
 * Author(s):
 *   <stevenway-s> at GitHub,
 *   Stefan Wallentowitz <stefan.wallentowitz@tum.de> (original work).
 *   
 * Modified by <stevenway-s> at GitHub. 
 *   Modifications: get rid of the 'active' checker, simpler logic design
 *   To do: one flaw: for multiple virtual channels and out-of-order flits transfer
 *          So far, there is no way to know a PAYLOAD-type/LAST-type flit 
 *          belond to which Header-type flit
 *   Note: 0. Whenever there is an input flit ('i_valid' is ON), 
 *            the structure should check the Look-Up Table and send request via 'o_valid',
 *            regardless of if the corresponding ouput port is ready.
 *         1. After the request is sent, the structure is wainting for the ready respond 
 *            from thr 'o_ready'.
 *         2. After the requested output port is ready, the structure sends notification
 *            back to the input FIFO.
 *         3. Whenever the input FIFO gets the ready notification from the routing structure,
 *            if its 'o_valid' is ON, then the fifo pops the first flit in it.
 *
 */

`include "lisnoc_def.vh"

module lisnoc_input_route (
   // Outputs
   fifo_ready, switch_request, switch_flit,
   // Inputs
   clk, rst, fifo_flit, fifo_valid, switch_read
   );

   parameter flit_data_width = 32;
   parameter flit_type_width = 2;
   localparam flit_width = flit_data_width+flit_type_width;
   parameter ph_dest_width = 5; // width of code that indicates the destination node

   // The number of destinations is a parameter of each port.
   // It should in general be equal for all routers in a NoC and
   // must be within the range defined by FLIT_DEST_WIDTH.
   parameter num_dests = 1;

   // The number of directions of each router is the number of output ports.
   parameter directions = 1;

   // The externally defined destination->direction lookup
   // It is the concatenation of directions-width elements starting
   // with destiantion 0:
   //  { destination0_direction, destination1_direction, ... }
   parameter [directions*num_dests-1:0] lookup = {num_dests*directions{1'b0}};

   // General ports
   input clk;
   input rst;
   // The fifo interface
   input [flit_width-1:0]  fifo_flit;  // current FIFO output
   input                   fifo_valid; // current output valid
   output                  fifo_ready; // current output has been registered
   // The switch interface
   output reg [directions-1:0]  switch_request;     // direction requests
   wire [directions-1:0]        nxt_switch_request; // combinatorial signal for this variable
   output reg [flit_width-1:0]  switch_flit;        // corresponding flit
   input [directions-1:0]       switch_read;        // destination acknowledge
   
 
   // Internal States 
   reg [directions-1:0]     cur_select;     // This stores the current selection
   wire [directions-1:0]    nxt_cur_select; // combinational signal


   // The lookup vector is generated for better code readability and
   // is in fact the lookup parameter in another representation
   wire [directions-1:0]    lookup_vector [0:num_dests-1];
   // generate this representation
   genvar                   i;
   generate
      for(i=0;i<num_dests;i=i+1) begin // array is indexed by the desired destination
         // The entries of this array are subranges from the parameter, where
         // the indexing is reversed (num_dests-i-1)!
         assign lookup_vector[num_dests-i-1] = lookup[(i+1)*directions-1:i*directions];
      end
   endgenerate


   // Some bit selections for better readability below
   wire [flit_type_width-1:0] flit_type;
   assign flit_type = fifo_flit[flit_width-1:flit_width-flit_type_width];

   wire [flit_data_width-1:0] flit_header;
   assign flit_header = fifo_flit[flit_data_width-1:0];

   wire [ph_dest_width-1:0] flit_dest;
   assign flit_dest = flit_header[flit_data_width-1:flit_data_width-ph_dest_width];

   
   // Generating the current destination selection
   assign nxt_cur_select = // check if the input flit is valid and if it is the first flit in the packet
                           (fifo_valid && (flit_type==`FLIT_TYPE_HEADER || flit_type==`FLIT_TYPE_SINGLE))?
                           // .. take selection from the lookup vector
                           lookup_vector[flit_dest] :
                           // take current value otherwise
                           cur_select;
                           
   // Bit-wise AND, checking if the requested direction in the next time cycle is available to go
   assign fifo_ready = ( // also check if the input flit is valid
                         fifo_valid && (nxt_cur_select & switch_read)
                        )? 1'b1 : 1'b0;
   
   // Generate the request for the output
   assign nxt_switch_request =  // check if this routing structure is ready ..
               fifo_valid? 
               // .. issue the current route request
               nxt_cur_select
               // .. and nothing otherwise.
               : {directions{1'b0}};
   
   // Synchronos Updates
   always @(posedge clk) begin
      if (rst) begin
         switch_request <= {directions{1'b0}};
         cur_select     <= {directions{1'b0}};
      end else begin
         cur_select     <= nxt_cur_select;
         switch_request <= nxt_switch_request;

         // Additionally check whether
         if (fifo_ready)
            switch_flit <= fifo_flit;
         end
   end

endmodule

`include "lisnoc_undef.vh"
