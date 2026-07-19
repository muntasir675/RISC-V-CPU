`timescale 1ns/1ps
import riscv_pkg::*;
module Testbench;

logic clock;
logic nreset;

always #5 clock = ~clock;
wire [31:0] x3  = u_cpu.u_writeback.register[3];
wire ecall = u_cpu.ecall_fired;

initial begin
    clock = 0;
    nreset = 0;
    @(posedge clock);
    @(posedge clock);
    @(posedge clock);
    @(posedge clock);
    nreset = 1;
end

CPU #(.PROGRAM_HEX("Debug/tests/rv32ui-p-add.hex")) u_cpu (
    .clock  (clock),
    .nreset (nreset),
    .debug_out(),
    .ecall_fired ()
);

// initial begin
//     wait(nreset == 1);
//     forever @(posedge clock) begin
//         $display("PC:%8d  %-12s  val1:%11d  val2:%11d  imm:%11d  result:%11d  next_pc:%8d",
//             u_cpu.u_fetch.curr_address,
//             u_cpu.u_memory.inst_info.name(),
//             u_cpu.u_execute.register_data1,
//             u_cpu.u_execute.register_data2,
//             u_cpu.u_execute.immediate,
//             u_cpu.u_execute.result,
//             u_cpu.u_execute.next_address);
//         if (u_cpu.u_memory.inst_info == INSTR_ECALL) begin
//             $display("ECALL fired: mtvec=0x%0x mepc=0x%0x mcause=0x%0x",
//                 u_cpu.u_memory.CSR[1],
//                 u_cpu.u_memory.CSR[2],
//                 u_cpu.u_memory.CSR[3]);
//         end
//         if (u_cpu.u_memory.inst_info == INSTR_MRET) begin
//             $display("MRET fired: returning to mepc=0x%0x",
//                 u_cpu.u_memory.CSR[2]);
//         end
//     end
// end

initial begin
    automatic string tests[] = '{
        "rv32ui-p-add.hex",   "rv32ui-p-addi.hex",  "rv32ui-p-and.hex",
        "rv32ui-p-andi.hex",  "rv32ui-p-auipc.hex", "rv32ui-p-beq.hex",
        "rv32ui-p-bge.hex",   "rv32ui-p-bgeu.hex",  "rv32ui-p-blt.hex",
        "rv32ui-p-bltu.hex",  "rv32ui-p-bne.hex",   "rv32ui-p-jal.hex",
        "rv32ui-p-jalr.hex",  "rv32ui-p-lb.hex",    "rv32ui-p-lbu.hex",
        "rv32ui-p-lh.hex",    "rv32ui-p-lhu.hex",   "rv32ui-p-lui.hex",
        "rv32ui-p-lw.hex",    "rv32ui-p-or.hex",    "rv32ui-p-ori.hex",
        "rv32ui-p-sb.hex",    "rv32ui-p-sh.hex",    "rv32ui-p-simple.hex",
        "rv32ui-p-sll.hex",   "rv32ui-p-slli.hex",  "rv32ui-p-slt.hex",
        "rv32ui-p-slti.hex",  "rv32ui-p-sltiu.hex", "rv32ui-p-sltu.hex",
        "rv32ui-p-sra.hex",   "rv32ui-p-srai.hex",  "rv32ui-p-srl.hex",
        "rv32ui-p-srli.hex",  "rv32ui-p-sub.hex",   "rv32ui-p-sw.hex",
        "rv32ui-p-xor.hex",   "rv32ui-p-xori.hex"
    };
    automatic int passed = 0, failed = 0;

    foreach (tests[i]) begin
        $readmemh({"Debug/tests/", tests[i]}, u_cpu.u_fetch.instruction_memory);
        nreset = 0; repeat(4) @(posedge clock); nreset = 1;
        @(posedge ecall);
        if (x3 == 1) begin
            $display("PASS:    %s", tests[i]);
            passed++;
        end else begin
            $display("FAIL:    %s  gp=%0d", tests[i], x3);
            failed++;
        end
    end

    $display("==============================");
    $display("  %0d/%0d passed", passed, passed+failed);
    $display("==============================");
    $stop;
end


endmodule
