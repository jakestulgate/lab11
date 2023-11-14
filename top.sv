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
// starts at some height Y above moon, falling at 5ft/s^2 towards ground
// thrusters counteract gravity anywhere from 0 to 9ft/s^2
// crash if downwards vel is 30ft/s or larger OR if thrust is above 5
// otherwise it will land

// demo
/* The lunar lander starts 4500 feet above the Moon.
The initial thrust is set to 4, and gravity is set to 5, so you start picking up speed at the rate of (4 - 5) = 1 ft/s2.
As downward velocity increases, your altitude starts dropping. 
The thrust is then adjusted to 0, in order to maximize the effect of gravity on the lander, and therefore pick up speed faster.

Around the point where the velocity reaches -80 to -90 ft/s,
we set a thrust of 5 ft/s to counteract gravity, and therefore keep our velocity constant.
At 1500 ft, we set full thrust by setting it to 9 ft/s2,
in order to start decreasing our downward velocity so that we don't crash due to our high velocity.
Once we reach a downward velocity less than 30 ft/s, we can set thrust back to 5 to let the lander continue descent at a constant velocity.

Notice that when the altitude reaches a value near zero, the green light turns on to indicate that we have safely landed. If our velocity was greater than 30 ft/s, or the thrust was bigger than 5 ft/s2, we would have crashed.
*/

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

  assign red = 1'b0;

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

  // Calculate new altitude
  bcdaddsub4 a1(.a(alt), .b(vel), .op(0), .s(alt_t)); // op = 1 to subtract, op = 0 to add
  // Calculate new velocity
  bcdaddsub4 v1(.a(vel), .b(GRAVITY), .op(1), .s(vel_t1)); // subtract
  bcdaddsub4 v2(.a(vel_t1), .b((fuel > 0) ? thrust : 0), .op(0), .s(vel_t2)); // add
  // Calculate new fuel
  bcdaddsub4 f1(.a(fuel), .b(thrust), .op(1), .s(fuel_t));

  
  
  always_comb begin
    // Adjust new altitude
    // alt_n = (alt_t <= 0) ? 0 : alt_t;
    alt_n = (alt_t >= 16'd4999) ? 0 : alt_t;
    // Adjust new velocity
    vel_n = (alt_t >= 16'd4999) ? 0 : ((fuel == 0) ? ((vel <= vel_t1) ? 0 : vel_t1) : vel_t2); // if new alt is <= 0 -> 0 otherwise use calculated
    // Adjust new fuel
    // fuel_n = (fuel_t <= 0) ? 0 : fuel_t;
    fuel_n = (fuel_t >= 16'd4999) ? 0 : fuel_t;
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



