/* Copyright (c) 2015 by the author(s)
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
 * This file implements the Arbiter on the output ports.
 *
 * Author(s):
 *   Stefan Wallentowitz <stefan.wallentowitz@tum.de>, (original work)
 *   <stevenway-s> at GitHub. 
 *      Modifications: disable 2 registers: 'sel_channel' and 'channel_selected'
 *      To do: 
 *
 */

`include "lisnoc_def.vh"

module lisnoc_output_arbiter(/*AUTOARG*/
   // Outputs
   fifo_ready_o, link_valid_o, link_flit_o,
   // Inputs
   clk, rst, fifo_valid_i, fifo_flit_i, link_ready_i
   );
   
   // parameters for flit
   parameter flit_data_width = 32;
   parameter flit_type_width = 2;
   localparam flit_width = flit_data_width+flit_type_width;
   // parameters for virtual channels
   parameter vchannels = 1;
   // localparam CHANNEL_WIDTH = $clog2(vchannels); // for vchannels > 1, function $clog2(1) = 0
   localparam CHANNEL_WIDTH = 1; // for vchannels = 1


   input                             clk, rst;
   // Output FIFO Side
   input [vchannels-1:0]             fifo_valid_i;
   input [vchannels*flit_width-1:0]  fifo_flit_i;
   output reg [vchannels-1:0]        fifo_ready_o;
   // Link Side 
   output reg [vchannels-1:0]        link_valid_o;
   output reg [flit_width-1:0]       link_flit_o;
   input [vchannels-1:0]             link_ready_i;


   // channel that was last served in the round robin process
   reg [CHANNEL_WIDTH-1:0]           channel;       // the final register
   reg [CHANNEL_WIDTH-1:0]           nxt_channel;   // the working register

   wire [vchannels-1:0]              serviceable;
   assign serviceable = fifo_valid_i & link_ready_i;  
   // bit-wise AND, determining the serviceable virtual channels


   // reg [CHANNEL_WIDTH-1:0]           sel_channel;
   // reg                               channel_selected;

   wire [flit_width-1:0]             fifo_flit_i_array [0:vchannels-1];
   
   genvar v;
   for (v=0;v<vchannels;v=v+1) begin
      assign fifo_flit_i_array[v] = fifo_flit_i[(v+1)*flit_width-1:v*flit_width];
   end

   assign link_flit_o = fifo_flit_i_array[channel];
  
   
   // Logic of V-channel Selection
   always @ (rst, channel, serviceable) begin
      link_valid_o = {vchannels{1'b0}};
      fifo_ready_o = {vchannels{1'b0}};
      if (rst)
        channel = {CHANNEL_WIDTH{1'b0}};
      else begin
        nxt_channel = channel;
        for(int c=0; c<vchannels; c=c+1) begin: Sel_Channel
            if (serviceable[c]) begin
               nxt_channel = c; // the #c channel is selected for output
               // link_flit_o = fifo_flit_i_array[channel];
               link_valid_o[c] = 1'b1; // tell Links it is sending output
               fifo_ready_o[c] = 1'b1; // tell o_fifo the input is selected
               break; // stop checking
            end // if
        end // for
      end // else
   end // always

   always @(posedge clk) begin
      channel <= nxt_channel;
   end

endmodule // lisnoc_output_arbiter

`include "lisnoc_undef.vh"
