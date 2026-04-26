`timescale 1ns/1ps
// ============================================================
// TESTBENCH: ADDRESS MUX
// Kiểm tra: sel=1 chọn PC, sel=0 chọn IR address
// Module này thuần combinational, không cần clock
// ============================================================
module tb_address_mux;

    reg        sel;
    reg  [31:0] pc_addr;
    reg  [31:0] ir_addr;
    wire [31:0] addr_out;

    integer pass_count = 0;
    integer fail_count = 0;

    address_mux dut (
        .sel      (sel),
        .pc_addr  (pc_addr),
        .ir_addr  (ir_addr),
        .addr_out (addr_out)
    );

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
        $dumpfile("tb_address_mux.vcd");
        $dumpvars(0, tb_address_mux);
        $display("========== TB ADDRESS MUX BẮT ĐẦU ==========");

        // ─────────────────────────────────────────────────────
        // Test 1: sel=1 → chọn PC (giai đoạn fetch lệnh)
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 1: sel=1 chọn PC address ---");
        sel = 1; pc_addr = 32'd5; ir_addr = 32'd20; #10;
        check(32'd5, addr_out, "sel=1: out = pc_addr=5");

        sel = 1; pc_addr = 32'd0; ir_addr = 32'd31; #10;
        check(32'd0, addr_out, "sel=1: out = pc_addr=0");

        sel = 1; pc_addr = 32'd15; ir_addr = 32'd3; #10;
        check(32'd15, addr_out, "sel=1: out = pc_addr=15");

        // ─────────────────────────────────────────────────────
        // Test 2: sel=0 → chọn IR address (giai đoạn thực thi)
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 2: sel=0 chọn IR address ---");
        sel = 0; pc_addr = 32'd5; ir_addr = 32'd20; #10;
        check(32'd20, addr_out, "sel=0: out = ir_addr=20");

        sel = 0; pc_addr = 32'd8; ir_addr = 32'd0; #10;
        check(32'd0, addr_out, "sel=0: out = ir_addr=0");

        sel = 0; pc_addr = 32'd3; ir_addr = 32'd31; #10;
        check(32'd31, addr_out, "sel=0: out = ir_addr=31 (max 5-bit)");

        // ─────────────────────────────────────────────────────
        // Test 3: Chuyển đổi sel động (kiểm tra tính tức thì)
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 3: Chuyển sel nhanh ---");
        pc_addr = 32'd10; ir_addr = 32'd25;

        sel = 1; #5; check(32'd10, addr_out, "sel=1: PC=10");
        sel = 0; #5; check(32'd25, addr_out, "sel=0: IR=25 (tức thì)");
        sel = 1; #5; check(32'd10, addr_out, "sel=1: PC=10 (tức thì)");

        // ─────────────────────────────────────────────────────
        // Test 4: Hai địa chỉ giống nhau (edge case)
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 4: PC = IR (edge case) ---");
        sel = 1; pc_addr = 32'd7; ir_addr = 32'd7; #10;
        check(32'd7, addr_out, "PC=IR=7, sel=1: out=7");

        sel = 0; #10;
        check(32'd7, addr_out, "PC=IR=7, sel=0: out=7");

        $display("\n========================================");
        $display("KẾT QUẢ: %0d PASS, %0d FAIL", pass_count, fail_count);
        if (fail_count == 0)
            $display(">>> TẤT CẢ TEST PASS! Address Mux đúng.");
        else
            $display(">>> CÓ LỖI! Xem lại các case FAIL.");
        $display("========================================");
        $finish;
    end

endmodule