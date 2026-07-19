vlib work
vmap work work
vlog -sv RTL/Instructions.sv
vlog -sv RTL/FETCH.sv
vlog -sv RTL/DECODE.sv
vlog -sv RTL/EXECUTE.sv
vlog -sv RTL/MEMORY.sv
vlog -sv RTL/CPU.sv
vlog -sv Testbench/Run_program.sv
transcript file Debug/logs/trace.log
vsim -t 1ns work.Run_program
run -all