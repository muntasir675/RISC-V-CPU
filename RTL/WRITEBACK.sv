module WRITEBACK(
    input  logic        clock,
    input  logic        nreset,
    input  logic        enable,
    input  logic [4:0]  reg3_addr,
    input  logic [4:0]  reg1_addr,
    input  logic [4:0]  reg2_addr,
    input  logic [31:0] reg3_data,
    output logic [31:0] reg1_data,
    output logic [31:0] reg2_data
);

// 32 registers of 4 byte words
logic [31:0] registers [0:31];

function automatic [31:0] read_reg(input [4:0] addr);
    if (addr == 5'b0)
        read_reg = 32'b0;
    else if (enable && (reg3_addr == addr))
        read_reg = reg3_data;
    else
        read_reg = registers[addr];
endfunction

// read
always_comb begin
    reg1_data = read_reg(reg1_addr);
    reg2_data = read_reg(reg2_addr);
end

// write
always_ff @(posedge clock or negedge nreset) begin
    if (!nreset) 
    for (int i = 0; i < 32; i++) registers[i] <= 32'h0;
    else if (enable && (reg3_addr != 5'd0))
        registers[reg3_addr] <= reg3_data;
end

endmodule
