module lut_feature_layer #(
    parameter INPUT_WIDTH   = 32,
    parameter LUT_IN_WIDTH  = 4,
    parameter NUM_NEURONS   = 8,
    parameter FEATURE_WIDTH = 3
)(
    input  [INPUT_WIDTH-1:0] in_bits_bus,
    input  [INPUT_WIDTH-1:0] mask_bus,
    output [NUM_NEURONS*FEATURE_WIDTH-1:0] feature_bus
);

    genvar i;
    generate
        for (i = 0; i < NUM_NEURONS; i = i + 1) begin : GEN_FEATURE_NEURONS
            localparam integer IN_LSB  = i * LUT_IN_WIDTH;
            localparam integer IN_MSB  = (i + 1) * LUT_IN_WIDTH - 1;
            localparam integer OUT_LSB = i * FEATURE_WIDTH;
            localparam integer OUT_MSB = (i + 1) * FEATURE_WIDTH - 1;

            lut_feature_neuron #(
                .LUT_IN_WIDTH(LUT_IN_WIDTH),
                .FEATURE_WIDTH(FEATURE_WIDTH)
            ) u_lut_feature_neuron (
                .in_bits(in_bits_bus[IN_MSB:IN_LSB]),
                .mask_bits(mask_bus[IN_MSB:IN_LSB]),
                .feature_out(feature_bus[OUT_MSB:OUT_LSB])
            );
        end
    endgenerate

endmodule