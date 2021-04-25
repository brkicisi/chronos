
import chronos::*;

module noctb();

localparam N_TILES = 16;
localparam DATA_WIDTH = 32;

genvar g;
integer i;

// Create a 100MHz clock
logic clk;
initial clk = '0;
always #5 clk = ~clk;

// Create the reset signal 
logic rstn;

task reset();
    rstn = '0;
    @(posedge clk);
    @(posedge clk);
    rstn = '1;
endtask

integer cycle;
always_ff @(posedge clk) begin
	if(!rstn)
		cycle <= 0;
	else
		cycle <= cycle + 1;
end

logic [N_TILES-1:0] s_wvalid;
logic [N_TILES-1:0] s_wready;
logic [N_TILES-1:0] [DATA_WIDTH-1:0] s_wdata;
tile_id_t [N_TILES-1:0] s_port;

logic [N_TILES-1:0] m_wvalid;
logic [N_TILES-1:0] m_wready;
logic [N_TILES-1:0] [DATA_WIDTH-1:0] m_wdata;

tile_noc # (
   .NUM_SI(N_TILES),
   .NUM_MI(N_TILES),
   .DATA_WIDTH(DATA_WIDTH)
) noc (.*);


task reset_ports();
	for(int i = 0; i < N_TILES; i++) begin
		s_wvalid[i] = '0;
		m_wready[i] = '1;
	end
endtask

logic [N_TILES-1:0] s_sent;
generate;
for(g = 0; g < N_TILES; g++) begin
	always_ff @(posedge clk) begin
		s_sent[g] <= s_wvalid[g] && s_wready[g];
	end
	always_ff @(posedge clk) begin
		if(m_wvalid[g]) begin
			$display("Recieved data = 0x%8x\t at dst=%2d.", m_wdata[g], g);
		end
	end
end
endgenerate

task send_msg(input tile_id_t src, input tile_id_t dst, input logic [DATA_WIDTH-1:0] data);
	s_wvalid[src] = 1'b1;
	s_port[src] = dst;
	s_wdata[src] = data;
	@(posedge clk);
	wait(s_sent[src] == 1'b1);
	s_wvalid[src] = 1'b0;
endtask


logic [DATA_WIDTH-1:0] data;

initial begin
    reset();
	reset_ports();
	@(posedge clk);
	@(posedge clk);

	data = -1;
	send_msg(0, 1, data);

	for(i = 0; i < 100; i++)
		@(posedge clk);

    $stop;
end

/*
typedef struct packed {
	logic valid;
	tile_id_t src;
	tile_id_t dst;
	logic [DATA_WIDTH-1:0] data;
} message_t;

message_t [N_TILES-1:0] sending_msg;

task send_msg(tile_id_t src, tile_id_t dst, logic [DATA_WIDTH-1:0] data);
	sending_msg[src].valid = 1'b1;
	sending_msg[src].dst = dst;
	sending_msg[src].data = data;
endtask

task init_send_msg();
	for(i = 0; i < N_TILES; i++) begin
		sending_msg[i].valid = 1'b0;
		sending_msg[i].src = i;
	end
endtask

generate;
for(g = 0; g < N_TILES; g++) begin
	always_ff @(posedge clk) begin
		if(!rstn) begin
			s_wvalid[g] <= 1'b0;
		end
		else begin
			s_wvalid[g] <= sending_msg[g].valid & !msg_sent;
			s_wdata[g] <= sending_msg[g].data;
			s_port[g] <= sending_msg[g].dst;
		end
	end
end
endgenerate
*/

endmodule
