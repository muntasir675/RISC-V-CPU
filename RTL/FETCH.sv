module FETCH#(parameter PROGRAM_HEX = "program.hex")
(
    input logic clock,
    input logic nreset,
    input logic  [31:0] next_address,
    output logic [31:0] instruction, curr_address
);

logic [31:0] instruction_memory [0:1023];


initial $readmemh(PROGRAM_HEX, instruction_memory);

assign instruction = instruction_memory[curr_address[30:2]];

always_ff @(posedge clock or negedge nreset) begin
    if(!nreset) curr_address <= 32'b0;
    else        curr_address<=next_address;
end

endmodule
