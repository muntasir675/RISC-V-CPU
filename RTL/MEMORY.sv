import riscv_pkg::*;
module MEMORY(
    input  logic        clock,nreset,
    input  logic [31:0] address, write_data, instruction, result,
    input  instr_type inst_info,
    output logic [31:0] read_data, register_data1, register_data2,
    output logic [31:0] mtvec, mepc
);

logic [31:0] CSR [0:5];
logic [7:0] Storage [0:8191];
logic [31:0] register[0:31];

assign register_data1 = (instruction[19:15] == 5'b0) ? 32'b0 : register[instruction[19:15]];
assign register_data2 = (instruction[24:20] == 5'b0) ? 32'b0 : register[instruction[24:20]];
assign mtvec = CSR[1];
assign mepc  = CSR[2];

function automatic logic [2:0] csr_idx(input logic [11:0] addr);
    case (addr)
        12'h300: csr_idx = 0;
        12'h305: csr_idx = 1;
        12'h341: csr_idx = 2;
        12'h342: csr_idx = 3;
        12'hf14: csr_idx = 4;
        default: csr_idx = 5; // write-ignore
    endcase
endfunction

always_ff @(posedge clock or negedge nreset) begin
    if(!nreset) begin
        for (integer i = 0; i < 32; i = i + 1) register[i] = 32'h0;
        for (integer i = 0; i < 6;  i++) CSR[i] = 32'h0;
        end
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

        // csr
        INSTR_CSRRW: begin
            CSR[csr_idx(instruction[31:20])] <= register_data1;
            if (instruction[11:7] != 5'b0) register[instruction[11:7]] <= CSR[csr_idx(instruction[31:20])];
        end
        INSTR_CSRRS: begin
            CSR[csr_idx(instruction[31:20])] <= CSR[csr_idx(instruction[31:20])] | register_data1;
            if (instruction[11:7] != 5'b0) register[instruction[11:7]] <= CSR[csr_idx(instruction[31:20])];
        end
        INSTR_CSRRC: begin
            CSR[csr_idx(instruction[31:20])] <= CSR[csr_idx(instruction[31:20])] & ~register_data1;
            if (instruction[11:7] != 5'b0) register[instruction[11:7]] <= CSR[csr_idx(instruction[31:20])];
        end
        INSTR_CSRRWI: begin
            CSR[csr_idx(instruction[31:20])] <= {27'b0, instruction[19:15]};
            if (instruction[11:7] != 5'b0) register[instruction[11:7]] <= CSR[csr_idx(instruction[31:20])];
        end
        INSTR_CSRRSI: begin
            CSR[csr_idx(instruction[31:20])] <= CSR[csr_idx(instruction[31:20])] | {27'b0, instruction[19:15]};
            if (instruction[11:7] != 5'b0) register[instruction[11:7]] <= CSR[csr_idx(instruction[31:20])];
        end
        INSTR_CSRRCI: begin
            CSR[csr_idx(instruction[31:20])] <= CSR[csr_idx(instruction[31:20])] & ~{27'b0, instruction[19:15]};
            if (instruction[11:7] != 5'b0) register[instruction[11:7]] <= CSR[csr_idx(instruction[31:20])];
        end
        INSTR_ECALL: begin
            CSR[2] <= result;
            CSR[3] <= 32'h8;
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