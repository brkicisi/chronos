import swarm::*;

module undo_log 
 #(
    parameter ID_BASE = 0,
    parameter TILE_ID = 0
 )
(
   input clk,
   input rstn,

   // Log interface
   input                   [N_THREADS-1:0] undo_log_valid,
   output logic            [N_THREADS-1:0] undo_log_ready,
   input undo_log_addr_t   [N_THREADS-1:0] undo_log_addr,
   input undo_log_data_t   [N_THREADS-1:0] undo_log_data,
   input cq_slice_slot_t   [N_THREADS-1:0] undo_log_slot,
  

   // Restore interface - Connects to conflict serializer
   output logic          [UNDO_LOG_THREADS-1:0] restore_arvalid,
   output task_type_t    [UNDO_LOG_THREADS-1:0] restore_araddr,
   input                 [UNDO_LOG_THREADS-1:0] restore_rvalid,
   input cq_slice_slot_t                        restore_cq_slot, 

   output logic          [UNDO_LOG_THREADS-1:0] restore_done_valid,
   input                 [UNDO_LOG_THREADS-1:0] restore_done_ready,
   output cq_slice_slot_t[UNDO_LOG_THREADS-1:0] restore_done_cq_slot,
   
   // L2
   axi_bus_t.slave      l2, 
   pci_debug_bus_t.master                 pci_debug,
   reg_bus_t.master                       reg_bus

);

logic [$clog2(N_THREADS)-1:0] undo_log_select_core;

lowbit #(
   .OUT_WIDTH($clog2(N_THREADS)),
   .IN_WIDTH(N_THREADS)
) UNDO_LOG_SELECT (
   .in(undo_log_valid),
   .out(undo_log_select_core)
);
logic undo_log_select_valid;
logic undo_log_select_ready;
cq_slice_slot_t undo_log_select_cq_slot;
always_comb begin
   undo_log_select_valid       = undo_log_valid       [undo_log_select_core];
   undo_log_select_cq_slot     = undo_log_slot        [undo_log_select_core];
end

genvar i;
generate 
   for (i=0;i<N_THREADS;i++) begin
      assign undo_log_ready[i] = undo_log_select_valid & undo_log_select_ready & 
         (undo_log_select_core ==i);
   end
endgenerate
assign undo_log_select_ready = undo_log_select_valid;
cq_slice_slot_t next_cq_slot;

undo_log_addr_t addr_log [0:2**LOG_CQ_SLICE_SIZE-1];
undo_log_data_t data_log [0:2**LOG_CQ_SLICE_SIZE-1];

undo_log_addr_t addr_read;
undo_log_data_t data_read;


always_ff @(posedge clk) begin
   if (undo_log_select_valid & undo_log_select_ready) begin
      addr_log[undo_log_select_cq_slot] <= undo_log_addr[undo_log_select_core];
   end
   addr_read <= addr_log[next_cq_slot];
end
always_ff @(posedge clk) begin
   if (undo_log_select_valid & undo_log_select_ready) begin
      data_log[undo_log_select_cq_slot] <= undo_log_data[undo_log_select_core];
   end
   data_read <= data_log[next_cq_slot];
end



// -- RESTORE LOGIC

logic [UNDO_LOG_THREADS-1:0] thread_in_use;
cq_slice_slot_t [UNDO_LOG_THREADS-1:0] thread_cq_slot;

typedef logic [$clog2(UNDO_LOG_THREADS)-1:0] undo_log_thread_id;
undo_log_thread_id arthread, rthread, reg_rthread;

lowbit #(
   .OUT_WIDTH($clog2(UNDO_LOG_THREADS)),
   .IN_WIDTH(UNDO_LOG_THREADS)
) UNDO_LOG_THREAD_SELECT (
   .in(~thread_in_use),
   .out(arthread)
);

typedef enum logic[1:0] {RESTORE_IDLE, RESTORE_READ_LOG, RESTORE_WRITE_MEM } restore_state_t;
restore_state_t restore_state;

typedef enum logic {RESTORE_ACK_IDLE, RESTORE_ACK_RECEIVED} restore_ack_state_t;
undo_log_thread_id restore_ack_thread;
restore_ack_state_t restore_ack_state;

generate;
for (i=0;i<UNDO_LOG_THREADS;i++) begin
   assign restore_arvalid[i] = (arthread == i) & !thread_in_use[i] 
         & (restore_state == RESTORE_IDLE) & !restore_rvalid[rthread];
   assign restore_araddr[i] = TASK_TYPE_UNDO_LOG_RESTORE;

   assign restore_done_valid[i] = (restore_ack_thread == i) 
            & (restore_ack_state == RESTORE_ACK_RECEIVED);
   assign restore_done_cq_slot[i] = thread_cq_slot[i];

   always_ff @(posedge clk) begin
      if (!rstn) begin
         thread_in_use[i] <= 1'b0;
      end else begin
         if ((restore_state == RESTORE_READ_LOG) & (reg_rthread==i)) begin
            thread_in_use[i] <= 1'b1;
         end else if ((restore_ack_state == RESTORE_ACK_RECEIVED) & (restore_done_ready[i])) begin
            thread_in_use[i] <= 1'b0;
         end
      end
   end
end
always_ff @(posedge clk) begin
   rthread <= arthread;
end

endgenerate
always_ff @(posedge clk) begin
   if (!rstn) begin
      restore_state <= RESTORE_IDLE;
   end else begin
      case (restore_state) 
         RESTORE_IDLE: begin
            if (restore_rvalid[rthread]) begin
               restore_state <= RESTORE_READ_LOG;
               next_cq_slot <= restore_cq_slot;
               reg_rthread <= rthread;
               thread_cq_slot[rthread] <= restore_cq_slot;
            end
         end
         RESTORE_READ_LOG: begin
            restore_state <= RESTORE_WRITE_MEM;
         end
         RESTORE_WRITE_MEM: begin
            if (l2.awready & l2.wready) begin
               restore_state <= RESTORE_IDLE;
            end
         end
      endcase
   end
end

always_ff @(posedge clk) begin
   if (!rstn) begin
      restore_ack_state <= RESTORE_ACK_IDLE;
   end else begin
      case (restore_ack_state) 
         RESTORE_ACK_IDLE : begin
            if (l2.bvalid) begin
               restore_ack_state <= RESTORE_ACK_RECEIVED;
               restore_ack_thread <= l2.bid[UNDO_LOG_THREADS-1:0];
            end
         end
         RESTORE_ACK_RECEIVED: begin
            if (restore_done_ready[restore_ack_thread] ) begin
               restore_ack_state <= RESTORE_ACK_IDLE;
            end
         end
      endcase
   end
end

assign l2.awvalid = (restore_state == RESTORE_WRITE_MEM);
assign l2.wvalid = (restore_state == RESTORE_WRITE_MEM);
assign l2.awsize = 2;
assign l2.awlen = 0;
assign l2.awaddr = addr_read;  
assign l2.wdata = data_read;
assign l2.awid = ID_BASE | reg_rthread;
assign l2.wid = ID_BASE | reg_rthread;
assign l2.wstrb = '1;
assign l2.bready = (restore_ack_state == RESTORE_ACK_IDLE);



// No L2 reads/ only writes
assign l2.arvalid = 1'b0;
assign l2.rready = 1'b1;

logic [LOG_LOG_DEPTH:0] log_size; 
always_ff @(posedge clk) begin
   if (!rstn) begin
      reg_bus.rvalid <= 1'b0;
   end
   if (reg_bus.arvalid) begin
      reg_bus.rvalid <= 1'b1;
      case (reg_bus.araddr) 
         DEBUG_CAPACITY : reg_bus.rdata <= log_size;
      endcase
   end else begin
      reg_bus.rvalid <= 1'b0;
   end
end  

if (UNDO_LOG_LOGGING[TILE_ID]) begin
   logic log_valid;
   typedef struct packed {

      logic [3:0] restore_arvalid;
      logic [3:0] restore_rvalid;
      logic [7:0] restore_cq_slot;

      logic awvalid;
      logic awready; 
      logic [13:0] awid;

      logic [15:0] bid;
      logic bvalid;
      logic bready;
      logic [5:0] restore_ack_thread;
      logic [3:0] restore_done_valid;
      logic [3:0] restore_done_ready;
      
   } undo_log_t;
   undo_log_t log_word;
   always_comb begin

      log_word = '0;

      log_word.bid = l2.bid;
      log_word.bvalid = l2.bvalid;
      log_word.bready = l2.bready;
      log_word.restore_ack_thread = restore_ack_thread;
      log_word.restore_done_valid = restore_done_valid;
      log_word.restore_done_ready = restore_done_ready;
      
      log_word.restore_arvalid = restore_arvalid;
      log_word.restore_rvalid = restore_rvalid;
      log_word.restore_cq_slot = restore_cq_slot;
      
      log_word.awvalid = l2.awvalid;
      log_word.awready = l2.awready;
      log_word.awid = l2.awid;
   
      log_valid = (l2.bvalid | (restore_done_valid != 0) | restore_arvalid[3] | (restore_rvalid !=0) | l2.awvalid );
   end

   log #(
      .WIDTH($bits(log_word)),
      .LOG_DEPTH(LOG_LOG_DEPTH)
   ) TASK_UNIT_LOG (
      .clk(clk),
      .rstn(rstn),

      .wvalid(log_valid),
      .wdata(log_word),

      .pci(pci_debug),

      .size(log_size)

   );
end

endmodule