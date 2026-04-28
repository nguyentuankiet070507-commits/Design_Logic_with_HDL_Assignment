module memory (
    input              clk,
    input  [31:0]      addr,
    input              rd, wr,
    inout [31:0]		data
);
    reg [31:0] mem [0:31];  // 32 locations
	
	reg [31:0] read_data_reg;

    initial $readmemh("program.hex", mem);
	
	assign data = (rd && !wr)? read_data_reg : 32'bz;
	
	always @(posedge clk)
	begin 
		if (wr && !rd) mem[addr[4:0]] <= data;
		else if (rd && !wr) read_data_reg <= mem[addr[4:0]];
	end
endmodule