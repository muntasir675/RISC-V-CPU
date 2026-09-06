import riscv_pkg::*;

module CPU2 #(parameter PROGRAM_HEX = "program.hex")
(
    input  logic        clock,
    input  logic        nreset,
    output logic        ecall_fired,
    output logic [31:0] debug_out
);

// Undelayed signals
logic [31:0] instruction, curr_address;
instr_type   inst_info;
logic        enable;
logic [31:0] immediate;
logic [31:0] result, next_address;
logic        flush;              // EXECUTE output
logic        stall;
logic [31:0] read_data;
logic [31:0] reg1_data, reg2_data;
logic [31:0] reg3_data;

// Delayed signals

// FETCH outputs
logic [31:0] instruction_d1;   // plumbing -> feeds instruction_d2
logic [31:0] instruction_d2;   // plumbing -> feeds instruction_d3
logic [31:0] instruction_d3;   // plumbing -> feeds instruction_d4
logic [31:0] instruction_d4;   // -> WRITEBACK (sliced [19:15]/[24:20]/[11:7] at port), aligned with enable_d3
logic [31:0] curr_address_d1;  // plumbing -> feeds curr_address_d2
logic [31:0] curr_address_d2;  // -> EXECUTE (curr_address input)

// DECODE outputs
instr_type   inst_info_d1;     // -> EXECUTE (inst_info input); plumbing -> feeds inst_info_d2
instr_type   inst_info_d2;     // -> MEMORY (inst_info input); plumbing -> feeds inst_info_d3
instr_type   inst_info_d3;     // -> used in writeback mux (reg3_data select)
logic [31:0] immediate_d1;     // -> EXECUTE (immediate input)
logic        enable_d1;        // plumbing -> feeds enable_d2
logic        enable_d2;        // plumbing -> feeds enable_d3
logic        enable_d3;        // -> WRITEBACK (enable input)

// EXECUTE outputs
logic [31:0] result_d1;        // -> MEMORY (address input); plumbing -> feeds result_d2
logic [31:0] result_d2;        // -> writeback mux (reg3_data select)
logic [31:0] next_address_d1;  // -> FETCH (next_address input), 1 delay

// MEMORY outputs
logic [31:0] read_data_d1;     // -> writeback mux (reg3_data select)

// WRITEBACK outputs
logic [31:0] reg1_data_d1;     // -> EXECUTE (register_data1 input)
logic [31:0] reg2_data_d1;     // plumbing -> feeds reg2_data_d2; -> EXECUTE (register_data2 input)
logic [31:0] reg2_data_d2;     // -> MEMORY (write_data input)

always_ff @(posedge clock or negedge nreset) begin
    if (!nreset) begin
        instruction_d1  <= 32'h00000013;
        instruction_d2  <= 32'h00000013;
        instruction_d3  <= 32'h00000013;
        instruction_d4  <= 32'h00000013;
        curr_address_d1 <= 32'b0;
        curr_address_d2 <= 32'b0;
        inst_info_d1    <= INSTR_UNKNOWN;
        inst_info_d2    <= INSTR_UNKNOWN;
        inst_info_d3    <= INSTR_UNKNOWN;
        immediate_d1    <= 32'b0;
        enable_d1       <= 1'b0;
        enable_d2       <= 1'b0;
        enable_d3       <= 1'b0;
        result_d1       <= 32'b0;
        result_d2       <= 32'b0;
        next_address_d1 <= 32'b0;
        read_data_d1    <= 32'b0;
        reg1_data_d1    <= 32'b0;
        reg2_data_d1    <= 32'b0;
        reg2_data_d2    <= 32'b0;
    end
    else begin
        // FETCH -> DECODE stage register (subject to flush/stall)
        if (flush) begin
            instruction_d1  <= 32'h00000013;
            curr_address_d1 <= 32'b0;
            inst_info_d1    <= INSTR_UNKNOWN;
            enable_d1       <= 1'b0;
            immediate_d1    <= 32'b0;
        end 
        else if (stall) begin
            instruction_d1  <= instruction_d1;
            curr_address_d1 <= curr_address_d1;
            inst_info_d1    <= INSTR_UNKNOWN;
            enable_d1       <= 1'b0;
            immediate_d1    <= 32'b0;
        end
        else begin
            instruction_d1  <= instruction;
            curr_address_d1 <= curr_address;
            inst_info_d1    <= inst_info;
            enable_d1       <= enable;
            immediate_d1    <= immediate;
        end

        // Always-advancing plumbing (never frozen by stall/flush)
        instruction_d2  <= instruction_d1;
        instruction_d3  <= instruction_d2;
        instruction_d4  <= instruction_d3;

        curr_address_d2 <= curr_address_d1;

        inst_info_d2 <= inst_info_d1;
        inst_info_d3 <= inst_info_d2;

        enable_d2 <= enable_d1;
        enable_d3 <= enable_d2;

        // EXECUTE outputs
        result_d1       <= result;
        result_d2       <= result_d1;
        next_address_d1 <= next_address;

        // MEMORY outputs
        read_data_d1 <= read_data;

        // WRITEBACK outputs / forwarding
        if ((instruction_d1[19:15] == instruction_d2[11:7]) && (instruction_d2[11:7] != 0) && enable_d1) begin
            if ((inst_info_d2 >= INSTR_LW) && (inst_info_d2 <= INSTR_LBU))
                reg1_data_d1 <= read_data;
            else
                reg1_data_d1 <= result;
        end
        else if ((instruction_d1[19:15] == instruction_d3[11:7]) && (instruction_d3[11:7] != 0) && enable_d2) begin
            if ((inst_info_d3 >= INSTR_LW) && (inst_info_d3 <= INSTR_LBU))
                reg1_data_d1 <= read_data_d1;
            else
                reg1_data_d1 <= result_d1;
        end
        else
            reg1_data_d1 <= reg1_data;

        if ((instruction_d1[24:20] == instruction_d2[11:7]) && (instruction_d2[11:7] != 0) && enable_d1) begin
            if ((inst_info_d2 >= INSTR_LW) && (inst_info_d2 <= INSTR_LBU))
                reg2_data_d1 <= read_data;
            else
                reg2_data_d1 <= result;
        end
        else if ((instruction_d1[24:20] == instruction_d3[11:7]) && (instruction_d3[11:7] != 0) && enable_d2) begin
            if ((inst_info_d3 >= INSTR_LW) && (inst_info_d3 <= INSTR_LBU))
                reg2_data_d1 <= read_data_d1;
            else
                reg2_data_d1 <= result_d1;
        end
        else
            reg2_data_d1 <= reg2_data;

        reg2_data_d2 <= reg2_data_d1;
    end
end

// Module instances

FETCH #(.PROGRAM_HEX(PROGRAM_HEX)) u_fetch (
    .clock        (clock),
    .nreset       (nreset),
    .stall        (stall),
    .flush        (flush),
    .next_address (next_address), // changed from d1 to immediate

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

assign reg3_data = ((inst_info_d3 >= INSTR_LW) && (inst_info_d3 <= INSTR_LBU)) ? read_data_d1 : result_d2;

assign debug_out = reg3_data;
assign ecall_fired = (inst_info_d3 == INSTR_ECALL);

always_comb begin
    if ((inst_info_d1 >= INSTR_LW) && (inst_info_d1 <= INSTR_LBU) &&
        (instruction_d2[11:7] != 0) &&
        ((instruction_d2[11:7] == instruction_d1[19:15]) ||
         (instruction_d2[11:7] == instruction_d1[24:20])))
        stall = 1'b1;
    else
        stall = 1'b0;
end

endmodule