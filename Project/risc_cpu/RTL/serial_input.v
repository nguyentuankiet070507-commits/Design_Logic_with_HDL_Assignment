module serial_input_32bit(
    input wire clk,
    input wire rst,

    // Input switch for bit value
    input wire sw_data,

    // Button to confirm current bit
    input wire btn_next,

    // 32-bit output
    output reg [31:0] data_out,

    // Current bit index
    output reg [5:0] bit_index,

    // Finish flag
    output reg done,

    // LED mirror of current switch
    output wire led_current_bit
);

assign led_current_bit = sw_data;

// =====================================================
// Edge detection for btn_next
// =====================================================
reg btn_d;
wire btn_rising;

always @(posedge clk) begin
    btn_d <= btn_next;
end

assign btn_rising = btn_next & ~btn_d;

// =====================================================
// Main logic
// =====================================================
always @(posedge clk or posedge rst) begin
    if (rst) begin
        data_out  <= 32'b0;
        bit_index <= 6'd0;
        done      <= 1'b0;
    end
    else begin

        // Only allow input while not finished
        if (!done) begin

            // On button press
            if (btn_rising) begin

                // Store switch value into current bit
                data_out[bit_index] <= sw_data;

                // If last bit entered
                if (bit_index == 6'd31) begin
                    done <= 1'b1;
                end
                else begin
                    bit_index <= bit_index + 1'b1;
                end
            end
        end
    end
endmodule