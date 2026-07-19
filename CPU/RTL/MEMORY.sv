import riscv_pkg::*;
module MEMORY(
    input  logic        clock,nreset,
    input  logic [31:0] instruction, result,
    input  instr_type inst_info,
    output logic [31:0] register_data1, register_data2 // you make these inputs and use them.
);

logic [7:0] Storage [0:1023];
logic [31:0] register[0:31];
logic [31:0] read_data_memory;

assign register_data1 = register[instruction[19:15]];
assign register_data2 = register[instruction[24:20]]; // these you will put into a different file with register

always_ff @(posedge clock or negedge nreset) begin
    if(!nreset)
        for (integer i = 0; i < 32; i = i + 1) register[i] = 32'h0;
    else begin
        case (inst_info)
            INSTR_SB: Storage[result] <= register_data2[7:0];
            INSTR_SH: begin
                Storage[result]   <= register_data2[7:0];
                Storage[result+1] <= register_data2[15:8];
            end
            INSTR_SW: begin
                Storage[result]   <= register_data2[7:0];
                Storage[result+1] <= register_data2[15:8];
                Storage[result+2] <= register_data2[23:16];
                Storage[result+3] <= register_data2[31:24];
            end
            // all this is register operations
            INSTR_ADD,  INSTR_SUB,  INSTR_AND,   INSTR_OR,
            INSTR_XOR,  INSTR_SLL,  INSTR_SRL,   INSTR_SRA,
            INSTR_SLT,  INSTR_SLTU, INSTR_ADDI,  INSTR_ANDI,
            INSTR_ORI,  INSTR_XORI, INSTR_SLLI,  INSTR_SRLI,
            INSTR_SRAI, INSTR_SLTI, INSTR_SLTIU, INSTR_JAL, 
            INSTR_JALR, INSTR_LUI,  INSTR_AUIPC:
                if (instruction[11:7] != 5'b0) register[instruction[11:7]] <= result;
            INSTR_LW, INSTR_LH, INSTR_LHU, INSTR_LB, INSTR_LBU:
                if (instruction[11:7] != 5'b0) register[instruction[11:7]] <= read_data_memory;
        endcase
    end
end

always_comb begin
    case (inst_info)
        INSTR_LB:  read_data_memory = {{24{Storage[result][7]}}, Storage[result]};
        INSTR_LH:  read_data_memory = {{16{Storage[result+1][7]}}, Storage[result+1], Storage[result]};
        INSTR_LW:  read_data_memory = {Storage[result+3], Storage[result+2], Storage[result+1], Storage[result]};
        INSTR_LBU: read_data_memory = {24'b0, Storage[result]};
        INSTR_LHU: read_data_memory = {16'b0, Storage[result+1], Storage[result]};
        default:   read_data_memory = 32'b0;
    endcase
end

endmodule