`include "sr_cpu.vh"

module decode(
    input               clk,
    
    input      [31:0]   instr_i,
    input      [31:0]   pc_i,
    input      [31:0]   pcPlus4_i,
    input               en,

    output              wdSrc,
    output              regWrite,
    output              branch,
    output [2:0]        aluControl,
    output              aluSrc,
    output              aluZero,

    output [ 4:0]       rs1,
    output [ 4:0]       rs2,
    output [ 4:0]       rd,
    output [31:0]       immI,
    output [31:0]       immU,

    output [31:0]       pcBranch,
    output [31:0]       pcPlus4,

    output [7:0]        A_op,
    output [7:0]        B_op,
    output              start
);
   

    reg [31:0] instrR;
    reg [31:0] pcR;
    reg [31:0] pcPlus4R;

    // decode wires
    wire [31:0] instrW = instrR;
    wire [ 6:0] cmdOpW;
    wire [ 4:0] rdW;
    wire [ 2:0] cmdF3W;
    wire [ 4:0] rs1W;
    wire [ 4:0] rs2W;
    wire [ 6:0] cmdF7W;
    wire [31:0] immIW;
    wire [31:0] immBW;
    wire [31:0] immUW;

    //instruction decode
    sr_decode id (
        .instr      ( instrW        ),
        .cmdOp      ( cmdOpW        ),
        .rd         ( rdW           ),
        .cmdF3      ( cmdF3W        ),
        .rs1        ( rs1W          ),
        .rs2        ( rs2W          ),
        .cmdF7      ( cmdF7W        ),
        .immI       ( immIW         ),
        .immB       ( immBW         ),
        .immU       ( immUW         ) 
    );

    wire       regWriteW;
    wire       aluSrcW;
    wire       wdSrcW;
    wire [2:0] aluControlW;
    wire       condZeroW;
    wire       bgeW;

    //control
    sr_control sm_control (
        .cmdOp      ( cmdOpW        ),
        .cmdF3      ( cmdF3W        ),
        .cmdF7      ( cmdF7W        ),

        .wdSrc      ( wdSrcW        ),
        .regWrite   ( regWriteW     ),
        .branch     ( branch_o       ),
        .aluControl ( aluControlW   ),
        .aluSrc     ( aluSrcW       ),
        .condZero   ( condZeroW     ),
        .bge        ( bgeW          )
    );

    always @ (posedge clk) begin
        if(en) begin
            instrR      <= 32'h13;
            pcR         <= 32'b0;
            pcPlus4R    <= 32'b0;
        end
        else begin
            instrR      <= instr_i;
            pcR         <= pc_i;
            pcPlus4R    <= pcPlus4_i;
        end         
    end     

    assign wdSrc       = wdSrcW;
    assign regWrite    = regWriteW;
    assign aluControl  = aluControlW;
    assign aluSrc      = aluSrcW;
    assign condZero    = condZeroW;

    assign rs1         = rs1W;
    assign rs2         = rs2W;
    assign rd          = rdW;
    assign immI        = immIW;
    assign immU        = immUW;

    assign pcBranch    = immBW + pcR;
    assign pcPlus4     = pcPlus4R;

    assign A_op           = (instrR[6:0] == 7'b1111111) ?  (instrR[19:12]) : (8'b0);
    assign B_op           = (instrR[6:0] == 7'b1111111) ?  (instrR[27:20]) : (8'b0);
    assign start          = (instrR[6:0] == 7'b1111111) ?  (1'b1) : (1'b0);

endmodule

module sr_decode
(
    input      [31:0] instr,
    output     [ 6:0] cmdOp,
    output     [ 4:0] rd,
    output     [ 2:0] cmdF3,
    output     [ 4:0] rs1,
    output     [ 4:0] rs2,
    output     [ 6:0] cmdF7,
    output reg [31:0] immI,
    output reg [31:0] immB,
    output reg [31:0] immU 
);
    assign cmdOp = instr[ 6: 0];
    assign rd    = instr[11: 7];
    assign cmdF3 = instr[14:12];
    assign rs1   = instr[19:15];
    assign rs2   = instr[24:20];
    assign cmdF7 = instr[31:25];

    // I-immediate
    always @ (*) begin
        immI[10: 0] = instr[30:20];
        immI[31:11] = { 21 {instr[31]} };
    end

    // B-immediate
    always @ (*) begin
        immB[    0] = 1'b0;
        immB[ 4: 1] = instr[11:8];
        immB[10: 5] = instr[30:25];
        immB[   11] = instr[7];
        immB[31:12] = { 20 {instr[31]} };
    end

    // U-immediate
    always @ (*) begin
        immU[11: 0] = 12'b0;
        immU[31:12] = instr[31:12];
    end

endmodule

module sr_control
(
    input     [ 6:0] cmdOp,
    input     [ 2:0] cmdF3,
    input     [ 6:0] cmdF7,

    output reg        wdSrc,
    output reg        regWrite,
    output reg        branch,
    output reg [2:0]  aluControl,
    output reg        aluSrc,
    output reg        condZero,
    output reg        bge
);

    always @ (*) begin
        branch      = 1'b0;
        condZero    = 1'b0;
        regWrite    = 1'b0;
        aluSrc      = 1'b0;
        wdSrc       = 1'b0;
        bge         = 1'b0;
        aluControl  = `ALU_ADD;

        casez( {cmdF7, cmdF3, cmdOp} )
            { `RVF7_ADD,  `RVF3_ADD,  `RVOP_ADD  } : begin regWrite = 1'b1; aluControl = `ALU_ADD;  end
            { `RVF7_OR,   `RVF3_OR,   `RVOP_OR   } : begin regWrite = 1'b1; aluControl = `ALU_OR;   end
            { `RVF7_SRL,  `RVF3_SRL,  `RVOP_SRL  } : begin regWrite = 1'b1; aluControl = `ALU_SRL;  end
            { `RVF7_SLTU, `RVF3_SLTU, `RVOP_SLTU } : begin regWrite = 1'b1; aluControl = `ALU_SLTU; end
            { `RVF7_SUB,  `RVF3_SUB,  `RVOP_SUB  } : begin regWrite = 1'b1; aluControl = `ALU_SUB;  end

            { `RVF7_ANY,  `RVF3_ADDI, `RVOP_ADDI } : begin regWrite = 1'b1; aluSrc = 1'b1; aluControl = `ALU_ADD; end
            { `RVF7_ANY,  `RVF3_ANDI, `RVOP_ANDI } : begin regWrite = 1'b1; aluSrc = 1'b1; aluControl = `ALU_AND; end
            { `RVF7_ANY,  `RVF3_ANY,  `RVOP_LUI  } : begin regWrite = 1'b1; wdSrc  = 1'b1; end

            { `RVF7_ANY,  `RVF3_BEQ,  `RVOP_BEQ  } : begin branch = 1'b1; condZero = 1'b1; aluControl = `ALU_SUB; end
            { `RVF7_ANY,  `RVF3_BNE,  `RVOP_BNE  } : begin branch = 1'b1; aluControl = `ALU_SUB; end
            { `RVF7_ANY,  `RVF3_ANY,  `RVOP_FUNC  } : begin regWrite = 1'b1; aluControl = `ALU_ADD;  end
        endcase
    end
endmodule