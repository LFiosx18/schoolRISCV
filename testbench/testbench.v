`timescale 1 ns / 100 ps

`include "sr_cpu.vh"

`ifndef SIMULATION_CYCLES
    `define SIMULATION_CYCLES 7000
`endif

module sm_testbench;

    // simulation options
    parameter Tt     = 20;

    reg         clk;
    reg         rst_n;
    reg  [ 4:0] regAddr;
    wire        cpuClk;

    // ***** DUT start ************************

    sm_top sm_top
    (
        .clkIn     ( clk     ),
        .rst_n     ( rst_n   ),
        .clkDivide ( 4'b0    ),
        .clkEnable ( 1'b1    ),
        .clk       ( cpuClk  ),
        .regAddr   ( 32'b0    ),
        .regData   (         )
    );

    defparam sm_top.sm_clk_divider.bypass = 1;

    // ***** DUT  end  ************************

`ifdef ICARUS
    //iverilog memory dump init workaround
    initial $dumpvars;
    genvar k;
    for (k = 0; k < 32; k = k + 1) begin
        initial $dumpvars(0, sm_top.sm_cpu.rf.rf[k]);
    end
`endif

    // simulation init
    initial begin
        clk = 0;
        forever clk = #(Tt/2) ~clk;
    end

    initial begin
        rst_n   = 0;
        repeat (4)  @(posedge clk);
        rst_n   = 1;
    end

    task disasmInstr;

        reg [ 6:0] cmdOp;
        reg [ 4:0] rd;
        reg [ 2:0] cmdF3;
        reg [ 4:0] rs1;
        reg [ 4:0] rs2;
        reg [ 6:0] cmdF7;
        reg [31:0] immI;
        reg signed [31:0] immB;
        reg [31:0] immU;

    begin
        cmdOp = sm_top.sm_cpu.decode.cmdOpW;
        rd    = sm_top.sm_cpu.decode.rd_o;
        cmdF3 = sm_top.sm_cpu.decode.cmdF3W;
        rs1   = sm_top.sm_cpu.decode.rs1W;
        rs2   = sm_top.sm_cpu.decode.rs2W;
        cmdF7 = sm_top.sm_cpu.decode.cmdF7W;
        immI  = sm_top.sm_cpu.decode.immI_o;
        immB  = sm_top.sm_cpu.decode.immBW;
        immU  = sm_top.sm_cpu.decode.immU_o;

        if (cmdF3 == `RVF3_ADDI && cmdOp == `RVOP_ADDI && rs1 == 0 && rs2 == 0) $write ("nop");
        else

        //$write(" Opcode $%b , cmdf3 $%b , cmdf7 $%b ",cmdOp, cmdF3, cmdF7);
        casez( { cmdF7, cmdF3, cmdOp } )
            default :                                $write ("new/unknown");
            { `RVF7_ADD,  `RVF3_ADD,  `RVOP_ADD  } : $write ("add   $%1d, $%1d, $%1d", rd, rs1, rs2);
            { `RVF7_OR,   `RVF3_OR,   `RVOP_OR   } : $write ("or    $%1d, $%1d, $%1d", rd, rs1, rs2);
            { `RVF7_SRL,  `RVF3_SRL,  `RVOP_SRL  } : $write ("srl   $%1d, $%1d, $%1d", rd, rs1, rs2);
            { `RVF7_SLTU, `RVF3_SLTU, `RVOP_SLTU } : $write ("sltu  $%1d, $%1d, $%1d", rd, rs1, rs2);
            { `RVF7_SUB,  `RVF3_SUB,  `RVOP_SUB  } : $write ("sub   $%1d, $%1d, $%1d", rd, rs1, rs2);

            { `RVF7_ANY,  `RVF3_ADDI, `RVOP_ADDI } : $write ("addi  $%1d, $%1d, 0x%8h",rd, rs1, immI);
            { `RVF7_ANY,  `RVF3_ANY,  `RVOP_LUI  } : $write ("lui   $%1d, 0x%8h",      rd, immU);
            { `RVF7_ANY,  `RVF3_ANDI, `RVOP_ANDI } : $write ("andi  $%1d, $%1d, 0x%8h",rd, rs1, immI);

            { `RVF7_ANY,  `RVF3_ANY,  `RVOP_FUNC  } : $write ("myfun   $%1d, $%b, $%b", rd, sm_top.sm_cpu.decode.instrR[19:12], sm_top.sm_cpu.decode.instrR[27:20]);
        endcase

    end
    endtask


    //simulation debug output
    integer cycle; initial cycle = 0;

    reg finish = 0;
    always @ (posedge clk)
    begin
        $write ("%5d  pc = %2h ", cycle, sm_top.sm_cpu.fetch.pc_o);

        if (sm_top.sm_cpu.fetch.instr_o !== 32'bX) $write("instr = %h ", sm_top.sm_cpu.fetch.instr_o);
        else $write("instr = 00000013 ");

        $write ("a0 = 0x%8h a1 = 0x%8h   :   ",sm_top.sm_cpu.sm_register_file.rf[10], sm_top.sm_cpu.sm_register_file.rf[11]);

        disasmInstr();

        $write("\n");

        cycle = cycle + 1;


        if ((sm_top.sm_cpu.fetch.instr_o === 32'bX) && (sm_top.sm_cpu.fetch.pc_o !== 32'bX) && !sm_top.sm_cpu.conflict_prevention.freeze)
        begin
            if (finish) begin
                $display ("Timeout");
                $stop;
            end  
            finish <= 1;
        end
        
    end

endmodule