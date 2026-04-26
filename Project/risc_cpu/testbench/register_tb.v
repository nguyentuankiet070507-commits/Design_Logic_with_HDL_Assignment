`timescale 1ns/1ps
// ============================================================
// TESTBENCH: REGISTER (dùng chung cho IR và Accumulator)
// Kiểm tra: reset đồng bộ, load, giữ giá trị
// ============================================================
module tb_register;

    reg        clk, rst, load;
    reg  [31:0] data_in;
    wire [31:0] data_out;

    integer pass_count = 0;
    integer fail_count = 0;

    register dut (
        .clk      (clk),
        .rst      (rst),
        .load     (load),
        .data_in  (data_in),
        .data_out (data_out)
    );

    // Clock 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    task check;
        input [31:0] expected;
        input [31:0] actual;
        input [127:0] name;
        begin
            if (expected === actual) begin
                $display("  [PASS] %s | expected=0x%08X, got=0x%08X", name, expected, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("  [FAIL] %s | expected=0x%08X, got=0x%08X  <---", name, expected, actual);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("tb_register.vcd");
        $dumpvars(0, tb_register);
        $display("========== TB REGISTER BẮT ĐẦU ==========");

        // Khởi tạo
        rst = 1; load = 0; data_in = 32'hDEADBEEF;

        // ─────────────────────────────────────────────────────
        // Test 1: Reset đồng bộ — phải đợi cạnh lên của clk
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 1: Reset đồng bộ ---");
        @(posedge clk); #1;
        check(32'd0, data_out, "Reset: data_out = 0");

        // ─────────────────────────────────────────────────────
        // Test 2: Giữ giá trị khi load=0 và rst=0
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 2: Giữ giá trị (hold) ---");
        rst = 0; load = 0; data_in = 32'hABCDEF01;
        @(posedge clk); #1;
        check(32'd0, data_out, "Hold: vẫn = 0, không load");

        @(posedge clk); #1;
        check(32'd0, data_out, "Hold: vẫn = 0 sau nhiều clock");

        // ─────────────────────────────────────────────────────
        // Test 3: Load giá trị mới
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 3: Load giá trị ---");
        rst = 0; load = 1; data_in = 32'hCAFEBABE;
        @(posedge clk); #1;
        check(32'hCAFEBABE, data_out, "Load: data_out = 0xCAFEBABE");

        // Load giá trị khác
        data_in = 32'd12345;
        @(posedge clk); #1;
        check(32'd12345, data_out, "Load: data_out = 12345");

        // ─────────────────────────────────────────────────────
        // Test 4: Tắt load → giữ giá trị cuối
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 4: Tắt load, giữ giá trị ---");
        load = 0; data_in = 32'hFFFFFFFF; // thay đổi input nhưng load=0
        @(posedge clk); #1;
        check(32'd12345, data_out, "Hold sau load: vẫn giữ 12345");

        @(posedge clk); #1;
        check(32'd12345, data_out, "Hold: không bị ảnh hưởng data_in");

        // ─────────────────────────────────────────────────────
        // Test 5: Reset ưu tiên hơn load
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 5: Reset ưu tiên hơn load ---");
        load = 1; rst = 1; data_in = 32'hDEADBEEF;
        @(posedge clk); #1;
        check(32'd0, data_out, "Reset > Load: output = 0 dù load=1");

        // ─────────────────────────────────────────────────────
        // Test 6: Load giá trị 0
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 6: Load giá trị 0 ---");
        rst = 0; load = 1; data_in = 32'd0;
        @(posedge clk); #1;
        check(32'd0, data_out, "Load 0: data_out = 0");

        // Load lại giá trị khác để phân biệt với reset
        data_in = 32'd999;
        @(posedge clk); #1;
        check(32'd999, data_out, "Load 999 sau khi load 0");

        // ─────────────────────────────────────────────────────
        // Test 7: Giá trị biên
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 7: Giá trị biên ---");
        data_in = 32'h80000000; // MSB = 1
        @(posedge clk); #1;
        check(32'h80000000, data_out, "Load MSB=1 (0x80000000)");

        data_in = 32'hFFFFFFFF;
        @(posedge clk); #1;
        check(32'hFFFFFFFF, data_out, "Load all-ones (0xFFFFFFFF)");

        $display("\n========================================");
        $display("KẾT QUẢ: %0d PASS, %0d FAIL", pass_count, fail_count);
        if (fail_count == 0)
            $display(">>> TẤT CẢ TEST PASS! Register hoạt động đúng.");
        else
            $display(">>> CÓ LỖI! Xem lại các case FAIL.");
        $display("========================================");
        $finish;
    end

endmodule