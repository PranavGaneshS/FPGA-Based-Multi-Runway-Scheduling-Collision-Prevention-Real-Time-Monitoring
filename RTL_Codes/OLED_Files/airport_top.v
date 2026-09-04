//==============================================================================
// Module: airport_top
// Description: Basys 3 FPGA Top-Level Module for Airport Runway Scheduler
//              Interfaces:
//              - Switches SW[3:0] : Aircraft ID (1 to 9)
//              - Switches SW[5:4] : Request Type (01=Landing, 10=Emerg, 11=Takeoff)
//              - Switch   SW[15]  : Timer Speed (0=Real 1s tick, 1=Fast demo)
//              - Button   btnC    : Submit Request (debounced single pulse)
//              - Button   btnU    : System Reset (instant synchronizer)
//              - LEDs     LD[3:0] : Emergency Queue Count
//              - LEDs     LD[7:4] : Normal Queue Count
//              - LED      LD[8]   : Allocation Valid (pulse indicator)
//              - LED      LD[9]   : Request Rejected (indicator)
//              - LEDs     LD[15:10]: Echo active switch inputs
//              - Pmod JA          : Runway 1 OLED (128x32 SSD1306)
//              - Pmod JB          : Runway 2 OLED (128x32 SSD1306)
//              - Pmod JC          : Runway 3 OLED (128x32 SSD1306)
//==============================================================================

`timescale 1ns / 1ps

module airport_top #(
    parameter [7:0] BUSY_CYCLES = 8'd12,
    parameter       SIM_SPEEDUP = 0
)(
    input  wire        clk,        // 100 MHz system clock (Pin W5)
    input  wire        btnC,       // Center button: Submit request
    input  wire        btnU,       // Up button: System reset
    input  wire [15:0] sw,         // Slide switches
    output wire [15:0] led,        // User LEDs

    // Pmod Header JA (Runway 1 OLED)
    output wire [7:0]  ja,

    // Pmod Header JB (Runway 2 OLED)
    output wire [7:0]  jb,

    // Pmod Header JC (Runway 3 OLED)
    output wire [7:0]  jc
);

    //==========================================================================
    // RESET SYNCHRONIZATION (Instant 2-stage sync, no 20ms debounce delay)
    //==========================================================================
    reg [1:0] reset_sync = 2'b00;
    always @(posedge clk) begin
        reset_sync <= {reset_sync[0], btnU};
    end
    wire sys_reset = reset_sync[1];

    //==========================================================================
    // INPUT DEBOUNCING FOR SUBMIT BUTTON (btnC)
    //==========================================================================
    wire req_valid_pulse;

    button_pulse #(
        .SIM_SPEEDUP (SIM_SPEEDUP)
    ) u_btn_submit (
        .clk        (clk),
        .btn_in     (btnC),
        .debounced  (),
        .pulse_out  (req_valid_pulse)
    );

    //==========================================================================
    // REAL-TIME HARDWARE 1-SECOND TICK GENERATOR
    // Decrements scheduler busy timers in real-world seconds
    //==========================================================================
    localparam COUNT_1S   = (SIM_SPEEDUP) ? 27'd50     : 27'd100_000_000;
    localparam COUNT_FAST = (SIM_SPEEDUP) ? 27'd10     : 27'd500_000;

    reg [26:0] tick_counter = 27'd0;
    reg        timer_tick_1s = 1'b0;

    wire [26:0] tick_limit = (sw[15]) ? COUNT_FAST : COUNT_1S;

    always @(posedge clk) begin
        if (sys_reset) begin
            tick_counter  <= 27'd0;
            timer_tick_1s <= 1'b0;
        end
        else begin
            if (tick_counter >= tick_limit - 1'b1) begin
                tick_counter  <= 27'd0;
                timer_tick_1s <= 1'b1;
            end
            else begin
                tick_counter  <= tick_counter + 1'b1;
                timer_tick_1s <= 1'b0;
            end
        end
    end

    //==========================================================================
    // AIRPORT SCHEDULER CORE
    //==========================================================================
    wire [3:0] r1_flight, r2_flight, r3_flight;
    wire [1:0] r1_type,   r2_type,   r3_type;
    wire [7:0] r1_timer,  r2_timer,  r3_timer;
    wire [3:0] last_alloc_flight;
    wire [1:0] last_alloc_runway;
    wire       alloc_valid;
    wire       req_rejected;
    wire [3:0] emerg_count;
    wire [3:0] norm_count;
    wire [9:1] parked_flights;

    airport_scheduler #(
        .BUSY_CYCLES (BUSY_CYCLES)
    ) u_scheduler (
        .clk               (clk),
        .reset             (sys_reset),
        .timer_tick        (timer_tick_1s),
        .flight_id         (sw[3:0]),
        .req_type          (sw[5:4]),
        .req_valid         (req_valid_pulse),

        .runway1_flight    (r1_flight),
        .runway2_flight    (r2_flight),
        .runway3_flight    (r3_flight),

        .runway1_type      (r1_type),
        .runway2_type      (r2_type),
        .runway3_type      (r3_type),

        .r1_timer          (r1_timer),
        .r2_timer          (r2_timer),
        .r3_timer          (r3_timer),

        .last_alloc_flight (last_alloc_flight),
        .last_alloc_runway (last_alloc_runway),
        .alloc_valid       (alloc_valid),

        .req_rejected      (req_rejected),
        .emerg_count       (emerg_count),
        .norm_count        (norm_count),
        .parked_flights    (parked_flights)
    );

    //==========================================================================
    // LED STATUS INDICATORS
    //==========================================================================
    reg [23:0] alloc_led_cnt = 24'd0;
    reg [23:0] reject_led_cnt = 24'd0;

    always @(posedge clk) begin
        if (sys_reset) begin
            alloc_led_cnt  <= 24'd0;
            reject_led_cnt <= 24'd0;
        end
        else begin
            if (alloc_valid)
                alloc_led_cnt <= (SIM_SPEEDUP) ? 24'd100 : 24'd10_000_000;
            else if (alloc_led_cnt > 24'd0)
                alloc_led_cnt <= alloc_led_cnt - 1'b1;

            if (req_rejected)
                reject_led_cnt <= (SIM_SPEEDUP) ? 24'd100 : 24'd10_000_000;
            else if (reject_led_cnt > 24'd0)
                reject_led_cnt <= reject_led_cnt - 1'b1;
        end
    end

    assign led[3:0]   = emerg_count;
    assign led[7:4]   = norm_count;
    assign led[8]     = (alloc_led_cnt > 24'd0);
    assign led[9]     = (reject_led_cnt > 24'd0);
    assign led[13:10] = sw[3:0]; // Echo flight_id
    assign led[15:14] = sw[5:4]; // Echo req_type

    //==========================================================================
    // RUNWAY 1 OLED DISPLAY (Pmod JA)
    //==========================================================================
    wire r1_cs_n, r1_sdin, r1_sclk, r1_dc, r1_res_n, r1_vbat, r1_vdd;

    oled_controller #(
        .SIM_SPEEDUP (SIM_SPEEDUP)
    ) u_oled_r1 (
        .clk           (clk),
        .reset         (sys_reset),
        .runway_num    (2'd1),
        .runway_flight (r1_flight),
        .runway_type   (r1_type),
        .r_timer       (r1_timer),

        .oled_cs_n     (r1_cs_n),
        .oled_sdin     (r1_sdin),
        .oled_sclk     (r1_sclk),
        .oled_dc       (r1_dc),
        .oled_res_n    (r1_res_n),
        .oled_vbat     (r1_vbat),
        .oled_vdd      (r1_vdd)
    );

    assign ja[0] = r1_cs_n;   // Pin 1 (CS#)
    assign ja[1] = r1_sdin;   // Pin 2 (MOSI / SDIN)
    assign ja[2] = 1'b0;      // Pin 3 (NC)
    assign ja[3] = r1_sclk;   // Pin 4 (SCLK)
    assign ja[4] = r1_dc;     // Pin 7 (D/C#)
    assign ja[5] = r1_res_n;  // Pin 8 (RES#)
    assign ja[6] = r1_vbat;   // Pin 9 (VBAT#)
    assign ja[7] = r1_vdd;    // Pin 10 (VDD#)

    //==========================================================================
    // RUNWAY 2 OLED DISPLAY (Pmod JB)
    //==========================================================================
    wire r2_cs_n, r2_sdin, r2_sclk, r2_dc, r2_res_n, r2_vbat, r2_vdd;

    oled_controller #(
        .SIM_SPEEDUP (SIM_SPEEDUP)
    ) u_oled_r2 (
        .clk           (clk),
        .reset         (sys_reset),
        .runway_num    (2'd2),
        .runway_flight (r2_flight),
        .runway_type   (r2_type),
        .r_timer       (r2_timer),

        .oled_cs_n     (r2_cs_n),
        .oled_sdin     (r2_sdin),
        .oled_sclk     (r2_sclk),
        .oled_dc       (r2_dc),
        .oled_res_n    (r2_res_n),
        .oled_vbat     (r2_vbat),
        .oled_vdd      (r2_vdd)
    );

    assign jb[0] = r2_cs_n;   // Pin 1 (CS#)
    assign jb[1] = r2_sdin;   // Pin 2 (MOSI / SDIN)
    assign jb[2] = 1'b0;      // Pin 3 (NC)
    assign jb[3] = r2_sclk;   // Pin 4 (SCLK)
    assign jb[4] = r2_dc;     // Pin 7 (D/C#)
    assign jb[5] = r2_res_n;  // Pin 8 (RES#)
    assign jb[6] = r2_vbat;   // Pin 9 (VBAT#)
    assign jb[7] = r2_vdd;    // Pin 10 (VDD#)

    //==========================================================================
    // RUNWAY 3 OLED DISPLAY (Pmod JC)
    //==========================================================================
    wire r3_cs_n, r3_sdin, r3_sclk, r3_dc, r3_res_n, r3_vbat, r3_vdd;

    oled_controller #(
        .SIM_SPEEDUP (SIM_SPEEDUP)
    ) u_oled_r3 (
        .clk           (clk),
        .reset         (sys_reset),
        .runway_num    (2'd3),
        .runway_flight (r3_flight),
        .runway_type   (r3_type),
        .r_timer       (r3_timer),

        .oled_cs_n     (r3_cs_n),
        .oled_sdin     (r3_sdin),
        .oled_sclk     (r3_sclk),
        .oled_dc       (r3_dc),
        .oled_res_n    (r3_res_n),
        .oled_vbat     (r3_vbat),
        .oled_vdd      (r3_vdd)
    );

    assign jc[0] = r3_cs_n;   // Pin 1 (CS#)
    assign jc[1] = r3_sdin;   // Pin 2 (MOSI / SDIN)
    assign jc[2] = 1'b0;      // Pin 3 (NC)
    assign jc[3] = r3_sclk;   // Pin 4 (SCLK)
    assign jc[4] = r3_dc;     // Pin 7 (D/C#)
    assign jc[5] = r3_res_n;  // Pin 8 (RES#)
    assign jc[6] = r3_vbat;   // Pin 9 (VBAT#)
    assign jc[7] = r3_vdd;    // Pin 10 (VDD#)

endmodule
