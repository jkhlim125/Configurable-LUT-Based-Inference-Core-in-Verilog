module decision_logic #(
    parameter SUM_WIDTH = 5
)(
    input  [SUM_WIDTH-1:0] class0_sum,
    input  [SUM_WIDTH-1:0] class1_sum,
    input  [SUM_WIDTH-1:0] class2_sum,
    input  [SUM_WIDTH-1:0] class3_sum,

    output reg [1:0] class_out
);

    always @(*) begin
        class_out = 2'd0;

        if (class1_sum > class0_sum &&
            class1_sum >= class2_sum &&
            class1_sum >= class3_sum) begin
            class_out = 2'd1;
        end
        else if (class2_sum > class0_sum &&
                 class2_sum > class1_sum &&
                 class2_sum >= class3_sum) begin
            class_out = 2'd2;
        end
        else if (class3_sum > class0_sum &&
                 class3_sum > class1_sum &&
                 class3_sum > class2_sum) begin
            class_out = 2'd3;
        end
    end

endmodule