//==============================================================================
// Module: button_pulse
// Description: Debounces a physical pushbutton on the Basys 3 board using a
//              20 ms filter at 100 MHz clock and outputs a clean 1-clock-cycle
//              pulse on the rising edge.
//==============================================================================

`timescale 1ns / 1ps

module button_pulse #(
    parameter SIM_SPEEDUP = 0
)(
    input  wire clk,         // 100 MHz system clock
    input  wire btn_in,      // Raw asynchronous button input from pin
    output reg  debounced,   // Clean debounced button level
    output reg  pulse_out    // 1-clock-cycle active-high pulse on press
);

    initial begin
        debounced      = 1'b0;
        pulse_out      = 1'b0;
    end

    // In simulation speedup mode, debounce in 10 cycles; in HW, 2,000,000 cycles (20ms)
    localparam DEBOUNCE_LIMIT = (SIM_SPEEDUP) ? 21'd10 : 21'd2_000_000;

    reg sync_0 = 1'b0;
    reg sync_1 = 1'b0;
    always @(posedge clk) begin
        sync_0 <= btn_in;
        sync_1 <= sync_0;
    end

    reg [20:0] count = 21'd0;
    reg        prev_debounced = 1'b0;

    always @(posedge clk) begin
        if (sync_1 != debounced) begin
            if (count < DEBOUNCE_LIMIT) begin
                count <= count + 1'b1;
            end
            else begin
                debounced <= sync_1;
                count     <= 21'd0;
            end
        end
        else begin
            count <= 21'd0;
        end

        prev_debounced <= debounced;
        pulse_out      <= debounced & ~prev_debounced;
    end

endmodule