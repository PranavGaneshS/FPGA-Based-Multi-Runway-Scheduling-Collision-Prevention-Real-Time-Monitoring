//==============================================================================
// Module: oled_controller
// Description: Ultra-Low-Power SSD1306 SPI Controller for Digilent Pmod OLED
//              (128x32 Monochrome).
// Features:
//   1. Proper Pmod OLED power sequencing (VDD on -> Reset -> Init -> VBAT on -> Disp ON).
//   2. Low-contrast command (0x81, 0x15) to cut OLED panel power by ~75%.
//   3. Event-driven refresh: Transmits ONLY when runway state changes.
//   4. Clock/SPI Quieting: In IDLE, SCLK is clamped LOW and CS is deasserted,
//      eliminating dynamic switching dissipation (P = alpha*C*V^2*f -> 0).
//==============================================================================

`timescale 1ns / 1ps

module oled_controller #(
    parameter SIM_SPEEDUP = 0
)(
    input  wire        clk,          // 100 MHz Basys 3 clock
    input  wire        reset,        // Active-high reset

    // Runway status inputs from Airport Scheduler
    input  wire [1:0]  runway_num,   // Runway number: 2'd1, 2'd2, 2'd3
    input  wire [3:0]  runway_flight,// Aircraft ID (4'd0 = free, 4'd1..4'd9)
    input  wire [1:0]  runway_type,  // 00=Free, 01=Landing, 10=Emergency, 11=Takeoff
    input  wire [7:0]  r_timer,      // Remaining busy duration in seconds

    // Physical Digilent Pmod OLED pins
    output reg         oled_cs_n  = 1'b1, // Pin 1: Chip Select (active-low)
    output reg         oled_sdin  = 1'b0, // Pin 2: Serial Data Out (MOSI)
    output reg         oled_sclk  = 1'b0, // Pin 4: Serial Clock
    output reg         oled_dc    = 1'b0, // Pin 7: Data/Command (0=Cmd, 1=Data)
    output reg         oled_res_n = 1'b1, // Pin 8: Reset (active-low)
    output reg         oled_vbat  = 1'b1, // Pin 9: Panel Power Enable (active-low)
    output reg         oled_vdd   = 1'b1  // Pin 10: Logic Power Enable (active-low)
);

    //==========================================================================
    // CONTROLLER STATES
    //==========================================================================
    localparam [3:0]
        ST_POWER_ON     = 4'd0,  // VDD enabled, delay ~20ms
        ST_RESET_PULSE  = 4'd1,  // RES# asserted low for ~50us
        ST_RESET_WAIT   = 4'd2,  // Wait ~5ms after reset release
        ST_INIT_CMDS    = 4'd3,  // Send SSD1306 low-power init commands
        ST_POWER_VBAT   = 4'd4,  // VBAT enabled, delay ~100ms
        ST_DISP_ON      = 4'd5,  // Send 0xAF (Display ON)
        ST_IDLE         = 4'd6,  // Low-power idle state: SPI quiet, clock static
        ST_PAGE_CMD0    = 4'd7,  // Send Page Start Address (0xB0 | page)
        ST_PAGE_CMD1    = 4'd8,  // Send Lower Column Address (0x00)
        ST_PAGE_CMD2    = 4'd9,  // Send Higher Column Address (0x10)
        ST_DATA_BURST   = 4'd10; // Stream 128 pixel column bytes for current page

    reg [3:0] state = ST_POWER_ON;

    // Delay thresholds
    wire [23:0] D_20MS  = (SIM_SPEEDUP) ? 24'd200 : 24'd2_000_000;
    wire [23:0] D_50US  = (SIM_SPEEDUP) ? 24'd10  : 24'd5_000;
    wire [23:0] D_5MS   = (SIM_SPEEDUP) ? 24'd50  : 24'd500_000;
    wire [23:0] D_100MS = (SIM_SPEEDUP) ? 24'd500 : 24'd10_000_000;

    //==========================================================================
    // DELAY & CLOCK COUNTERS
    //==========================================================================
    reg [23:0] delay_cnt = 24'd0;
    
    wire [6:0] SPI_DIV_LIMIT = (SIM_SPEEDUP) ? 7'd3 : 7'd99;
    wire [6:0] SPI_DIV_HALF  = (SIM_SPEEDUP) ? 7'd1 : 7'd49;

    reg [6:0] spi_clk_div = 7'd0;
    wire spi_tick_half = (spi_clk_div == SPI_DIV_HALF);
    wire spi_tick_full = (spi_clk_div == SPI_DIV_LIMIT);

    always @(posedge clk) begin
        if (reset)
            spi_clk_div <= 7'd0;
        else if (spi_clk_div >= SPI_DIV_LIMIT)
            spi_clk_div <= 7'd0;
        else
            spi_clk_div <= spi_clk_div + 1'b1;
    end

    //==========================================================================
    // SPI BYTE TRANSMITTER ENGINE
    //==========================================================================
    reg        spi_start   = 1'b0;
    reg [7:0]  spi_tx_byte = 8'd0;
    reg        spi_is_data = 1'b0;
    reg        spi_busy    = 1'b0;
    reg [3:0]  spi_bit_idx = 4'd0;
    reg [7:0]  spi_shifter = 8'd0;
    reg        spi_done    = 1'b0;
    reg        byte_sent   = 1'b0;

    always @(posedge clk) begin
        if (reset) begin
            oled_cs_n   <= 1'b1;
            oled_sclk   <= 1'b0;
            oled_sdin   <= 1'b0;
            oled_dc     <= 1'b0;
            spi_busy    <= 1'b0;
            spi_bit_idx <= 4'd0;
            spi_shifter <= 8'd0;
            spi_done    <= 1'b0;
        end
        else begin
            spi_done <= 1'b0;

            if (spi_start && !spi_busy) begin
                spi_busy    <= 1'b1;
                spi_shifter <= spi_tx_byte;
                oled_dc     <= spi_is_data;
                oled_cs_n   <= 1'b0;
                oled_sclk   <= 1'b0;
                oled_sdin   <= spi_tx_byte[7];
                spi_bit_idx <= 4'd0;
            end
            else if (spi_busy) begin
                if (spi_tick_half) begin
                    oled_sclk <= 1'b1;
                end
                else if (spi_tick_full) begin
                    oled_sclk <= 1'b0;
                    if (spi_bit_idx == 4'd7) begin
                        spi_busy <= 1'b0;
                        spi_done <= 1'b1;
                    end
                    else begin
                        spi_shifter <= {spi_shifter[6:0], 1'b0};
                        oled_sdin   <= spi_shifter[6];
                        spi_bit_idx <= spi_bit_idx + 1'b1;
                    end
                end
            end
            else if (state == ST_IDLE) begin
                oled_cs_n <= 1'b1;
                oled_sclk <= 1'b0;
                oled_sdin <= 1'b0;
            end
        end
    end

    //==========================================================================
    // INITIALIZATION COMMAND SEQUENCE (SSD1306 128x32 Low-Power Setup)
    //==========================================================================
    localparam INIT_LEN = 5'd24;
    reg [4:0] init_idx = 5'd0;

    function [7:0] get_init_cmd;
        input [4:0] idx;
        begin
            case (idx)
                5'd0:  get_init_cmd = 8'hAE; // Display OFF
                5'd1:  get_init_cmd = 8'h8D; // Charge Pump
                5'd2:  get_init_cmd = 8'h14; // Enable Charge Pump (7.5V)
                5'd3:  get_init_cmd = 8'hD5; // Display Clock Divide
                5'd4:  get_init_cmd = 8'h80; // Default oscillator frequency
                5'd5:  get_init_cmd = 8'hA8; // Multiplex Ratio
                5'd6:  get_init_cmd = 8'h1F; // 31 (for 32 vertical lines)
                5'd7:  get_init_cmd = 8'hD3; // Display Offset
                5'd8:  get_init_cmd = 8'h00; // 0
                5'd9:  get_init_cmd = 8'h40; // Start Line 0
                5'd10: get_init_cmd = 8'h20; // Memory Addressing Mode
                5'd11: get_init_cmd = 8'h02; // Page Addressing Mode
                5'd12: get_init_cmd = 8'hA1; // Segment Remap (COL127 -> SEG0)
                5'd13: get_init_cmd = 8'hC8; // COM Output Scan Direction Remapped
                5'd14: get_init_cmd = 8'hDA; // COM Hardware Config
                5'd15: get_init_cmd = 8'h02; // Sequential COM configuration (128x32)
                5'd16: get_init_cmd = 8'h81; // Contrast Control
                5'd17: get_init_cmd = 8'h15; // 0x15: LOW CONTRAST for ULTRA-LOW POWER CONSUMPTION
                5'd18: get_init_cmd = 8'hD9; // Pre-charge Period
                5'd19: get_init_cmd = 8'h22; // Low-power precharge (Phase 1=2, Phase 2=2)
                5'd20: get_init_cmd = 8'hDB; // VCOMH Deselect Level
                5'd21: get_init_cmd = 8'h20; // ~0.77 x VCC
                5'd22: get_init_cmd = 8'hA4; // Resume from entire display ON
                5'd23: get_init_cmd = 8'hA6; // Normal Display (0=off, 1=on)
                default: get_init_cmd = 8'hAE;
            endcase
        end
    endfunction

    //==========================================================================
    // TEXT GENERATION LOGIC (4 lines x 16 characters)
    //==========================================================================
    reg [1:0] cur_page = 2'd0;
    reg [3:0] cur_char = 4'd0;
    reg [2:0] cur_col  = 3'd0;

    reg [3:0] lat_flight   = 4'd0;
    reg [1:0] lat_type     = 2'd0;
    reg [7:0] lat_timer    = 8'd0;
    reg       need_refresh = 1'b0;
    reg       first_drawn  = 1'b0;

    function [6:0] get_char;
        input [1:0] pg;
        input [3:0] idx;
        input [1:0] rw_num;
        input [3:0] flt_id;
        input [1:0] req_t;
        input [7:0] tmr;
        reg   [6:0] tens_digit;
        reg   [6:0] ones_digit;
        reg   [6:0] flt_char;
        reg   [6:0] rw_char;
        begin
            tens_digit = (tmr / 8'd10) + 7'd48;
            ones_digit = (tmr % 8'd10) + 7'd48;
            flt_char   = flt_id + 7'd48;
            rw_char    = rw_num + 7'd48;

            case (pg)
                2'd0: begin // Line 0: "RUNWAY X: FREE  " or "RUNWAY X: BUSY  "
                    case (idx)
                        4'd0:  get_char = "R";
                        4'd1:  get_char = "U";
                        4'd2:  get_char = "N";
                        4'd3:  get_char = "W";
                        4'd4:  get_char = "A";
                        4'd5:  get_char = "Y";
                        4'd6:  get_char = " ";
                        4'd7:  get_char = rw_char;
                        4'd8:  get_char = ":";
                        4'd9:  get_char = " ";
                        4'd10: get_char = (flt_id != 4'd0) ? "B" : "F";
                        4'd11: get_char = (flt_id != 4'd0) ? "U" : "R";
                        4'd12: get_char = (flt_id != 4'd0) ? "S" : "E";
                        4'd13: get_char = (flt_id != 4'd0) ? "Y" : "E";
                        default: get_char = " ";
                    endcase
                end

                2'd1: begin // Line 1: "FLIGHT: #0X     " or "FLIGHT: NONE    "
                    case (idx)
                        4'd0:  get_char = "F";
                        4'd1:  get_char = "L";
                        4'd2:  get_char = "I";
                        4'd3:  get_char = "G";
                        4'd4:  get_char = "H";
                        4'd5:  get_char = "T";
                        4'd6:  get_char = ":";
                        4'd7:  get_char = " ";
                        4'd8:  get_char = (flt_id != 4'd0) ? "#" : "N";
                        4'd9:  get_char = (flt_id != 4'd0) ? "0" : "O";
                        4'd10: get_char = (flt_id != 4'd0) ? flt_char : "N";
                        4'd11: get_char = (flt_id != 4'd0) ? " " : "E";
                        default: get_char = " ";
                    endcase
                end

                2'd2: begin // Line 2: "TYPE: LANDING   " / "TYPE: EMERGENCY " / "TYPE: TAKEOFF   "
                    case (idx)
                        4'd0:  get_char = "T";
                        4'd1:  get_char = "Y";
                        4'd2:  get_char = "P";
                        4'd3:  get_char = "E";
                        4'd4:  get_char = ":";
                        4'd5:  get_char = " ";
                        default: begin
                            if (flt_id == 4'd0) begin
                                case (idx)
                                    4'd6:  get_char = "N";
                                    4'd7:  get_char = "O";
                                    4'd8:  get_char = "N";
                                    4'd9:  get_char = "E";
                                    default: get_char = " ";
                                endcase
                            end else begin
                                case (req_t)
                                    2'b01: begin // LANDING
                                        case (idx)
                                            4'd6:  get_char = "L";
                                            4'd7:  get_char = "A";
                                            4'd8:  get_char = "N";
                                            4'd9:  get_char = "D";
                                            4'd10: get_char = "I";
                                            4'd11: get_char = "N";
                                            4'd12: get_char = "G";
                                            default: get_char = " ";
                                        endcase
                                    end
                                    2'b10: begin // EMERGENCY
                                        case (idx)
                                            4'd6:  get_char = "E";
                                            4'd7:  get_char = "M";
                                            4'd8:  get_char = "E";
                                            4'd9:  get_char = "R";
                                            4'd10: get_char = "G";
                                            4'd11: get_char = "E";
                                            4'd12: get_char = "N";
                                            4'd13: get_char = "C";
                                            4'd14: get_char = "Y";
                                            default: get_char = " ";
                                        endcase
                                    end
                                    2'b11: begin // TAKEOFF
                                        case (idx)
                                            4'd6:  get_char = "T";
                                            4'd7:  get_char = "A";
                                            4'd8:  get_char = "K";
                                            4'd9:  get_char = "E";
                                            4'd10: get_char = "O";
                                            4'd11: get_char = "F";
                                            4'd12: get_char = "F";
                                            default: get_char = " ";
                                        endcase
                                    end
                                    default: get_char = " ";
                                endcase
                            end
                        end
                    endcase
                end

                2'd3: begin // Line 3: "TIME: 12S LEFT  " or "RUNWAY READY    "
                    if (flt_id == 4'd0) begin
                        case (idx)
                            4'd0:  get_char = "R";
                            4'd1:  get_char = "U";
                            4'd2:  get_char = "N";
                            4'd3:  get_char = "W";
                            4'd4:  get_char = "A";
                            4'd5:  get_char = "Y";
                            4'd6:  get_char = " ";
                            4'd7:  get_char = "R";
                            4'd8:  get_char = "E";
                            4'd9:  get_char = "A";
                            4'd10: get_char = "D";
                            4'd11: get_char = "Y";
                            default: get_char = " ";
                        endcase
                    end else begin
                        case (idx)
                            4'd0:  get_char = "T";
                            4'd1:  get_char = "I";
                            4'd2:  get_char = "M";
                            4'd3:  get_char = "E";
                            4'd4:  get_char = ":";
                            4'd5:  get_char = " ";
                            4'd6:  get_char = tens_digit;
                            4'd7:  get_char = ones_digit;
                            4'd8:  get_char = "S";
                            4'd9:  get_char = " ";
                            4'd10: get_char = "L";
                            4'd11: get_char = "E";
                            4'd12: get_char = "F";
                            4'd13: get_char = "T";
                            default: get_char = " ";
                        endcase
                    end
                end
            endcase
        end
    endfunction

    wire [6:0] active_char = get_char(cur_page, cur_char, runway_num, lat_flight, lat_type, lat_timer);
    wire [7:0] active_font_col;

    font_rom u_font (
        .char_code (active_char),
        .col       (cur_col),
        .font_data (active_font_col)
    );

    //==========================================================================
    // MAIN CONTROLLER FSM
    //==========================================================================
    always @(posedge clk) begin
        if (reset) begin
            state        <= ST_POWER_ON;
            delay_cnt    <= 24'd0;
            init_idx     <= 5'd0;
            cur_page     <= 2'd0;
            cur_char     <= 4'd0;
            cur_col      <= 3'd0;
            spi_start    <= 1'b0;
            spi_tx_byte  <= 8'd0;
            spi_is_data  <= 1'b0;
            byte_sent    <= 1'b0;
            oled_vdd     <= 1'b1;
            oled_vbat    <= 1'b1;
            oled_res_n   <= 1'b1;
            lat_flight   <= 4'd0;
            lat_type     <= 2'd0;
            lat_timer    <= 8'd0;
            need_refresh <= 1'b0;
            first_drawn  <= 1'b0;
        end
        else begin
            spi_start <= 1'b0;

            if ((runway_flight != lat_flight) ||
                (runway_type   != lat_type)   ||
                (r_timer       != lat_timer)   ||
                (!first_drawn)) begin
                need_refresh <= 1'b1;
            end

            case (state)
                ST_POWER_ON: begin
                    oled_vdd   <= 1'b0;
                    oled_vbat  <= 1'b1;
                    oled_res_n <= 1'b1;
                    if (delay_cnt < D_20MS) begin
                        delay_cnt <= delay_cnt + 1'b1;
                    end
                    else begin
                        delay_cnt <= 24'd0;
                        state     <= ST_RESET_PULSE;
                    end
                end

                ST_RESET_PULSE: begin
                    oled_res_n <= 1'b0;
                    if (delay_cnt < D_50US) begin
                        delay_cnt <= delay_cnt + 1'b1;
                    end
                    else begin
                        oled_res_n <= 1'b1;
                        delay_cnt  <= 24'd0;
                        state      <= ST_RESET_WAIT;
                    end
                end

                ST_RESET_WAIT: begin
                    if (delay_cnt < D_5MS) begin
                        delay_cnt <= delay_cnt + 1'b1;
                    end
                    else begin
                        delay_cnt <= 24'd0;
                        init_idx  <= 5'd0;
                        byte_sent <= 1'b0;
                        state     <= ST_INIT_CMDS;
                    end
                end

                ST_INIT_CMDS: begin
                    if (!byte_sent) begin
                        spi_tx_byte <= get_init_cmd(init_idx);
                        spi_is_data <= 1'b0;
                        spi_start   <= 1'b1;
                        byte_sent   <= 1'b1;
                    end
                    else if (spi_done) begin
                        byte_sent <= 1'b0;
                        if (init_idx == INIT_LEN - 1) begin
                            delay_cnt <= 24'd0;
                            state     <= ST_POWER_VBAT;
                        end
                        else begin
                            init_idx <= init_idx + 1'b1;
                        end
                    end
                end

                ST_POWER_VBAT: begin
                    oled_vbat <= 1'b0;
                    if (delay_cnt < D_100MS) begin
                        delay_cnt <= delay_cnt + 1'b1;
                    end
                    else begin
                        delay_cnt <= 24'd0;
                        byte_sent <= 1'b0;
                        state     <= ST_DISP_ON;
                    end
                end

                ST_DISP_ON: begin
                    if (!byte_sent) begin
                        spi_tx_byte <= 8'hAF;
                        spi_is_data <= 1'b0;
                        spi_start   <= 1'b1;
                        byte_sent   <= 1'b1;
                    end
                    else if (spi_done) begin
                        byte_sent    <= 1'b0;
                        state        <= ST_IDLE;
                        need_refresh <= 1'b1;
                    end
                end

                ST_IDLE: begin
                    if (need_refresh) begin
                        need_refresh <= 1'b0;
                        first_drawn  <= 1'b1;
                        lat_flight   <= runway_flight;
                        lat_type     <= runway_type;
                        lat_timer    <= r_timer;
                        cur_page     <= 2'd0;
                        cur_char     <= 4'd0;
                        cur_col      <= 3'd0;
                        byte_sent    <= 1'b0;
                        state        <= ST_PAGE_CMD0;
                    end
                end

                ST_PAGE_CMD0: begin
                    if (!byte_sent) begin
                        spi_tx_byte <= {6'b101100, cur_page};
                        spi_is_data <= 1'b0;
                        spi_start   <= 1'b1;
                        byte_sent   <= 1'b1;
                    end
                    else if (spi_done) begin
                        byte_sent <= 1'b0;
                        state     <= ST_PAGE_CMD1;
                    end
                end

                ST_PAGE_CMD1: begin
                    if (!byte_sent) begin
                        spi_tx_byte <= 8'h00;
                        spi_is_data <= 1'b0;
                        spi_start   <= 1'b1;
                        byte_sent   <= 1'b1;
                    end
                    else if (spi_done) begin
                        byte_sent <= 1'b0;
                        state     <= ST_PAGE_CMD2;
                    end
                end

                ST_PAGE_CMD2: begin
                    if (!byte_sent) begin
                        spi_tx_byte <= 8'h10;
                        spi_is_data <= 1'b0;
                        spi_start   <= 1'b1;
                        byte_sent   <= 1'b1;
                    end
                    else if (spi_done) begin
                        byte_sent <= 1'b0;
                        cur_char  <= 4'd0;
                        cur_col   <= 3'd0;
                        state     <= ST_DATA_BURST;
                    end
                end

                ST_DATA_BURST: begin
                    if (!byte_sent) begin
                        spi_tx_byte <= active_font_col;
                        spi_is_data <= 1'b1;
                        spi_start   <= 1'b1;
                        byte_sent   <= 1'b1;
                    end
                    else if (spi_done) begin
                        byte_sent <= 1'b0;
                        if (cur_col == 3'd7) begin
                            cur_col <= 3'd0;
                            if (cur_char == 4'd15) begin
                                cur_char <= 4'd0;
                                if (cur_page == 2'd3) begin
                                    state <= ST_IDLE;
                                end
                                else begin
                                    cur_page <= cur_page + 1'b1;
                                    state    <= ST_PAGE_CMD0;
                                end
                            end
                            else begin
                                cur_char <= cur_char + 1'b1;
                            end
                        end
                        else begin
                            cur_col <= cur_col + 1'b1;
                        end
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
