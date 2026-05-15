module controller (
    input        clk, rst,
    input  [2:0] opcode,
    input        is_zero,
    output reg   sel, rd, ld_ir, halt,
    output reg   inc_pc, ld_ac, ld_pc, wr, data_e
);
    // State encoding
    localparam INST_ADDR  = 3'd0,
               INST_FETCH = 3'd1,
               INST_LOAD  = 3'd2,
               IDLE       = 3'd3,
               OP_ADDR    = 3'd4,
               OP_FETCH   = 3'd5,
               ALU_OP     = 3'd6,
               STORE      = 3'd7;

    // Opcode parameters
    localparam HLT=3'b000, SKZ=3'b001, ADD=3'b010,
               AND=3'b011, XOR=3'b100, LDA=3'b101,
               STO=3'b110, JMP=3'b111;

    reg [2:0] state;

    // ALU_OP flag: opcode needs memory operand
    wire alu_op = (opcode==ADD||opcode==AND||opcode==XOR||opcode==LDA);

    always @(posedge clk) begin
        if (rst) state <= INST_ADDR;
        else if (halt) state <= OP_ADDR;
        else     state <= state + 1;  // sequential 0→7→0
    end

    always @(*) begin
        // Default all outputs to 0
        {sel,rd,ld_ir,halt,inc_pc,ld_ac,ld_pc,wr,data_e} = 9'b0;
        case (state)
            INST_ADDR:  sel = 1;
            INST_FETCH: begin sel = 1; rd = 1; end
            INST_LOAD:  begin sel = 1; rd = 1; ld_ir = 1; end
            IDLE:       begin sel = 1; rd = 1; ld_ir = 1;
                              inc_pc = 1; end
            OP_ADDR:    begin
                              halt   = (opcode == HLT);
                              inc_pc = (opcode == SKZ) & is_zero;
                        end
            OP_FETCH:   rd = alu_op; 
            ALU_OP:     begin
                              rd     = alu_op;
                              ld_pc  = (opcode == JMP);
                              data_e = (opcode == STO);
                        end
            STORE:      begin
                              rd     = alu_op;
                              ld_ac  = alu_op;
                              ld_pc  = (opcode == JMP);
                              wr     = (opcode == STO);
                              data_e = (opcode == STO);
                        end
        endcase
    end
endmodule
