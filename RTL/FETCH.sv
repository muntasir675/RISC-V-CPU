module FETCH #(
    parameter PROGRAM_HEX = "program.hex"
)(
    input  logic clock,
    input  logic nreset,
    input  logic stall,
    input  logic [31:0] next_address,
    output logic [31:0] instruction,
    output logic [31:0] curr_address
);

logic [31:0] instruction_memory [0:1023];
initial $readmemh(PROGRAM_HEX, instruction_memory);

// Word-indexed fetch: drop PC[1:0] since every instruction is 4 bytes
assign instruction = instruction_memory[curr_address[31:2]]; 

always_ff @(posedge clock or negedge nreset) begin
    if (!nreset)
        curr_address <= 32'b0;
    else if (!stall) begin
        curr_address <= next_address;
    end
end

endmodule