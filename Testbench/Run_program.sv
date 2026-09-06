`timescale 1ns/1ps
import riscv_pkg::*;

module Run_program;

logic clock;
logic nreset;

always #5 clock = ~clock;

wire [31:0] x10 = u_cpu.u_writeback.registers[10];
wire [31:0] debug_out;
wire ecall;

CPU2 #(.PROGRAM_HEX("program.hex")) u_cpu (
    .clock       (clock),
    .nreset      (nreset),
    .debug_out   (debug_out),
    .ecall_fired (ecall)
);

initial begin
    automatic string programs[] = '{
        "program.hex",
        "program2.hex"
    };

    clock = 0;

    foreach (programs[i]) begin
        $display("\n========================================");
        $display("Running %s ...", programs[i]);
        $display("========================================");

        $readmemh(programs[i], u_cpu.u_fetch.instruction_memory);
        nreset = 0;
        repeat(4) @(posedge clock);
        nreset = 1;

        fork
            begin
                @(posedge ecall);
            end
            begin
                // Detect 'j .' infinite loop at end of program
                forever @(posedge clock) begin
                    if (nreset && (u_cpu.u_execute.next_address == u_cpu.u_execute.curr_address)) begin
                        repeat(10) @(posedge clock);
                        break;
                    end
                end
            end
            begin
                repeat(1000000) @(posedge clock);
            end
        join_any
        disable fork;

        $display("Finished %s at time %0t ns", programs[i], $time);
        $display("Return value (x10 / a0) = %0d (0x%08h)", $signed(x10), x10);
        $display("Registers: x1=%0d, x2=%0d, x3=%0d, x10=%0d, x11=%0d",
            u_cpu.u_writeback.registers[1],
            u_cpu.u_writeback.registers[2],
            u_cpu.u_writeback.registers[3],
            u_cpu.u_writeback.registers[10],
            u_cpu.u_writeback.registers[11]);
        if (programs[i] == "program.hex") begin
            if (x10 == 4181)
                $display("RESULT: [PASS] fib(19) == 4181");
            else
                $display("RESULT: [FAIL] expected 4181, got %0d", x10);
        end else if (programs[i] == "program2.hex") begin
            if (x10 == 1)
                $display("RESULT: [PASS] program2 passed all hazard tests!");
            else
                $display("RESULT: [FAIL] program2 failed at test error code %0d", $signed(x10));
        end
    end

    $display("\n========================================");
    $display("All programs completed.");
    $display("========================================");
    $stop;
end

endmodule
