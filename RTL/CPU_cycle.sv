import riscv_pkg::*;

module riscv_single_cycle (
    input  logic clk,
    input  logic rst_n
);

    // Fetch state
    logic [31:0] program_counter;
    logic [31:0] next_program_counter;
    logic [31:0] program_counter_plus_4;
    logic [31:0] instruction;

    // Decoded instruction fields
    logic [6:0]  opcode;
    logic [4:0]  destination_reg_address;
    logic [2:0]  funct3;
    logic [4:0]  source_reg1_address;
    logic [4:0]  source_reg2_address;
    logic [6:0]  funct7;

    // Register file datapath
    logic [31:0] source_reg1_data;
    logic [31:0] source_reg2_data;
    logic [31:0] destination_reg_data;

    // Immediate datapath
    logic [31:0] immediate;
    logic [31:0] program_counter_plus_immediate;

    // ALU datapath
    logic [31:0] alu_a;
    logic [31:0] alu_b;
    logic [31:0] alu_result;
    logic        alu_zero;
    logic        alu_carry;

    // Memory datapath
    logic [31:0] memory_read_data;

    // Branch decision
    logic        take_branch;

    // Control outputs
    logic        reg_write;
    logic        mem_read;
    logic        mem_write;
    logic        mem_to_reg;
    logic        alu_src;
    immediate_select_t imm_sel;
    alu_operation_t    alu_ctrl;
    instruction_type_t instruction_type;
    logic [2:0]        memory_access_size;

    // Derived instruction class checks
    logic is_branch_instruction;
    logic is_jal_instruction;
    logic is_jalr_instruction;
    logic is_link_instruction;
    logic is_lui_instruction;
    logic is_auipc_instruction;

    assign opcode                  = instruction[6:0];
    assign destination_reg_address = instruction[11:7];
    assign funct3                  = instruction[14:12];
    assign source_reg1_address     = instruction[19:15];
    assign source_reg2_address     = instruction[24:20];
    assign funct7                  = instruction[31:25];

    assign is_branch_instruction = (instruction_type == INST_BRANCH);
    assign is_jal_instruction    = (instruction_type == INST_JAL);
    assign is_jalr_instruction   = (instruction_type == INST_JALR);
    assign is_link_instruction   = is_jal_instruction || is_jalr_instruction;
    assign is_lui_instruction    = (instruction_type == INST_LUI);
    assign is_auipc_instruction  = (instruction_type == INST_AUIPC);

    assign program_counter_plus_4         = program_counter + 32'd4;
    assign program_counter_plus_immediate = program_counter + immediate;
    assign alu_a                          = is_auipc_instruction ? program_counter : source_reg1_data;
    assign alu_b                          = alu_src ? immediate : source_reg2_data;

    pc_reg u_pc (
        .clk     (clk),
        .rst_n   (rst_n),
        .next_pc (next_program_counter),
        .pc      (program_counter)
    );

    instr_mem u_imem (
        .pc    (program_counter),
        .instr (instruction)
    );

    control_unit u_ctrl (
        .opcode          (opcode),
        .funct3          (funct3),
        .funct7_5        (funct7[5]),
        .reg_write       (reg_write),
        .mem_read        (mem_read),
        .mem_write       (mem_write),
        .mem_to_reg      (mem_to_reg),
        .alu_src         (alu_src),
        .imm_sel         (imm_sel),
        .alu_ctrl        (alu_ctrl),
        .instruction_type(instruction_type),
        .mem_size        (memory_access_size)
    );

    reg_file u_rf (
        .clock                  (clk),
        .reset_active_low       (rst_n),
        .source_reg1_address    (source_reg1_address),
        .source_reg1_data       (source_reg1_data),
        .source_reg2_address    (source_reg2_address),
        .source_reg2_data       (source_reg2_data),
        .destination_reg_address(destination_reg_address),
        .destination_reg_data   (destination_reg_data),
        .write_enable           (reg_write)
    );

    imm_gen u_immgen (
        .instr   (instruction),
        .imm_sel (imm_sel),
        .imm_out (immediate)
    );

    alu u_alu (
        .a        (alu_a),
        .b        (alu_b),
        .alu_ctrl (alu_ctrl),
        .result   (alu_result),
        .zero     (alu_zero),
        .carry    (alu_carry)
    );

    branch_unit u_branch (
        .funct3        (funct3),
        .inst_is_branch(is_branch_instruction),
        .zero          (alu_zero),
        .alu_result    (alu_result),
        .take_branch   (take_branch)
    );

    data_mem #(.DEPTH(8192)) u_dmem (
        .clock       (clk),
        .read_enable (mem_read),
        .write_enable(mem_write),
        .address     (alu_result),
        .write_data  (source_reg2_data),
        .byte_count  (memory_access_size),
        .read_data   (memory_read_data)
    );

    always_comb begin
        next_program_counter = program_counter_plus_4;

        if (is_jalr_instruction)
            next_program_counter = {alu_result[31:1], 1'b0};
        else if (is_jal_instruction)
            next_program_counter = program_counter_plus_immediate;
        else if (is_branch_instruction && take_branch)
            next_program_counter = program_counter_plus_immediate;
    end

    always_comb begin
        destination_reg_data = alu_result;

        if (is_link_instruction)
            destination_reg_data = program_counter_plus_4;
        else if (is_lui_instruction)
            destination_reg_data = immediate;
        else if (mem_to_reg)
            destination_reg_data = memory_read_data;
    end

endmodule
