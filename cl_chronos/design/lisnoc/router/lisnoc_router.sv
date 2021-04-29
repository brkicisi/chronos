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
 * This is the generic router toplevel.
 *
 * (c) 2021 by the author(s)
 *
 * Author(s):
 *   Stefan Wallentowitz <stefan.wallentowitz@tum.de>,
 *   <stevenway-s> at GitHub.
 *
 * Modified by <stevenway-s> at GitHub.
 *    Modifications : Added Synchronization for switch_in flits.
 *                    Rewrote the file, while keeping the original I/O interfaces
 *                    and basic structure. Now the Switching Structure is synchronous.
 *    
 *           To do : 1. Solve congestion condition.
 *               When multiple input flits are requesting the same output port,
 *               a congestion cnodition occurs. In this case, only one flit is
 *               selected (priority: input port [0] > [1] > [2] > [3] > [4]), and
 *               all the other flits are abandoned. 
 *               --> We will have data miss.
 *            2. Make virtual channels work
 *               One solution for the congestion conditions is applying virtual
 *               channels. However, virtual channels are not available (vchannels must be '1')
 *               in the current version. Extra work will be done in the future.
 *            3. Each transfer of a single flit must tale at least 4 clock cycles. The whole router
 *               design will be modified to be fully synchronous for all signals and data. 
 *               The whole routing process will be splitted into multiple stages so that 
 *               pipelining can be applied.
 *
 */

`include "lisnoc_def.vh"

module lisnoc_router( /*AUTOARG*/


// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
// Debug Area #1
debug_in_all_flits, debug_sync_all_flits, debug_sin_flit, debug_sin_request, debug_sout_request, 
debug_sout_read, debug_sin_read, debug_oflit_array,
// from input port
debug_ip_fifo_flit_show,
// from output port
debug_op_fifo_ready, debug_op_oparb_ready,
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *  

    
    
   // Outputs
   out_flit, out_valid, in_ready,
   // Inputs
   clk, rst, out_ready, in_flit, in_valid
   );

   // FIXME The lowercase parameters are legacy, replace any use by the
   // uppercase variant!
   parameter  flit_data_width = 32;
   parameter  flit_type_width = 2;

   parameter  num_dests = 32;
   parameter  ph_dest_width = 5;

   parameter use_prio = 0;
   parameter ph_prio_width = 4;

   parameter vchannels = 1;     // Disable virtual channels for now

   parameter input_ports = 5;
   parameter output_ports = 5;

   parameter in_fifo_length = 4;
   parameter out_fifo_length = 4;

   parameter [output_ports*num_dests-1:0] lookup = {num_dests*output_ports{1'b0}};

   // Width of the actual flit data
   parameter  FLIT_DATA_WIDTH = flit_data_width;
   // Type width, use 2 for the moment
   parameter  FLIT_TYPE_WIDTH = flit_type_width;
   localparam FLIT_WIDTH = FLIT_DATA_WIDTH + FLIT_TYPE_WIDTH;

   // Number of destinations in the entire NoC
   parameter  NUM_DESTS = num_dests;
   // Width of the destination field in the packet header
   parameter  PH_DEST_WIDTH = ph_dest_width;

   // Use priorities
   parameter USE_PRIO = use_prio;
   // Width of the priority field in the packet header
   parameter PH_PRIO_WIDTH = ph_prio_width;

   // Number of virtual channels
   parameter VCHANNELS = vchannels;

   // Number of input ports
   parameter INPUT_PORTS = input_ports;
   // Number of output ports
   parameter OUTPUT_PORTS = output_ports;

   // Size of the input FIFOs
   parameter IN_FIFO_LENGTH = in_fifo_length;
   // Size of the output FIFOs
   parameter OUT_FIFO_LENGTH = out_fifo_length;

   // Lookup "table" (will synthesize as logic usually). Be careful
   // that it is ordered from MSB to LSB, meaning it can be easier
   // used for readable concatenation like
   //
   // {PORT_FOR_DEST0, PORT_FOR_DEST1, ..}
   // parameter [output_ports*num_dests-1:0] LOOKUP = lookup;
   parameter [OUTPUT_PORTS*NUM_DESTS-1:0] LOOKUP = lookup;


// I/O Interfaces

   // Clock and reset
   input clk, rst;
   // Output interfaces (flat)
   output [OUTPUT_PORTS*FLIT_WIDTH-1:0] out_flit;
   output [OUTPUT_PORTS*VCHANNELS-1:0]  out_valid;
   input [OUTPUT_PORTS*VCHANNELS-1:0]   out_ready;
   // Input interfaces (flat)
   input [INPUT_PORTS*FLIT_WIDTH-1:0]   in_flit;
   input [INPUT_PORTS*VCHANNELS-1:0]    in_valid;
   output [INPUT_PORTS*VCHANNELS-1:0]   in_ready;

   // Array conversion
   wire [FLIT_WIDTH-1:0]                out_flit_array [0:OUTPUT_PORTS-1];
   wire [VCHANNELS-1:0]                 out_valid_array [0:OUTPUT_PORTS-1];
   wire [VCHANNELS-1:0]                 out_ready_array [0:OUTPUT_PORTS-1];

   wire [FLIT_WIDTH-1:0]                in_flit_array [0:INPUT_PORTS-1];
   wire [VCHANNELS-1:0]                 in_valid_array [0:INPUT_PORTS-1];
   wire [VCHANNELS-1:0]                 in_ready_array [0:INPUT_PORTS-1];

   genvar                 p;
   genvar                 op,v,ip;
   generate
      for (p = 0; p < OUTPUT_PORTS; p = p + 1) begin : output_arrays
         assign out_flit[(p+1)*FLIT_WIDTH-1:p*FLIT_WIDTH] = out_flit_array[p];
         assign out_valid[(p+1)*VCHANNELS-1:p*VCHANNELS]  = out_valid_array[p];
         assign out_ready_array[p] = out_ready[(p+1)*VCHANNELS-1:p*VCHANNELS];
      end
   endgenerate

   generate
      for (p = 0; p < INPUT_PORTS; p = p + 1) begin : input_arrays
         assign in_flit_array[p]  = in_flit[(p+1)*FLIT_WIDTH-1:p*FLIT_WIDTH];
         assign in_valid_array[p] = in_valid[(p+1)*VCHANNELS-1:p*VCHANNELS];
         assign in_ready[(p+1)*VCHANNELS-1:p*VCHANNELS] = in_ready_array[p];
      end
   endgenerate


// The Switching Structure

   // Those are the switching wires
   wire [FLIT_WIDTH*VCHANNELS-1:0]   switch_in_flit[0:INPUT_PORTS-1];
   wire [OUTPUT_PORTS*VCHANNELS-1:0] switch_in_request[0:INPUT_PORTS-1];
   wire [OUTPUT_PORTS*VCHANNELS-1:0] nxt_switch_in_read[0:INPUT_PORTS-1];
   reg  [OUTPUT_PORTS*VCHANNELS-1:0] switch_in_read[0:INPUT_PORTS-1]; // register used for synchronization

   wire [FLIT_WIDTH*VCHANNELS*INPUT_PORTS-1:0] switch_out_flit[0:OUTPUT_PORTS-1];
   wire [INPUT_PORTS*VCHANNELS-1:0]            nxt_switch_out_request[0:OUTPUT_PORTS-1];
   reg  [INPUT_PORTS*VCHANNELS-1:0]            switch_out_request[0:OUTPUT_PORTS-1]; // register used for synchronization
   wire [INPUT_PORTS*VCHANNELS-1:0]            switch_out_read[0:OUTPUT_PORTS-1];



// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
// Working Area #1
    // Concatenated flits
    wire [FLIT_WIDTH*INPUT_PORTS*VCHANNELS-1:0] in_all_flits;
    reg  [FLIT_WIDTH*INPUT_PORTS*VCHANNELS-1:0] sync_all_flits;
    // Delay Check for synchronization
    reg  [2:0] sync_flag;   // 3-bit boolean flag, (3 beats in total), checking if a synchronization is required
    wire [INPUT_PORTS*OUTPUT_PORTS*VCHANNELS-1:0] all_switch_in_request; 
    generate
        for (p = 0; p < INPUT_PORTS; p = p+1) begin : compose_all_switch_in_request
            assign all_switch_in_request[(p+1)*OUTPUT_PORTS*VCHANNELS-1 : (p)*OUTPUT_PORTS*VCHANNELS]
                    = switch_in_request[p];
        end
    endgenerate
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *


   generate
      for (p = 0; p < INPUT_PORTS; p = p + 1) begin : compose_all_flits
         assign in_all_flits[(p+1)*VCHANNELS*FLIT_WIDTH-1:p*VCHANNELS*FLIT_WIDTH] = switch_in_flit[p];
      end
   endgenerate

   generate
      for (p = 0; p < OUTPUT_PORTS; p = p + 1) begin : assign_all_flits_with_Synchronization
         assign switch_out_flit[p] = sync_all_flits;
      end
   endgenerate

   generate
      for (op = 0; op < OUTPUT_PORTS; op = op + 1) begin: connect_switch
         for (v = 0; v < VCHANNELS; v = v + 1) begin
            for (ip = 0; ip < INPUT_PORTS; ip = ip + 1) begin
               assign nxt_switch_out_request[op][v*INPUT_PORTS+ip] = switch_in_request[ip][v*OUTPUT_PORTS+op];
               assign nxt_switch_in_read[ip][v*OUTPUT_PORTS+op]    = switch_out_read[op][v*INPUT_PORTS+ip];
            end
         end
      end
   endgenerate
  
   
   
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
// Debug Area #2

//output [FLIT_WIDTH*VCHANNELS-1:0]   switch_in_flit[0:INPUT_PORTS-1];
//output [OUTPUT_PORTS*VCHANNELS-1:0] switch_in_request[0:INPUT_PORTS-1];
//output [OUTPUT_PORTS*VCHANNELS-1:0] switch_in_read[0:INPUT_PORTS-1];

//output [FLIT_WIDTH*VCHANNELS*INPUT_PORTS-1:0] switch_out_flit[0:OUTPUT_PORTS-1];
//output [INPUT_PORTS*VCHANNELS-1:0]            switch_out_request[0:OUTPUT_PORTS-1];
//output [INPUT_PORTS*VCHANNELS-1:0]            switch_out_read[0:OUTPUT_PORTS-1];

output [FLIT_WIDTH*INPUT_PORTS*VCHANNELS-1:0] debug_in_all_flits;
assign debug_in_all_flits = in_all_flits;

output [FLIT_WIDTH*INPUT_PORTS*VCHANNELS-1:0] debug_sync_all_flits;
assign debug_sync_all_flits = sync_all_flits;

output [FLIT_WIDTH*VCHANNELS-1:0] debug_sin_flit;
assign debug_sin_flit = switch_in_flit[0];          // <-- Here

output [OUTPUT_PORTS*VCHANNELS-1:0] debug_sin_request;
assign debug_sin_request = switch_in_request[0];    // <-- Here

output [INPUT_PORTS*VCHANNELS-1:0] debug_sout_request;
assign debug_sout_request = switch_out_request[1];

output [INPUT_PORTS*VCHANNELS-1:0] debug_sout_read;
assign debug_sout_read = switch_out_read[1];

output [OUTPUT_PORTS*VCHANNELS-1:0] debug_sin_read;
assign debug_sin_read = switch_in_read[0];          // <-- Here    

output [FLIT_WIDTH-1:0] debug_oflit_array;
assign debug_oflit_array = out_flit_array[1];

// Inside the Input Ports
// Input-FIFO (o_flit) --> (i_flit) Routing Structure
output [FLIT_WIDTH-1:0] debug_ip_fifo_flit_show;
// wire [INPUT_PORTS*FLIT_WIDTH-1:0] debug_ip_fifo_flit;
wire [FLIT_WIDTH-1:0] debug_ip_fifo_flit_array [0:INPUT_PORTS-1];
assign debug_ip_fifo_flit_show = debug_ip_fifo_flit_array[0];       // <-- Here

// Inside the Output Ports
// Switch-Arbiter (o_ready) <-- (i_ready) Output-FIFO
output [OUTPUT_PORTS-1:0] debug_op_fifo_ready;
wire debug_op_fifo_ready_array [0:OUTPUT_PORTS-1];
generate
      for (p = 0; p < OUTPUT_PORTS; p = p + 1) begin : assign_debug_op_fifo_ready
         assign debug_op_fifo_ready[p] = debug_op_fifo_ready_array[p];
      end
endgenerate
// Output-FIFO (o_ready) <-- (i_ready) Output-Arbiter
output [OUTPUT_PORTS*VCHANNELS-1:0] debug_op_oparb_ready;
wire [VCHANNELS-1:0] debug_op_oparb_ready_array [0:OUTPUT_PORTS-1];
generate
      for (p = 0; p < OUTPUT_PORTS; p = p + 1) begin : assig_debug_op_oparb_ready
         assign debug_op_oparb_ready[(p+1)*VCHANNELS-1:(p)*VCHANNELS] = debug_op_oparb_ready_array[p];
      end
endgenerate

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

   
 
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
// Working Area #2
// Functional Design
   // Whenever the 'switch_in_request'signal from any Input Port is updated (to a different value), 
   // there must be a 3-CLK-cycle delay for synchronization.
   always @(all_switch_in_request) begin 
        sync_flag = 3'b001;     // turn the sync_flag ON, delay 3 clk-cycles in total  
   end
   
   // Synchronous Update, with delay check
   always @(posedge clk) begin
        if (rst) begin
            sync_flag <= 3'b000;
            for (integer i=0; i<OUTPUT_PORTS; i=i+1) // update o_valid
                switch_out_request[i] <= 0;
            for (integer i=0; i<INPUT_PORTS; i=i+1) // update i_ready
                switch_in_read[i]     <= 0;
        end
        else begin
            for (integer i=0; i<OUTPUT_PORTS; i=i+1) // update o_valid
                switch_out_request[i] <= nxt_switch_out_request[i];
            for (integer i=0; i<INPUT_PORTS; i=i+1) // update i_ready
                switch_in_read[i]     <= nxt_switch_in_read[i];
        // Delay
            if (sync_flag)  // sync_flag is ON (NOT 0), wait one more clk cycle
                sync_flag <= sync_flag << 1;
            else            // sync_flag is OFF, update the switch_out flits
                sync_all_flits <= in_all_flits; // update o_flit
        end
   end
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *   

   
// Instantiations of all the Input Ports and Output Ports
   generate
      for (p = 0; p < INPUT_PORTS; p = p + 1) begin : inputs
         /* lisnoc_router_input AUTO_TEMPLATE (
         .link_ready     (in_ready_array[p]),
         .link_flit      (in_flit_array[p]),
         .link_valid     (in_valid_array[p]),
         .switch_request (switch_in_request[p]),
         .switch_flit    (switch_in_flit[p]),
         .switch_read    (switch_in_read[p]),
         );*/

         lisnoc_router_input
            #(.vchannels(VCHANNELS),.ports(OUTPUT_PORTS),
               .num_dests(NUM_DESTS),.lookup(LOOKUP),.flit_data_width(FLIT_DATA_WIDTH),
               .flit_type_width(FLIT_TYPE_WIDTH),.ph_dest_width(PH_DEST_WIDTH),
               .fifo_length(IN_FIFO_LENGTH))
         inputs(/*AUTOINST*/
                // Outputs
                .link_ready             (in_ready_array[p]),     // Templated
                .switch_request         (switch_in_request[p]),  // Templated
                .switch_flit            (switch_in_flit[p]),     // Templated
                
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
// Debug Area #3
.debug_ip_fifo_flit(debug_ip_fifo_flit_array[p]),
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

                // Inputs
                .clk                    (clk),
                .rst                    (rst),
                .link_flit              (in_flit_array[p]),      // Templated
                .link_valid             (in_valid_array[p]),     // Templated
                .switch_read            (switch_in_read[p]));    // Templated
      end // block: inputs
   endgenerate

   generate
      for (p = 0; p < OUTPUT_PORTS; p = p + 1) begin : outputs
         /* lisnoc_router_output AUTO_TEMPLATE (
         .link_flit      (out_flit_array[p]),
         .link_valid     (out_valid_array[p]),
         .link_ready     (out_ready_array[p]),
         .switch_read    (switch_out_read[p]),
         .switch_request (switch_out_request[p]),
         .switch_flit    (switch_out_flit[p]),
         );*/

         lisnoc_router_output

         #(.vchannels(VCHANNELS),.ports(INPUT_PORTS),
              .flit_data_width(FLIT_DATA_WIDTH),.flit_type_width(FLIT_TYPE_WIDTH),
              .fifo_length(OUT_FIFO_LENGTH),
              .use_prio(USE_PRIO),.ph_prio_width(PH_PRIO_WIDTH),.ph_prio_offset(PH_DEST_WIDTH))

         outputs (/*AUTOINST*/
                  // Outputs
                  .link_flit            (out_flit_array[p]),     // Templated
                  .link_valid           (out_valid_array[p]),    // Templated
                  .switch_read          (switch_out_read[p]),    // Templated
                
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
// Debug Area #4
// Switch-Arbiter (o_ready) <-- (i_ready) Output-FIFO
.debug_op_fifo_ready(debug_op_fifo_ready_array[p]),
// Output-FIFO (o_ready) <-- (i_ready) Output-Arbiter
.debug_op_oparb_ready(debug_op_oparb_ready_array[p]),
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *      
                
                  // Inputs
                  .clk                  (clk),
                  .rst                  (rst),
                  .link_ready           (out_ready_array[p]),    // Templated
                  .switch_request       (switch_out_request[p]), // Templated
                  .switch_flit          (switch_out_flit[p]));   // Templated
      end // block: outputs
   endgenerate

endmodule // lisnoc_router

`include "lisnoc_undef.vh"

