// MAC-based inference top.
// Structure intentionally mirrors `inference_top`:
//   input register -> LUT feature extraction -> scoring -> aggregation -> argmax
//
// The key difference is that the "class scoring" stage is MAC-style (no LUT
// case-table) implemented by `class_scoring_layer_mac`.
module inference_top_mac #(
    parameter INPUT_WIDTH   = 32,
    parameter LUT_IN_WIDTH  = 4,
    parameter FEATURE_WIDTH = 3,
    parameter SCORE_WIDTH   = 3,
    parameter SUM_WIDTH     = 5,
    parameter L1_NEURONS    = 8,
    parameter L2_NEURONS    = 4
)(
    input  clk,
    input  rst_n,
    input  in_valid,
    input  [INPUT_WIDTH-1:0] in_bits,
    input  [INPUT_WIDTH-1:0] mask_bus,
    output reg out_valid,
    // Stage valid visibility for hardware-timing comparison (pipeline behavior).
    output reg stg1_valid,
    output reg stg2_valid,
    output reg stg3_valid,
    output reg [1:0] class_out
);

    // ----------------------------
    // Stage 1: Input register
    // ----------------------------
    reg [INPUT_WIDTH-1:0] in_bits_reg;
    reg [INPUT_WIDTH-1:0] mask_bus_reg;
    reg valid_s1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_bits_reg  <= {INPUT_WIDTH{1'b0}};
            mask_bus_reg <= {INPUT_WIDTH{1'b0}};
            valid_s1     <= 1'b0;
        end else begin
            in_bits_reg  <= in_bits;
            mask_bus_reg <= mask_bus;
            valid_s1     <= in_valid;
        end
    end


    // ----------------------------
    // Layer 1: LUT feature extraction
    // ----------------------------
    wire [L1_NEURONS*FEATURE_WIDTH-1:0] feature_bus_comb;

    lut_feature_layer #(
        .INPUT_WIDTH(INPUT_WIDTH),
        .LUT_IN_WIDTH(LUT_IN_WIDTH),
        .NUM_NEURONS(L1_NEURONS),
        .FEATURE_WIDTH(FEATURE_WIDTH)
    ) u_lut_feature_layer (
        .in_bits_bus(in_bits_reg),
        .mask_bus(mask_bus_reg),
        .feature_bus(feature_bus_comb)
    );

    // ----------------------------
    // Stage 2: Feature register
    // ----------------------------
    reg [L1_NEURONS*FEATURE_WIDTH-1:0] feature_bus_reg;
    reg valid_s2;
    reg valid_s2_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            feature_bus_reg <= {(L1_NEURONS*FEATURE_WIDTH){1'b0}};
            valid_s2        <= 1'b0;
            valid_s2_d      <= 1'b0;
        end else begin
            feature_bus_reg <= feature_bus_comb;
            valid_s2        <= valid_s1;
            valid_s2_d      <= valid_s2;
        end
    end


    // ----------------------------
    // Layer 2: Class scoring (MAC-style)
    // Assumption: L1_NEURONS = 2 * L2_NEURONS
    // ----------------------------
    wire [L2_NEURONS*SCORE_WIDTH-1:0] class0_bus_comb;
    wire [L2_NEURONS*SCORE_WIDTH-1:0] class1_bus_comb;
    wire [L2_NEURONS*SCORE_WIDTH-1:0] class2_bus_comb;
    wire [L2_NEURONS*SCORE_WIDTH-1:0] class3_bus_comb;

    class_scoring_layer_mac #(
        .NUM_NEURONS(L2_NEURONS),
        .FEATURE_WIDTH(FEATURE_WIDTH),
        .LUT_IN_WIDTH(LUT_IN_WIDTH),
        .SCORE_WIDTH(SCORE_WIDTH)
    ) u_class_scoring_layer_mac (
        .clk(clk),
        .rst_n(rst_n),
        .feature_bus(feature_bus_reg),
        .class0_bus(class0_bus_comb),
        .class1_bus(class1_bus_comb),
        .class2_bus(class2_bus_comb),
        .class3_bus(class3_bus_comb)
    );

    // ----------------------------
    // Stage 3: Partial class score register
    // ----------------------------
    reg [L2_NEURONS*SCORE_WIDTH-1:0] class0_bus_reg;
    reg [L2_NEURONS*SCORE_WIDTH-1:0] class1_bus_reg;
    reg [L2_NEURONS*SCORE_WIDTH-1:0] class2_bus_reg;
    reg [L2_NEURONS*SCORE_WIDTH-1:0] class3_bus_reg;
    reg valid_s3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            class0_bus_reg <= {(L2_NEURONS*SCORE_WIDTH){1'b0}};
            class1_bus_reg <= {(L2_NEURONS*SCORE_WIDTH){1'b0}};
            class2_bus_reg <= {(L2_NEURONS*SCORE_WIDTH){1'b0}};
            class3_bus_reg <= {(L2_NEURONS*SCORE_WIDTH){1'b0}};
            valid_s3       <= 1'b0;
        end else begin
            class0_bus_reg <= class0_bus_comb;
            class1_bus_reg <= class1_bus_comb;
            class2_bus_reg <= class2_bus_comb;
            class3_bus_reg <= class3_bus_comb;
            // MAC neuron now has an extra mult->acc pipeline stage.
            // Delay valid to match the updated datapath availability.
            valid_s3       <= valid_s2_d;
        end
    end


    // ----------------------------
    // Layer 3: Aggregation + Decision
    // ----------------------------
    wire [SUM_WIDTH-1:0] class0_sum_comb;
    wire [SUM_WIDTH-1:0] class1_sum_comb;
    wire [SUM_WIDTH-1:0] class2_sum_comb;
    wire [SUM_WIDTH-1:0] class3_sum_comb;

    class_aggregator #(
        .NUM_NEURONS(L2_NEURONS),
        .SCORE_WIDTH(SCORE_WIDTH),
        .SUM_WIDTH(SUM_WIDTH)
    ) u_class_aggregator (
        .class0_bus(class0_bus_reg),
        .class1_bus(class1_bus_reg),
        .class2_bus(class2_bus_reg),
        .class3_bus(class3_bus_reg),
        .class0_sum(class0_sum_comb),
        .class1_sum(class1_sum_comb),
        .class2_sum(class2_sum_comb),
        .class3_sum(class3_sum_comb)
    );

    wire [1:0] class_out_comb;
    decision_logic #(
        .SUM_WIDTH(SUM_WIDTH)
    ) u_decision_logic (
        .class0_sum(class0_sum_comb),
        .class1_sum(class1_sum_comb),
        .class2_sum(class2_sum_comb),
        .class3_sum(class3_sum_comb),
        .class_out(class_out_comb)
    );

    // ----------------------------
    // Stage 4: Output register
    // ----------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            class_out <= 2'd0;
            out_valid <= 1'b0;
            stg1_valid <= 1'b0;
            stg2_valid <= 1'b0;
            stg3_valid <= 1'b0;
        end else begin
            class_out <= class_out_comb;
            out_valid <= valid_s3;
            // Align exposed stage-valids with the output register timing.
            stg1_valid <= valid_s1;
            stg2_valid <= valid_s2;
            stg3_valid <= valid_s3;
        end
    end

endmodule

