`timescale 1ns/1ps
import riscv_pkg::*;
module Run_program;
logic clock;
logic nreset;
always #5 clock = ~clock;
wire [31:0] x10 = u_cpu.u_memory.register[10];
initial begin
    clock = 0;
    nreset = 0;
    repeat(8) @(posedge clock);
    nreset = 1;
    repeat(10000) @(posedge clock);
    $display("fib(10) = %0d", x10);
    $display("instr0=%h instr1=%h instr2=%h", u_cpu.u_fetch.instruction_memory[0], u_cpu.u_fetch.instruction_memory[1], u_cpu.u_fetch.instruction_memory[2]);
    $display("x1=%0d x2=%0d x3=%0d x10=%0d x11=%0d", u_cpu.u_memory.register[1], u_cpu.u_memory.register[2], u_cpu.u_memory.register[3], u_cpu.u_memory.register[10], u_cpu.u_memory.register[11]);
    $stop;
end
CPU #(.PROGRAM_HEX("program.hex")) u_cpu (
    .clock  (clock),
    .nreset (nreset)
);
endmodule