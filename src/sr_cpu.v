/*
 * schoolRISCV - small RISC-V CPU 
 *
 * originally based on Sarah L. Harris MIPS CPU 
 *                   & schoolMIPS project
 * 
 * Copyright(c) 2017-2020 Stanislav Zhelnio 
 *                        Aleksandr Romanov 
 */ 

`include "sr_cpu.vh"

module sr_cpu
(
    input           clk,        // clock
    input           rst_n,      // reset
    input   [ 4:0]  regAddr,    // debug access reg address
    output  [31:0]  regData,    // debug access reg data
    output  [31:0]  imAddr,     // instruction memory address
    input   [31:0]  imData      // instruction memory data
);
    //fetch wires
    wire [31:0] pc_f;
    wire [31:0] pc_w;

    wire [31:0] instr_fd;
    wire [31:0] pc_fd;
    wire [31:0] pcPlus4_fd;

    //decode wires
    wire        wdSrc_de;
    wire        regWrite_de;
    wire        branch_de;
    wire [2:0]  aluControl_de;
    wire        aluSrc_de;
    wire        condZero_de;
    wire        bge_de;

    wire [ 4:0] rs1_de;
    wire [ 4:0] rs2_de;
    wire [ 4:0] rd_de;
    wire [31:0] immI_de;
    wire [31:0] immU_de;

    wire [31:0] pcBranch_de;
    wire [31:0] pcPlus4_de;


    wire [31:0] srcA;
    wire [31:0] srcB;
    wire [31:0] rd1;
    wire [31:0] rd2;

    wire [7:0]  A;
    wire [7:0]  B;
    wire        start_module;  

    //execute wires
    wire        wdSrc_ew;
    wire        regWrite_ew;
    wire        branch_ew;
    wire        condZero_ew;
    wire        aluZero_ew;
    wire        aluNeg_ew;   
    wire        bge_ew; 

    wire [31:0] aluResult_ew;

    wire [ 4:0] rd_ew;
    wire [31:0] immU_ew;    

    wire [31:0] pcBranch_ew;
    wire [31:0] pcPlus4_ew;

    //writeback wires

    wire freeze;
    wire [4:0] rd_e;

    fetch fetch(
        .clk(clk),
        .pc_i(pc_f),
        .instr_o(instr_fd),
        .pc_o(pc_fd),
        .pcPlus4_o(pcPlus4_fd)
    );

    decode decode(
        .clk(clk),
        .freeze(freeze),
        .instr_i(instr_fd),
        .pc_i(pc_fd),
        .pcPlus4_i(pcPlus4_fd),

        .wdSrc_o(wdSrc_de),
        .regWrite_o(regWrite_de),
        .branch_o(branch_de),
        .aluControl_o(aluControl_de),
        .aluSrc_o(aluSrc_de),
        .condZero_o(condZero_de),
        .bge_o(bge_de),

        .rs1_o(rs1_de),
        .rs2_o(rs2_de),
        .rd_o(rd_de),
        .immI_o(immI_de),
        .immU_o(immU_de),

        .pcBranch_o(pcBranch_de),
        .pcPlus4_o(pcPlus4_de),

        .A_o(A),
        .B_o(B),
        .start_module_o(start_module)
    );

    execute execute(
        .clk(clk),

        .wdSrc_i(wdSrc_de),
        .regWrite_i(regWrite_de),
        .branch_i(branch_de),
        .condZero_i(condZero_de),
        .bge_i(bge_de),
        .aluControl_i(aluControl_de),
        .aluSrc_i(aluSrc_de),

        .srcA_i(srcA),
        .srcB_i(srcB),
        .rd_i(rd_e),
        .immI_i(immI_de),
        .immU_i(immU_de),

        .pcBranch_i(pcBranch_de),
        .pcPlus4_i(pcPlus4_de),

        .wdSrc_o(wdSrc_ew),
        .regWrite_o(regWrite_ew),
        .branch_o(branch_ew),
        .condZero_o(condZero_ew),
        .aluZero_o(aluZero_ew),
        .aluNeg_o(aluNeg_ew),
        .bge_o(bge_ew),

        .aluResult_o(aluResult_ew),

        .rd_o(rd_ew),
        .immU_o(immU_ew),    

        .pcBranch_o(pcBranch_ew),
        .pcPlus4_o(pcPlus4_ew)
    );

    writeback writeback(

        .clk(clk),

        .aluZero_i(aluZero_ew),
        .aluNeg_i(aluNeg_ew),
        .condZero_i(condZero_ew),                 
        .branch_i(branch_ew),
        .bge_i(bge_ew),

        .pcBranch_i(pcBranch_ew),
        .pcPlus4_i(pcPlus4_ew),

        .newPC_o(pc_w)

    );

    sm_register_file sm_register_file(
        .clk(clk),

        .wdSrc(wdSrc_ew),
        .immU(immU_ew),
        .aluResult(aluResult_ew),

        .a1(rs1_de),
        .a2(rs2_de),
        .a3(rd_ew),
        .rd1(rd1),
        .rd2(rd2),
        .we3(regWrite_ew)
    );  

    conflict_prevention conflict_prevention(
        .clk(clk),
        .start_pc(imAddr),

        .rd1(rd1),
        .rd2(rd2),

        .rs1(rs1_de),
        .rs2(rs2_de),

        .regWrite(regWrite_ew),
        .aluResult(aluResult_ew),
        .immU(immU_ew),
        .wdSrc(wdSrc_ew),
        .rd(rd_ew),
        .rd_de(rd_de),

        .freeze(freeze),
        .branch(branch_de),
        .pcPlus4(pcPlus4_fd),
        .pcBranch(pc_w),


        .pcTarget(pc_f),
        .srcA(srcA),
        .srcB(srcB),
        .rd_o(rd_e),

        .A(A),
        .B(B),
        .start_module   (start_module)
    );


endmodule

module sm_register_file
(
    input         clk,

    input       wdSrc,
    input [31:0] immU,
    input [31:0] aluResult,

    input  [ 4:0] a1,
    input  [ 4:0] a2,
    input  [ 4:0] a3,
    output [31:0] rd1,
    output [31:0] rd2,
    input         we3
);
    reg [31:0] rf [31:0];

    wire [31:0] wd3 = wdSrc ? immU : aluResult;

    assign rd1 = (a1 != 5'b0) ? rf [a1] : 32'b0;
    assign rd2 = (a2 != 5'b0) ? rf [a2] : 32'b0;

    always @ (negedge clk) begin
        if(we3) rf [a3] <= wd3;
    end    

endmodule

module conflict_prevention
(
    input           clk,

    input [31:0]    start_pc,

    input [31:0]    rd1,
    input [31:0]    rd2,

    input [ 4:0]    rs1,
    input [ 4:0]    rs2,

    input           regWrite,
    input [31:0]    aluResult,
    input [31:0]    immU,
    input           wdSrc,
    input [ 4:0]    rd,
    input [ 4:0]    rd_de,

    input           branch,
    input [31:0]    pcBranch,
    input [31:0]    pcPlus4,

    input           start_module,
    input [7:0]     A,
    input [7:0]     B,

    output reg          freeze,
    output reg [31:0]   pcTarget,

    output [31:0]       srcA,
    output [31:0]       srcB,
    output [4:0]        rd_o
);

    reg [1:0] state = 2'b0;
    reg [1:0] start = 2'b11;

    
    // control conflict
    always @ (negedge clk) begin
        if (start == 3 ) begin
            freeze <= 0;
            pcTarget <= 32'b0;
            start <= 2;
        end  
        else if (start == 2) begin
            freeze <= 0;
            pcTarget <= pcPlus4;
            start <= 1;
        end   
        else 
            case (state)
                2'b00 : begin
                            if (branch) begin
                                state <= 1;
                                freeze <= 1;
                            end
                            else if (freeze) pcTarget <= pcPlus4 - 4;
                            else pcTarget <= pcPlus4;
                        end
                2'b01 : state <= 2;
                2'b10 : begin 
                            pcTarget <= pcBranch;
                            state <= 3;
                        end
                2'b11 : begin 
                            state <= 0;
                            freeze <= 0;
                            pcTarget <= pcPlus4;
                        end
            endcase    
    end    

    wire busyW;
    wire [23:0] func_resW;
    reg busy = 0;
    reg [4:0] rdR = 0;
    wire [4:0] rdW = rdR;

    //data conflict
    assign srcA = (!busyW && busy) ? func_resW : (rs1 == rd && regWrite) ? (wdSrc ? immU : aluResult) : rd1;
    assign srcB = (!busyW && busy) ? 32'b0 : (rs2 == rd && regWrite) ? (wdSrc ? immU : aluResult) : rd2;
    assign rd_o = (!busyW && busy) ? rdW : rd_de;


    // func logic 
    always @ (negedge clk) begin
        if (start_module) begin
            busy <= 1;
            freeze <= 1;
            rdR <= rd_de;
        end    
        else if (!busyW && busy && freeze) begin
            freeze <= 0;
        end    
        else if (!busyW && busy && !freeze) begin
            busy <= 0;
        end  
    end    

    fun my_func(
        .clk_i(clk),
        .rst_i(rst),
        .a_i(A),
        .b_i(B),
        .start_i(start_module),

        .y_o(func_resW),
        .busy(busyW)
    );
endmodule
