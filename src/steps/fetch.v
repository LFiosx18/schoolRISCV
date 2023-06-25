module fetch(
    input clk,
    input [31:0] pc_i,
    output [31:0] instr_o,
    output [31:0] pc_o,
    output [31:0] pcPlus4_o
);

    reg [31:0] pcR;
    wire [31:0] pcW;
    wire [31:0] dataW;

    assign pcW = pcR;

    sm_rom reset_rom(pcW, dataW);

    always @ (posedge clk) begin
        pcR <= pc_i;
    end    

    assign instr_o = dataW;
    assign pc_o = pcR;
    assign pcPlus4_o = pcR + 4;


endmodule