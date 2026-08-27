`timescale 1ns / 1ps
//====================================================================================
// Testbench for airport_scheduler
// Scenario walked through:
//   1) Flights 1,2,3 land -> fill all three runways (FCFS)
//   2) Flight 4 requests landing -> no runway free -> queued (normal queue)
//   3) Flight 5 requests EMERGENCY landing -> jumps ahead of flight 4
//   4) Flight 2 takes off -> frees a runway -> flight 5 (emergency) gets it, not flight 4
//   5) Flight 6 requests EMERGENCY landing while flight 4 still waiting
//   6) Flight 1 takes off -> flight 6 (emergency, FCFS among emergencies) gets the runway
//   7) Flight 3 takes off -> emergency queue now empty -> flight 4 finally gets the runway
//====================================================================================
module airport_scheduler_tb;

    reg        clk;
    reg        reset;
    reg [3:0]  flight_id;
    reg [1:0]  req_type;
    reg        req_valid;

    wire [3:0] runway1_flight, runway2_flight, runway3_flight;
    wire [3:0] last_alloc_flight;
    wire [1:0] last_alloc_runway;
    wire       alloc_valid;
    wire       req_rejected;
    wire [3:0] emerg_count, norm_count;

    localparam LANDING   = 2'b01;
    localparam EMERGENCY = 2'b10;
    localparam TAKEOFF   = 2'b11;

    airport_scheduler DUT (
        .clk(clk), .reset(reset),
        .flight_id(flight_id), .req_type(req_type), .req_valid(req_valid),
        .runway1_flight(runway1_flight),
        .runway2_flight(runway2_flight),
        .runway3_flight(runway3_flight),
        .last_alloc_flight(last_alloc_flight),
        .last_alloc_runway(last_alloc_runway),
        .alloc_valid(alloc_valid),
        .req_rejected(req_rejected),
        .emerg_count(emerg_count),
        .norm_count(norm_count)
    );

    // 100 MHz clock
    always #5 clk = ~clk;

    task send_request(input [3:0] fid, input [1:0] rtype);
        begin
            @(negedge clk);
            flight_id = fid;
            req_type  = rtype;
            req_valid = 1'b1;
            @(negedge clk);
            req_valid = 1'b0;
        end
    endtask

    initial begin
        clk = 0; reset = 1; flight_id = 0; req_type = 0; req_valid = 0;
        repeat (2) @(negedge clk);
        reset = 0;

        // Step 1: three normal landings fill all runways
        send_request(4'd1, LANDING);
        send_request(4'd2, LANDING);
        send_request(4'd3, LANDING);

        // Step 2: normal landing queues up, no runway free
        send_request(4'd4, LANDING);

        // Step 3: emergency landing jumps the normal queue
        send_request(4'd5, EMERGENCY);

        // Step 4: flight 2 takes off, freeing a runway for the emergency flight 5
        send_request(4'd2, TAKEOFF);
        @(negedge clk); // let the freed runway be seen and allocated

        // Step 5: a second emergency arrives while flight 4 still waits
        send_request(4'd6, EMERGENCY);

        // Step 6: flight 1 takes off -> emergency flight 6 (FCFS among emergencies) wins
        send_request(4'd1, TAKEOFF);
        @(negedge clk);

        // Step 7: flight 3 takes off -> emergency queue empty -> flight 4 finally lands
        send_request(4'd3, TAKEOFF);
        @(negedge clk);

        // Try an illegal takeoff (flight 9 was never on a runway) -> should be rejected
        send_request(4'd9, TAKEOFF);

        repeat (5) @(negedge clk);
        $finish;
    end

    // simple monitor
    initial begin
        $display(" time | R1 R2 R3 | emQ nQ | alloc? flight->runway | rejected");
        $monitor("%5t |  %0d  %0d  %0d | %0d   %0d  |   %0d      %0d->%0d      |   %0d",
                  $time, runway1_flight, runway2_flight, runway3_flight,
                  emerg_count, norm_count, alloc_valid, last_alloc_flight,
                  last_alloc_runway, req_rejected);
    end

endmodule
