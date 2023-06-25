`include "sr_cpu.vh"

module execute(
    input               clk,

    input               wdSrc_i,
    input               regWrite_i,
    input               branch_i,
    input               condZero_i,
    input               bge_i,
    input [ 2:0]        aluControl_i,
    input               aluSrc_i,

    input [31:0]        srcA_i,
    input [31:0]        srcB_i,
    input [ 4:0]        rd_i,
    input [31:0]        immI_i,
    input [31:0]        immU_i,

    input [31:0]        pcBranch_i,
    input [31:0]        pcPlus4_i,

    output          wdSrc_o,
    output          regWrite_o,
    output          branch_o,
    output          condZero_o,
    output          aluZero_o,
    output          aluNeg_o,
    output [31:0]   aluResult_o,
    output          bge_o,

    output [ 4:0]   rd_o,
    output [31:0]   immU_o,    

    output [31:0]   pcBranch_o,
    output [31:0]   pcPlus4_o
);

    reg         wdSrcR;
    reg         regWriteR;
    reg         branchR;
    reg         condZeroR;
    reg         bgeR;
    reg [ 2:0]  aluControlR;
    reg         aluSrcR;

    reg [31:0]  srcAR;
    reg [31:0]  srcBR;
    reg [ 4:0]  rdR;
    reg [31:0]  immIR;
    reg [31:0]  immUR;

    reg [31:0]  pcBranchR;
    reg [31:0]  pcPlus4R;

    wire [31:0] srcAW = srcAR;
    wire [31:0] aluSecondW = aluSrcR ? immIR : srcBR;
    wire [ 2:0] aluControlW = aluControlR;
    wire        aluZeroW;
    wire        aluNegW;
    wire [31:0] aluResultW;
    
    sr_alu sr_alu(
        .srcA(srcAW),
        .srcB(aluSecondW),
        .oper(aluControlW),
        .zero(aluZeroW),
        .neg(aluNegW),
        .result(aluResultW)
    );

    always @ (posedge clk) begin
        wdSrcR      <= wdSrc_i;
        regWriteR   <= regWrite_i;
        branchR     <= branch_i;
        condZeroR   <= condZero_i;
        bgeR        <= bge_i;
        aluControlR <= aluControl_i;
        aluSrcR     <= aluSrc_i;
        srcAR       <= srcA_i;
        srcBR       <= srcB_i;
        rdR         <= rd_i;
        immIR       <= immI_i;
        immUR       <= immU_i;
        pcBranchR   <= pcBranch_i;
        pcPlus4R    <= pcPlus4_i;
    end    

    assign   wdSrc_o     = wdSrcR;
    assign   regWrite_o  = regWriteR;
    assign   branch_o    = branchR;
    assign   condZero_o  = condZeroR;
    assign   aluZero_o   = aluZeroW;
    assign   aluNeg_o    = aluNegW;
    assign   aluResult_o = aluResultW;
    assign   rd_o        = rdR;
    assign   immU_o      = immUR;
    assign   pcBranch_o  = pcBranchR;
    assign   pcPlus4_o   = pcPlus4R;
    assign   bge_o       = bgeR;


endmodule

module sr_alu
(
    input  [31:0]     srcA,
    input  [31:0]     srcB,
    input  [ 2:0]     oper,
    output          zero,
    output          neg,
    output  [31:0]  result
);

    reg [31:0] resultReg;

    always @ (*) begin
        case (oper)
            default   : result = srcA + srcB;
            `ALU_ADD  : result = srcA + srcB;
            `ALU_OR   : result = srcA | srcB;
            `ALU_SRL  : result = srcA >> srcB [4:0];
            `ALU_SLTU : result = (srcA < srcB) ? 1 : 0;
            `ALU_SUB  : result = srcA - srcB;
            `ALU_AND  : result = srcA & srcB;
        endcase
    end

    assign neg = (result < 0);
    assign zero = (result == 0);
    assign result = resultReg;

endmodule