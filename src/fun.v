module fun(
input clk_i, //click
input rst_i, //reset
input [7:0] a_i, //input
input [7:0] b_i, //input
input start_i, //start
output reg busy_o, //is buisy now
output reg [10:0] y_bo);

localparam IDLE = 0,
           MUL = 1,
           WAIT_MUL = 2,
           RT3 = 3,
           WAIT_RT3 = 4,
           WAIT_SUM = 5;
           
reg [3:0] state = IDLE;

reg   [7:0] mult2_a;
reg   [7:0] mult2_b;
wire [10:0] mult2_y;
reg  mult2_start;
wire  mult2_busy;

mult mul2_inst(
    .clk_i(clk_i),
    .rst_i(rst_i),
    .a_bi(mult2_a),
    .b_bi(mult2_b),
    .start_i(mult2_start),
    .busy_o(mult2_busy),
    .y_bo(mult2_y)
);

reg [31:0] sum_a;
reg [31:0] sum_b;
wire [31:0] sum_out;

adder sum_inst(
    .a(sum_a),
    .b(sum_b),
    .out(sum_out)
);

reg start_rt3;
reg [7:0] in_rt3;
wire [3:0] out_rt3;
wire busy_rt3;

rt3 rt3_inst(
    .clk_i(clk_i),
    .rst_i(rst_i),
    .a_i(in_rt3),
    .start_i(start_rt3),
    .y_bo(out_rt3),
    .busy_o(busy_rt3)
);
 
always @(posedge clk_i) begin
    if (rst_i) begin
        y_bo <= 0;
        busy_o <= 0;
        start_rt3 <= 0;
        mult2_start <= 0;
        state <= IDLE;
    end else begin
        case (state)
            IDLE:
                begin
                    if (start_i) begin
                        y_bo <= 0;
                        busy_o <= 1;
                        state <= RT3;
                    end
                end
            RT3:
                begin
                    in_rt3 <= b_i;
                    start_rt3 <= 1;
                    state <= WAIT_RT3;
                end
            WAIT_RT3:
                begin
                    start_rt3 <= 0;
                    if (~busy_rt3 && ~start_rt3) begin
                        mult2_a <= a_i; 
                        mult2_b <= out_rt3;
                        mult2_start <= 1;
                        state <= WAIT_MUL;
                    end
                end
            WAIT_MUL:
                begin
                    mult2_start <= 0;
                    if (~mult2_busy && ~mult2_start) begin
                        y_bo <= mult2_y;
                        busy_o <= 0;
                        state <= IDLE;
                    end
                end
        endcase
    end
end
endmodule