`timescale 1ns / 1ps

module airport_scheduler_tb;

    localparam [7:0] BUSY_CYCLES = 8'd12; // 12 clock cycles per runway landing

    reg        clk;
    reg        reset;
    reg [3:0]  flight_id;
    reg [1:0]  req_type;
    reg        req_valid;

    wire [3:0] runway1_flight, runway2_flight, runway3_flight;
    wire [7:0] r1_timer, r2_timer, r3_timer;
    wire [3:0] last_alloc_flight;
    wire [1:0] last_alloc_runway;
    wire       alloc_valid;
    wire       req_rejected;
    wire [3:0] emerg_count, norm_count;
    wire [9:1] parked_flights;

    localparam LANDING   = 2'b01;
    localparam EMERGENCY = 2'b10;
    localparam TAKEOFF   = 2'b11;
    localparam UNDEFINED = 2'b00;

    airport_scheduler #(
        .BUSY_CYCLES(BUSY_CYCLES)
    ) DUT (
        .clk(clk),
        .reset(reset),
        .flight_id(flight_id),
        .req_type(req_type),
        .req_valid(req_valid),
        .runway1_flight(runway1_flight),
        .runway2_flight(runway2_flight),
        .runway3_flight(runway3_flight),
        .r1_timer(r1_timer),
        .r2_timer(r2_timer),
        .r3_timer(r3_timer),
        .last_alloc_flight(last_alloc_flight),
        .last_alloc_runway(last_alloc_runway),
        .alloc_valid(alloc_valid),
        .req_rejected(req_rejected),
        .emerg_count(emerg_count),
        .norm_count(norm_count),
        .parked_flights(parked_flights)
    );

    // 100 MHz Clock (10 ns period)
    always #5 clk = ~clk;

    // Send single-cycle request pulse
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

        //-------------------------------------------------------------
        // 1. Initial 3 flights land and fill Runways 1, 2, 3
        //-------------------------------------------------------------
        send_request(4'd1, LANDING);
        send_request(4'd2, LANDING);
        send_request(4'd3, LANDING);

        //-------------------------------------------------------------
        // 2. Queue Normal Flight 4 and Emergency Flight 5
        //-------------------------------------------------------------
        send_request(4'd4, LANDING);    // Queues in norm_q
        send_request(4'd5, EMERGENCY);  // Queues in emerg_q (jumps ahead)

        //-------------------------------------------------------------
        // 3. Duplicate request while Flight 4 is in queue -> REJECT
        //-------------------------------------------------------------
        send_request(4'd4, LANDING);    // req_rejected = 1

        //-------------------------------------------------------------
        // 4. Wait for Runway 1 timer to expire
        //    Emergency Flight 5 must be allocated to Runway 1 first!
        //-------------------------------------------------------------
        repeat (BUSY_CYCLES) @(negedge clk);

        //-------------------------------------------------------------
        // 5. Wait for Runway 2 timer to expire
        //    Normal Flight 4 must now be allocated to Runway 2!
        //-------------------------------------------------------------
        repeat (BUSY_CYCLES) @(negedge clk);

        //-------------------------------------------------------------
        // 6. Wait for timers to expire -> Flights move to Parking Lot
        //-------------------------------------------------------------
        repeat (BUSY_CYCLES + 2) @(negedge clk);

        //-------------------------------------------------------------
        // 7. Duplicate landing request while Flight 4 is parked -> REJECT
        //-------------------------------------------------------------
        send_request(4'd4, LANDING);    // req_rejected = 1

        //-------------------------------------------------------------
        // 8. Flight 4 takes off from Parking Lot -> VALID
        //-------------------------------------------------------------
        send_request(4'd4, TAKEOFF);

        //-------------------------------------------------------------
        // 9. Takeoff for a flight that never landed (Flight 9) -> REJECT
        //-------------------------------------------------------------
        send_request(4'd9, LANDING);    // req_rejected = 1

        
        //-------------------------------------------------------------
        // 11. Early manual takeoff of Flight 4 while on active runway
        //-------------------------------------------------------------
        send_request(4'd4, TAKEOFF);

        //-------------------------------------------------------------
        // 12. Invalid IDs and bad opcodes
        //-------------------------------------------------------------
        send_request(4'd0, LANDING);    // req_rejected = 1
        send_request(4'd15, LANDING);   // req_rejected = 1
        send_request(4'd7, UNDEFINED);  // req_rejected = 1

        repeat (10) @(negedge clk);
        $display("Simulation Finished Successfully.");
        $finish;
    end

endmodule
