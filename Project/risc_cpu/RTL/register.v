module register #(parameter WIDTH = 32) (
    input              clk, rst,
    input              load,
    input  [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
    always @(posedge clk) begin
        if (rst)
            data_out <= 0;
        else if (load)
            data_out <= data_in;
    end
endmodule