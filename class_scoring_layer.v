module class_scoring_layer #(
    parameter NUM_NEURONS   = 4,
    parameter FEATURE_WIDTH = 3,
    parameter LUT_IN_WIDTH  = 4,
    parameter SCORE_WIDTH   = 3
)(
    input  [NUM_NEURONS*2*FEATURE_WIDTH-1:0] feature_bus,

    output [NUM_NEURONS*SCORE_WIDTH-1:0] class0_bus,
    output [NUM_NEURONS*SCORE_WIDTH-1:0] class1_bus,
    output [NUM_NEURONS*SCORE_WIDTH-1:0] class2_bus,
    output [NUM_NEURONS*SCORE_WIDTH-1:0] class3_bus
);

    genvar i;
    generate
        for (i = 0; i < NUM_NEURONS; i = i + 1) begin : GEN_SCORING_NEURONS
            localparam integer FEAT0_LSB = (2*i)   * FEATURE_WIDTH;
            localparam integer FEAT0_MSB = (2*i+1) * FEATURE_WIDTH - 1;
            localparam integer FEAT1_LSB = (2*i+1) * FEATURE_WIDTH;
            localparam integer FEAT1_MSB = (2*i+2) * FEATURE_WIDTH - 1;

            localparam integer OUT_LSB = i * SCORE_WIDTH;
            localparam integer OUT_MSB = (i + 1) * SCORE_WIDTH - 1;

            wire [FEATURE_WIDTH-1:0] feat_a;
            wire [FEATURE_WIDTH-1:0] feat_b;
            wire [LUT_IN_WIDTH-1:0] lut_in;

            assign feat_a = feature_bus[FEAT0_MSB:FEAT0_LSB];
            assign feat_b = feature_bus[FEAT1_MSB:FEAT1_LSB];

            // Compress two 3-bit features into a 4-bit LUT address.
            assign lut_in = {feat_b[1:0], feat_a[1:0]};

            class_scoring_neuron #(
                .LUT_IN_WIDTH(LUT_IN_WIDTH),
                .SCORE_WIDTH(SCORE_WIDTH)
            ) u_class_scoring_neuron (
                .in_bits(lut_in),
                .class0_score(class0_bus[OUT_MSB:OUT_LSB]),
                .class1_score(class1_bus[OUT_MSB:OUT_LSB]),
                .class2_score(class2_bus[OUT_MSB:OUT_LSB]),
                .class3_score(class3_bus[OUT_MSB:OUT_LSB])
            );
        end
    endgenerate

endmodule