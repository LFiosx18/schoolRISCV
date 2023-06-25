`timescale 1ns / 1ps

module writeback(
    input clk,

    input               aluZero_i,
    input               condZero_i,                 
    input               branch_i,
    input               aluNeg_i,
    input               bge_i,

    input [31:0]        pcBranch_i,
    input [31:0]        pcPlus4_i,

    output [31:0]   newPC_o 
);


    reg         bgeR;
    reg         aluNegR;

    reg         aluZeroR;
    reg         condZeroR;
    reg         branchR;
    reg [31:0]  pcBranchR;
    reg [31:0]  pcPlus4R;

    always @ (posedge clk) begin
        aluNegR     <= aluNeg_i;
        bgeR        <= bge_i;   
        aluZeroR    <= aluZero_i;
        condZeroR   <= condZero_i;
        branchR     <= branch_i;
        pcBranchR   <= pcBranch_i;
        pcPlus4R    <= pcPlus4_i;
    end  

    wire bge = bgeR & aluNegR;
    wire beq = ~(aluZeroR ^ condZeroR);
    wire res = beq | bge;
    wire enable = res & branchR;
    wire [31:0] newPCW = enable ? pcBranchR : pcPlus4R;

    assign newPC_o     = newPCW; 

endmodule