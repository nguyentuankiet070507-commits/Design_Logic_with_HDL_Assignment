`timescale 1ns/1ps
// ============================================================
// TESTBENCH: RISC CPU TOP-LEVEL
// Executes a real program and verifies final results.
//
// Test Program:
//   [0] LDA 16   → ACC = mem[16] = 5
//   [1] ADD 17   → ACC = ACC + mem[17] = 5 + 3 = 8
//   [2] AND 18   → ACC = ACC & mem[18] = 8 & 0xFF = 8
//   [3] XOR 19   → ACC = ACC ^ mem[19] = 8 ^ 0 = 8
//   [4] STO 20   → mem[20] = ACC = 8
//   [5] LDA 20   → ACC = mem[20] = 8 (Verify store operation)
//   [6] JMP 7    → Jump to address 7 (Test JMP logic)
//   [7] HLT      → Halt the machine
//
// Data:
//   mem[16] = 5, mem[17] = 3, mem[18] = 0xFF, mem[19] = 0
// ============================================================
module tb_risc_cpu_top;

    reg clk, rst;
    integer pass_count = 0;
    integer fail_count = 0;

    // Instantiate Design Under Test (DUT)
    risc_cpu_top dut (
        .clk (clk),
        .rst (rst)
    );

    // Clock generation (100MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    // Internal signals for verification (Hierarchical References)
    wire [31:0] acc_val  = dut.acc.data_out; // Fixed instance name from acc_reg to acc
    wire [31:0] pc_val   = dut.pc.pc_out;
    wire [2:0]  state    = dut.ctrl.state;
    wire        halt_sig = dut.halt;

    // Task to check results and log status
    task check;
        input [31:0] expected;
        input [31:0] actual;
        input [1023:0] name; // Use large string buffer for names
        begin
            if (expected === actual) begin
                $display("  [PASS] %s | expected=%0d (0x%h), got=%0d (0x%h)",
                    name, expected, expected, actual, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("  [FAIL] %s | expected=%0d, got=%0d  <--- ERROR",
                    name, expected, actual);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Pre-load program into memory
    task load_program;
        integer i;
        begin
            // Clear memory first
            for (i = 0; i < 32; i = i+1)
                dut.mem.mem[i] = 32'd0;

            // Load Instructions (Opcode [7:5] | Address [4:0])
            // Opcodes: HLT=000, ADD=010, AND=011, XOR=100, LDA=101, STO=110, JMP=111
            dut.mem.mem[0]  = {24'b0, 3'b101, 5'd16}; // LDA 16
            dut.mem.mem[1]  = {24'b0, 3'b010, 5'd17}; // ADD 17
            dut.mem.mem[2]  = {24'b0, 3'b011, 5'd18}; // AND 18
            dut.mem.mem[3]  = {24'b0, 3'b100, 5'd19}; // XOR 19
            dut.mem.mem[4]  = {24'b0, 3'b110, 5'd20}; // STO 20
            dut.mem.mem[5]  = {24'b0, 3'b101, 5'd20}; // LDA 20 (Verify)
            dut.mem.mem[6]  = {24'b0, 3'b111, 5'd7};  // JMP 7
            dut.mem.mem[7]  = {24'b0, 3'b000, 5'd0};  // HLT

            // Load Data Operands
            dut.mem.mem[16] = 32'd5;           // Operand A
            dut.mem.mem[17] = 32'd3;           // Operand B
            dut.mem.mem[18] = 32'h000000FF;    // AND Mask
            dut.mem.mem[19] = 32'd0;           // XOR zero (identity)
            dut.mem.mem[20] = 32'd0;           // Result slot (initially 0)

            $display("  Program loaded into memory.");
        end
    endtask

    // Wait for N instructions (each instruction takes 8 clock cycles)
    task wait_instructions;
        input integer n;
        begin
            repeat(n * 8) @(posedge clk);
            #1; // Settle time
        end
    endtask

    initial begin
        $dumpfile("tb_risc_cpu_top.vcd");
        $dumpvars(0, tb_risc_cpu_top);
        $display("========== STARTING RISC CPU TOP-LEVEL TEST ==========");

        // 1. Initialization
        rst = 1; @(posedge clk); #1;
        $display("\n--- Loading Program ---");
        load_program();

        // 2. Start Execution
        $display("\n--- De-asserting Reset ---");
        rst = 0;

        // Verify LDA 16
        wait_instructions(1);
        $display("\n--- After LDA 16 (Inst 1) ---");
        check(32'd5, acc_val, "ACC = mem[16]");
        check(32'd1, pc_val,  "PC Incremented");

        // Verify ADD 17
        wait_instructions(1);
        $display("\n--- After ADD 17 (Inst 2) ---");
        check(32'd8, acc_val, "ACC = 5 + 3");
        check(32'd2, pc_val,  "PC Incremented");

        // Verify AND 18
        wait_instructions(1);
        $display("\n--- After AND 18 (Inst 3) ---");
        check(32'd8, acc_val, "ACC = 8 & 0xFF");

        // Verify STO 20
        wait_instructions(2); // Waiting for STO and then LDA verify
        $display("\n--- After STO 20 and LDA 20 ---");
        check(32'd8, dut.mem.mem[20], "Memory check at addr 20");
        check(32'd8, acc_val,         "ACC re-loaded from addr 20");

        // Verify JMP 7 and HLT
        wait_instructions(2);
        $display("\n--- Final Status Check ---");
        check(32'd7, pc_val, "PC after JMP");
        
        if (halt_sig === 1'b1) begin
            $display("  [PASS] HALT signal detected. CPU stopped correctly.");
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] HALT signal NOT detected.");
            fail_count = fail_count + 1;
        end

        // 3. Reset mid-execution test
        $display("\n--- Testing Mid-Execution Reset ---");
        rst = 1; @(posedge clk); #1;
        check(32'd0, pc_val,  "PC reset to 0");
        check(32'd0, acc_val, "ACC reset to 0");

        // Final Summary
        $display("\n========================================");
        $display("FINAL RESULT: %0d PASS, %0d FAIL", pass_count, fail_count);
        if (fail_count == 0) begin
            $display(">>> ALL TESTS PASSED SUCCESSFULLY!");
        end else begin
            $display(">>> %0d ERRORS FOUND! Check waveforms.", fail_count);
        end
        $display("========================================");
        $finish;
    end
endmodule