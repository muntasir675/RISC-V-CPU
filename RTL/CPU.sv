import riscv_pkg::*;

module CPU #(parameter string PROGRAM_HEX = "")
(
    input logic clock,
    input logic nreset
);

    // FETCH outputs
    logic [31:0] instruction;
    logic [31:0] curr_address;

    // DECODE outputs
    instr_type    inst_info;
    logic [31:0]  immediate;

    // EXECUTE outputs
    logic [31:0]  result;
    logic [31:0]  next_address;

    // MEMORY outputs
    logic [31:0]  read_data;
    logic [31:0]  register_data1;
    logic [31:0]  register_data2;
    logic [31:0]  mtvec, mepc;

    FETCH #(.PROGRAM_HEX(PROGRAM_HEX)) u_fetch (
        .clock        (clock),
        .nreset       (nreset),
        .next_address (next_address),
        .curr_address (curr_address),
        .instruction  (instruction)
    );

    DECODE u_decode (
        .instruction  (instruction),
        .inst_info    (inst_info),
        .immediate    (immediate)
    );

    EXECUTE u_execute (
        .register_data1 (register_data1),
        .register_data2 (register_data2),
        .mtvec          (mtvec),
        .mepc           (mepc),
        .immediate      (immediate),
        .curr_address   (curr_address),
        .inst_info      (inst_info),
        .result         (result),
        .next_address   (next_address)
    );

    MEMORY u_memory (
        .clock          (clock),
        .nreset         (nreset),
        .address        (result),
        .write_data     (register_data2),
        .instruction    (instruction),
        .result         (result),
        .inst_info      (inst_info),
        .read_data      (read_data),
        .register_data1 (register_data1),
        .register_data2 (register_data2),
        .mtvec          (mtvec),
        .mepc           (mepc)
    );

endmodule