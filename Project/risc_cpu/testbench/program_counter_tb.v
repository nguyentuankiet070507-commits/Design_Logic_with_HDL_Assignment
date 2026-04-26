`timescale 1ns/1ps
// ============================================================
// TESTBENCH: PROGRAM COUNTER
// Kiểm tra: reset, increment, load (jump), ưu tiên tín hiệu
// ============================================================
module tb_program_counter;

    reg        clk, rst, inc, load;
    reg  [31:0] data_in;
    wire [31:0] pc_out;

    integer pass_count = 0;
    integer fail_count = 0;

    program_counter dut (
        .clk     (clk),
        .rst     (rst),
        .inc     (inc),
        .load    (load),
        .data_in (data_in),
        .pc_out  (pc_out)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task check;
        input [31:0] expected;
        input [31:0] actual;
        input [127:0] name;
        begin
            if (expected === actual) begin
                $display("  [PASS] %s | expected=%0d, got=%0d", name, expected, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("  [FAIL] %s | expected=%0d, got=%0d  <---", name, expected, actual);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("tb_program_counter.vcd");
        $dumpvars(0, tb_program_counter);
        $display("========== TB PROGRAM COUNTER BẮT ĐẦU ==========");

        rst = 1; inc = 0; load = 0; data_in = 32'd0;

        // ─────────────────────────────────────────────────────
        // Test 1: Reset về 0
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 1: Reset ---");
        @(posedge clk); #1;
        check(32'd0, pc_out, "Reset: PC = 0");

        // ─────────────────────────────────────────────────────
        // Test 2: Giữ nguyên khi inc=0, load=0
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 2: Hold (không làm gì) ---");
        rst = 0; inc = 0; load = 0;
        @(posedge clk); #1;
        check(32'd0, pc_out, "Hold: PC vẫn = 0");

        // ─────────────────────────────────────────────────────
        // Test 3: Tăng dần (increment)
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 3: Increment ---");
        inc = 1;
        @(posedge clk); #1; check(32'd1, pc_out, "Inc: PC = 1");
        @(posedge clk); #1; check(32'd2, pc_out, "Inc: PC = 2");
        @(posedge clk); #1; check(32'd3, pc_out, "Inc: PC = 3");
        @(posedge clk); #1; check(32'd4, pc_out, "Inc: PC = 4");
        @(posedge clk); #1; check(32'd5, pc_out, "Inc: PC = 5");

        // ─────────────────────────────────────────────────────
        // Test 4: Load (JMP) — nhảy đến địa chỉ bất kỳ
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 4: Load (JMP) ---");
        inc = 0; load = 1; data_in = 32'd20;
        @(posedge clk); #1;
        check(32'd20, pc_out, "JMP: PC nhảy đến 20");

        // Nhảy đến địa chỉ khác
        data_in = 32'd7;
        @(posedge clk); #1;
        check(32'd7, pc_out, "JMP: PC nhảy đến 7");

        // ─────────────────────────────────────────────────────
        // Test 5: Load ưu tiên hơn Inc
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 5: Load ưu tiên hơn Inc ---");
        inc = 1; load = 1; data_in = 32'd15;
        @(posedge clk); #1;
        check(32'd15, pc_out, "Load > Inc: PC = 15 (không +1)");

        // ─────────────────────────────────────────────────────
        // Test 6: Tiếp tục increment từ sau khi load
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 6: Inc tiếp sau khi JMP ---");
        load = 0; inc = 1;
        @(posedge clk); #1; check(32'd16, pc_out, "Inc sau JMP: PC = 16");
        @(posedge clk); #1; check(32'd17, pc_out, "Inc sau JMP: PC = 17");

        // ─────────────────────────────────────────────────────
        // Test 7: Reset ưu tiên cao nhất
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 7: Reset ưu tiên cao nhất ---");
        inc = 1; load = 1; data_in = 32'd31; rst = 1;
        @(posedge clk); #1;
        check(32'd0, pc_out, "Reset > Load > Inc: PC = 0");

        // ─────────────────────────────────────────────────────
        // Test 8: Sau reset, inc bình thường
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 8: Hoạt động bình thường sau reset ---");
        rst = 0; load = 0; inc = 1;
        @(posedge clk); #1; check(32'd1, pc_out, "Sau reset: PC = 1");
        @(posedge clk); #1; check(32'd2, pc_out, "Sau reset: PC = 2");

        // ─────────────────────────────────────────────────────
        // Test 9: Mô phỏng 1 vòng fetch đơn giản
        //         (CPU fetch 3 lệnh, rồi JMP về 0)
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 9: Mô phỏng fetch + JMP về 0 ---");
        rst = 1; inc = 0; load = 0;
        @(posedge clk); #1; // reset

        rst = 0; inc = 1;
        @(posedge clk); #1; check(32'd1, pc_out, "Fetch lệnh 1");
        @(posedge clk); #1; check(32'd2, pc_out, "Fetch lệnh 2");
        @(posedge clk); #1; check(32'd3, pc_out, "Fetch lệnh 3");

        inc = 0; load = 1; data_in = 32'd0; // JMP về đầu
        @(posedge clk); #1; check(32'd0, pc_out, "JMP về 0");

        $display("\n========================================");
        $display("KẾT QUẢ: %0d PASS, %0d FAIL", pass_count, fail_count);
        if (fail_count == 0)
            $display(">>> TẤT CẢ TEST PASS! Program Counter đúng.");
        else
            $display(">>> CÓ LỖI! Xem lại các case FAIL.");
        $display("========================================");
        $finish;
    end

endmodule