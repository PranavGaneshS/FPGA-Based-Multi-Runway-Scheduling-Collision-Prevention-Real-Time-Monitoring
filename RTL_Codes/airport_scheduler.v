`timescale 1ns / 1ps

module airport_scheduler #(
    parameter [7:0] BUSY_CYCLES = 8'd12
)(
    input  wire       clk,
    input  wire       reset,

    // Real-time hardware timer enable tick (1 Hz pulse in HW, 1'b1 in cycle-accurate sim)
    input  wire       timer_tick,

    input  wire [3:0] flight_id,
    input  wire [1:0] req_type,
    input  wire       req_valid,

    //========================================================
    // RUNWAY OUTPUTS
    //========================================================

    output reg [3:0] runway1_flight = 4'd0,
    output reg [3:0] runway2_flight = 4'd0,
    output reg [3:0] runway3_flight = 4'd0,

    //========================================================
    // REQUEST TYPE ON EACH RUNWAY
    //
    // 00 = FREE
    // 01 = LANDING
    // 10 = EMERGENCY
    // 11 = TAKEOFF
    //========================================================

    output reg [1:0] runway1_type = 2'b00,
    output reg [1:0] runway2_type = 2'b00,
    output reg [1:0] runway3_type = 2'b00,

    //========================================================
    // TIMERS
    //========================================================

    output reg [7:0] r1_timer = 8'd0,
    output reg [7:0] r2_timer = 8'd0,
    output reg [7:0] r3_timer = 8'd0,

    //========================================================
    // LAST ALLOCATION
    //========================================================

    output reg [3:0] last_alloc_flight = 4'd0,
    output reg [1:0] last_alloc_runway = 2'd0,
    output reg       alloc_valid       = 1'b0,

    //========================================================
    // REQUEST REJECTED
    //========================================================

    output reg req_rejected = 1'b0,

    //========================================================
    // QUEUE COUNTS
    //========================================================

    output reg [3:0] emerg_count = 4'd0,
    output reg [3:0] norm_count  = 4'd0,

    //========================================================
    // PARKING LOT
    //========================================================

    output reg [9:1] parked_flights = 9'd0
);

    //========================================================
    // CONSTANTS
    //========================================================

    localparam Q_DEPTH = 9;

    localparam UNDEFINED = 2'b00;
    localparam LANDING   = 2'b01;
    localparam EMERGENCY = 2'b10;
    localparam TAKEOFF   = 2'b11;


    //========================================================
    // RUNWAY OPERATION TRACKING
    //
    // 1 = landing
    // 0 = takeoff
    //========================================================

    reg r1_is_landing = 1'b0;
    reg r2_is_landing = 1'b0;
    reg r3_is_landing = 1'b0;


    //========================================================
    // EMERGENCY QUEUE
    //========================================================

    reg [3:0] emerg_q [0:Q_DEPTH-1];
    reg [3:0] emerg_head = 4'd0;


    //========================================================
    // NORMAL QUEUE
    //========================================================

    reg [3:0] norm_q [0:Q_DEPTH-1];
    reg [3:0] norm_head = 4'd0;

    reg norm_is_takeoff [0:Q_DEPTH-1];


    //========================================================
    // TEMPORARY VARIABLES
    //========================================================

    integer j;

    reg dup_or_busy;

    reg [3:0] next_flight;
    reg       next_is_takeoff;
    reg [1:0] next_request_type;


    //========================================================
    // WRAP QUEUE INDEX
    //========================================================

    function [3:0] wrap9;

        input [4:0] idx;

        begin

            if (idx >= Q_DEPTH)
                wrap9 = idx - Q_DEPTH;
            else
                wrap9 = idx[3:0];

        end

    endfunction


    //========================================================
    // MAIN PROCESS
    //========================================================

    always @(posedge clk) begin

        if (reset) begin

            //====================================================
            // RESET RUNWAYS
            //====================================================

            runway1_flight <= 4'd0;
            runway2_flight <= 4'd0;
            runway3_flight <= 4'd0;

            runway1_type <= UNDEFINED;
            runway2_type <= UNDEFINED;
            runway3_type <= UNDEFINED;


            //====================================================
            // RESET TIMERS
            //====================================================

            r1_timer <= 8'd0;
            r2_timer <= 8'd0;
            r3_timer <= 8'd0;


            //====================================================
            // RESET RUNWAY OPERATION TYPE
            //====================================================

            r1_is_landing <= 1'b0;
            r2_is_landing <= 1'b0;
            r3_is_landing <= 1'b0;


            //====================================================
            // RESET QUEUES
            //====================================================

            emerg_head  <= 4'd0;
            emerg_count <= 4'd0;

            norm_head   <= 4'd0;
            norm_count  <= 4'd0;


            //====================================================
            // RESET ALLOCATION
            //====================================================

            last_alloc_flight <= 4'd0;
            last_alloc_runway <= 2'd0;
            alloc_valid       <= 1'b0;


            //====================================================
            // RESET REJECTION
            //====================================================

            req_rejected <= 1'b0;


            //====================================================
            // RESET PARKING
            //====================================================

            parked_flights <= 9'b0;

        end

        else begin

            //====================================================
            // DEFAULT ONE-CYCLE SIGNALS
            //====================================================

            alloc_valid  <= 1'b0;
            req_rejected <= 1'b0;


            //====================================================
            // RUNWAY 1 TIMER (Gated with timer_tick for HW timing & power)
            //====================================================

            if (runway1_flight != 4'd0) begin

                if (timer_tick) begin

                    if (r1_timer > 8'd1) begin

                        r1_timer <= r1_timer - 1'b1;

                    end

                    else if (r1_timer == 8'd1) begin

                        r1_timer <= 8'd0;

                        if (r1_is_landing)
                            parked_flights[runway1_flight] <= 1'b1;

                        runway1_flight <= 4'd0;
                        runway1_type   <= UNDEFINED;

                    end

                end

            end


            //====================================================
            // RUNWAY 2 TIMER
            //====================================================

            if (runway2_flight != 4'd0) begin

                if (timer_tick) begin

                    if (r2_timer > 8'd1) begin

                        r2_timer <= r2_timer - 1'b1;

                    end

                    else if (r2_timer == 8'd1) begin

                        r2_timer <= 8'd0;

                        if (r2_is_landing)
                            parked_flights[runway2_flight] <= 1'b1;

                        runway2_flight <= 4'd0;
                        runway2_type   <= UNDEFINED;

                    end

                end

            end


            //====================================================
            // RUNWAY 3 TIMER
            //====================================================

            if (runway3_flight != 4'd0) begin

                if (timer_tick) begin

                    if (r3_timer > 8'd1) begin

                        r3_timer <= r3_timer - 1'b1;

                    end

                    else if (r3_timer == 8'd1) begin

                        r3_timer <= 8'd0;

                        if (r3_is_landing)
                            parked_flights[runway3_flight] <= 1'b1;

                        runway3_flight <= 4'd0;
                        runway3_type   <= UNDEFINED;

                    end

                end

            end


            //====================================================
            // HANDLE REQUEST
            //====================================================

            if (req_valid) begin

                case (req_type)

                    //================================================
                    // TAKEOFF
                    //================================================

                    TAKEOFF: begin

                        if ((flight_id >= 4'd1) &&
                            (flight_id <= 4'd9) &&
                            parked_flights[flight_id]) begin

                            dup_or_busy = 1'b0;

                            for (j = 0; j < Q_DEPTH; j = j + 1) begin

                                if ((j < norm_count) &&
                                    (norm_q[
                                        wrap9(norm_head + j)
                                    ] == flight_id))

                                    dup_or_busy = 1'b1;

                            end


                            if (dup_or_busy ||
                                (norm_count == Q_DEPTH)) begin

                                req_rejected <= 1'b1;

                            end

                            else begin

                                norm_q[
                                    wrap9(norm_head + norm_count)
                                ] <= flight_id;

                                norm_is_takeoff[
                                    wrap9(norm_head + norm_count)
                                ] <= 1'b1;

                                norm_count <= norm_count + 1'b1;

                                parked_flights[flight_id] <= 1'b0;

                            end

                        end

                        else begin

                            req_rejected <= 1'b1;

                        end

                    end


                    //================================================
                    // EMERGENCY LANDING
                    //================================================

                    EMERGENCY: begin

                        dup_or_busy =
                            (flight_id == 4'd0) ||
                            (flight_id > 4'd9) ||
                            (runway1_flight == flight_id) ||
                            (runway2_flight == flight_id) ||
                            (runway3_flight == flight_id) ||
                            parked_flights[flight_id];


                        for (j = 0; j < Q_DEPTH; j = j + 1) begin

                            if ((j < emerg_count) &&
                                (emerg_q[
                                    wrap9(emerg_head + j)
                                ] == flight_id))

                                dup_or_busy = 1'b1;


                            if ((j < norm_count) &&
                                (norm_q[
                                    wrap9(norm_head + j)
                                ] == flight_id))

                                dup_or_busy = 1'b1;

                        end


                        if (dup_or_busy ||
                            (emerg_count == Q_DEPTH)) begin

                            req_rejected <= 1'b1;

                        end

                        else begin

                            emerg_q[
                                wrap9(emerg_head + emerg_count)
                            ] <= flight_id;

                            emerg_count <= emerg_count + 1'b1;

                        end

                    end


                    //================================================
                    // NORMAL LANDING
                    //================================================

                    LANDING: begin

                        dup_or_busy =
                            (flight_id == 4'd0) ||
                            (flight_id > 4'd9) ||
                            (runway1_flight == flight_id) ||
                            (runway2_flight == flight_id) ||
                            (runway3_flight == flight_id) ||
                            parked_flights[flight_id];


                        for (j = 0; j < Q_DEPTH; j = j + 1) begin

                            if ((j < emerg_count) &&
                                (emerg_q[
                                    wrap9(emerg_head + j)
                                ] == flight_id))

                                dup_or_busy = 1'b1;


                            if ((j < norm_count) &&
                                (norm_q[
                                    wrap9(norm_head + j)
                                ] == flight_id))

                                dup_or_busy = 1'b1;

                        end


                        if (dup_or_busy ||
                            (norm_count == Q_DEPTH)) begin

                            req_rejected <= 1'b1;

                        end

                        else begin

                            norm_q[
                                wrap9(norm_head + norm_count)
                            ] <= flight_id;

                            norm_is_takeoff[
                                wrap9(norm_head + norm_count)
                            ] <= 1'b0;

                            norm_count <= norm_count + 1'b1;

                        end

                    end


                    //================================================
                    // INVALID
                    //================================================

                    default: begin

                        req_rejected <= 1'b1;

                    end

                endcase

            end


            //====================================================
            // RUNWAY ALLOCATION
            //====================================================

            if ((emerg_count != 4'd0) ||
                (norm_count != 4'd0)) begin


                //================================================
                // RUNWAY 1
                //================================================

                if ((runway1_flight == 4'd0) ||
                    (r1_timer == 8'd1 && timer_tick)) begin

                    if (emerg_count != 4'd0) begin

                        next_flight =
                            emerg_q[emerg_head];

                        next_is_takeoff = 1'b0;

                        next_request_type = EMERGENCY;

                        emerg_head <=
                            wrap9(emerg_head + 1'b1);

                        emerg_count <=
                            emerg_count - 1'b1;

                    end

                    else begin

                        next_flight =
                            norm_q[norm_head];

                        next_is_takeoff =
                            norm_is_takeoff[norm_head];

                        if (norm_is_takeoff[norm_head])
                            next_request_type = TAKEOFF;
                        else
                            next_request_type = LANDING;

                        norm_head <=
                            wrap9(norm_head + 1'b1);

                        norm_count <=
                            norm_count - 1'b1;

                    end


                    runway1_flight <= next_flight;
                    runway1_type   <= next_request_type;

                    r1_is_landing <= ~next_is_takeoff;
                    r1_timer      <= BUSY_CYCLES;

                    last_alloc_runway <= 2'd1;
                    last_alloc_flight <= next_flight;

                    alloc_valid <= 1'b1;

                end


                //================================================
                // RUNWAY 2
                //================================================

                else if ((runway2_flight == 4'd0) ||
                         (r2_timer == 8'd1 && timer_tick)) begin

                    if (emerg_count != 4'd0) begin

                        next_flight =
                            emerg_q[emerg_head];

                        next_is_takeoff = 1'b0;

                        next_request_type = EMERGENCY;

                        emerg_head <=
                            wrap9(emerg_head + 1'b1);

                        emerg_count <=
                            emerg_count - 1'b1;

                    end

                    else begin

                        next_flight =
                            norm_q[norm_head];

                        next_is_takeoff =
                            norm_is_takeoff[norm_head];

                        if (norm_is_takeoff[norm_head])
                            next_request_type = TAKEOFF;
                        else
                            next_request_type = LANDING;

                        norm_head <=
                            wrap9(norm_head + 1'b1);

                        norm_count <=
                            norm_count - 1'b1;

                    end


                    runway2_flight <= next_flight;
                    runway2_type   <= next_request_type;

                    r2_is_landing <= ~next_is_takeoff;
                    r2_timer      <= BUSY_CYCLES;

                    last_alloc_runway <= 2'd2;
                    last_alloc_flight <= next_flight;

                    alloc_valid <= 1'b1;

                end


                //================================================
                // RUNWAY 3
                //================================================

                else if ((runway3_flight == 4'd0) ||
                         (r3_timer == 8'd1 && timer_tick)) begin

                    if (emerg_count != 4'd0) begin

                        next_flight =
                            emerg_q[emerg_head];

                        next_is_takeoff = 1'b0;

                        next_request_type = EMERGENCY;

                        emerg_head <=
                            wrap9(emerg_head + 1'b1);

                        emerg_count <=
                            emerg_count - 1'b1;

                    end

                    else begin

                        next_flight =
                            norm_q[norm_head];

                        next_is_takeoff =
                            norm_is_takeoff[norm_head];

                        if (norm_is_takeoff[norm_head])
                            next_request_type = TAKEOFF;
                        else
                            next_request_type = LANDING;

                        norm_head <=
                            wrap9(norm_head + 1'b1);

                        norm_count <=
                            norm_count - 1'b1;

                    end


                    runway3_flight <= next_flight;
                    runway3_type   <= next_request_type;

                    r3_is_landing <= ~next_is_takeoff;
                    r3_timer      <= BUSY_CYCLES;

                    last_alloc_runway <= 2'd3;
                    last_alloc_flight <= next_flight;

                    alloc_valid <= 1'b1;

                end

            end

        end

    end

endmodule
