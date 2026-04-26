module memory (
    input              clk,
    input  [31:0]      addr,
    input              rd, wr,
    input  [31:0]      data_in,
    output reg [31:0]  data_out
);
    reg [31:0] mem [0:31];  // 32 locations

    initial $readmemh("program.hex", mem);

    always @(posedge clk) begin
        if (wr)
            mem[addr[4:0]] <= data_in;
        else if (rd)
            data_out <= mem[addr[4:0]];
    end
endmodule