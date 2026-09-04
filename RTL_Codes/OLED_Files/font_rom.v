//==============================================================================
// Module: font_rom
// Description: 8x8 ASCII Font ROM for 128x32 SSD1306 OLED Display.
//              Provides vertical slice (column) byte: bit 0 = top pixel,
//              bit 7 = bottom pixel.
// Optimized for low logic footprint and low power.
//==============================================================================

`timescale 1ns / 1ps

module font_rom (
    input  wire [6:0] char_code, // ASCII character code (32 ' ' to 90 'Z')
    input  wire [2:0] col,       // Column index within character (0 to 7)
    output reg  [7:0] font_data  // 8 vertical pixels for this column
);

    always @(*) begin
        case (char_code)
            // Space (ASCII 32)
            7'd32: font_data = 8'h00;

            // '#' (ASCII 35)
            7'd35: begin
                case (col)
                    3'd0: font_data = 8'h14;
                    3'd1: font_data = 8'h7F;
                    3'd2: font_data = 8'h14;
                    3'd3: font_data = 8'h14;
                    3'd4: font_data = 8'h7F;
                    3'd5: font_data = 8'h14;
                    default: font_data = 8'h00;
                endcase
            end

            // '(' (ASCII 40)
            7'd40: begin
                case (col)
                    3'd1: font_data = 8'h1C;
                    3'd2: font_data = 8'h22;
                    3'd3: font_data = 8'h41;
                    default: font_data = 8'h00;
                endcase
            end

            // ')' (ASCII 41)
            7'd41: begin
                case (col)
                    3'd1: font_data = 8'h41;
                    3'd2: font_data = 8'h22;
                    3'd3: font_data = 8'h1C;
                    default: font_data = 8'h00;
                endcase
            end

            // '-' (ASCII 45)
            7'd45: begin
                case (col)
                    3'd1: font_data = 8'h08;
                    3'd2: font_data = 8'h08;
                    3'd3: font_data = 8'h08;
                    3'd4: font_data = 8'h08;
                    default: font_data = 8'h00;
                endcase
            end

            // ':' (ASCII 58)
            7'd58: begin
                case (col)
                    3'd2: font_data = 8'h36;
                    3'd3: font_data = 8'h36;
                    default: font_data = 8'h00;
                endcase
            end

            // '0' (ASCII 48)
            7'd48: begin
                case (col)
                    3'd0: font_data = 8'h3E;
                    3'd1: font_data = 8'h51;
                    3'd2: font_data = 8'h49;
                    3'd3: font_data = 8'h45;
                    3'd4: font_data = 8'h3E;
                    default: font_data = 8'h00;
                endcase
            end

            // '1' (ASCII 49)
            7'd49: begin
                case (col)
                    3'd0: font_data = 8'h00;
                    3'd1: font_data = 8'h42;
                    3'd2: font_data = 8'h7F;
                    3'd3: font_data = 8'h40;
                    default: font_data = 8'h00;
                endcase
            end

            // '2' (ASCII 50)
            7'd50: begin
                case (col)
                    3'd0: font_data = 8'h42;
                    3'd1: font_data = 8'h61;
                    3'd2: font_data = 8'h51;
                    3'd3: font_data = 8'h49;
                    3'd4: font_data = 8'h46;
                    default: font_data = 8'h00;
                endcase
            end

            // '3' (ASCII 51)
            7'd51: begin
                case (col)
                    3'd0: font_data = 8'h21;
                    3'd1: font_data = 8'h41;
                    3'd2: font_data = 8'h45;
                    3'd3: font_data = 8'h4B;
                    3'd4: font_data = 8'h31;
                    default: font_data = 8'h00;
                endcase
            end

            // '4' (ASCII 52)
            7'd52: begin
                case (col)
                    3'd0: font_data = 8'h18;
                    3'd1: font_data = 8'h14;
                    3'd2: font_data = 8'h12;
                    3'd3: font_data = 8'h7F;
                    3'd4: font_data = 8'h10;
                    default: font_data = 8'h00;
                endcase
            end

            // '5' (ASCII 53)
            7'd53: begin
                case (col)
                    3'd0: font_data = 8'h27;
                    3'd1: font_data = 8'h45;
                    3'd2: font_data = 8'h45;
                    3'd3: font_data = 8'h45;
                    3'd4: font_data = 8'h39;
                    default: font_data = 8'h00;
                endcase
            end

            // '6' (ASCII 54)
            7'd54: begin
                case (col)
                    3'd0: font_data = 8'h3C;
                    3'd1: font_data = 8'h4A;
                    3'd2: font_data = 8'h49;
                    3'd3: font_data = 8'h49;
                    3'd4: font_data = 8'h30;
                    default: font_data = 8'h00;
                endcase
            end

            // '7' (ASCII 55)
            7'd55: begin
                case (col)
                    3'd0: font_data = 8'h01;
                    3'd1: font_data = 8'h71;
                    3'd2: font_data = 8'h09;
                    3'd3: font_data = 8'h05;
                    3'd4: font_data = 8'h03;
                    default: font_data = 8'h00;
                endcase
            end

            // '8' (ASCII 56)
            7'd56: begin
                case (col)
                    3'd0: font_data = 8'h36;
                    3'd1: font_data = 8'h49;
                    3'd2: font_data = 8'h49;
                    3'd3: font_data = 8'h49;
                    3'd4: font_data = 8'h36;
                    default: font_data = 8'h00;
                endcase
            end

            // '9' (ASCII 57)
            7'd57: begin
                case (col)
                    3'd0: font_data = 8'h06;
                    3'd1: font_data = 8'h49;
                    3'd2: font_data = 8'h49;
                    3'd3: font_data = 8'h29;
                    3'd4: font_data = 8'h1E;
                    default: font_data = 8'h00;
                endcase
            end

            // 'A' (ASCII 65)
            7'd65: begin
                case (col)
                    3'd0: font_data = 8'h7E;
                    3'd1: font_data = 8'h09;
                    3'd2: font_data = 8'h09;
                    3'd3: font_data = 8'h09;
                    3'd4: font_data = 8'h7E;
                    default: font_data = 8'h00;
                endcase
            end

            // 'B' (ASCII 66)
            7'd66: begin
                case (col)
                    3'd0: font_data = 8'h7F;
                    3'd1: font_data = 8'h49;
                    3'd2: font_data = 8'h49;
                    3'd3: font_data = 8'h49;
                    3'd4: font_data = 8'h36;
                    default: font_data = 8'h00;
                endcase
            end

            // 'C' (ASCII 67)
            7'd67: begin
                case (col)
                    3'd0: font_data = 8'h3E;
                    3'd1: font_data = 8'h41;
                    3'd2: font_data = 8'h41;
                    3'd3: font_data = 8'h41;
                    3'd4: font_data = 8'h22;
                    default: font_data = 8'h00;
                endcase
            end

            // 'D' (ASCII 68)
            7'd68: begin
                case (col)
                    3'd0: font_data = 8'h7F;
                    3'd1: font_data = 8'h41;
                    3'd2: font_data = 8'h41;
                    3'd3: font_data = 8'h22;
                    3'd4: font_data = 8'h1C;
                    default: font_data = 8'h00;
                endcase
            end

            // 'E' (ASCII 69)
            7'd69: begin
                case (col)
                    3'd0: font_data = 8'h7F;
                    3'd1: font_data = 8'h49;
                    3'd2: font_data = 8'h49;
                    3'd3: font_data = 8'h49;
                    3'd4: font_data = 8'h41;
                    default: font_data = 8'h00;
                endcase
            end

            // 'F' (ASCII 70)
            7'd70: begin
                case (col)
                    3'd0: font_data = 8'h7F;
                    3'd1: font_data = 8'h09;
                    3'd2: font_data = 8'h09;
                    3'd3: font_data = 8'h09;
                    3'd4: font_data = 8'h01;
                    default: font_data = 8'h00;
                endcase
            end

            // 'G' (ASCII 71)
            7'd71: begin
                case (col)
                    3'd0: font_data = 8'h3E;
                    3'd1: font_data = 8'h41;
                    3'd2: font_data = 8'h49;
                    3'd3: font_data = 8'h49;
                    3'd4: font_data = 8'h7A;
                    default: font_data = 8'h00;
                endcase
            end

            // 'H' (ASCII 72)
            7'd72: begin
                case (col)
                    3'd0: font_data = 8'h7F;
                    3'd1: font_data = 8'h08;
                    3'd2: font_data = 8'h08;
                    3'd3: font_data = 8'h08;
                    3'd4: font_data = 8'h7F;
                    default: font_data = 8'h00;
                endcase
            end

            // 'I' (ASCII 73)
            7'd73: begin
                case (col)
                    3'd0: font_data = 8'h00;
                    3'd1: font_data = 8'h41;
                    3'd2: font_data = 8'h7F;
                    3'd3: font_data = 8'h41;
                    default: font_data = 8'h00;
                endcase
            end

            // 'J' (ASCII 74)
            7'd74: begin
                case (col)
                    3'd0: font_data = 8'h20;
                    3'd1: font_data = 8'h40;
                    3'd2: font_data = 8'h41;
                    3'd3: font_data = 8'h3F;
                    3'd4: font_data = 8'h01;
                    default: font_data = 8'h00;
                endcase
            end

            // 'K' (ASCII 75)
            7'd75: begin
                case (col)
                    3'd0: font_data = 8'h7F;
                    3'd1: font_data = 8'h08;
                    3'd2: font_data = 8'h14;
                    3'd3: font_data = 8'h22;
                    3'd4: font_data = 8'h41;
                    default: font_data = 8'h00;
                endcase
            end

            // 'L' (ASCII 76)
            7'd76: begin
                case (col)
                    3'd0: font_data = 8'h7F;
                    3'd1: font_data = 8'h40;
                    3'd2: font_data = 8'h40;
                    3'd3: font_data = 8'h40;
                    3'd4: font_data = 8'h40;
                    default: font_data = 8'h00;
                endcase
            end

            // 'M' (ASCII 77)
            7'd77: begin
                case (col)
                    3'd0: font_data = 8'h7F;
                    3'd1: font_data = 8'h02;
                    3'd2: font_data = 8'h0C;
                    3'd3: font_data = 8'h02;
                    3'd4: font_data = 8'h7F;
                    default: font_data = 8'h00;
                endcase
            end

            // 'N' (ASCII 78)
            7'd78: begin
                case (col)
                    3'd0: font_data = 8'h7F;
                    3'd1: font_data = 8'h04;
                    3'd2: font_data = 8'h08;
                    3'd3: font_data = 8'h10;
                    3'd4: font_data = 8'h7F;
                    default: font_data = 8'h00;
                endcase
            end

            // 'O' (ASCII 79)
            7'd79: begin
                case (col)
                    3'd0: font_data = 8'h3E;
                    3'd1: font_data = 8'h41;
                    3'd2: font_data = 8'h41;
                    3'd3: font_data = 8'h41;
                    3'd4: font_data = 8'h3E;
                    default: font_data = 8'h00;
                endcase
            end

            // 'P' (ASCII 80)
            7'd80: begin
                case (col)
                    3'd0: font_data = 8'h7F;
                    3'd1: font_data = 8'h09;
                    3'd2: font_data = 8'h09;
                    3'd3: font_data = 8'h09;
                    3'd4: font_data = 8'h06;
                    default: font_data = 8'h00;
                endcase
            end

            // 'Q' (ASCII 81)
            7'd81: begin
                case (col)
                    3'd0: font_data = 8'h3E;
                    3'd1: font_data = 8'h41;
                    3'd2: font_data = 8'h51;
                    3'd3: font_data = 8'h21;
                    3'd4: font_data = 8'h5E;
                    default: font_data = 8'h00;
                endcase
            end

            // 'R' (ASCII 82)
            7'd82: begin
                case (col)
                    3'd0: font_data = 8'h7F;
                    3'd1: font_data = 8'h09;
                    3'd2: font_data = 8'h19;
                    3'd3: font_data = 8'h29;
                    3'd4: font_data = 8'h46;
                    default: font_data = 8'h00;
                endcase
            end

            // 'S' (ASCII 83)
            7'd83: begin
                case (col)
                    3'd0: font_data = 8'h46;
                    3'd1: font_data = 8'h49;
                    3'd2: font_data = 8'h49;
                    3'd3: font_data = 8'h49;
                    3'd4: font_data = 8'h31;
                    default: font_data = 8'h00;
                endcase
            end

            // 'T' (ASCII 84)
            7'd84: begin
                case (col)
                    3'd0: font_data = 8'h01;
                    3'd1: font_data = 8'h01;
                    3'd2: font_data = 8'h7F;
                    3'd3: font_data = 8'h01;
                    3'd4: font_data = 8'h01;
                    default: font_data = 8'h00;
                endcase
            end

            // 'U' (ASCII 85)
            7'd85: begin
                case (col)
                    3'd0: font_data = 8'h3F;
                    3'd1: font_data = 8'h40;
                    3'd2: font_data = 8'h40;
                    3'd3: font_data = 8'h40;
                    3'd4: font_data = 8'h3F;
                    default: font_data = 8'h00;
                endcase
            end

            // 'V' (ASCII 86)
            7'd86: begin
                case (col)
                    3'd0: font_data = 8'h1F;
                    3'd1: font_data = 8'h20;
                    3'd2: font_data = 8'h40;
                    3'd3: font_data = 8'h20;
                    3'd4: font_data = 8'h1F;
                    default: font_data = 8'h00;
                endcase
            end

            // 'W' (ASCII 87)
            7'd87: begin
                case (col)
                    3'd0: font_data = 8'h7F;
                    3'd1: font_data = 8'h20;
                    3'd2: font_data = 8'h18;
                    3'd3: font_data = 8'h20;
                    3'd4: font_data = 8'h7F;
                    default: font_data = 8'h00;
                endcase
            end

            // 'X' (ASCII 88)
            7'd88: begin
                case (col)
                    3'd0: font_data = 8'h63;
                    3'd1: font_data = 8'h14;
                    3'd2: font_data = 8'h08;
                    3'd3: font_data = 8'h14;
                    3'd4: font_data = 8'h63;
                    default: font_data = 8'h00;
                endcase
            end

            // 'Y' (ASCII 89)
            7'd89: begin
                case (col)
                    3'd0: font_data = 8'h07;
                    3'd1: font_data = 8'h08;
                    3'd2: font_data = 8'h70;
                    3'd3: font_data = 8'h08;
                    3'd4: font_data = 8'h07;
                    default: font_data = 8'h00;
                endcase
            end

            // 'Z' (ASCII 90)
            7'd90: begin
                case (col)
                    3'd0: font_data = 8'h61;
                    3'd1: font_data = 8'h51;
                    3'd2: font_data = 8'h49;
                    3'd3: font_data = 8'h45;
                    3'd4: font_data = 8'h43;
                    default: font_data = 8'h00;
                endcase
            end

            default: font_data = 8'h00;
        endcase
    end

endmodule
