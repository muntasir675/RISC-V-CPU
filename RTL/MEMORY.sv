import riscv_pkg::*;
module MEMORY(
    input  logic        clock,
    input  logic [31:0] address,
    input  logic [31:0] write_data,
    input  instr_type inst_info,
    output logic [31:0] read_data
);

logic [31:0] Storage [0:255];
logic [31:0] mem_read_word;

always_ff @(posedge clock) begin
    case (inst_info)
        INSTR_SB: Storage[address[31:2]][address[1:0]*8 +: 8] <= write_data[7:0];
        INSTR_SH: begin
            Storage[address[31:2]][address[1:0]*8 +: 8] <= write_data[7:0];
            if (address[1:0] < 3)
                Storage[address[31:2]][(address[1:0]+1)*8 +: 8] <= write_data[15:8];
        end
        INSTR_SW: Storage[address[31:2]] <= write_data;
        default: ;
    endcase
end

// Make the read combinational!
assign mem_read_word = Storage[address[31:2]];

always_comb begin
    case (inst_info)
        INSTR_LB:  read_data = {{24{mem_read_word[address[1:0]*8 + 7]}}, mem_read_word[address[1:0]*8 +: 8]};
        INSTR_LH:  read_data = {{16{mem_read_word[(address[1:0]+1)*8 + 7]}}, mem_read_word[(address[1:0]+1)*8 +: 8], mem_read_word[address[1:0]*8 +: 8]};
        INSTR_LW:  read_data = mem_read_word;
        INSTR_LBU: read_data = {24'b0, mem_read_word[address[1:0]*8 +: 8]};
        INSTR_LHU: read_data = {16'b0, mem_read_word[(address[1:0]+1)*8 +: 8], mem_read_word[address[1:0]*8 +: 8]};
        default:   read_data = 32'b0;
    endcase
end

endmodule
