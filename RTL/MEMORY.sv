import riscv_pkg::*;

module MEMORY(
    input  logic        clock,
    input  instr_type   inst_info,
    input  logic [31:0] address,
    input  logic [31:0] write_data,
    output logic [31:0] read_data
);

// 256 word ram of 32 bits each ramstyle for hardware to interpret as ram
(* ramstyle = "M10K, no_rw_check" *) logic [31:0] storage [0:255];

wire [29:0] word_addr = address[31:2];
wire [4:0] byte_addr = address[1:0]*8;

// Write logic
always_ff @(posedge clock) begin
    case (inst_info)
        INSTR_SB: storage[word_addr][byte_addr +: 8] <= write_data[7:0];
        INSTR_SH: storage[word_addr][byte_addr +: 16] <= write_data[15:0]; // trusting input no guard
        INSTR_SW: storage[word_addr] <= write_data;
        default: ;
    endcase
end

// Read logic 
wire [31:0] rd_word = storage[word_addr];
always_comb begin
    case (inst_info)
        INSTR_LB:  read_data = 32'($signed(rd_word[byte_addr +: 8]));
        INSTR_LH:  read_data = 32'($signed(rd_word[byte_addr +: 16]));
        INSTR_LW:  read_data = rd_word;
        INSTR_LBU: read_data = 32'($unsigned(rd_word[byte_addr +: 8]));
        INSTR_LHU: read_data = 32'($unsigned(rd_word[byte_addr +: 16]));
        default:   read_data = 32'b0;
    endcase
end

endmodule