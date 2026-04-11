import riscv_pkg::*;
module MEMORY(
    input  logic        clock,
    input  logic [31:0] address, write_data, instruction, result,
    input  instr_type inst_info,
    output logic [31:0] read_data, register_data1, register_data2
);

logic [7:0] Storage [0:8191];
logic [31:0] register[0:31];

assign register_data1 = (instruction[19:15] == 5'b0) ? 32'b0 : register[instruction[19:15]];
assign register_data2 = (instruction[24:20] == 5'b0) ? 32'b0 : register[instruction[24:20]];


always_ff @(posedge clock) begin
    case (inst_info)
        INSTR_SB: Storage[address] <= write_data[7:0];
        INSTR_SH: begin
            Storage[address]   <= write_data[7:0];
            Storage[address+1] <= write_data[15:8];
        end
        INSTR_SW: begin
            Storage[address]   <= write_data[7:0];
            Storage[address+1] <= write_data[15:8];
            Storage[address+2] <= write_data[23:16];
            Storage[address+3] <= write_data[31:24];
        end
        INSTR_ADD, INSTR_SUB, INSTR_AND, INSTR_OR, INSTR_XOR,
        INSTR_SLL, INSTR_SRL, INSTR_SRA, INSTR_SLT, INSTR_SLTU,
        INSTR_ADDI, INSTR_ANDI, INSTR_ORI, INSTR_XORI,
        INSTR_SLLI, INSTR_SRLI, INSTR_SRAI, INSTR_SLTI, INSTR_SLTIU,
        INSTR_JAL, INSTR_JALR, INSTR_LUI, INSTR_AUIPC: begin
            if (instruction[11:7] != 5'b0) register[instruction[11:7]] <= result;
        end

        INSTR_LW, INSTR_LH, INSTR_LHU, INSTR_LB, INSTR_LBU: begin
            if (instruction[11:7] != 5'b0) register[instruction[11:7]] <= read_data;
        end
    endcase
end

always_comb begin
    case (inst_info)
        INSTR_LB:  read_data = {{24{Storage[address][7]}}, Storage[address]};
        INSTR_LH:  read_data = {{16{Storage[address+1][7]}}, Storage[address+1], Storage[address]};
        INSTR_LW:  read_data = {Storage[address+3], Storage[address+2], Storage[address+1], Storage[address]};
        INSTR_LBU: read_data = {24'b0, Storage[address]};
        INSTR_LHU: read_data = {16'b0, Storage[address+1], Storage[address]};
        default:   read_data = 32'b0;
    endcase
end

endmodule