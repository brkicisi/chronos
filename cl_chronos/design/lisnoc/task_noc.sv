
import chronos::*;

module tile_noc
#(
   parameter NUM_SI=N_TILES,
   parameter NUM_MI=N_TILES,
   parameter DATA_WIDTH = 32
)
( 
	input clk,
	input rstn,
   
   input logic        [NUM_SI-1:0] s_wvalid,
   output logic       [NUM_SI-1:0] s_wready,
   input [NUM_SI-1:0] [DATA_WIDTH-1:0] s_wdata,
   input tile_id_t  [NUM_SI-1:0]       s_port,
   
   output logic       [NUM_MI-1:0] m_wvalid,
   input              [NUM_MI-1:0] m_wready,
   output logic [NUM_SI-1:0] [DATA_WIDTH-1:0] m_wdata
);

always_ff @(posedge clk) begin
	if(!rstn)
		assert (NUM_SI == NUM_MI) else $error("tile_noc not defined for NUM_SI != NUM_MI.");
end

mesh4x4_wrapper #(
	.num_nodes(NUM_SI),
	.flit_data_width(DATA_WIDTH)
) mesh (
	.link_in_flit_i(s_wdata),
	.link_in_valid_i(s_wvalid),
	.link_in_ready_o(s_wready),
	.link_in_addr_i(s_port),

	.link_out_flit_o(m_wdata),
	.link_out_valid_o(m_wvalid),
	.link_out_ready_i(m_wready),

	.clk(clk),
	.rst(!rstn)
);

endmodule
