`timescale 1ns/1ps
// ============================================================
// TESTBENCH: CONTROLLER
// Kiểm tra FSM 8 trạng thái với từng opcode
// Quan trọng nhất: bảng output của từng state phải đúng
// ============================================================
module tb_controller;

    reg        clk, rst;
    reg  [2:0]  opcode;
    reg         is_zero;

    wire sel, rd, ld_ir, halt;
    wire inc_pc, ld_ac, ld_pc, wr, data_e;

    integer pass_count = 0;
    integer fail_count = 0;

    controller dut (
        .clk     (clk),
        .rst     (rst),
        .opcode  (opcode),
        .is_zero (is_zero),
        .sel     (sel),   .rd    (rd),    .ld_ir  (ld_ir),
        .halt    (halt),  .inc_pc(inc_pc),.ld_ac  (ld_ac),
        .ld_pc   (ld_pc), .wr    (wr),    .data_e (data_e)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // Tổng hợp tất cả output thành 1 bus 9-bit để so sánh dễ hơn
    // Thứ tự: {sel, rd, ld_ir, halt, inc_pc, ld_ac, ld_pc, wr, data_e}
    wire [8:0] ctrl_out = {sel, rd, ld_ir, halt, inc_pc, ld_ac, ld_pc, wr, data_e};

    task check_state;
        input [8:0]   expected;
        input [127:0] state_name;
        begin
            if (ctrl_out === expected) begin
                $display("  [PASS] %s | ctrl={sel=%b,rd=%b,ld_ir=%b,halt=%b,inc_pc=%b,ld_ac=%b,ld_pc=%b,wr=%b,data_e=%b}",
                    state_name, sel, rd, ld_ir, halt, inc_pc, ld_ac, ld_pc, wr, data_e);
                pass_count = pass_count + 1;
            end else begin
                $display("  [FAIL] %s", state_name);
                $display("         Expected: sel=%b rd=%b ld_ir=%b halt=%b inc_pc=%b ld_ac=%b ld_pc=%b wr=%b data_e=%b",
                    expected[8],expected[7],expected[6],expected[5],expected[4],expected[3],expected[2],expected[1],expected[0]);
                $display("         Got:      sel=%b rd=%b ld_ir=%b halt=%b inc_pc=%b ld_ac=%b ld_pc=%b wr=%b data_e=%b",
                    sel, rd, ld_ir, halt, inc_pc, ld_ac, ld_pc, wr, data_e);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Helper: đợi 1 clock rồi kiểm tra output
    task tick_check;
        input [8:0]   expected;
        input [127:0] name;
        begin
            @(posedge clk); #1;
            check_state(expected, name);
        end
    endtask

    initial begin
        $dumpfile("tb_controller.vcd");
        $dumpvars(0, tb_controller);
        $display("========== TB CONTROLLER BẮT ĐẦU ==========");

        // Bảng expected output (từ spec):
        // {sel, rd, ld_ir, halt, inc_pc, ld_ac, ld_pc, wr, data_e}
        //  [8]  [7]  [6]   [5]   [4]    [3]    [2]   [1]   [0]

        rst = 1; opcode = 3'b010; is_zero = 0; // ADD, not zero

        // ─────────────────────────────────────────────────────
        // Test 1: Chu kỳ đầy đủ với opcode ADD (010)
        //         ADD cần memory operand → alu_op = 1
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 1: Chu kỳ hoàn chỉnh với ADD ---");
        @(posedge clk); #1; // reset → INST_ADDR
        rst = 0;

        // state 0: INST_ADDR  → sel=1, rest=0
        check_state(9'b100000000, "INST_ADDR: sel=1");

        // state 1: INST_FETCH → sel=1, rd=1
        tick_check(9'b110000000, "INST_FETCH: sel=1,rd=1");

        // state 2: INST_LOAD  → sel=1, rd=1, ld_ir=1
        tick_check(9'b111000000, "INST_LOAD: sel=1,rd=1,ld_ir=1");

        // state 3: IDLE       → sel=1, rd=1, ld_ir=1, inc_pc=1
        tick_check(9'b111010000, "IDLE: sel=1,rd=1,ld_ir=1,inc_pc=1");

        // state 4: OP_ADDR    → tất cả 0 (ADD không halt, không skip)
        tick_check(9'b000000000, "OP_ADDR (ADD): all 0");

        // state 5: OP_FETCH   → rd=1 (ADD cần đọc memory)
        tick_check(9'b010000000, "OP_FETCH (ADD): rd=1");

        // state 6: ALU_OP     → rd=1 (alu_op), ld_pc=0, wr=0
        tick_check(9'b010000000, "ALU_OP (ADD): rd=1");

        // state 7: STORE      → rd=1, ld_ac=1 (lưu kết quả vào ACC)
        tick_check(9'b010001000, "STORE (ADD): rd=1,ld_ac=1");

        // ─────────────────────────────────────────────────────
        // Test 2: Opcode HLT (000) — phải kích hoạt halt ở OP_ADDR
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 2: HLT (000) ---");
        rst = 1; opcode = 3'b000; // HLT
        @(posedge clk); #1; rst = 0;

        // States 0-3 giống nhau với mọi opcode
        tick_check(9'b110000000, "HLT-INST_FETCH");
        tick_check(9'b111000000, "HLT-INST_LOAD");
        tick_check(9'b111010000, "HLT-IDLE");

        // OP_ADDR với HLT: halt=1
        tick_check(9'b000100000, "HLT-OP_ADDR: halt=1");

        // ─────────────────────────────────────────────────────
        // Test 3: SKZ (001) khi is_zero=1 — phải skip (inc_pc=1)
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 3: SKZ khi is_zero=1 ---");
        rst = 1; opcode = 3'b001; is_zero = 1; // SKZ, ACC=0
        @(posedge clk); #1; rst = 0;

        tick_check(9'b110000000, "SKZ-INST_FETCH");
        tick_check(9'b111000000, "SKZ-INST_LOAD");
        tick_check(9'b111010000, "SKZ-IDLE");

        // OP_ADDR với SKZ và is_zero=1: inc_pc=1 (bỏ qua lệnh tiếp)
        tick_check(9'b000010000, "SKZ-OP_ADDR (is_zero=1): inc_pc=1");

        // ─────────────────────────────────────────────────────
        // Test 4: SKZ (001) khi is_zero=0 — không skip
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 4: SKZ khi is_zero=0 ---");
        rst = 1; opcode = 3'b001; is_zero = 0;
        @(posedge clk); #1; rst = 0;

        tick_check(9'b110000000, "SKZ-INST_FETCH");
        tick_check(9'b111000000, "SKZ-INST_LOAD");
        tick_check(9'b111010000, "SKZ-IDLE");

        // OP_ADDR với SKZ và is_zero=0: tất cả 0
        tick_check(9'b000000000, "SKZ-OP_ADDR (is_zero=0): all 0");

        // ─────────────────────────────────────────────────────
        // Test 5: JMP (111) — phải load PC mới
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 5: JMP (111) ---");
        rst = 1; opcode = 3'b111; is_zero = 0;
        @(posedge clk); #1; rst = 0;

        tick_check(9'b110000000, "JMP-INST_FETCH");
        tick_check(9'b111000000, "JMP-INST_LOAD");
        tick_check(9'b111010000, "JMP-IDLE");
        tick_check(9'b000000000, "JMP-OP_ADDR: all 0");
        tick_check(9'b000000000, "JMP-OP_FETCH: rd=0 (JMP không cần data)");

        // ALU_OP với JMP: ld_pc=1
        tick_check(9'b000000100, "JMP-ALU_OP: ld_pc=1");

        // STORE với JMP: ld_pc=1 vẫn còn
        tick_check(9'b000000100, "JMP-STORE: ld_pc=1");

        // ─────────────────────────────────────────────────────
        // Test 6: STO (110) — ghi ACC vào memory
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 6: STO (110) ---");
        rst = 1; opcode = 3'b110; is_zero = 0;
        @(posedge clk); #1; rst = 0;

        tick_check(9'b110000000, "STO-INST_FETCH");
        tick_check(9'b111000000, "STO-INST_LOAD");
        tick_check(9'b111010000, "STO-IDLE");
        tick_check(9'b000000000, "STO-OP_ADDR: all 0");
        tick_check(9'b000000000, "STO-OP_FETCH: rd=0");

        // ALU_OP với STO: wr=1, data_e=1
        tick_check(9'b000000011, "STO-ALU_OP: wr=1,data_e=1");

        // STORE với STO: wr=1, data_e=1 (tiếp tục ghi)
        tick_check(9'b000000011, "STO-STORE: wr=1,data_e=1");

        // ─────────────────────────────────────────────────────
        // Test 7: LDA (101) — load từ memory vào ACC
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 7: LDA (101) ---");
        rst = 1; opcode = 3'b101; is_zero = 0;
        @(posedge clk); #1; rst = 0;

        tick_check(9'b110000000, "LDA-INST_FETCH");
        tick_check(9'b111000000, "LDA-INST_LOAD");
        tick_check(9'b111010000, "LDA-IDLE");
        tick_check(9'b000000000, "LDA-OP_ADDR");
        tick_check(9'b010000000, "LDA-OP_FETCH: rd=1");
        tick_check(9'b010000000, "LDA-ALU_OP: rd=1");
        tick_check(9'b010001000, "LDA-STORE: rd=1,ld_ac=1");

        // ─────────────────────────────────────────────────────
        // Test 8: AND và XOR cũng là alu_op, tương tự ADD
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 8: AND (011) - kiểm tra alu_op flag ---");
        rst = 1; opcode = 3'b011; is_zero = 0;
        @(posedge clk); #1; rst = 0;

        // Nhảy đến STORE (state 7) để kiểm tra ld_ac
        repeat(6) @(posedge clk); #1; // states 0-6
        check_state(9'b010001000, "AND-STORE: rd=1,ld_ac=1 (alu_op)");

        // ─────────────────────────────────────────────────────
        // Test 9: Reset bất kỳ lúc nào → về INST_ADDR
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 9: Reset giữa chừng ---");
        opcode = 3'b010;
        // Đang ở giữa chu kỳ, bất ngờ reset
        rst = 1;
        @(posedge clk); #1;
        check_state(9'b100000000, "Reset giữa chừng → INST_ADDR (sel=1)");
        rst = 0;

        $display("\n========================================");
        $display("KẾT QUẢ: %0d PASS, %0d FAIL", pass_count, fail_count);
        if (fail_count == 0)
            $display(">>> TẤT CẢ TEST PASS! Controller FSM đúng.");
        else
            $display(">>> CÓ LỖI! Kiểm tra lại bảng output của Controller.");
        $display("========================================");
        $finish;
    end

endmodule