import riscv_pkg::*;

module CPU2 #(parameter PROGRAM_HEX = "program.hex")
(
    input  logic        clock,
    input  logic        nreset,
    output logic        ecall_fired,
    output logic [31:0] debug_out
);

// ============ SIGNALS ============

// FETCH
logic [31:0] fetch_instruction;
logic [31:0] fetch_curr_address;
logic [31:0] fetch_next_address;

// DECODE
instr_type   inst_info;
logic [31:0] immediate;

// WRITEBACK read ports
logic [31:0] rs1_data;
logic [31:0] rs2_data;

// EXECUTE
logic [31:0] execute_result;
logic [31:0] execute_next_address;

// MEMORY
logic [31:0] memory_read_data;

// WRITEBACK write port
logic [31:0] write_data;
logic [4:0]  rd_addr;
logic        reg_write;

// ============ MODULE INSTANTIATIONS ============

FETCH #(.PROGRAM_HEX(PROGRAM_HEX)) u_fetch (
    .clock        (clock),
    .nreset       (nreset),
    .stall        (1'b0),
    .next_address (fetch_next_address),
    .curr_address (fetch_curr_address),
    .instruction  (fetch_instruction)
);

DECODE u_decode (
    .instruction (fetch_instruction),
    .inst_info   (inst_info),
    .immediate   (immediate)
);

EXECUTE u_execute (
    .register_data1 (rs1_data),
    .register_data2 (rs2_data),
    .immediate      (immediate),
    .curr_address   (fetch_curr_address),
    .inst_info      (inst_info),
    .result         (execute_result),
    .next_address   (execute_next_address)
);

MEMORY u_memory (
    .clock      (clock),
    .inst_info  (inst_info),
    .address    (execute_result),
    .write_data (rs2_data),
    .read_data  (memory_read_data)
);

WRITEBACK u_writeback (
    .clock      (clock),
    .nreset     (nreset),
    .enable     (reg_write),
    .reg1_addr  (fetch_instruction[19:15]),
    .reg1_data  (rs1_data),
    .reg2_addr  (fetch_instruction[24:20]),
    .reg2_data  (rs2_data),
    .reg3_addr  (rd_addr),
    .reg3_data  (write_data)
);

// ============ FEATURES TO IMPLEMENT ============
// 1. Fetch: branch/jump target mux (fetch_next_address = execute_next_address or curr + 4)
// 2. Decode: control signals — reg_write (writes_rd), mem_read (reads_mem),
//    uses_rs1/uses_rs2 — to replace the old classifier functions
// 3. Writeback: data select — write_data = memory_read_data for loads, else execute_result
// 4. rd_addr = fetch_instruction[11:7]
// 5. ecall_fired = (inst_info == INSTR_ECALL)
// 6. debug_out = write_data
// 7. Pipeline: to make this pipelined, add IF/ID, ID/EX, EX/MEM, MEM/WB banks,
//    forwarding, load-use hazard detection, and branch flush

endmodule