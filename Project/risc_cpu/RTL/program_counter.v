module program_counter #(parameter WIDTH = 32) (
    input              clk, rst,
    input              inc,  
    input              load,  
    input  [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] pc_out
);
    always @(posedge clk) begin 
		if (rst) pc_out <= 0;
		else if (load) pc_out <= data_in;
		else if (inc) pc_out <= pc_out + 1;
	end
endmodule