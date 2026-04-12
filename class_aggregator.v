module class_aggregator #(
    parameter NUM_NEURONS = 4,
    parameter SCORE_WIDTH = 3,
    parameter SUM_WIDTH   = 5
)(
    input  [NUM_NEURONS*SCORE_WIDTH-1:0] class0_bus,
    input  [NUM_NEURONS*SCORE_WIDTH-1:0] class1_bus,
    input  [NUM_NEURONS*SCORE_WIDTH-1:0] class2_bus,
    input  [NUM_NEURONS*SCORE_WIDTH-1:0] class3_bus,

    output reg [SUM_WIDTH-1:0] class0_sum,
    output reg [SUM_WIDTH-1:0] class1_sum,
    output reg [SUM_WIDTH-1:0] class2_sum,
    output reg [SUM_WIDTH-1:0] class3_sum
);

    integer i;
    integer SCORE_MASK;

    reg [SUM_WIDTH-1:0] tmp0;
    reg [SUM_WIDTH-1:0] tmp1;
    reg [SUM_WIDTH-1:0] tmp2;
    reg [SUM_WIDTH-1:0] tmp3;

    always @(*) begin
        tmp0 = {SUM_WIDTH{1'b0}};
        tmp1 = {SUM_WIDTH{1'b0}};
        tmp2 = {SUM_WIDTH{1'b0}};
        tmp3 = {SUM_WIDTH{1'b0}};

        SCORE_MASK = (1 << SCORE_WIDTH) - 1;

        for (i = 0; i < NUM_NEURONS; i = i + 1) begin
            tmp0 = tmp0 + ((class0_bus >> (i * SCORE_WIDTH)) & SCORE_MASK);
            tmp1 = tmp1 + ((class1_bus >> (i * SCORE_WIDTH)) & SCORE_MASK);
            tmp2 = tmp2 + ((class2_bus >> (i * SCORE_WIDTH)) & SCORE_MASK);
            tmp3 = tmp3 + ((class3_bus >> (i * SCORE_WIDTH)) & SCORE_MASK);
        end

        class0_sum = tmp0;
        class1_sum = tmp1;
        class2_sum = tmp2;
        class3_sum = tmp3;
    end

endmodule