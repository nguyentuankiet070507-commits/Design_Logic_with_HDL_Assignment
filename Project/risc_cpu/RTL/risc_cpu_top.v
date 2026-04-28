module risc_cpu_top (
    input clk, rst
);
    wire [31:0] pc_out, mux_addr, ir_out, acc_out, alu_out;
    wire [2:0]  opcode;
    wire        is_zero, sel, rd, ld_ir, halt, inc_pc, ld_ac, ld_pc, wr, data_e;
    
    // Quản lý Bidirectional Bus cho Memory
    wire [31:0] mem_bus;
    assign mem_bus = data_e ? acc_out : 32'bz;
    assign opcode = ir_out[7:5]; // 3-bit top of instructions

    program_counter pc (.clk(clk), .rst(rst), .inc(inc_pc), .load(ld_pc), 
                        .data_in(alu_out), .pc_out(pc_out));

    address_mux amux (.sel(sel), .pc_addr(pc_out), .ir_addr({27'b0, ir_out[4:0]}), 
                      .addr_out(mux_addr));

    memory mem (.clk(clk), .addr(mux_addr), .rd(rd), .wr(wr), .data(mem_bus));

    register ir (.clk(clk), .rst(rst), .load(ld_ir), .data_in(mem_bus), .data_out(ir_out));

    register acc (.clk(clk), .rst(rst), .load(ld_ac), .data_in(alu_out), .data_out(acc_out));

    alu alu0 (.opcode(opcode), .inA(acc_out), .inB(mem_bus), .out(alu_out), .is_zero(is_zero));

    controller ctrl (.clk(clk), .rst(rst), .opcode(opcode), .is_zero(is_zero),
                     .sel(sel), .rd(rd), .ld_ir(ld_ir), .halt(halt), .inc_pc(inc_pc), 
                     .ld_ac(ld_ac), .ld_pc(ld_pc), .wr(wr), .data_e(data_e));
endmodule