module lunarlander #(
  parameter FUEL=16'h800,
  parameter ALTITUDE=16'h4500,
  parameter VELOCITY=16'h0,
  parameter THRUST=16'h5,
  parameter GRAVITY=16'h5
)(
  input logic hz100, reset,
  input logic [19:0] in,
  output logic [7:0] ss7, ss6, ss5, 
  output logic [7:0] ss3, ss2, ss1, ss0,
  output logic red, green
);
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
