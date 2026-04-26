`timescale 1ns/1ps
// ============================================================
// TESTBENCH: MEMORY
// Kiểm tra: ghi (wr), đọc (rd), không đọc/ghi cùng lúc
// ============================================================
module tb_memory;

    reg        clk;
    reg  [4:0]  addr;
    reg        rd, wr;
    reg  [31:0] data_in;
    wire [31:0] data_out;

    integer pass_count = 0;
    integer fail_count = 0;

    memory dut (
        .clk      (clk),
        .addr     (addr),
        .rd       (rd),
        .wr       (wr),
        .data_in  (data_in),
        .data_out (data_out)
    );

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

    // Helper: ghi 1 giá trị vào memory
    task mem_write;
        input [4:0]  a;
        input [31:0] d;
        begin
            addr = a; data_in = d; wr = 1; rd = 0;
            @(posedge clk); #1;
            wr = 0;
        end
    endtask

    // Helper: đọc 1 giá trị từ memory
    task mem_read;
        input [4:0] a;
        begin
            addr = a; wr = 0; rd = 1;
            @(posedge clk); #1;
            rd = 0;
        end
    endtask

    initial begin
        $dumpfile("tb_memory.vcd");
        $dumpvars(0, tb_memory);
        $display("========== TB MEMORY BẮT ĐẦU ==========");

        rd = 0; wr = 0; addr = 0; data_in = 0;
        @(posedge clk); #1; // 1 cycle khởi tạo

        // ─────────────────────────────────────────────────────
        // Test 1: Ghi rồi đọc lại — địa chỉ 0
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 1: Ghi rồi đọc (addr=0) ---");
        mem_write(5'd0, 32'hCAFEBABE);
        mem_read(5'd0);
        check(32'hCAFEBABE, data_out, "Ghi/đọc addr=0: 0xCAFEBABE");

        // ─────────────────────────────────────────────────────
        // Test 2: Ghi/đọc nhiều địa chỉ khác nhau
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 2: Nhiều địa chỉ ---");
        mem_write(5'd1,  32'd100);
        mem_write(5'd2,  32'd200);
        mem_write(5'd10, 32'hDEADBEEF);
        mem_write(5'd31, 32'hFFFFFFFF); // địa chỉ cao nhất

        mem_read(5'd1);  check(32'd100,       data_out, "Đọc addr=1:  100");
        mem_read(5'd2);  check(32'd200,       data_out, "Đọc addr=2:  200");
        mem_read(5'd10); check(32'hDEADBEEF,  data_out, "Đọc addr=10: 0xDEADBEEF");
        mem_read(5'd31); check(32'hFFFFFFFF,  data_out, "Đọc addr=31: 0xFFFFFFFF");

        // ─────────────────────────────────────────────────────
        // Test 3: Ghi đè — giá trị mới phải thắng
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 3: Ghi đè ---");
        mem_write(5'd5, 32'd111);
        mem_write(5'd5, 32'd999); // ghi đè
        mem_read(5'd5);
        check(32'd999, data_out, "Ghi đè addr=5: giá trị mới = 999");

        // ─────────────────────────────────────────────────────
        // Test 4: Địa chỉ không ghi vẫn giữ nguyên
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 4: Địa chỉ khác không bị ảnh hưởng ---");
        mem_write(5'd0, 32'hAAAAAAAA);
        mem_read(5'd1); // địa chỉ 1 không được ghi
        check(32'd100, data_out, "addr=1 không đổi sau khi ghi addr=0");

        // ─────────────────────────────────────────────────────
        // Test 5: Không làm gì khi rd=0, wr=0
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 5: rd=0, wr=0 → giữ data_out ---");
        mem_read(5'd0); // đọc để data_out có giá trị cũ
        // Bây giờ tắt cả rd và wr
        rd = 0; wr = 0; addr = 5'd15; data_in = 32'hBBBBBBBB;
        @(posedge clk); #1;
        check(32'hAAAAAAAA, data_out, "rd=wr=0: data_out giữ nguyên");

        // ─────────────────────────────────────────────────────
        // Test 6: Mô phỏng chương trình thực
        //   - Nạp instruction vào addr 0..3
        //   - Nạp data vào addr 16, 17
        //   - Đọc lần lượt như CPU làm
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 6: Mô phỏng nạp program ---");
        // Instruction: LDA 16, ADD 17, STO 18, HLT
        mem_write(5'd0,  32'h000000B0); // LDA  addr=16 (binary: 10110000)
        mem_write(5'd1,  32'h00000050); // ADD  addr=17 (binary: 01010001)
        mem_write(5'd2,  32'h000000D2); // STO  addr=18 (binary: 11010010)
        mem_write(5'd3,  32'h00000000); // HLT
        // Data
        mem_write(5'd16, 32'd5);
        mem_write(5'd17, 32'd3);

        // CPU đọc instruction
        mem_read(5'd0);  check(32'h000000B0, data_out, "Fetch lệnh 0: LDA");
        mem_read(5'd1);  check(32'h00000050, data_out, "Fetch lệnh 1: ADD");
        mem_read(5'd2);  check(32'h000000D2, data_out, "Fetch lệnh 2: STO");
        mem_read(5'd3);  check(32'h00000000, data_out, "Fetch lệnh 3: HLT");

        // CPU đọc data
        mem_read(5'd16); check(32'd5, data_out, "Đọc data addr=16: 5");
        mem_read(5'd17); check(32'd3, data_out, "Đọc data addr=17: 3");

        // CPU ghi kết quả (STO: 5+3=8)
        mem_write(5'd18, 32'd8);
        mem_read(5'd18); check(32'd8, data_out, "Kết quả STO addr=18: 8");

        $display("\n========================================");
        $display("KẾT QUẢ: %0d PASS, %0d FAIL", pass_count, fail_count);
        if (fail_count == 0)
            $display(">>> TẤT CẢ TEST PASS! Memory hoạt động đúng.");
        else
            $display(">>> CÓ LỖI! Xem lại các case FAIL.");
        $display("========================================");
        $finish;
    end

endmodule