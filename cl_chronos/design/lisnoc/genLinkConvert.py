#!/usr/bin/env python3

with open("tmptmp.sv", 'w+') as f:
	for i in range(16):
		f.write(f"""generate
always_comb begin
	if({i} >= num_nodes) begin
		link{i}_in_flit_i = {{flit_width{{1'b0}}}};
		link{i}_in_valid_i = {{vchannels{{1'b0}}}};
		link_in_ready_o[{i}] = {{vchannels{{1'b0}}}};
		link_out_flit_o[{i}] = {{flit_width{{1'b0}}}};
		link_out_valid_o[{i}] = {{vchannels{{1'b0}}}};
		link{i}_out_ready_i = {{vchannels{{1'b0}}}};
	end
	else begin
		link{i}_in_flit_i = {{`FLIT_TYPE_SINGLE, link_in_addr_i[{i}], link_in_flit_i[{i}]}};
		link{i}_in_valid_i = link_in_valid_i[{i}];
		link_in_ready_o[{i}] = link{i}_in_ready_o;
		link_out_flit_o[{i}] = link{i}_out_flit_o[flit_data_width-1:0];
		link_out_valid_o[{i}] = link{i}_out_valid_o;
		link{i}_out_ready_i = link_out_ready_i[{i}];
	end
end
endgenerate
""")
