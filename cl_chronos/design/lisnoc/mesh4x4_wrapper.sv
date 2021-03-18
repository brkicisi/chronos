
/*
 * This is a wrapper for the 4x4 mesh NoC
 * It converts data on an AXI bus to flits.
 * It assumes data makes its own unit (ie the AXI data each cycle is independent
 * and travels in its own flit).
 */
import chronos::*;

`include "lisnoc_def.vh"

module mesh4x4_wrapper (
	link_in_flit_i,
	link_in_valid_i,
	link_in_ready_o,
	link_in_addr_i,

	link_out_flit_o,
	link_out_valid_o,
	link_out_ready_i,

	clk, rst
);

parameter num_nodes = 16;
parameter vchannels = 1;
parameter flit_data_width = 32;

parameter flit_type_width = 2;
parameter log_num_nodes = (num_nodes == 1) ? 1 : $clog2(num_nodes); // address bits
parameter flit_width = flit_type_width + log_num_nodes + flit_data_width;

input clk;
input rst;

input [num_nodes-1:0][flit_data_width-1:0] link_in_flit_i;
input [vchannels-1:0][num_nodes-1:0] link_in_valid_i;
output logic [vchannels-1:0][num_nodes-1:0] link_in_ready_o;
input tile_id_t [num_nodes-1:0] link_in_addr_i;


output logic [num_nodes-1:0][flit_data_width-1:0] link_out_flit_o;
output logic [vchannels-1:0][num_nodes-1:0] link_out_valid_o;
input [vchannels-1:0][num_nodes-1:0] link_out_ready_i;


// logic [num_nodes:0] num_nodes_tmp;
// assign num_nodes_tmp = num_nodes;
always_ff @(posedge clk) begin
	if(rst) begin
		assert (num_nodes > 0) else $error("Min 1 node in a 4x4 mesh.");
		assert (num_nodes <= 16) else $error("Maximum 16 nodes in a 4x4 mesh.");
	end
end

logic [flit_width-1:0] link0_in_flit_i;
logic [vchannels-1:0] link0_in_valid_i;
logic [vchannels-1:0] link0_in_ready_o;
logic [flit_width-1:0] link0_out_flit_o;
logic [vchannels-1:0] link0_out_valid_o;
logic [vchannels-1:0] link0_out_ready_i;

logic [flit_width-1:0] link1_in_flit_i;
logic [vchannels-1:0] link1_in_valid_i;
logic [vchannels-1:0] link1_in_ready_o;
logic [flit_width-1:0] link1_out_flit_o;
logic [vchannels-1:0] link1_out_valid_o;
logic [vchannels-1:0] link1_out_ready_i;

logic [flit_width-1:0] link2_in_flit_i;
logic [vchannels-1:0] link2_in_valid_i;
logic [vchannels-1:0] link2_in_ready_o;
logic [flit_width-1:0] link2_out_flit_o;
logic [vchannels-1:0] link2_out_valid_o;
logic [vchannels-1:0] link2_out_ready_i;

logic [flit_width-1:0] link3_in_flit_i;
logic [vchannels-1:0] link3_in_valid_i;
logic [vchannels-1:0] link3_in_ready_o;
logic [flit_width-1:0] link3_out_flit_o;
logic [vchannels-1:0] link3_out_valid_o;
logic [vchannels-1:0] link3_out_ready_i;

logic [flit_width-1:0] link4_in_flit_i;
logic [vchannels-1:0] link4_in_valid_i;
logic [vchannels-1:0] link4_in_ready_o;
logic [flit_width-1:0] link4_out_flit_o;
logic [vchannels-1:0] link4_out_valid_o;
logic [vchannels-1:0] link4_out_ready_i;

logic [flit_width-1:0] link5_in_flit_i;
logic [vchannels-1:0] link5_in_valid_i;
logic [vchannels-1:0] link5_in_ready_o;
logic [flit_width-1:0] link5_out_flit_o;
logic [vchannels-1:0] link5_out_valid_o;
logic [vchannels-1:0] link5_out_ready_i;

logic [flit_width-1:0] link6_in_flit_i;
logic [vchannels-1:0] link6_in_valid_i;
logic [vchannels-1:0] link6_in_ready_o;
logic [flit_width-1:0] link6_out_flit_o;
logic [vchannels-1:0] link6_out_valid_o;
logic [vchannels-1:0] link6_out_ready_i;

logic [flit_width-1:0] link7_in_flit_i;
logic [vchannels-1:0] link7_in_valid_i;
logic [vchannels-1:0] link7_in_ready_o;
logic [flit_width-1:0] link7_out_flit_o;
logic [vchannels-1:0] link7_out_valid_o;
logic [vchannels-1:0] link7_out_ready_i;

logic [flit_width-1:0] link8_in_flit_i;
logic [vchannels-1:0] link8_in_valid_i;
logic [vchannels-1:0] link8_in_ready_o;
logic [flit_width-1:0] link8_out_flit_o;
logic [vchannels-1:0] link8_out_valid_o;
logic [vchannels-1:0] link8_out_ready_i;

logic [flit_width-1:0] link9_in_flit_i;
logic [vchannels-1:0] link9_in_valid_i;
logic [vchannels-1:0] link9_in_ready_o;
logic [flit_width-1:0] link9_out_flit_o;
logic [vchannels-1:0] link9_out_valid_o;
logic [vchannels-1:0] link9_out_ready_i;

logic [flit_width-1:0] link10_in_flit_i;
logic [vchannels-1:0] link10_in_valid_i;
logic [vchannels-1:0] link10_in_ready_o;
logic [flit_width-1:0] link10_out_flit_o;
logic [vchannels-1:0] link10_out_valid_o;
logic [vchannels-1:0] link10_out_ready_i;

logic [flit_width-1:0] link11_in_flit_i;
logic [vchannels-1:0] link11_in_valid_i;
logic [vchannels-1:0] link11_in_ready_o;
logic [flit_width-1:0] link11_out_flit_o;
logic [vchannels-1:0] link11_out_valid_o;
logic [vchannels-1:0] link11_out_ready_i;

logic [flit_width-1:0] link12_in_flit_i;
logic [vchannels-1:0] link12_in_valid_i;
logic [vchannels-1:0] link12_in_ready_o;
logic [flit_width-1:0] link12_out_flit_o;
logic [vchannels-1:0] link12_out_valid_o;
logic [vchannels-1:0] link12_out_ready_i;

logic [flit_width-1:0] link13_in_flit_i;
logic [vchannels-1:0] link13_in_valid_i;
logic [vchannels-1:0] link13_in_ready_o;
logic [flit_width-1:0] link13_out_flit_o;
logic [vchannels-1:0] link13_out_valid_o;
logic [vchannels-1:0] link13_out_ready_i;

logic [flit_width-1:0] link14_in_flit_i;
logic [vchannels-1:0] link14_in_valid_i;
logic [vchannels-1:0] link14_in_ready_o;
logic [flit_width-1:0] link14_out_flit_o;
logic [vchannels-1:0] link14_out_valid_o;
logic [vchannels-1:0] link14_out_ready_i;

logic [flit_width-1:0] link15_in_flit_i;
logic [vchannels-1:0] link15_in_valid_i;
logic [vchannels-1:0] link15_in_ready_o;
logic [flit_width-1:0] link15_out_flit_o;
logic [vchannels-1:0] link15_out_valid_o;
logic [vchannels-1:0] link15_out_ready_i;


generate
always_comb begin
	if(0 >= num_nodes) begin
		link0_in_flit_i = {flit_width{1'b0}};
		link0_in_valid_i = {vchannels{1'b0}};
		link_in_ready_o[0] = {vchannels{1'b0}};
		link_out_flit_o[0] = {flit_width{1'b0}};
		link_out_valid_o[0] = {vchannels{1'b0}};
		link0_out_ready_i = {vchannels{1'b0}};
	end
	else begin
		link0_in_flit_i = {`FLIT_TYPE_SINGLE, link_in_addr_i[0], link_in_flit_i[0]};
		link0_in_valid_i = link_in_valid_i[0];
		link_in_ready_o[0] = link0_in_ready_o;
		link_out_flit_o[0] = link0_out_flit_o[flit_data_width-1:0];
		link_out_valid_o[0] = link0_out_valid_o;
		link0_out_ready_i = link_out_ready_i[0];
	end
end
endgenerate
generate
always_comb begin
	if(1 >= num_nodes) begin
		link1_in_flit_i = {flit_width{1'b0}};
		link1_in_valid_i = {vchannels{1'b0}};
		link_in_ready_o[1] = {vchannels{1'b0}};
		link_out_flit_o[1] = {flit_width{1'b0}};
		link_out_valid_o[1] = {vchannels{1'b0}};
		link1_out_ready_i = {vchannels{1'b0}};
	end
	else begin
		link1_in_flit_i = {`FLIT_TYPE_SINGLE, link_in_addr_i[1], link_in_flit_i[1]};
		link1_in_valid_i = link_in_valid_i[1];
		link_in_ready_o[1] = link1_in_ready_o;
		link_out_flit_o[1] = link1_out_flit_o[flit_data_width-1:0];
		link_out_valid_o[1] = link1_out_valid_o;
		link1_out_ready_i = link_out_ready_i[1];
	end
end
endgenerate
generate
always_comb begin
	if(2 >= num_nodes) begin
		link2_in_flit_i = {flit_width{1'b0}};
		link2_in_valid_i = {vchannels{1'b0}};
		link_in_ready_o[2] = {vchannels{1'b0}};
		link_out_flit_o[2] = {flit_width{1'b0}};
		link_out_valid_o[2] = {vchannels{1'b0}};
		link2_out_ready_i = {vchannels{1'b0}};
	end
	else begin
		link2_in_flit_i = {`FLIT_TYPE_SINGLE, link_in_addr_i[2], link_in_flit_i[2]};
		link2_in_valid_i = link_in_valid_i[2];
		link_in_ready_o[2] = link2_in_ready_o;
		link_out_flit_o[2] = link2_out_flit_o[flit_data_width-1:0];
		link_out_valid_o[2] = link2_out_valid_o;
		link2_out_ready_i = link_out_ready_i[2];
	end
end
endgenerate
generate
always_comb begin
	if(3 >= num_nodes) begin
		link3_in_flit_i = {flit_width{1'b0}};
		link3_in_valid_i = {vchannels{1'b0}};
		link_in_ready_o[3] = {vchannels{1'b0}};
		link_out_flit_o[3] = {flit_width{1'b0}};
		link_out_valid_o[3] = {vchannels{1'b0}};
		link3_out_ready_i = {vchannels{1'b0}};
	end
	else begin
		link3_in_flit_i = {`FLIT_TYPE_SINGLE, link_in_addr_i[3], link_in_flit_i[3]};
		link3_in_valid_i = link_in_valid_i[3];
		link_in_ready_o[3] = link3_in_ready_o;
		link_out_flit_o[3] = link3_out_flit_o[flit_data_width-1:0];
		link_out_valid_o[3] = link3_out_valid_o;
		link3_out_ready_i = link_out_ready_i[3];
	end
end
endgenerate
generate
always_comb begin
	if(4 >= num_nodes) begin
		link4_in_flit_i = {flit_width{1'b0}};
		link4_in_valid_i = {vchannels{1'b0}};
		link_in_ready_o[4] = {vchannels{1'b0}};
		link_out_flit_o[4] = {flit_width{1'b0}};
		link_out_valid_o[4] = {vchannels{1'b0}};
		link4_out_ready_i = {vchannels{1'b0}};
	end
	else begin
		link4_in_flit_i = {`FLIT_TYPE_SINGLE, link_in_addr_i[4], link_in_flit_i[4]};
		link4_in_valid_i = link_in_valid_i[4];
		link_in_ready_o[4] = link4_in_ready_o;
		link_out_flit_o[4] = link4_out_flit_o[flit_data_width-1:0];
		link_out_valid_o[4] = link4_out_valid_o;
		link4_out_ready_i = link_out_ready_i[4];
	end
end
endgenerate
generate
always_comb begin
	if(5 >= num_nodes) begin
		link5_in_flit_i = {flit_width{1'b0}};
		link5_in_valid_i = {vchannels{1'b0}};
		link_in_ready_o[5] = {vchannels{1'b0}};
		link_out_flit_o[5] = {flit_width{1'b0}};
		link_out_valid_o[5] = {vchannels{1'b0}};
		link5_out_ready_i = {vchannels{1'b0}};
	end
	else begin
		link5_in_flit_i = {`FLIT_TYPE_SINGLE, link_in_addr_i[5], link_in_flit_i[5]};
		link5_in_valid_i = link_in_valid_i[5];
		link_in_ready_o[5] = link5_in_ready_o;
		link_out_flit_o[5] = link5_out_flit_o[flit_data_width-1:0];
		link_out_valid_o[5] = link5_out_valid_o;
		link5_out_ready_i = link_out_ready_i[5];
	end
end
endgenerate
generate
always_comb begin
	if(6 >= num_nodes) begin
		link6_in_flit_i = {flit_width{1'b0}};
		link6_in_valid_i = {vchannels{1'b0}};
		link_in_ready_o[6] = {vchannels{1'b0}};
		link_out_flit_o[6] = {flit_width{1'b0}};
		link_out_valid_o[6] = {vchannels{1'b0}};
		link6_out_ready_i = {vchannels{1'b0}};
	end
	else begin
		link6_in_flit_i = {`FLIT_TYPE_SINGLE, link_in_addr_i[6], link_in_flit_i[6]};
		link6_in_valid_i = link_in_valid_i[6];
		link_in_ready_o[6] = link6_in_ready_o;
		link_out_flit_o[6] = link6_out_flit_o[flit_data_width-1:0];
		link_out_valid_o[6] = link6_out_valid_o;
		link6_out_ready_i = link_out_ready_i[6];
	end
end
endgenerate
generate
always_comb begin
	if(7 >= num_nodes) begin
		link7_in_flit_i = {flit_width{1'b0}};
		link7_in_valid_i = {vchannels{1'b0}};
		link_in_ready_o[7] = {vchannels{1'b0}};
		link_out_flit_o[7] = {flit_width{1'b0}};
		link_out_valid_o[7] = {vchannels{1'b0}};
		link7_out_ready_i = {vchannels{1'b0}};
	end
	else begin
		link7_in_flit_i = {`FLIT_TYPE_SINGLE, link_in_addr_i[7], link_in_flit_i[7]};
		link7_in_valid_i = link_in_valid_i[7];
		link_in_ready_o[7] = link7_in_ready_o;
		link_out_flit_o[7] = link7_out_flit_o[flit_data_width-1:0];
		link_out_valid_o[7] = link7_out_valid_o;
		link7_out_ready_i = link_out_ready_i[7];
	end
end
endgenerate
generate
always_comb begin
	if(8 >= num_nodes) begin
		link8_in_flit_i = {flit_width{1'b0}};
		link8_in_valid_i = {vchannels{1'b0}};
		link_in_ready_o[8] = {vchannels{1'b0}};
		link_out_flit_o[8] = {flit_width{1'b0}};
		link_out_valid_o[8] = {vchannels{1'b0}};
		link8_out_ready_i = {vchannels{1'b0}};
	end
	else begin
		link8_in_flit_i = {`FLIT_TYPE_SINGLE, link_in_addr_i[8], link_in_flit_i[8]};
		link8_in_valid_i = link_in_valid_i[8];
		link_in_ready_o[8] = link8_in_ready_o;
		link_out_flit_o[8] = link8_out_flit_o[flit_data_width-1:0];
		link_out_valid_o[8] = link8_out_valid_o;
		link8_out_ready_i = link_out_ready_i[8];
	end
end
endgenerate
generate
always_comb begin
	if(9 >= num_nodes) begin
		link9_in_flit_i = {flit_width{1'b0}};
		link9_in_valid_i = {vchannels{1'b0}};
		link_in_ready_o[9] = {vchannels{1'b0}};
		link_out_flit_o[9] = {flit_width{1'b0}};
		link_out_valid_o[9] = {vchannels{1'b0}};
		link9_out_ready_i = {vchannels{1'b0}};
	end
	else begin
		link9_in_flit_i = {`FLIT_TYPE_SINGLE, link_in_addr_i[9], link_in_flit_i[9]};
		link9_in_valid_i = link_in_valid_i[9];
		link_in_ready_o[9] = link9_in_ready_o;
		link_out_flit_o[9] = link9_out_flit_o[flit_data_width-1:0];
		link_out_valid_o[9] = link9_out_valid_o;
		link9_out_ready_i = link_out_ready_i[9];
	end
end
endgenerate
generate
always_comb begin
	if(10 >= num_nodes) begin
		link10_in_flit_i = {flit_width{1'b0}};
		link10_in_valid_i = {vchannels{1'b0}};
		link_in_ready_o[10] = {vchannels{1'b0}};
		link_out_flit_o[10] = {flit_width{1'b0}};
		link_out_valid_o[10] = {vchannels{1'b0}};
		link10_out_ready_i = {vchannels{1'b0}};
	end
	else begin
		link10_in_flit_i = {`FLIT_TYPE_SINGLE, link_in_addr_i[10], link_in_flit_i[10]};
		link10_in_valid_i = link_in_valid_i[10];
		link_in_ready_o[10] = link10_in_ready_o;
		link_out_flit_o[10] = link10_out_flit_o[flit_data_width-1:0];
		link_out_valid_o[10] = link10_out_valid_o;
		link10_out_ready_i = link_out_ready_i[10];
	end
end
endgenerate
generate
always_comb begin
	if(11 >= num_nodes) begin
		link11_in_flit_i = {flit_width{1'b0}};
		link11_in_valid_i = {vchannels{1'b0}};
		link_in_ready_o[11] = {vchannels{1'b0}};
		link_out_flit_o[11] = {flit_width{1'b0}};
		link_out_valid_o[11] = {vchannels{1'b0}};
		link11_out_ready_i = {vchannels{1'b0}};
	end
	else begin
		link11_in_flit_i = {`FLIT_TYPE_SINGLE, link_in_addr_i[11], link_in_flit_i[11]};
		link11_in_valid_i = link_in_valid_i[11];
		link_in_ready_o[11] = link11_in_ready_o;
		link_out_flit_o[11] = link11_out_flit_o[flit_data_width-1:0];
		link_out_valid_o[11] = link11_out_valid_o;
		link11_out_ready_i = link_out_ready_i[11];
	end
end
endgenerate
generate
always_comb begin
	if(12 >= num_nodes) begin
		link12_in_flit_i = {flit_width{1'b0}};
		link12_in_valid_i = {vchannels{1'b0}};
		link_in_ready_o[12] = {vchannels{1'b0}};
		link_out_flit_o[12] = {flit_width{1'b0}};
		link_out_valid_o[12] = {vchannels{1'b0}};
		link12_out_ready_i = {vchannels{1'b0}};
	end
	else begin
		link12_in_flit_i = {`FLIT_TYPE_SINGLE, link_in_addr_i[12], link_in_flit_i[12]};
		link12_in_valid_i = link_in_valid_i[12];
		link_in_ready_o[12] = link12_in_ready_o;
		link_out_flit_o[12] = link12_out_flit_o[flit_data_width-1:0];
		link_out_valid_o[12] = link12_out_valid_o;
		link12_out_ready_i = link_out_ready_i[12];
	end
end
endgenerate
generate
always_comb begin
	if(13 >= num_nodes) begin
		link13_in_flit_i = {flit_width{1'b0}};
		link13_in_valid_i = {vchannels{1'b0}};
		link_in_ready_o[13] = {vchannels{1'b0}};
		link_out_flit_o[13] = {flit_width{1'b0}};
		link_out_valid_o[13] = {vchannels{1'b0}};
		link13_out_ready_i = {vchannels{1'b0}};
	end
	else begin
		link13_in_flit_i = {`FLIT_TYPE_SINGLE, link_in_addr_i[13], link_in_flit_i[13]};
		link13_in_valid_i = link_in_valid_i[13];
		link_in_ready_o[13] = link13_in_ready_o;
		link_out_flit_o[13] = link13_out_flit_o[flit_data_width-1:0];
		link_out_valid_o[13] = link13_out_valid_o;
		link13_out_ready_i = link_out_ready_i[13];
	end
end
endgenerate
generate
always_comb begin
	if(14 >= num_nodes) begin
		link14_in_flit_i = {flit_width{1'b0}};
		link14_in_valid_i = {vchannels{1'b0}};
		link_in_ready_o[14] = {vchannels{1'b0}};
		link_out_flit_o[14] = {flit_width{1'b0}};
		link_out_valid_o[14] = {vchannels{1'b0}};
		link14_out_ready_i = {vchannels{1'b0}};
	end
	else begin
		link14_in_flit_i = {`FLIT_TYPE_SINGLE, link_in_addr_i[14], link_in_flit_i[14]};
		link14_in_valid_i = link_in_valid_i[14];
		link_in_ready_o[14] = link14_in_ready_o;
		link_out_flit_o[14] = link14_out_flit_o[flit_data_width-1:0];
		link_out_valid_o[14] = link14_out_valid_o;
		link14_out_ready_i = link_out_ready_i[14];
	end
end
endgenerate
generate
always_comb begin
	if(15 >= num_nodes) begin
		link15_in_flit_i = {flit_width{1'b0}};
		link15_in_valid_i = {vchannels{1'b0}};
		link_in_ready_o[15] = {vchannels{1'b0}};
		link_out_flit_o[15] = {flit_width{1'b0}};
		link_out_valid_o[15] = {vchannels{1'b0}};
		link15_out_ready_i = {vchannels{1'b0}};
	end
	else begin
		link15_in_flit_i = {`FLIT_TYPE_SINGLE, link_in_addr_i[15], link_in_flit_i[15]};
		link15_in_valid_i = link_in_valid_i[15];
		link_in_ready_o[15] = link15_in_ready_o;
		link_out_flit_o[15] = link15_out_flit_o[flit_data_width-1:0];
		link_out_valid_o[15] = link15_out_valid_o;
		link15_out_ready_i = link_out_ready_i[15];
	end
end
endgenerate


lisnoc_mesh4x4 #(
	.vchannels(vchannels),
	.flit_data_width(log_num_nodes + flit_data_width),
	.flit_type_width(flit_type_width)
) mesh4x4 (
    link0_in_flit_i, link0_in_valid_i, link0_in_ready_o,
    link0_out_flit_o, link0_out_valid_o, link0_out_ready_i,

    link1_in_flit_i, link1_in_valid_i, link1_in_ready_o,
    link1_out_flit_o, link1_out_valid_o, link1_out_ready_i,

    link2_in_flit_i, link2_in_valid_i, link2_in_ready_o,
    link2_out_flit_o, link2_out_valid_o, link2_out_ready_i,

    link3_in_flit_i, link3_in_valid_i, link3_in_ready_o,
    link3_out_flit_o, link3_out_valid_o, link3_out_ready_i,

    link4_in_flit_i, link4_in_valid_i, link4_in_ready_o,
    link4_out_flit_o, link4_out_valid_o, link4_out_ready_i,

    link5_in_flit_i, link5_in_valid_i, link5_in_ready_o,
    link5_out_flit_o, link5_out_valid_o, link5_out_ready_i,

    link6_in_flit_i, link6_in_valid_i, link6_in_ready_o,
    link6_out_flit_o, link6_out_valid_o, link6_out_ready_i,

    link7_in_flit_i, link7_in_valid_i, link7_in_ready_o,
    link7_out_flit_o, link7_out_valid_o, link7_out_ready_i,

    link8_in_flit_i, link8_in_valid_i, link8_in_ready_o,
    link8_out_flit_o, link8_out_valid_o, link8_out_ready_i,

    link9_in_flit_i, link9_in_valid_i, link9_in_ready_o,
    link9_out_flit_o, link9_out_valid_o, link9_out_ready_i,

    link10_in_flit_i, link10_in_valid_i, link10_in_ready_o,
    link10_out_flit_o, link10_out_valid_o, link10_out_ready_i,

    link11_in_flit_i, link11_in_valid_i, link11_in_ready_o,
    link11_out_flit_o, link11_out_valid_o, link11_out_ready_i,

    link12_in_flit_i, link12_in_valid_i, link12_in_ready_o,
    link12_out_flit_o, link12_out_valid_o, link12_out_ready_i,

    link13_in_flit_i, link13_in_valid_i, link13_in_ready_o,
    link13_out_flit_o, link13_out_valid_o, link13_out_ready_i,

    link14_in_flit_i, link14_in_valid_i, link14_in_ready_o,
    link14_out_flit_o, link14_out_valid_o, link14_out_ready_i,

    link15_in_flit_i, link15_in_valid_i, link15_in_ready_o,
    link15_out_flit_o, link15_out_valid_o, link15_out_ready_i,

    clk, rst
    );

endmodule

`include "lisnoc_undef.vh"
