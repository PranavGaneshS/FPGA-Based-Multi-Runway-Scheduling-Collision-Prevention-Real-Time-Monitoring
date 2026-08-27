`timescale 1ns / 1ps
//====================================================================================
// Title   : FPGA-Based Intelligent Multi-Runway Airport Scheduler
// Runways : 3  (Runway 1, Runway 2, Runway 3)
// Flights : 9  (Flight IDs 1 to 9 ; 0 = invalid / no flight)
//
// req_type encoding :
//    2'b01 -> Landing request
//    2'b10 -> Emergency Landing request
//    2'b11 -> Takeoff request
//
// Scheduling rules :
//    - Emergency landings always have higher priority than normal landings.
//    - Within the same priority class, flights are served First-Come-First-Serve.
//    - A flight is allotted a free runway as soon as one becomes available.
//    - Takeoff immediately frees the runway that flight was occupying.
//    - A runway freed this cycle becomes visible to the allocator from the
//      NEXT clock cycle (clean, single-writer-per-register, no races).
//====================================================================================
module airport_scheduler (
    input  wire        clk,
    input  wire        reset,          // synchronous, active-high

    input  wire [3:0]  flight_id,      // 1-9 (valid), 0 = don't care
    input  wire [1:0]  req_type,       // 01=Landing, 10=Emergency, 11=Takeoff
    input  wire        req_valid,      // 1-cycle pulse : "submit this request"

    output reg  [3:0]  runway1_flight, // 0 = FREE, else flight ID occupying it
    output reg  [3:0]  runway2_flight,
    output reg  [3:0]  runway3_flight,

    output reg  [3:0]  last_alloc_flight,  // flight most recently allotted a runway
    output reg  [1:0]  last_alloc_runway,  // 1 / 2 / 3
    output reg         alloc_valid,        // 1-cycle pulse when an allocation happens

    output reg         req_rejected,       // 1-cycle pulse: invalid / duplicate / queue full

    output reg  [3:0]  emerg_count,        // # flights waiting in emergency queue
    output reg  [3:0]  norm_count          // # flights waiting in normal queue
);

    localparam Q_DEPTH   = 9;
    localparam LANDING   = 2'b01;
    localparam EMERGENCY = 2'b10;
    localparam TAKEOFF   = 2'b11;

    // ---------------------------------------------------------------
    // Two FIFOs: one for emergency requests, one for normal landings
    // ---------------------------------------------------------------
    reg [3:0] emerg_q [0:Q_DEPTH-1];
    reg [3:0] emerg_head;

    reg [3:0] norm_q [0:Q_DEPTH-1];
    reg [3:0] norm_head;

    integer   j;
    reg       dup_or_busy;    // scratch flag: flight already on a runway / already queued
    reg [3:0] next_flight;    // flight picked for allocation this cycle

    // wrap an index that can run 0..16 back into 0..8 (avoids using % on hardware)
    function [3:0] wrap9;
        input [4:0] idx;
        begin
            wrap9 = (idx >= Q_DEPTH) ? (idx - Q_DEPTH) : idx[3:0];
        end
    endfunction

    // current runway occupancy (combinational view of registered state)
    wire runway1_busy = (runway1_flight != 4'd0);
    wire runway2_busy = (runway2_flight != 4'd0);
    wire runway3_busy = (runway3_flight != 4'd0);

    always @(posedge clk) begin
        if (reset) begin
            runway1_flight    <= 4'd0;
            runway2_flight    <= 4'd0;
            runway3_flight    <= 4'd0;
            emerg_head        <= 4'd0;
            emerg_count       <= 4'd0;
            norm_head         <= 4'd0;
            norm_count        <= 4'd0;
            alloc_valid       <= 1'b0;
            req_rejected      <= 1'b0;
            last_alloc_flight <= 4'd0;
            last_alloc_runway <= 2'd0;
        end else begin
            // pulses default low unless explicitly set below
            alloc_valid  <= 1'b0;
            req_rejected <= 1'b0;

            //=====================================================
            // STEP 1: accept a new request (landing / emergency / takeoff)
            //=====================================================
            if (req_valid) begin
                case (req_type)

                    //---------------- TAKEOFF ------------------
                    TAKEOFF: begin
                        if (runway1_flight == flight_id)
                            runway1_flight <= 4'd0;              // runway becomes free
                        else if (runway2_flight == flight_id)
                            runway2_flight <= 4'd0;
                        else if (runway3_flight == flight_id)
                            runway3_flight <= 4'd0;
                        else
                            req_rejected <= 1'b1;                // flight wasn't on any runway
                    end

                    //---------------- EMERGENCY LANDING --------
                    EMERGENCY: begin
                        dup_or_busy = (flight_id == 4'd0) || (flight_id > 4'd9) ||
                                      (runway1_flight == flight_id) ||
                                      (runway2_flight == flight_id) ||
                                      (runway3_flight == flight_id);
                        for (j = 0; j < Q_DEPTH; j = j + 1) begin
                            if (j < emerg_count && emerg_q[wrap9(emerg_head + j)] == flight_id)
                                dup_or_busy = 1'b1;
                            if (j < norm_count  && norm_q[wrap9(norm_head + j)]  == flight_id)
                                dup_or_busy = 1'b1;
                        end

                        if (dup_or_busy || (emerg_count == Q_DEPTH))
                            req_rejected <= 1'b1;
                        else begin
                            emerg_q[wrap9(emerg_head + emerg_count)] <= flight_id;
                            emerg_count <= emerg_count + 1'b1;
                        end
                    end

                    //---------------- NORMAL LANDING -----------
                    LANDING: begin
                        dup_or_busy = (flight_id == 4'd0) || (flight_id > 4'd9) ||
                                      (runway1_flight == flight_id) ||
                                      (runway2_flight == flight_id) ||
                                      (runway3_flight == flight_id);
                        for (j = 0; j < Q_DEPTH; j = j + 1) begin
                            if (j < emerg_count && emerg_q[wrap9(emerg_head + j)] == flight_id)
                                dup_or_busy = 1'b1;
                            if (j < norm_count  && norm_q[wrap9(norm_head + j)]  == flight_id)
                                dup_or_busy = 1'b1;
                        end

                        if (dup_or_busy || (norm_count == Q_DEPTH))
                            req_rejected <= 1'b1;
                        else begin
                            norm_q[wrap9(norm_head + norm_count)] <= flight_id;
                            norm_count <= norm_count + 1'b1;
                        end
                    end

                    default: req_rejected <= 1'b1;               // undefined 2'b00 code
                endcase
            end

            //=====================================================
            // STEP 2: allocate a free runway to the highest-priority
            //         waiting flight (emergency first, then normal, FCFS within class)
            //=====================================================
            if ((emerg_count != 0 || norm_count != 0) &&
                (!runway1_busy || !runway2_busy || !runway3_busy)) begin

                if (emerg_count != 0) begin
                    next_flight = emerg_q[emerg_head];
                    emerg_head  <= wrap9(emerg_head + 1'b1);
                    emerg_count <= emerg_count - 1'b1;
                end else begin
                    next_flight = norm_q[norm_head];
                    norm_head   <= wrap9(norm_head + 1'b1);
                    norm_count  <= norm_count - 1'b1;
                end

                if (!runway1_busy) begin
                    runway1_flight    <= next_flight;
                    last_alloc_runway <= 2'd1;
                end else if (!runway2_busy) begin
                    runway2_flight    <= next_flight;
                    last_alloc_runway <= 2'd2;
                end else begin
                    runway3_flight    <= next_flight;
                    last_alloc_runway <= 2'd3;
                end

                last_alloc_flight <= next_flight;
                alloc_valid       <= 1'b1;
            end
        end
    end

endmodule
