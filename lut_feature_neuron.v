module lut_feature_neuron #(
    parameter LUT_IN_WIDTH = 4,
    parameter FEATURE_WIDTH = 3
)(
    input  [LUT_IN_WIDTH-1:0] in_bits,
    input  [LUT_IN_WIDTH-1:0] mask_bits,
    output reg [FEATURE_WIDTH-1:0] feature_out
);

    wire [LUT_IN_WIDTH-1:0] masked_in;
    assign masked_in = in_bits & mask_bits;

    // Simple 16-entry LUT for feature extraction.
    // The values are hand-defined to make the behavior non-trivial but still easy to follow.
    always @(*) begin
        case (masked_in)
            4'h0: feature_out = 3'd0;
            4'h1: feature_out = 3'd1;
            4'h2: feature_out = 3'd2;
            4'h3: feature_out = 3'd3;
            4'h4: feature_out = 3'd1;
            4'h5: feature_out = 3'd4;
            4'h6: feature_out = 3'd2;
            4'h7: feature_out = 3'd5;
            4'h8: feature_out = 3'd1;
            4'h9: feature_out = 3'd3;
            4'hA: feature_out = 3'd4;
            4'hB: feature_out = 3'd6;
            4'hC: feature_out = 3'd2;
            4'hD: feature_out = 3'd5;
            4'hE: feature_out = 3'd6;
            4'hF: feature_out = 3'd7;
            default: feature_out = 3'd0;
        endcase
    end

endmodule