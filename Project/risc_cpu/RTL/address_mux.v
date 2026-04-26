module address_mux #(parameter WIDTH = 32) (
    input              sel,        // 0 = IR addr, 1 = PC
    input  [WIDTH-1:0] pc_addr,
    input  [WIDTH-1:0] ir_addr,
    output [WIDTH-1:0] addr_out
);
    assign addr_out = sel ? pc_addr : ir_addr;
endmodule