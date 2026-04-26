`timescale 1ns/1ps
// ============================================================
// TESTBENCH: ALU
// Kiểm tra tất cả 8 opcode và tín hiệu is_zero
// ============================================================
module tb_alu;

    // ── Khai báo tín hiệu ────────────────────────────────────
    reg  [2:0]  opcode;
    reg  [31:0] inA, inB;
    wire [31:0] out;
    wire        is_zero;

    // ── Biến đếm pass/fail ───────────────────────────────────
    integer pass_count = 0;
    integer fail_count = 0;

    // ── Gắn module cần test ──────────────────────────────────
    alu dut (
        .opcode  (opcode),
        .inA     (inA),
        .inB     (inB),
        .out     (out),
        .is_zero (is_zero)
    );

    // ── Task kiểm tra kết quả ────────────────────────────────
    task check;
        input [63:0] expected;
        input [63:0] actual;
        input [127:0] test_name;
        begin
            if (expected === actual) begin
                $display("  [PASS] %s | expected=%0d, got=%0d", test_name, expected, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("  [FAIL] %s | expected=%0d, got=%0d  <---", test_name, expected, actual);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // ── Chương trình test chính ──────────────────────────────
    initial begin
        $dumpfile("tb_alu.vcd");
        $dumpvars(0, tb_alu);
        $display("========== TB ALU BẮT ĐẦU ==========");

        // ------------------------------------------------
        // Test 1: HLT (000) → output = inA (pass-through)
        // ------------------------------------------------
        $display("\n--- HLT (opcode=000) ---");
        opcode = 3'b000; inA = 32'd99; inB = 32'd55; #10;
        check(32'd99, out, "HLT: out = inA");

        // ------------------------------------------------
        // Test 2: SKZ (001) → output = inA, is_zero phản ánh inA
        // ------------------------------------------------
        $display("\n--- SKZ (opcode=001) ---");
        opcode = 3'b001; inA = 32'd5; inB = 32'd0; #10;
        check(32'd5,  out,     "SKZ: out = inA khi inA != 0");
        check(32'd0,  is_zero, "SKZ: is_zero=0 khi inA=5");

        opcode = 3'b001; inA = 32'd0; inB = 32'd99; #10;
        check(32'd0,  out,     "SKZ: out = 0 khi inA=0");
        check(32'd1,  is_zero, "SKZ: is_zero=1 khi inA=0");

        // ------------------------------------------------
        // Test 3: ADD (010) → inA + inB
        // ------------------------------------------------
        $display("\n--- ADD (opcode=010) ---");
        opcode = 3'b010; inA = 32'd10; inB = 32'd5; #10;
        check(32'd15, out, "ADD: 10+5=15");

        opcode = 3'b010; inA = 32'd0; inB = 32'd7; #10;
        check(32'd7, out, "ADD: 0+7=7");

        // Test tràn số (overflow)
        opcode = 3'b010; inA = 32'hFFFFFFFF; inB = 32'd1; #10;
        check(32'd0, out, "ADD: overflow 0xFFFFFFFF+1=0");

        // ------------------------------------------------
        // Test 4: AND (011) → inA & inB
        // ------------------------------------------------
        $display("\n--- AND (opcode=011) ---");
        opcode = 3'b011; inA = 32'hFF00FF00; inB = 32'hFFFF0000; #10;
        check(32'hFF000000, out, "AND: 0xFF00FF00 & 0xFFFF0000");

        opcode = 3'b011; inA = 32'hFFFFFFFF; inB = 32'h0F0F0F0F; #10;
        check(32'h0F0F0F0F, out, "AND: all-ones & mask");

        opcode = 3'b011; inA = 32'hAAAAAAAA; inB = 32'h55555555; #10;
        check(32'h00000000, out, "AND: no overlap = 0");

        // ------------------------------------------------
        // Test 5: XOR (100) → inA ^ inB
        // ------------------------------------------------
        $display("\n--- XOR (opcode=100) ---");
        opcode = 3'b100; inA = 32'hFF00FF00; inB = 32'hFFFF0000; #10;
        check(32'h00FFFF00, out, "XOR: FF00FF00 ^ FFFF0000");

        opcode = 3'b100; inA = 32'hAAAAAAAA; inB = 32'hAAAAAAAA; #10;
        check(32'h00000000, out, "XOR: same values = 0");

        opcode = 3'b100; inA = 32'd0; inB = 32'hDEADBEEF; #10;
        check(32'hDEADBEEF, out, "XOR: 0 ^ x = x");

        // ------------------------------------------------
        // Test 6: LDA (101) → output = inB (load từ memory)
        // ------------------------------------------------
        $display("\n--- LDA (opcode=101) ---");
        opcode = 3'b101; inA = 32'd999; inB = 32'd42; #10;
        check(32'd42, out, "LDA: out = inB, bỏ qua inA");

        opcode = 3'b101; inA = 32'hDEAD; inB = 32'hBEEF; #10;
        check(32'hBEEF, out, "LDA: out = inB=0xBEEF");

        // ------------------------------------------------
        // Test 7: STO (110) → output = inA (ghi ACC ra memory)
        // ------------------------------------------------
        $display("\n--- STO (opcode=110) ---");
        opcode = 3'b110; inA = 32'd77; inB = 32'd0; #10;
        check(32'd77, out, "STO: out = inA=77");

        // ------------------------------------------------
        // Test 8: JMP (111) → output = inA (PC sẽ được load)
        // ------------------------------------------------
        $display("\n--- JMP (opcode=111) ---");
        opcode = 3'b111; inA = 32'd15; inB = 32'd0; #10;
        check(32'd15, out, "JMP: out = inA=15");

        // ------------------------------------------------
        // Test 9: is_zero — kiểm tra bất đồng bộ
        // ------------------------------------------------
        $display("\n--- is_zero (async, mọi opcode) ---");
        opcode = 3'b010; inA = 32'd0;  inB = 32'd5; #5;
        check(1'b1, is_zero, "is_zero=1 khi inA=0");

        inA = 32'd1; #5;
        check(1'b0, is_zero, "is_zero=0 khi inA=1");

        inA = 32'h80000000; #5;
        check(1'b0, is_zero, "is_zero=0 khi inA=0x80000000");

        // ── Tổng kết ─────────────────────────────────────────
        $display("\n========================================");
        $display("KẾT QUẢ: %0d PASS, %0d FAIL", pass_count, fail_count);
        if (fail_count == 0)
            $display(">>> TẤT CẢ TEST PASS! ALU hoạt động đúng.");
        else
            $display(">>> CÓ LỖI! Kiểm tra lại các case FAIL.");
        $display("========================================");
        $finish;
    end

endmodule