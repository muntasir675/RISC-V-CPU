vlib work
vmap work work

vlog -sv RTL/Instructions.sv
vlog -sv RTL/FETCH.sv
vlog -sv RTL/DECODE.sv
vlog -sv RTL/EXECUTE.sv
vlog -sv RTL/MEMORY.sv
vlog -sv RTL/WRITEBACK.sv
vlog -sv RTL/CPU2.sv
vlog -sv Testbench/Testbench.sv

# transcript file Debug/logs/trace.log

vsim -t 1ns work.Testbench

run -all