module alu (
    input  [2:0]  opcode,
    input  [31:0] inA,      // Accumulator value
    input  [31:0] inB,      // Memory data
    output reg [31:0] out,
    output        is_zero   // async: inA == 0
);

    assign is_zero = (inA == 32'b0);

    always @(*) begin
        case (opcode)
            3'b000: out = inA;        // HLT
            3'b001: out = inA;        // SKZ
            3'b010: out = inA + inB;  // ADD
            3'b011: out = inA & inB;  // AND
            3'b100: out = inA ^ inB;  // XOR  
            3'b101: out = inB;        // LDA
            3'b110: out = inA;        // STO
            3'b111: out = inA;        // JMP
            default: out = inA;
        endcase
    end
endmodule