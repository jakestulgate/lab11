// DESCRIPTION: Verilator: Verilog example module
//
// This file ONLY is placed under the Creative Commons Public Domain, for
// any use, without warranty, 2017 by Wilson Snyder.
// SPDX-License-Identifier: CC0-1.0
//======================================================================
// For std::unique_ptr
#include <memory>

// Include common routines
#include <verilated.h>
#include "verilated_fst_c.h"

// Verilator using new C++?  Need to include these now
#include <iostream>

const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};
VerilatedFstC* tfp = new VerilatedFstC;

// Current simulation time (64-bit unsigned)
vluint64_t main_time = 0;
// Called by $time in Verilog
double sc_time_stamp()
{
  return main_time; // Note does conversion to real, to match SystemC
}

int concat(int w, int a, int b)
{
  return (a << w) | b;
}

int pin(int a, int b) {
  return (a >> b) & 1;
}

int pinsel(int x, int a, int b) {
    assert(a < b);
    int y = 0;
    for (int i = a; i <= b; i++) {
        y |= pin(x, i);
    }
    return y;
}

int intssenc (int x) {
    switch (x) {
        case -2: return 64; // dash
        case -1: return 0;  // blank
        case 0 : return 63;
        case 1 : return 6;
        case 2 : return 91;
        case 3 : return 79;
        case 4 : return 102;
        case 5 : return 109;
        case 6 : return 125;
        case 7 : return 7;
        case 8 : return 127;
        case 9 : return 103;
        case 10: return 119;
        case 11: return 124;
        case 12: return 57;
        case 13: return 94;
        case 14: return 121;
        case 15: return 113;
    }
    // uhhh this should not happen
    assert(false);
    return -255;
}

int intssdec (int x) {
    switch (x) {
        case 64: return -2; // dash
        case 0: return -1;  // blank
        case 63 : return 0;
        case 6 : return 1;
        case 91 : return 2;
        case 79 : return 3;
        case 102 : return 4;
        case 109 : return 5;
        case 125 : return 6;
        case 7 : return 7;
        case 127 : return 8;
        case 103 : return 9;
        case 119: return 10;
        case 124: return 11;
        case 57: return 12;
        case 94: return 13;
        case 121: return 14;
        case 113: return 15;
        default: return -2;
    }
    // uhhh this should not happen
    assert(false);
    return -255;
}

std::string bin(uint64_t b)
{
  std::string ans;
  while (b != 0)
  {
    ans += b % 2 == 0 ? "0" : "1";
    b /= 2;
  }
  std::reverse(ans.begin(), ans.end());
  return ans;
}

std::string padbin(uint64_t b, int n)
{
  std::string ans;
  while (b != 0)
  {
    ans += b % 2 == 0 ? "0" : "1";
    b /= 2;
    n--;
  }
  while (n-- != 0) {
    ans += "0";
  }
  std::reverse(ans.begin(), ans.end());
  return ans;
}

uint16_t bcdcomp9 (uint16_t a) {
  // invert number in 9's complement
  uint16_t ans = 0;
  for (int i = 0; i < 4; i++) {
    uint16_t a_digit = (a >> (4*i)) & 0xF;
    uint16_t ans_digit = 9 - a_digit;
    ans |= (ans_digit << (4*i));
  }
  return ans;
}

uint16_t bcdaddsub4 (uint16_t a, uint16_t b, bool op) {
  // equivalent to verilog function where a and b are BCD decimal format, eg.
  // a = 0x1234, b = 0x5678, op = 0, therefore return value = 0x6912
  // op = 0 -> add, op = 1 -> subtract
  uint16_t ans = 0;
  uint16_t carry = 0;
  // std::cout << "a = " << std::hex << a << ", b = " << std::hex << b << ", op = " << std::hex << op << "\n";
  if (op == 1)
    b = bcdaddsub4(bcdcomp9(b), 0x1, 0);
  // std::cout << "a = " << std::hex << a << ", b = " << std::hex << b << ", op = " << std::hex << op << "\n";
  for (int i = 0; i < 4; i++) {
    uint16_t a_digit = (a >> (4*i)) & 0xF;
    uint16_t b_digit = (b >> (4*i)) & 0xF;
    uint16_t ans_digit = 0;
    ans_digit = a_digit + b_digit + carry;
    if (ans_digit >= 10) {
      ans_digit -= 10;
      carry = 1;
    } else {
      carry = 0;
    }
    ans |= (ans_digit << (4*i));
  }
  // std::cout << "ans = " << std::hex << ans << "\n";
  return ans;
}

// Include model header, generated from Verilating the Verilog module.
#if defined(LL_ALU)
    #include "Vll_alu.h"
    static uint16_t exp_alt_n = 0;
    static uint16_t exp_vel_n = 0;
    static uint16_t exp_fuel_n = 0;
    void eval(Vll_alu *ll_alu) {
      contextp->timeInc(1);
      ll_alu->eval();
      tfp->dump(contextp->time());
    }
    void check_outputs(Vll_alu *ll_alu, int* pt, int* tt) {
      (*tt) += 3;
      if (ll_alu->alt_n != exp_alt_n)
        std::cout << "ERROR: alt_n expected " << std::hex << (exp_alt_n) << " but got " << std::hex << ll_alu->alt_n << "\n";
      else
        (*pt)++;
      if (ll_alu->vel_n != exp_vel_n)
        std::cout << "ERROR: vel_n expected " << std::hex << (exp_vel_n) << " but got " << std::hex << ll_alu->vel_n << "\n";
      else
        (*pt)++;
      if (ll_alu->fuel_n != exp_fuel_n)
        std::cout << "ERROR: fuel_n expected " << std::hex << (exp_fuel_n) << " but got " << std::hex << ll_alu->fuel_n << "\n";
      else
        (*pt)++;
    }
#elif defined(LL_MEMORY)
    #include "Vll_memory.h"
    static uint16_t exp_alt = 0;
    static uint16_t exp_vel = 0;
    static uint16_t exp_fuel = 0;
    static uint16_t exp_thrust = 0;
    void eval(Vll_memory *ll_memory) {
      contextp->timeInc(1);
      ll_memory->eval();
      tfp->dump(contextp->time());
    }
    void cycle_clock(Vll_memory *ll_memory) {
      ll_memory->clk = 1; eval(ll_memory);
      ll_memory->clk = 0; eval(ll_memory);
    }
    void check_outputs(Vll_memory *ll_memory, int* pt, int* tt) {
      (*tt) += 4;
      if (ll_memory->alt != exp_alt)
        std::cout << "ERROR: alt expected " << std::hex << (exp_alt) << " but got " << std::hex << ll_memory->alt << "\n";
      else
        (*pt)++;
      if (ll_memory->vel != exp_vel)
        std::cout << "ERROR: vel expected " << std::hex << (exp_vel) << " but got " << std::hex << ll_memory->vel << "\n";
      else
        (*pt)++;
      if (ll_memory->fuel != exp_fuel)
        std::cout << "ERROR: fuel expected " << std::hex << (exp_fuel) << " but got " << std::hex << ll_memory->fuel << "\n";
      else
        (*pt)++;
      if (ll_memory->thrust != exp_thrust)
        std::cout << "ERROR: thrust expected " << std::hex << (exp_thrust) << " but got " << std::hex << ll_memory->thrust << "\n";
      else
        (*pt)++;
    }
#elif defined(LL_CONTROL)
    #include "Vll_control.h"
    static bool exp_land = 0;
    static bool exp_crash = 0;
    static bool exp_wen = 0;
    void eval(Vll_control *ll_control) {
      contextp->timeInc(1);
      ll_control->eval();
      tfp->dump(contextp->time());
    }
    void cycle_clock(Vll_control *ll_control) {
      ll_control->clk = 1; eval(ll_control);
      ll_control->clk = 0; eval(ll_control);
    }
    void check_outputs(Vll_control *ll_control, int* pt, int* tt) {
      (*tt) += 3;
      if (ll_control->land != exp_land)
        std::cout << "ERROR: land expected " << std::hex << (exp_land) << " but got " << std::to_string(ll_control->land) << "\n";
      else
        (*pt)++;
      if (ll_control->crash != exp_crash)
        std::cout << "ERROR: crash expected " << std::hex << (exp_crash) << " but got " << std::to_string(ll_control->crash) << "\n";
      else
        (*pt)++;
      if (ll_control->wen != exp_wen)
        std::cout << "ERROR: wen expected " << std::hex << (exp_wen) << " but got " << std::to_string(ll_control->wen) << "\n";
      else
        (*pt)++;
    }
#else
    #error "No module specified"
#endif

static int passed_test_count = 0; // every time we perform a test, and the test passes, increment this by one.
static int total_test_count = 0;  // every time we perform a test, increment this by one.

void update_tests(int passed, int total, std::string test) {
  // add tests to global test variables
  passed_test_count += passed;
  total_test_count += total;
  // perform sanity check on global test variables
  assert(passed_test_count <= total_test_count);
  // let TA know if this set of tests failed
  std::cout << "Part " << test << ": " << std::to_string(passed) << " out of " << std::to_string(total) << " tests passed.\n";
}

int main(int argc, char **argv)
{
  // This is a more complicated example, please also see the simpler examples/make_hello_c.

  // Prevent unused variable warnings
  if (0 && argc && argv) {}

  int passed_subtests = 0; // if we have multiple subtests, we need to know how many passed for each
  int total_subtests = 0;
  
  // Set debug level, 0 is off, 9 is highest presently used
  // May be overridden by commandArgs argument parsing
  contextp->debug(0);

  // Randomization reset policy
  // May be overridden by commandArgs argument parsing
  contextp->randReset(2);

  // Verilator must compute traced signals
  contextp->traceEverOn(true);

  // Pass arguments so Verilated code can see them, e.g. $value$plusargs
  // This needs to be called before you create any model
  contextp->commandArgs(argc, argv);

  #if defined(LL_ALU)
    std::cout << "Testing ll_alu...\n";
    // Construct the Verilated model, from each module after Verilating each module file
    const std::unique_ptr<Vll_alu> ll_alu {new Vll_alu {contextp.get(), "LL_ALU"} };
    ll_alu->trace(tfp, 99);
    tfp->open("ll_alu.fst");
    // inputs: alt/vel/fuel/thrust (16 bits each, BCD representations of numbers)
    // outputs: alt_n/vel_n/fuel_n (16 bits each, BCD representations of numbers)
    // start with alt = 4500, vel = 0, fuel = 800, thrust = 5, gravity = 5
    // after setting inputs, call eval, and then check outputs
    ll_alu->alt = 0x4500;
    ll_alu->vel = 0x0;
    ll_alu->fuel = 0x800;
    ll_alu->thrust = 0x5;
    eval(ll_alu.get());
    // decrement fuel all the way
    std::cout << "Test case: Decrement fuel all the way.\n";
    uint16_t GRAVITY = 0x5;
    for (int i = 0; i < 163; i++) {
      exp_alt_n = bcdaddsub4(ll_alu->alt, ll_alu->vel, 0);
      exp_vel_n = bcdaddsub4(bcdaddsub4(ll_alu->vel, GRAVITY, 1), (ll_alu->fuel == 0) ? 0 : ll_alu->thrust, 0);
      if ((exp_alt_n & 0x8000) || (exp_alt_n == 0)) {
        exp_alt_n = 0;
        exp_vel_n = 0;
      }
      exp_fuel_n = bcdaddsub4(ll_alu->fuel, ll_alu->thrust, 1);
      if ((exp_fuel_n & 0x8000) || (exp_fuel_n == 0))
        exp_fuel_n = 0;
      check_outputs(ll_alu.get(), &passed_subtests, &total_subtests);
      // std::cout << "ll_alu->alt " << std::hex << ll_alu->alt << "\n";
      ll_alu->alt = ll_alu->alt_n;
      // std::cout << "ll_alu->vel " << std::hex << ll_alu->vel << "\n";
      ll_alu->vel = ll_alu->vel_n;
      // std::cout << "ll_alu->fuel " << std::hex << ll_alu->fuel << "\n\n";
      ll_alu->fuel = ll_alu->fuel_n;
      eval(ll_alu.get());
    }

    // test altitude decrement by setting thrust to 0
    std::cout << "Test case: Decrement altitude to 0 by setting thrust to 0.\n";
    ll_alu->thrust = 0x0;
    eval(ll_alu.get());
    for (int i = 0; i < 50; i++) {
      exp_alt_n = bcdaddsub4(ll_alu->alt, ll_alu->vel, 0);
      exp_vel_n = bcdaddsub4(bcdaddsub4(ll_alu->vel, GRAVITY, 1), ll_alu->thrust, 0);
      if ((exp_alt_n & 0x8000) || (exp_alt_n == 0)) {
        exp_alt_n = 0;
        exp_vel_n = 0;
      }
      exp_fuel_n = bcdaddsub4(ll_alu->fuel, ll_alu->thrust, 1);
      if ((exp_fuel_n & 0x8000) || (exp_fuel_n == 0))
        exp_fuel_n = 0;
      check_outputs(ll_alu.get(), &passed_subtests, &total_subtests);
      // std::cout << "ll_alu->alt " << std::hex << ll_alu->alt << "\n";
      ll_alu->alt = ll_alu->alt_n;
      // std::cout << "ll_alu->vel " << std::hex << ll_alu->vel << "\n";
      ll_alu->vel = ll_alu->vel_n;
      // std::cout << "ll_alu->fuel " << std::hex << ll_alu->fuel << "\n\n";
      ll_alu->fuel = ll_alu->fuel_n;
      eval(ll_alu.get());
    }
  #elif defined(LL_MEMORY)
    std::cout << "Testing ll_memory...\n";
    // Construct the Verilated model, from each module after Verilating each module file
    const std::unique_ptr<Vll_memory> ll_memory {new Vll_memory {contextp.get(), "LL_MEMORY"} };
    ll_memory->trace(tfp, 99);
    tfp->open("ll_memory.fst");
    ll_memory->clk = 0;
    ll_memory->rst = 0;
    ll_memory->wen = 0;
    eval(ll_memory.get());
    // test power-on reset
    ll_memory->rst = 1;
    eval(ll_memory.get());
    cycle_clock(ll_memory.get());
    std::cout << "Test case: Power-on reset.\n";
    exp_alt = 0x4500;
    exp_vel = 0x0;
    exp_fuel = 0x800;
    exp_thrust = 0x5;
    check_outputs(ll_memory.get(), &passed_subtests, &total_subtests);
    // test different values with no enable
    ll_memory->rst = 0;
    ll_memory->alt_n = 0x1234;
    ll_memory->vel_n = 0x5678;
    ll_memory->fuel_n = 0x9ABC;
    ll_memory->thrust_n = 0xDEF0;
    std::cout << "Test case: Write values with wen = 0.\n";
    eval(ll_memory.get());
    cycle_clock(ll_memory.get());
    check_outputs(ll_memory.get(), &passed_subtests, &total_subtests);
    // test different values with enable
    ll_memory->wen = 1;
    eval(ll_memory.get());
    std::cout << "Test case: Write values with wen = 1.\n";
    cycle_clock(ll_memory.get());
    exp_alt = 0x1234;
    exp_vel = 0x5678;
    exp_fuel = 0x9ABC;
    exp_thrust = 0xDEF0;
    check_outputs(ll_memory.get(), &passed_subtests, &total_subtests);
  #elif defined(LL_CONTROL)
    std::cout << "Testing ll_control...\n";
    const std::unique_ptr<Vll_control> ll_control {new Vll_control {contextp.get(), "LL_CONTROL"} };
    ll_control->trace(tfp, 99);
    tfp->open("ll_control.fst");
    /*
      input logic clk, rst,
      input logic [15:0] alt, vel,
      output logic land, crash, wen
    */
    ll_control->clk = 0;
    ll_control->rst = 0;
    ll_control->alt = 0x4500;
    ll_control->vel = 0x0;
    // test power-on reset
    ll_control->rst = 1;
    eval(ll_control.get());
    exp_land = 0;
    exp_crash = 0;
    exp_wen = 0;
    std::cout << "Test case: Power-on reset.\n";
    check_outputs(ll_control.get(), &passed_subtests, &total_subtests);
    // try land=1 by setting altitude to 28, velocity to 9970
    ll_control->rst = 0;
    eval(ll_control.get());
    ll_control->alt = 0x28;
    ll_control->vel = 0x9970;
    eval(ll_control.get());
    cycle_clock(ll_control.get());
    exp_land = 1;
    exp_wen = 0;
    std::cout << "Test case: Land when altitude = 28, velocity = -30.\n";
    check_outputs(ll_control.get(), &passed_subtests, &total_subtests);
    // try crash=1 by setting velocity to 9969
    ll_control->rst = 1;
    eval(ll_control.get());
    ll_control->rst = 0;
    ll_control->vel = 0x9969;
    eval(ll_control.get());
    cycle_clock(ll_control.get());
    exp_land = 0;
    exp_crash = 1;
    exp_wen = 0;
    std::cout << "Test case: Crash when altitude = 28, velocity = -31.\n";
    check_outputs(ll_control.get(), &passed_subtests, &total_subtests);
    // we should not be able to move from this state, even if we set altitude and velocity to 0
    ll_control->alt = 0x0;
    ll_control->vel = 0x0;
    std::cout << "Test case: Land/crash should not change even when quantities change until async reset.\n";
    check_outputs(ll_control.get(), &passed_subtests, &total_subtests);
    // try wen=1 by setting altitude to 4500, velocity to 0
    ll_control->rst = 1;
    eval(ll_control.get());
    ll_control->rst = 0;
    ll_control->alt = 0x4500;
    ll_control->vel = 0;
    eval(ll_control.get());
    cycle_clock(ll_control.get());
    exp_land = 0;
    exp_crash = 0;
    exp_wen = 1;
    std::cout << "Test case: Reset, wen=1 when still in the air to update quantities.\n";
    check_outputs(ll_control.get(), &passed_subtests, &total_subtests);
  #endif

  tfp->close();
  tfp = nullptr;
  
  update_tests(passed_subtests, total_subtests, "1");
  /***********************************/

  passed_subtests = 0;
  total_subtests = 0;

  /***********************************/
  // END TESTS
  /*************************************************************************/

  // good to have to detect bugs
  assert(passed_test_count <= total_test_count);

  if (passed_test_count == total_test_count)
  {
    std::cout << "ALL " << std::to_string(total_test_count) << " TESTS PASSED"
              << "\n";
  }
  else
  {
    std::cout << "ERROR: " << std::to_string(passed_test_count) << "/" << std::to_string(total_test_count) << " tests passed.\n";
  }

  // Fin
  return 0;
}
