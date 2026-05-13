`timescale 1ns/1ps
    btn_next = 0;
    #10;
end
endtask

integer i;
reg [31:0] test_data;

// =====================================================
// Test sequence
// =====================================================
initial begin

    rst = 1;
    sw_data = 0;
    btn_next = 0;

    #20;
    rst = 0;

    // Example input data
    test_data = 32'hA5A5F00F;

    // Input bit-by-bit
    for (i = 0; i < 32; i = i + 1) begin

        sw_data = test_data[i];

        #10;
        press_next();

        $display(
            "Input bit %0d = %b | data_out = %h",
            i,
            sw_data,
            data_out
        );
    end

    #20;

    // Check result
    if (data_out == test_data)
        $display("TEST PASSED: %h", data_out);
    else
        $display("TEST FAILED: got %h expected %h",
                 data_out,
                 test_data);

    #50;
    $finish;
end

endmodule