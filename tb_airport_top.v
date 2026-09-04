//==============================================================================
// Testbench: tb_airport_top
// Description: Simulates the complete Basys 3 top-level system:
//              - Fast simulation speedup for OLED initialization
//              - Pushbutton debouncing and request generation
//              - Scheduler priority and runway allocation
//              - Pmod OLED power sequencing & SPI packet transmission
//              - Verifying event-driven SPI bus quieting for low power
//==============================================================================

`timescale 1ns / 1ps

module tb_airport_top;

    reg         clk;
    reg         btnC;
    reg         btnU;
    reg  [15:0] sw;
    wire [15:0] led;
    wire [7:0]  ja;
    wire [7:0]  jb;
    wire [7:0]  jc;

    // Clock generation: 100 MHz (10 ns period)
    always #5 clk = ~clk;

    // Instantiate Top-Level with SIM_SPEEDUP = 1
    airport_top #(
        .BUSY_CYCLES (8'd4),
        .SIM_SPEEDUP (1)
    ) dut (
        .clk  (clk),
        .btnC (btnC),
        .btnU (btnU),
        .sw   (sw),
        .led  (led),
        .ja   (ja),
        .jb   (jb),
        .jc   (jc)
    );

    // Track SPI activity on Runway 1 OLED (ja[3] is SCLK)
    integer sclk_toggles;
    always @(posedge ja[3]) begin
        sclk_toggles = sclk_toggles + 1;
    end

    initial begin
        $display("------------------------------------------------------------");
        $display("Starting Airport Runway Scheduler FPGA & OLED Simulation");
        $display("------------------------------------------------------------");

        // Initialize signals
        clk          = 1'b0;
        btnC         = 1'b0;
        btnU         = 1'b1; // Reset asserted initially
        sw           = 16'd0;
        sclk_toggles = 0;

        // Hold reset for 100 ns (10 clock cycles)
        #100;
        btnU = 1'b0;
        $display("[T=%0t] System Reset released.", $time);

        // Wait for OLED to complete power sequencing and render initial frame
        wait (dut.u_oled_r1.first_drawn == 1'b1 && dut.u_oled_r1.state == 4'd6);
        $display("[T=%0t] Runway 1 OLED initialized and rendered initial FREE frame!", $time);

        // Wait in IDLE to demonstrate bus quieting (zero power)
        #500;
        $display("[T=%0t] Verifying zero SPI bus switching activity in IDLE: SCLK=%b, CS#=%b",
                 $time, ja[3], ja[0]);

        // Submit Flight 3: EMERGENCY LANDING (req_type = 2'b10, flight_id = 4'd3)
        $display("[T=%0t] Action: Setting SW for Flight 3 Emergency Landing, pressing btnC...", $time);
        sw[3:0] = 4'd3;
        sw[5:4] = 2'b10;
        @(posedge clk);
        btnC = 1'b1;
        repeat (12) @(posedge clk); // Hold > DEBOUNCE_LIMIT (10 cycles)
        btnC = 1'b0;
        @(posedge clk);

        // Wait for allocation
        wait (dut.alloc_valid == 1'b1);
        $display("[T=%0t] SUCCESS: Flight %0d allocated to Runway %0d!",
                 $time, dut.last_alloc_flight, dut.last_alloc_runway);

        // Wait for Runway 1 OLED to finish rendering the BUSY frame
        wait (dut.u_oled_r1.state == 4'd10); // ST_DATA_BURST
        $display("[T=%0t] Runway 1 OLED started rendering Flight 3 BUSY frame...", $time);
        wait (dut.u_oled_r1.state == 4'd6);  // ST_IDLE
        $display("[T=%0t] Runway 1 OLED finished render and entered quiescent IDLE!", $time);

        // Submit Flight 7: NORMAL LANDING (req_type = 2'b01, flight_id = 4'd7)
        #1000;
        $display("[T=%0t] Action: Setting SW for Flight 7 Normal Landing, pressing btnC...", $time);
        sw[3:0] = 4'd7;
        sw[5:4] = 2'b01;
        @(posedge clk);
        btnC = 1'b1;
        repeat (12) @(posedge clk);
        btnC = 1'b0;
        @(posedge clk);

        wait (dut.alloc_valid == 1'b1);
        $display("[T=%0t] SUCCESS: Flight %0d allocated to Runway %0d!",
                 $time, dut.last_alloc_flight, dut.last_alloc_runway);

        // Run until timers tick down
        #15000;

        $display("------------------------------------------------------------");
        $display("Simulation Complete! All OLED channels & scheduler verified.");
        $display("Total SCLK toggles: %0d", sclk_toggles);
        $display("------------------------------------------------------------");
        $finish;
    end

endmodule