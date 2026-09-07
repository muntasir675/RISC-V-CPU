import riscv_pkg::*;

module CPU #(parameter PROGRAM_HEX = "program.hex")
(
    input  logic        clock,
    input  logic        nreset,
    output logic        ecall_fired,
    output logic [31:0] debug_out
);

// FETCH outputs
logic [31:0] instruction, instruction_d1, instruction_d2, instruction_d3, instruction_d4;
logic [31:0] curr_address, curr_address_d1, curr_address_d2;

// DECODE outputs
instr_type   inst_info, inst_info_d1, inst_info_d2, inst_info_d3;
logic [31:0] immediate, immediate_d1;
logic        enable, enable_d1, enable_d2, enable_d3;

// EXECUTE outputs
logic        flush;
logic [31:0] result, result_d1, result_d2;
logic [31:0] next_address, next_address_d1;

// MEMORY outputs
logic [31:0] read_data, read_data_d1;

// WRITEBACK outputs
logic [31:0] reg1_data, reg1_data_d1;
logic [31:0] reg2_data, reg2_data_d1, reg2_data_d2;

// CPU signals
logic        stall;
logic [31:0] reg3_data;

function automatic logic is_load(input instr_type info);
    is_load = (info >= LW) && (info <= LBU);
endfunction

always_ff @(posedge clock or negedge nreset) begin
    if (!nreset) begin
        // Fetch
        instruction_d1      <= 32'h00000013;
        instruction_d2      <= 32'h00000013;
        instruction_d3      <= 32'h00000013;
        instruction_d4      <= 32'h00000013;
        curr_address_d1     <= 32'b0;
        curr_address_d2     <= 32'b0;
        // Decode
        inst_info_d1        <= UNKNOWN;
        inst_info_d2        <= UNKNOWN;
        inst_info_d3        <= UNKNOWN;
        immediate_d1        <= 32'b0;
        enable_d1           <= 1'b0;
        enable_d2           <= 1'b0;
        enable_d3           <= 1'b0;
        // Execute
        result_d1           <= 32'b0;
        result_d2           <= 32'b0;
        next_address_d1     <= 32'b0;
        // Memory
        read_data_d1        <= 32'b0;
        // Writeback
        reg1_data_d1        <= 32'b0;
        reg2_data_d1        <= 32'b0;
        reg2_data_d2        <= 32'b0;
    end
    else begin
        if (flush) begin
            // Fetch
            instruction_d1  <= 32'h00000013;
            instruction_d2  <= 32'h00000013;
            curr_address_d1 <= 32'b0;
            // Decode
            inst_info_d1    <= UNKNOWN;
            enable_d1       <= 1'b0;
            immediate_d1    <= 32'b0;
        end 
        else if (stall) begin
            // Fetch
            instruction_d1  <= instruction_d1;
            curr_address_d1 <= curr_address_d1;
            // Decode
            inst_info_d1    <= UNKNOWN;
            enable_d1       <= 1'b0;
            immediate_d1    <= 32'b0;
        end
        else begin
            // Fetch
            instruction_d1  <= instruction;
            instruction_d2  <= instruction_d1;
            curr_address_d1 <= curr_address;
            // Decode
            inst_info_d1    <= inst_info;
            enable_d1       <= enable;
            immediate_d1    <= immediate;
        end

        // FETCH outputs
        instruction_d3      <= instruction_d2;
        instruction_d4      <= instruction_d3;
        curr_address_d2     <= curr_address_d1;
        // DECODE outputs
        inst_info_d2        <= inst_info_d1;
        inst_info_d3        <= inst_info_d2;
        enable_d2           <= enable_d1;
        enable_d3           <= enable_d2;
        // EXECUTE outputs
        result_d1           <= result;
        result_d2           <= result_d1;
        next_address_d1     <= next_address;
        // MEMORY outputs
        read_data_d1        <= read_data;

        // WRITEBACK outputs
        reg2_data_d2        <= reg2_data_d1;

        // Forwarding
        if ((instruction_d1[19:15] == instruction_d2[11:7]) && (instruction_d2[11:7] != 0) && enable_d1)
            reg1_data_d1 <= result;
        else if ((instruction_d1[19:15] == instruction_d3[11:7]) && (instruction_d3[11:7] != 0) && enable_d2)
            reg1_data_d1 <= is_load(inst_info_d2) ? read_data : result_d1;
        else
            reg1_data_d1 <= reg1_data;

        if ((instruction_d1[24:20] == instruction_d2[11:7]) && (instruction_d2[11:7] != 0) && enable_d1)
            reg2_data_d1 <= result;
        else if ((instruction_d1[24:20] == instruction_d3[11:7]) && (instruction_d3[11:7] != 0) && enable_d2)
            reg2_data_d1 <= is_load(inst_info_d2) ? read_data : result_d1;
        else
            reg2_data_d1 <= reg2_data;
    end
end

always_comb begin
    reg3_data   = is_load(inst_info_d3) ? read_data_d1 : result_d2;
    debug_out   = reg3_data;
    ecall_fired = (inst_info_d3 == ECALL);

    if (is_load(inst_info_d1) && (instruction_d2[11:7] != 0) &&
        ((instruction_d2[11:7] == instruction_d1[19:15]) || (instruction_d2[11:7] == instruction_d1[24:20])))
        stall = 1'b1;
    else
        stall = 1'b0;
end

FETCH #(.PROGRAM_HEX(PROGRAM_HEX)) u_fetch (
    .clock        (clock),
    .nreset       (nreset),
    .stall        (stall),
    .flush        (flush),
    .next_address (next_address),

    .instruction  (instruction),
    .curr_address (curr_address)
);

DECODE u_decode (
    .instruction (instruction_d1),

    .inst_info   (inst_info),
    .immediate   (immediate),
    .enable      (enable)
);

EXECUTE u_execute (
    .register_data1 (reg1_data_d1),
    .register_data2 (reg2_data_d1),
    .immediate      (immediate_d1),
    .curr_address   (curr_address_d2),
    .inst_info      (inst_info_d1),

    .result         (result),
    .flush          (flush),
    .next_address   (next_address)
);

MEMORY u_memory (
    .clock      (clock),
    .inst_info  (inst_info_d2),
    .address    (result_d1),
    .write_data (reg2_data_d2),

    .read_data  (read_data)
);

WRITEBACK u_writeback (
    .clock      (clock),
    .nreset     (nreset),
    .enable     (enable_d3),
    .reg1_addr  (instruction_d1[19:15]),
    .reg2_addr  (instruction_d1[24:20]),
    .reg3_addr  (instruction_d4[11:7]),
    .reg3_data  (reg3_data),

    .reg1_data  (reg1_data),
    .reg2_data  (reg2_data)
);

endmodule