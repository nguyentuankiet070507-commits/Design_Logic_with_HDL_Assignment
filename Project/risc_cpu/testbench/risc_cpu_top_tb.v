`timescale 1ns/1ps
// ============================================================
// TESTBENCH: RISC CPU TOP-LEVEL
// Chạy một chương trình thực tế và kiểm tra kết quả cuối
//
// Chương trình test:
//   [0] LDA 16   → ACC = mem[16] = 5
//   [1] ADD 17   → ACC = ACC + mem[17] = 5+3 = 8
//   [2] AND 18   → ACC = ACC & mem[18] = 8 & 0xFF = 8
//   [3] XOR 19   → ACC = ACC ^ mem[19] = 8 ^ 0 = 8
//   [4] STO 20   → mem[20] = ACC = 8
//   [5] LDA 20   → ACC = mem[20] = 8 (đọc lại để kiểm tra)
//   [6] JMP 0    → nhảy về địa chỉ 0 (kiểm tra JMP)
//                  (lần 2: chạy lại nhưng dừng sau HLT)
//   [7] HLT      → dừng (lần này sau JMP không chạy nữa)
//
//   Data:
//   mem[16] = 5
//   mem[17] = 3
//   mem[18] = 0xFF
//   mem[19] = 0
// ============================================================
module tb_risc_cpu_top;

    reg clk, rst;

    integer pass_count = 0;
    integer fail_count = 0;

    risc_cpu_top dut (
        .clk (clk),
        .rst (rst)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // Truy cập nội bộ để đọc giá trị kiểm thử
    // (dùng hierarchical reference)
    wire [31:0] acc_val  = dut.acc_reg.data_out;
    wire [31:0] pc_val   = dut.pc.pc_out;
    wire [2:0]  state    = dut.ctrl.state;
    wire        halt_sig = dut.halt;

    task check;
        input [31:0] expected;
        input [31:0] actual;
        input [127:0] name;
        begin
            if (expected === actual) begin
                $display("  [PASS] %s | expected=%0d (0x%08X), got=%0d (0x%08X)",
                    name, expected, expected, actual, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("  [FAIL] %s | expected=%0d, got=%0d  <---",
                    name, expected, actual);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Nạp chương trình vào memory trước khi chạy
    task load_program;
        integer i;
        begin
            // Xóa sạch memory
            for (i = 0; i < 32; i = i+1)
                dut.mem.mem[i] = 32'd0;

            // Instructions (opcode[7:5] | addr[4:0] = 8 bit, zero-pad to 32)
            // LDA=101, ADD=010, AND=011, XOR=100, STO=110, JMP=111, HLT=000
            dut.mem.mem[0]  = {24'b0, 3'b101, 5'd16}; // LDA addr=16
            dut.mem.mem[1]  = {24'b0, 3'b010, 5'd17}; // ADD addr=17
            dut.mem.mem[2]  = {24'b0, 3'b011, 5'd18}; // AND addr=18
            dut.mem.mem[3]  = {24'b0, 3'b100, 5'd19}; // XOR addr=19
            dut.mem.mem[4]  = {24'b0, 3'b110, 5'd20}; // STO addr=20
            dut.mem.mem[5]  = {24'b0, 3'b101, 5'd20}; // LDA addr=20 (verify)
            dut.mem.mem[6]  = {24'b0, 3'b111, 5'd7};  // JMP addr=7
            dut.mem.mem[7]  = {24'b0, 3'b000, 5'd0};  // HLT

            // Data
            dut.mem.mem[16] = 32'd5;           // operand A
            dut.mem.mem[17] = 32'd3;           // operand B
            dut.mem.mem[18] = 32'h000000FF;    // AND mask
            dut.mem.mem[19] = 32'd0;           // XOR with 0 = no change
            dut.mem.mem[20] = 32'd0;           // result slot

            $display("  Program đã được nạp vào memory.");
        end
    endtask

    // Đợi CPU hoàn thành N instructions (mỗi instruction = 8 clock)
    task wait_instructions;
        input integer n;
        begin
            repeat(n * 8) @(posedge clk);
            #1; // settle
        end
    endtask

    initial begin
        $dumpfile("tb_risc_cpu_top.vcd");
        $dumpvars(0, tb_risc_cpu_top);
        $display("========== TB RISC CPU TOP-LEVEL BẮT ĐẦU ==========");

        // ─────────────────────────────────────────────────────
        // Khởi tạo
        // ─────────────────────────────────────────────────────
        rst = 1; @(posedge clk); #1;
        $display("\n--- Nạp chương trình ---");
        load_program();

        // ─────────────────────────────────────────────────────
        // Bắt đầu chạy
        // ─────────────────────────────────────────────────────
        $display("\n--- Bắt đầu chạy CPU ---");
        rst = 0;

        // ─────────────────────────────────────────────────────
        // Sau lệnh 1: LDA 16 → ACC = 5
        // ─────────────────────────────────────────────────────
        wait_instructions(1);
        $display("\n--- Sau LDA 16 (lệnh 1) ---");
        check(32'd5, acc_val, "ACC = mem[16] = 5");
        check(32'd1, pc_val,  "PC = 1 (tiếp theo)");

        // ─────────────────────────────────────────────────────
        // Sau lệnh 2: ADD 17 → ACC = 5+3 = 8
        // ─────────────────────────────────────────────────────
        wait_instructions(1);
        $display("\n--- Sau ADD 17 (lệnh 2) ---");
        check(32'd8, acc_val, "ACC = 5+3 = 8");
        check(32'd2, pc_val,  "PC = 2");

        // ─────────────────────────────────────────────────────
        // Sau lệnh 3: AND 18 → ACC = 8 & 0xFF = 8
        // ─────────────────────────────────────────────────────
        wait_instructions(1);
        $display("\n--- Sau AND 18 (lệnh 3) ---");
        check(32'd8, acc_val, "ACC = 8 & 0xFF = 8");
        check(32'd3, pc_val,  "PC = 3");

        // ─────────────────────────────────────────────────────
        // Sau lệnh 4: XOR 19 → ACC = 8 ^ 0 = 8
        // ─────────────────────────────────────────────────────
        wait_instructions(1);
        $display("\n--- Sau XOR 19 (lệnh 4) ---");
        check(32'd8, acc_val, "ACC = 8 ^ 0 = 8");
        check(32'd4, pc_val,  "PC = 4");

        // ─────────────────────────────────────────────────────
        // Sau lệnh 5: STO 20 → mem[20] = 8
        // ─────────────────────────────────────────────────────
        wait_instructions(1);
        $display("\n--- Sau STO 20 (lệnh 5) ---");
        check(32'd8, dut.mem.mem[20], "mem[20] = 8 (STO thành công)");
        check(32'd5, pc_val,          "PC = 5");

        // ─────────────────────────────────────────────────────
        // Sau lệnh 6: LDA 20 → ACC = mem[20] = 8 (verify STO)
        // ─────────────────────────────────────────────────────
        wait_instructions(1);
        $display("\n--- Sau LDA 20 (lệnh 6 - verify STO) ---");
        check(32'd8, acc_val, "ACC = mem[20] = 8 (STO/LDA verify OK)");
        check(32'd6, pc_val,  "PC = 6");

        // ─────────────────────────────────────────────────────
        // Sau lệnh 7: JMP 7 → PC nhảy đến 7
        // ─────────────────────────────────────────────────────
        wait_instructions(1);
        $display("\n--- Sau JMP 7 (lệnh 7) ---");
        check(32'd7, pc_val, "PC = 7 (JMP thành công)");

        // ─────────────────────────────────────────────────────
        // Sau lệnh 8: HLT → halt signal phải lên
        // ─────────────────────────────────────────────────────
        wait_instructions(1);
        $display("\n--- Sau HLT (lệnh 8) ---");
        if (halt_sig === 1'b1) begin
            $display("  [PASS] HALT signal = 1, CPU dừng đúng");
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] HALT signal = %b, mong đợi = 1", halt_sig);
            fail_count = fail_count + 1;
        end

        // ─────────────────────────────────────────────────────
        // Kiểm tra memory cuối cùng
        // ─────────────────────────────────────────────────────
        $display("\n--- Kiểm tra memory sau khi chạy xong ---");
        check(32'd5, dut.mem.mem[16], "mem[16] không đổi = 5");
        check(32'd3, dut.mem.mem[17], "mem[17] không đổi = 3");
        check(32'd8, dut.mem.mem[20], "mem[20] = 8 (kết quả STO)");

        // ─────────────────────────────────────────────────────
        // Test reset giữa chừng
        // ─────────────────────────────────────────────────────
        $display("\n--- Test: Reset CPU đang chạy ---");
        rst = 1;
        @(posedge clk); #1;
        check(32'd0, pc_val, "PC = 0 sau reset");
        // ACC cũng về 0 sau reset
        check(32'd0, acc_val, "ACC = 0 sau reset");
        rst = 0;

        // ─────────────────────────────────────────────────────
        // Tổng kết
        // ─────────────────────────────────────────────────────
        $display("\n========================================");
        $display("KẾT QUẢ: %0d PASS, %0d FAIL", pass_count, fail_count);
        if (fail_count == 0) begin
            $display(">>> TẤT CẢ TEST PASS!");
            $display(">>> CPU chạy đúng: LDA, ADD, AND, XOR, STO, JMP, HLT");
        end else begin
            $display(">>> CÓ %0d LỖI! Kiểm tra waveform để debug.", fail_count);
        end
        $display("========================================");
        $finish;
    end

    // Monitor: in ra mỗi khi state thay đổi (optional, bỏ comment để debug)
    // initial begin
    //     $monitor("t=%4t | state=%0d | PC=%0d | ACC=%0d | opcode=%b | halt=%b",
    //              $time, state, pc_val, acc_val, dut.opcode, halt_sig);
    // end

endmodule