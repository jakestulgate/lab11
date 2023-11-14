`default_nettype none
module top (
  // I/O ports
  input  logic hz100, reset,
  input  logic [20:0] pb,
  output logic [7:0] left, right,
         ss7, ss6, ss5, ss4, ss3, ss2, ss1, ss0,
  output logic red, green, blue,

  // UART ports
  output logic [7:0] txdata,
  input  logic [7:0] rxdata,
  output logic txclk, rxclk,
  input  logic txready, rxready
);
// ----- INPUTS -----

// create 100hz clock (done)

// system reset (done?)

// pushbuttons (async needs to be synced)
// Z/Y/X/W pushbuttons are used to select the quantity to be shown.
// 0-9 is used to select the thrust of the lander.


// ----- LOGIC AND MEMORY -----

// input handling

// memory unit

// ALU

// control unit

// display unit


// ----- OUTPUTS -----
// seven seg displays ss7-ss0
// The seven-segment displays are used to show one of the four lander quantities.
// Z/Y/X/W pushbuttons are used to select the quantity to be shown.

// rows of LEDs left/right

// RBG LEDs red/green/blue

// Instantiate the additional modules


// ... (other module instantiations)

// Instantiate the provided modules
  assign red = 1'b1;

endmodule

module ll_memory #(
  parameter ALTITUDE = 16'h4500,
  parameter VELOCITY = 16'h0,
  parameter FUEL = 16'h800,
  parameter THRUST = 16'h5
)(
  input logic clk,
  input logic rst,
  input logic wen,
  input logic [15:0] alt_n,
  input logic [15:0] vel_n,
  input logic [15:0] fuel_n,
  input logic [15:0] thrust_n,
  output logic [15:0] alt,
  output logic [15:0] vel,
  output logic [15:0] fuel,
  output logic [15:0] thrust
);
// On every rising edge of clk, the current quantities for the lander must be updated to the new values,
// but only if wen is asserted. The new values will come from the arithmetic unit.
// rst is an asynchronous reset, and should set the current values to the parameter values.
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      alt <= ALTITUDE;
      vel <= VELOCITY;
      fuel <= FUEL;
      thrust <= THRUST;
    end else if (wen) begin
      alt <= alt_n;
      vel <= vel_n;
      fuel <= fuel_n;
      thrust <= thrust_n;
    end
  end

endmodule

module ll_alu #(
  parameter GRAVITY = 16'h5 // -5ft/sec^2
)(
  input logic [15:0] alt,
  input logic [15:0] vel,
  input logic [15:0] fuel,
  input logic [15:0] thrust,
  output logic [15:0] alt_n,
  output logic [15:0] vel_n,
  output logic [15:0] fuel_n
);

  logic [15:0] alt_t, vel_t1, vel_t2, fuel_t;

  // if fuel == 0
  assign thrust = (fuel == 0) ? 0 : thrust;

  // Calculate new alt
  bcdaddsub4 a1(.a(alt), .b(vel), .op(1'b0), .s(alt_t)); // op = 1 to subtract, op = 0 to add
  // Calculate new velocity
  bcdaddsub4 v1(.a(vel), .b(GRAVITY), .op(1'b1), .s(vel_t1)); // subtract
  bcdaddsub4 v2(.a(vel_t1), .b(thrust), .op(1'b0), .s(vel_t2)); // add
  // Calculate new fuel
  bcdaddsub4 f1(.a(fuel), .b(thrust), .op(1'b1), .s(fuel_t));
  
  always_comb begin
    
    if (alt_t >= 16'h4999) begin
      alt_n = 0;
      vel_n = 0;
    end else begin
      alt_n = alt_t;
      vel_n = vel_t1;

      // Adjust new fuel
      if (fuel_t >= 16'h4999) begin
        fuel_n = 0;
      end else begin
        fuel_n = fuel_t;
      end
    end 
    
    
  end

endmodule

module ll_control (
  input logic clk,
  input logic rst,
  input logic [15:0] alt,
  input logic [15:0] vel,
  output logic land,
  output logic crash,
  output logic wen
);

  logic [15:0] alt_vel_sum;
  logic [15:0] alt_vel_sum_t1;
  logic [15:0] alt_vel_sum_t2;

  bcdaddsub4 av1(.a(alt), .b(vel), .op(1'b0), .s(alt_vel_sum));

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      alt_vel_sum_t1 <= 16'h0000;
      // alt_vel_sum_t2 <= 16'h0000;
    end 
    else begin
      alt_vel_sum_t1 <= alt_vel_sum;
      // alt_vel_sum_t2 <= alt_vel_sum_t1;
    end
  end

  // Landed condition
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      land <= 1'b0;
    end
    else begin
      if (alt_vel_sum_t1 > 16'h4999 || alt_vel_sum_t1 == 0) begin // negative
        land <= 1'b1;
      end 
      else begin
        land <= 1'b0;
      end
    end
  end

  // Crashed condition
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      crash <= 1'b0;
    end 
    else begin
      if (vel <= 16'h9970 && vel >= 16'h4999) begin  // -30 in 16-bit two's complement
        crash <= 1'b1;
      end 
      else begin
        crash <= 1'b0;
      end
    end
  end

  // Write enable condition
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      wen <= 1'b0;
    end 
    else begin
      if (!land && !crash) begin
        wen <= 1'b1;
      end 
      else begin
        wen <= 1'b0;
      end
    end
  end

endmodule





// 2 bit full adder
module fa (
  input a,
  input b,
  input ci,
  output s,
  output co
);

assign s = a ^ b ^ ci;
assign co = (a & b) | (b & ci) | (a & ci);

endmodule

// 4 bit full adder
module fa4 (
  input [3:0] a,
  input [3:0] b,
  input ci,
  output [3:0] s,
  output co
);

// use previous 'carry out' as input to next 'carry in'
logic [2:0] co_temp;

fa fa0 (.a(a[0]), .b(b[0]), .ci(ci), .s(s[0]), .co(co_temp[0]));
fa fa1 (.a(a[1]), .b(b[1]), .ci(co_temp[0]), .s(s[1]), .co(co_temp[1]));
fa fa2 (.a(a[2]), .b(b[2]), .ci(co_temp[1]), .s(s[2]), .co(co_temp[2]));
fa fa3 (.a(a[3]), .b(b[3]), .ci(co_temp[2]), .s(s[3]), .co(co));

endmodule

// step 3
module bcdadd1 (
  input [3:0] a, // 4-bit input A
  input [3:0] b, // 4-bit input B
  input ci, // Carry-in
  output [3:0] s, // Sum
  output co // Carry-out
);

  logic [3:0] s_temp;
  logic co_temp;
  logic [3:0] correction;
  
  // use 4 bit adder to get 4 bit intermediate sum
  fa4 fa0 (.a(a), .b(b), .ci(ci), .s(s_temp), .co(co_temp));
  assign co = (co_temp) || (&s_temp[3:2]) || (s_temp[3] & s_temp[1]);
  assign correction = co ? 4'b0110 : 4'b0;
  fa4 fa1 (.a(correction), .b(s_temp), .ci(0), .s(s), .co());
endmodule

// step 4
module bcdadd4 (
  input [15:0] a,   // 16-bit input A
  input [15:0] b,   // 16-bit input B
  input ci,         // Carry-in
  output [15:0] s,  // Sum
  output co         // Carry-out
);

logic [15:0] s_temp;
logic [2:0] co_temp;

bcdadd1 ba0(.a(a[3:0]), .b(b[3:0]), .ci(ci), .co(co_temp[0]), .s(s_temp[3:0]));
bcdadd1 ba1(.a(a[7:4]), .b(b[7:4]), .ci(co_temp[0]), .co(co_temp[1]), .s(s_temp[7:4]));
bcdadd1 ba2(.a(a[11:8]), .b(b[11:8]), .ci(co_temp[1]), .co(co_temp[2]), .s(s_temp[11:8]));
bcdadd1 ba3(.a(a[15:12]), .b(b[15:12]), .ci(co_temp[2]), .co(co), .s(s_temp[15:12]));

assign s = s_temp;

endmodule



module ssdec(
  input logic [3:0] in, // 4 bit binary representation of number
  input logic enable, 
  output logic [6:0] out // send this output SSD data to whichever SSD is in module instantiation      
);   

  logic [6:0] SEG7 [15:0];
  assign SEG7[4'h0] = 7'b0111111;
  assign SEG7[4'h1] = 7'b0000110;
  assign SEG7[4'h2] = 7'b1011011;
  assign SEG7[4'h3] = 7'b1001111;
  assign SEG7[4'h4] = 7'b1100110;
  assign SEG7[4'h5] = 7'b1101101;
  assign SEG7[4'h6] = 7'b1111101;
  assign SEG7[4'h7] = 7'b0000111;
  assign SEG7[4'h8] = 7'b1111111;
  assign SEG7[4'h9] = 7'b1100111;
  assign SEG7[4'ha] = 7'b1110111;
  assign SEG7[4'hb] = 7'b1111100;
  assign SEG7[4'hc] = 7'b0111001;
  assign SEG7[4'hd] = 7'b1011110;
  assign SEG7[4'he] = 7'b1111001;
  assign SEG7[4'hf] = 7'b1110001;
  assign out = enable ? SEG7[in] : 0;
endmodule

module bcd9comp1 (
  input logic [3:0] in,  // 4-bit BCD input
  output logic [3:0] out // 4-bit BCD nine's complement output
);

  always_comb begin
    case (in)
      4'b0000: out = 4'b1001;
      4'b0001: out = 4'b1000;
      4'b0010: out = 4'b0111;
      4'b0011: out = 4'b0110;
      4'b0100: out = 4'b0101;
      4'b0101: out = 4'b0100;
      4'b0110: out = 4'b0011;
      4'b0111: out = 4'b0010;
      4'b1000: out = 4'b0001;
      4'b1001: out = 4'b0000;
      default:   out = 4'b0000;
    endcase
  end

endmodule




module bcdaddsub4 (
  input logic [15:0] a, // 16-bit input A
  input logic [15:0] b, // 16-bit input B
  input logic op,       // Operation selector (0: addition, 1: subtraction)
  output logic [15:0] s  // Sum
);

logic [15:0] temp;
logic [15:0] a_logic;
logic [15:0] b_logic;

// compliments
bcd9comp1 u12(.in(b[3:0]), .out(b_logic[3:0]));
bcd9comp1 u13(.in(b[7:4]), .out(b_logic[7:4]));
bcd9comp1 u14(.in(b[11:8]), .out(b_logic[11:8]));
bcd9comp1 u15(.in(b[15:12]), .out(b_logic[15:12]));
always_comb begin
  if(op == 1'b1) begin
    temp = b_logic;
  end
  else begin
    temp = b;
  end
end
bcdadd4 u16(.a(a), .b(temp), .ci(op), .s(s), .co());

endmodule



module keysync(
  input clk, 
  input rst,
  input [19:0] keyin,
  output [4:0] keyout,
  output keyclk
);

logic [1:0] delay;
always_ff @(posedge clk, posedge rst)
if (rst) begin
  delay <= 2'b0;
end
else begin
  delay <= (delay << 1) | {1'b0, |keyin[19:0]}; // strobe;
end
// 32 to 5 encoder
assign keyclk = delay[1];
assign keyout[0] = keyin[1] | keyin[3] | keyin[5] | keyin[7] | keyin[9] | keyin[11] | keyin[13] | keyin[15] | keyin[17] | keyin[19] ? 1 : 0; // evey other bit
assign keyout[1] = |keyin[3:2] | |keyin[7:6] | |keyin[11:10] | |keyin[15:14] | |keyin[19:18]? 1 : 0; // every other 2 bits
assign keyout[2] = |keyin[7:4] | |keyin[15:12] ? 1 : 0; // every other 4 bits
assign keyout[3] = |keyin[15:8] ? 1 : 0; // every other 8 bits
assign keyout[4] = |keyin[19:16] ? 1 : 0; // every other 16 bits (here it would be 31:1 if there were more inputs)


endmodule