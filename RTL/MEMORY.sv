import riscv_pkg::*;
`ifdef ALTERA_RESERVED_QIS
`include "vendor/altsyncram.v"
`endif

module MEMORY(
    input  logic        clock,
    input  logic [31:0] address,
    input  logic [31:0] write_data,
    input  instr_type inst_info,
    output logic [31:0] read_data
);

localparam int WORD_COUNT = 256;
localparam int ADDR_WIDTH = 8;

logic [ADDR_WIDTH-1:0] word_address;
logic [31:0]           mem_read_word;

assign word_address = address[ADDR_WIDTH+1:2];

`ifdef ALTERA_RESERVED_QIS
// Synthesis path - simplified
logic [3:0]  write_byteena;
logic [31:0] ram_write_word;
logic        ram_write_enable;

always_comb begin
    ram_write_enable = (inst_info == INSTR_SB || inst_info == INSTR_SH || inst_info == INSTR_SW);
    
    case (inst_info)
        INSTR_SB: begin
            write_byteena  = 4'b0001 << address[1:0];
            ram_write_word = write_data[7:0] << (address[1:0] * 8);
        end
        INSTR_SH: begin
            write_byteena  = (address[1] ? 4'b1100 : 4'b0011) << address[0];
            ram_write_word = write_data[15:0] << (address[1:0] * 8);
        end
        INSTR_SW: begin
            write_byteena  = 4'b1111;
            ram_write_word = write_data;
        end
        default: begin
            write_byteena  = 4'b0000;
            ram_write_word = 32'b0;
        end
    endcase
end

wire [2:0] ram_eccstatus_unused;
altsyncram u_data_ram (
    .wren_a(ram_write_enable), .rden_a(1'b1), .data_a(ram_write_word),
    .address_a(word_address), .clock0(clock), .clocken0(1'b1),
    .byteena_a(write_byteena), .q_a(mem_read_word),
    .wren_b(1'b0), .rden_b(1'b1), .data_b(1'b0), .address_b(1'b0),
    .clock1(1'b1), .clocken1(1'b1), .clocken2(1'b1), .clocken3(1'b1),
    .aclr0(1'b0), .aclr1(1'b0), .byteena_b(1'b1),
    .addressstall_a(1'b0), .addressstall_b(1'b0),
    .eccstatus(ram_eccstatus_unused), .q_b()
);
defparam
    u_data_ram.operation_mode = "SINGLE_PORT",
    u_data_ram.width_a = 32,
    u_data_ram.widthad_a = ADDR_WIDTH,
    u_data_ram.numwords_a = WORD_COUNT,
    u_data_ram.width_byteena_a = 4,
    u_data_ram.outdata_reg_a = "UNREGISTERED",
    u_data_ram.power_up_uninitialized = "FALSE",
    u_data_ram.ram_block_type = "M10K";

`else
// Simulation path - ORIGINAL (don't touch this)
(* ramstyle = "M10K, no_rw_check" *) logic [31:0] storage [0:WORD_COUNT-1];

always_ff @(posedge clock) begin
    case (inst_info)
        INSTR_SB: storage[address[31:2]][address[1:0]*8 +: 8] <= write_data[7:0];
        INSTR_SH: begin
            storage[address[31:2]][address[1:0]*8 +: 8] <= write_data[7:0];
            if (address[1:0] < 3)
                storage[address[31:2]][(address[1:0]+1)*8 +: 8] <= write_data[15:8];
        end
        INSTR_SW: storage[address[31:2]] <= write_data;
        default: ;
    endcase
end

assign mem_read_word = storage[address[31:2]];
`endif

// Read logic
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