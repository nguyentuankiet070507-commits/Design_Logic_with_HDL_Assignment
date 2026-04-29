`timescale 1ns/1ps
module tb_memory;
    reg clk, rd, wr;
    reg [31:0] addr; // Sua lai 32-bit cho khop voi module
    
    // KY THUAT TEST CUC KY QUAN TRONG CHO PORT INOUT:
    wire [31:0] data;        // Bat buoc dung wire de noi vao DUT
    reg  [31:0] tb_data_in;  // Bien trung gian de testbench "bom" du lieu

    integer pass_count = 0;
    integer fail_count = 0;

    // Mach Tri-state cua Testbench (Dong vai tro la CPU):
    // Khi CPU ghi (wr=1), day tb_data_in vao bus data.
    // Khi CPU doc (wr=0), phai nha bus (High-Z) de RAM day ket qua ra.
    assign data = (wr) ? tb_data_in : 32'bz;

    memory dut (
        .clk(clk), 
        .addr(addr), 
        .rd(rd), 
        .wr(wr), 
        .data(data)
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

    initial begin
        $dumpfile("tb_memory.vcd");
        $dumpvars(0, tb_memory);
        $display("========== TB MEMORY BAT DAU ==========");

        // Khoi tao
        rd = 0; wr = 0; addr = 0; tb_data_in = 0;
        @(posedge clk); #1;

        // ─────────────────────────────────────────────────────
        // Test 1: Chuc nang Ghi va Doc co ban
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 1: Basic Write/Read ---");
        addr = 32'd10; tb_data_in = 32'hA5A5A5A5; wr = 1; rd = 0;
        @(posedge clk); #1; // RAM thuc hien ghi
        
        wr = 0; rd = 1;     // Tat ghi, bat doc de nha bus
        @(posedge clk); #1; // RAM xuat du lieu
        check(32'hA5A5A5A5, data, "Doc lai o nho so 10");

        // ─────────────────────────────────────────────────────
        // Test 2: Edge Case - Dia chi bien (O so 0 va 31)
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 2: Edge Case - Boundary Addresses ---");
addr = 32'd0;  tb_data_in = 32'h11111111; wr = 1; rd = 0; @(posedge clk); #1;
        addr = 32'd31; tb_data_in = 32'h99999999; wr = 1; rd = 0; @(posedge clk); #1;
        
        wr = 0; rd = 1; 
        addr = 32'd0;  @(posedge clk); #1; check(32'h11111111, data, "Doc o nho so 0");
        addr = 32'd31; @(posedge clk); #1; check(32'h99999999, data, "Doc o nho so 31");

        // ─────────────────────────────────────────────────────
        // Test 3: Edge Case - Tran dia chi (Out of bounds)
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 3: Edge Case - Address Overflow ---");
        // RAM chi lay 5 bit dia chi. Neu nhap dia chi 32 thi phai vong ve 0
        addr = 32'd32; wr = 0; rd = 1; 
        @(posedge clk); #1;
        check(32'h11111111, data, "Truy cap dia chi 32 tu dong vong ve 0");

        // ─────────────────────────────────────────────────────
        // Test 4: Edge Case - rd=1 va wr=1 cung luc (Loi dieu khien)
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 4: Edge Case - Read/Write Conflict ---");
        addr = 32'd5; tb_data_in = 32'hDEADBEEF; wr = 1; rd = 1;
        @(posedge clk); #1; // Module cua ban phai block lenh nay lai
        
        wr = 0; rd = 1; // Doc lai de xem RAM co bi ghi de hay khong
        @(posedge clk); #1;
        if (data !== 32'hDEADBEEF) begin
            $display("  [PASS] RAM an toan tu choi ghi khi rd=1 va wr=1");
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] RAM bi ghi de sai logic khi rd=1 va wr=1");
            fail_count = fail_count + 1;
        end

        // ─────────────────────────────────────────────────────
        // Test 5: Edge Case - Trang thai ranh roi (Idle)
        // ─────────────────────────────────────────────────────
        $display("\n--- Test 5: Edge Case - Idle State ---");
        wr = 0; rd = 0;
        @(posedge clk); #1;
        check(32'bz, data, "Bus dat trang thai High-Z (bz) khi ranh roi");

        // ─────────────────────────────────────────────────────
        // Tong ket
        // ─────────────────────────────────────────────────────
        $display("\n========================================");
$display("KET QUA: %0d PASS, %0d FAIL", pass_count, fail_count);
        if (fail_count == 0)
            $display(">>> TAT CA TEST PASS! Module Memory hoat dong hoan hao.");
        else
            $display(">>> CO LOI! Kiem tra lai cac truong hop FAIL.");
        $display("========================================");
        $finish;
    end
endmodule