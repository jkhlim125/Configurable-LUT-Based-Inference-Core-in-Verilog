module class_scoring_neuron #(
    parameter LUT_IN_WIDTH = 4,
    parameter SCORE_WIDTH  = 3
)(
    input  [LUT_IN_WIDTH-1:0] in_bits,
    output reg [SCORE_WIDTH-1:0] class0_score,
    output reg [SCORE_WIDTH-1:0] class1_score,
    output reg [SCORE_WIDTH-1:0] class2_score,
    output reg [SCORE_WIDTH-1:0] class3_score
);

    // A simple class-scoring LUT.
    // Each 4-bit input produces partial scores for 4 classes.
    always @(*) begin
        case (in_bits)
            4'h0: begin class0_score = 3'd3; class1_score = 3'd1; class2_score = 3'd0; class3_score = 3'd0; end
            4'h1: begin class0_score = 3'd2; class1_score = 3'd2; class2_score = 3'd0; class3_score = 3'd0; end
            4'h2: begin class0_score = 3'd1; class1_score = 3'd3; class2_score = 3'd1; class3_score = 3'd0; end
            4'h3: begin class0_score = 3'd0; class1_score = 3'd3; class2_score = 3'd2; class3_score = 3'd0; end
            4'h4: begin class0_score = 3'd0; class1_score = 3'd2; class2_score = 3'd3; class3_score = 3'd0; end
            4'h5: begin class0_score = 3'd0; class1_score = 3'd1; class2_score = 3'd3; class3_score = 3'd1; end
            4'h6: begin class0_score = 3'd0; class1_score = 3'd0; class2_score = 3'd3; class3_score = 3'd2; end
            4'h7: begin class0_score = 3'd0; class1_score = 3'd0; class2_score = 3'd2; class3_score = 3'd3; end
            4'h8: begin class0_score = 3'd1; class1_score = 3'd0; class2_score = 3'd0; class3_score = 3'd3; end
            4'h9: begin class0_score = 3'd2; class1_score = 3'd0; class2_score = 3'd0; class3_score = 3'd3; end
            4'hA: begin class0_score = 3'd3; class1_score = 3'd1; class2_score = 3'd0; class3_score = 3'd2; end
            4'hB: begin class0_score = 3'd2; class1_score = 3'd2; class2_score = 3'd1; class3_score = 3'd2; end
            4'hC: begin class0_score = 3'd1; class1_score = 3'd2; class2_score = 3'd2; class3_score = 3'd1; end
            4'hD: begin class0_score = 3'd1; class1_score = 3'd1; class2_score = 3'd3; class3_score = 3'd2; end
            4'hE: begin class0_score = 3'd2; class1_score = 3'd1; class2_score = 3'd2; class3_score = 3'd3; end
            4'hF: begin class0_score = 3'd3; class1_score = 3'd2; class2_score = 3'd1; class3_score = 3'd3; end
            default: begin class0_score = 3'd0; class1_score = 3'd0; class2_score = 3'd0; class3_score = 3'd0; end
        endcase
    end

endmodule