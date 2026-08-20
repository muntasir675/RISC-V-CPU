import riscv_pkg::*;

module CPU #(parameter PROGRAM_HEX = "program.hex")
(
    input logic clock,
    input logic nreset,
    output logic ecall_fired,
    output logic [31:0] debug_out
);
    function automatic logic instruction_uses_rs1(instr_type inst);
        case (inst)
            INSTR_ADD,  INSTR_SUB,  INSTR_AND,   INSTR_OR,
            INSTR_XOR,  INSTR_SLL,  INSTR_SRL,   INSTR_SRA,
            INSTR_SLT,  INSTR_SLTU, INSTR_ADDI,  INSTR_ANDI,
            INSTR_ORI,  INSTR_XORI, INSTR_SLLI,  INSTR_SRLI,
            INSTR_SRAI, INSTR_SLTI, INSTR_SLTIU, INSTR_LW,
            INSTR_LH,   INSTR_LHU,  INSTR_LB,    INSTR_LBU,
            INSTR_SW,   INSTR_SH,   INSTR_SB,    INSTR_BEQ,
            INSTR_BNE,  INSTR_BLT,  INSTR_BGE,   INSTR_BLTU,
            INSTR_BGEU, INSTR_JALR:
                instruction_uses_rs1 = 1'b1;
            default:
                instruction_uses_rs1 = 1'b0;
        endcase
    endfunction

    function automatic logic instruction_uses_rs2(instr_type inst);
        case (inst)
            INSTR_ADD, INSTR_SUB, INSTR_AND,  INSTR_OR,
            INSTR_XOR, INSTR_SLL, INSTR_SRL,  INSTR_SRA,
            INSTR_SLT, INSTR_SLTU, INSTR_SW,  INSTR_SH,
            INSTR_SB,  INSTR_BEQ, INSTR_BNE,  INSTR_BLT,
            INSTR_BGE, INSTR_BLTU, INSTR_BGEU:
                instruction_uses_rs2 = 1'b1;
            default:
                instruction_uses_rs2 = 1'b0;
        endcase
    endfunction

    function automatic logic instruction_writes_rd(instr_type inst);
        case (inst)
            INSTR_ADD,   INSTR_SUB,   INSTR_AND,   INSTR_OR,
            INSTR_XOR,   INSTR_SLL,   INSTR_SRL,   INSTR_SRA,
            INSTR_SLT,   INSTR_SLTU,  INSTR_ADDI,  INSTR_ANDI,
            INSTR_ORI,   INSTR_XORI,  INSTR_SLLI,  INSTR_SRLI,
            INSTR_SRAI,  INSTR_SLTI,  INSTR_SLTIU, INSTR_LW,
            INSTR_LH,    INSTR_LHU,   INSTR_LB,    INSTR_LBU,
            INSTR_JAL,   INSTR_JALR,  INSTR_LUI,   INSTR_AUIPC:
                instruction_writes_rd = 1'b1;
            default:
                instruction_writes_rd = 1'b0;
        endcase
    endfunction

    function automatic logic instruction_reads_mem(instr_type inst);
        case (inst)
            INSTR_LW, INSTR_LH, INSTR_LHU, INSTR_LB, INSTR_LBU:
                instruction_reads_mem = 1'b1;
            default:
                instruction_reads_mem = 1'b0;
        endcase
    endfunction

    logic [31:0] instruction;
    logic [31:0] curr_address;
    logic [31:0] fetch_next_address;
    logic        fetch_stall;

    logic [31:0] ifid_instruction;
    logic [31:0] ifid_pc;

    instr_type   decoded_inst_info;
    logic [31:0] decoded_immediate;
    logic [31:0] decode_rs1_data;
    logic [31:0] decode_rs2_data;
    logic        decode_uses_rs1;
    logic        decode_uses_rs2;
    logic        decode_reg_write;
    logic        decode_mem_read;

    logic [31:0] idex_pc;
    logic [31:0] idex_instruction;
    instr_type   idex_inst_info;
    logic [31:0] idex_immediate;
    logic [31:0] idex_rs1_data;
    logic [31:0] idex_rs2_data;
    logic [4:0]  idex_rs1_addr;
    logic [4:0]  idex_rs2_addr;
    logic [4:0]  idex_rd_addr;
    logic        idex_uses_rs1;
    logic        idex_uses_rs2;
    logic        idex_reg_write;
    logic        idex_mem_read;

    logic [31:0] execute_operand1;
    logic [31:0] execute_operand2;
    logic [31:0] execute_store_data;
    logic [31:0] execute_result;
    logic [31:0] execute_next_address;
    logic        execute_flush;

    logic [31:0] exmem_result;
    logic [31:0] exmem_store_data;
    instr_type   exmem_inst_info;
    logic [4:0]  exmem_rd_addr;
    logic        exmem_reg_write;
    logic        exmem_mem_read;

    logic [31:0] memory_read_data;

    logic [31:0] memwb_write_data;
    logic [4:0]  memwb_rd_addr;
    logic        memwb_reg_write;

    logic        load_use_hazard;


    FETCH #(.PROGRAM_HEX(PROGRAM_HEX)) u_fetch (
        .clock        (clock),
        .nreset       (nreset),
        .stall        (fetch_stall),
        .next_address (fetch_next_address),
        .curr_address (curr_address),
        .instruction  (instruction)
    );

    DECODE u_decode (
        .instruction  (ifid_instruction),
        .inst_info    (decoded_inst_info),
        .immediate    (decoded_immediate)
    );

    EXECUTE u_execute (
        .register_data1 (execute_operand1),
        .register_data2 (execute_operand2),
        .immediate      (idex_immediate),
        .curr_address   (idex_pc),
        .inst_info      (idex_inst_info),
        .result         (execute_result),
        .next_address   (execute_next_address)
    );

    MEMORY u_memory (
        .clock            (clock),
        .address          (exmem_result),
        .write_data       (exmem_store_data),
        .inst_info        (exmem_inst_info),
        .read_data        (memory_read_data)
    );

    WRITEBACK u_writeback (
        .clock           (clock),
        .nreset          (nreset),
        .rs1_addr        (ifid_instruction[19:15]),
        .rs2_addr        (ifid_instruction[24:20]),
        .rd_addr         (memwb_rd_addr),
        .rd_data         (memwb_write_data),
        .rd_write_enable (memwb_reg_write),
        .rs1_data        (decode_rs1_data),
        .rs2_data        (decode_rs2_data)
    );

    assign debug_out = memwb_write_data;

    assign decode_uses_rs1 = instruction_uses_rs1(decoded_inst_info);
    assign decode_uses_rs2 = instruction_uses_rs2(decoded_inst_info);
    assign decode_reg_write = instruction_writes_rd(decoded_inst_info);
    assign decode_mem_read = instruction_reads_mem(decoded_inst_info);
    assign ecall_fired = (exmem_inst_info == INSTR_ECALL);

    assign load_use_hazard =
        idex_mem_read &&
        (idex_rd_addr != 5'd0) &&
        (
            (decode_uses_rs1 && (idex_rd_addr == ifid_instruction[19:15])) ||
            (decode_uses_rs2 && (idex_rd_addr == ifid_instruction[24:20]))
        );


    assign fetch_stall = load_use_hazard;
    assign execute_flush = (execute_next_address != (idex_pc + 32'd4));
    assign fetch_next_address = execute_flush ? execute_next_address : (curr_address + 32'd4);

    always_comb begin
        execute_operand1 = idex_rs1_data;
        if (idex_uses_rs1 && exmem_reg_write && !exmem_mem_read && (exmem_rd_addr != 5'd0) && (exmem_rd_addr == idex_rs1_addr))
            execute_operand1 = exmem_result;
        else if (idex_uses_rs1 && memwb_reg_write && (memwb_rd_addr != 5'd0) && (memwb_rd_addr == idex_rs1_addr))
            execute_operand1 = memwb_write_data;

        execute_operand2 = idex_rs2_data;
        if (idex_uses_rs2 && exmem_reg_write && !exmem_mem_read && (exmem_rd_addr != 5'd0) && (exmem_rd_addr == idex_rs2_addr))
            execute_operand2 = exmem_result;
        else if (idex_uses_rs2 && memwb_reg_write && (memwb_rd_addr != 5'd0) && (memwb_rd_addr == idex_rs2_addr))
            execute_operand2 = memwb_write_data;

        execute_store_data = idex_rs2_data;
        if (exmem_reg_write && !exmem_mem_read && (exmem_rd_addr != 5'd0) && (exmem_rd_addr == idex_rs2_addr))
            execute_store_data = exmem_result;
        else if (memwb_reg_write && (memwb_rd_addr != 5'd0) && (memwb_rd_addr == idex_rs2_addr))
            execute_store_data = memwb_write_data;
    end

    always_ff @(posedge clock or negedge nreset) begin
        if (!nreset) begin
            ifid_instruction <= 32'h00000013;
            ifid_pc          <= 32'b0;

            idex_pc          <= 32'b0;
            idex_instruction <= 32'h00000013;
            idex_inst_info   <= INSTR_UNKNOWN;
            idex_immediate   <= 32'b0;
            idex_rs1_data    <= 32'b0;
            idex_rs2_data    <= 32'b0;
            idex_rs1_addr    <= 5'd0;
            idex_rs2_addr    <= 5'd0;
            idex_rd_addr     <= 5'd0;
            idex_uses_rs1    <= 1'b0;
            idex_uses_rs2    <= 1'b0;
            idex_reg_write   <= 1'b0;
            idex_mem_read    <= 1'b0;

            exmem_result     <= 32'b0;
            exmem_store_data <= 32'b0;
            exmem_inst_info  <= INSTR_UNKNOWN;
            exmem_rd_addr    <= 5'd0;
            exmem_reg_write  <= 1'b0;
            exmem_mem_read   <= 1'b0;

            memwb_write_data <= 32'b0;
            memwb_rd_addr    <= 5'd0;
            memwb_reg_write  <= 1'b0;
        end else begin
            memwb_write_data <= exmem_mem_read ? memory_read_data : exmem_result;
            memwb_rd_addr    <= exmem_rd_addr;
            memwb_reg_write  <= exmem_reg_write;

            exmem_result     <= execute_result;
            exmem_store_data <= execute_store_data;
            exmem_inst_info  <= idex_inst_info;
            exmem_rd_addr    <= idex_rd_addr;
            exmem_reg_write  <= idex_reg_write;
            exmem_mem_read   <= idex_mem_read;

            if (execute_flush || load_use_hazard) begin
                idex_pc          <= 32'b0;
                idex_instruction <= 32'h00000013;
                idex_inst_info   <= INSTR_UNKNOWN;
                idex_immediate   <= 32'b0;
                idex_rs1_data    <= 32'b0;
                idex_rs2_data    <= 32'b0;
                idex_rs1_addr    <= 5'd0;
                idex_rs2_addr    <= 5'd0;
                idex_rd_addr     <= 5'd0;
                idex_uses_rs1    <= 1'b0;
                idex_uses_rs2    <= 1'b0;
                idex_reg_write   <= 1'b0;
                idex_mem_read    <= 1'b0;
            end else begin
                idex_pc          <= ifid_pc;
                idex_instruction <= ifid_instruction;
                idex_inst_info   <= decoded_inst_info;
                idex_immediate   <= decoded_immediate;
                idex_rs1_data    <= decode_rs1_data;
                idex_rs2_data    <= decode_rs2_data;
                idex_rs1_addr    <= ifid_instruction[19:15];
                idex_rs2_addr    <= ifid_instruction[24:20];
                idex_rd_addr     <= ifid_instruction[11:7];
                idex_uses_rs1    <= decode_uses_rs1;
                idex_uses_rs2    <= decode_uses_rs2;
                idex_reg_write   <= decode_reg_write;
                idex_mem_read    <= decode_mem_read;
            end

            if (execute_flush) begin
                ifid_instruction <= 32'h00000013;
                ifid_pc          <= 32'b0;
            end else if (!load_use_hazard) begin
                ifid_instruction <= instruction;
                ifid_pc          <= curr_address;
            end
        end
    end

endmodule
