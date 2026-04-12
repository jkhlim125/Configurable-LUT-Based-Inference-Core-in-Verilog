module inference_top (
    input        clk,
    input        rst_n,
    input        in_valid,
    input  [7:0] in_bits,

    output reg       out_valid,
    output reg [1:0] class_out
);

    // ----------------------------
    // Stage 1: input register
    // ----------------------------
    reg [7:0] in_bits_reg;
    reg       valid_s1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_bits_reg <= 8'd0;
            valid_s1    <= 1'b0;
        end
        else begin
            in_bits_reg <= in_bits;
            valid_s1    <= in_valid;
        end
    end

    // ----------------------------
    // LUT layer (combinational)
    // ----------------------------
    wire [3:0] class0_sum_comb;
    wire [3:0] class1_sum_comb;
    wire [3:0] class2_sum_comb;
    wire [3:0] class3_sum_comb;

    lut_layer u_lut_layer (
        .in_bits(in_bits_reg),
        .class0_sum(class0_sum_comb),
        .class1_sum(class1_sum_comb),
        .class2_sum(class2_sum_comb),
        .class3_sum(class3_sum_comb)
    );

    // ----------------------------
    // Stage 2: class score register
    // ----------------------------
    reg [3:0] class0_sum_reg;
    reg [3:0] class1_sum_reg;
    reg [3:0] class2_sum_reg;
    reg [3:0] class3_sum_reg;
    reg       valid_s2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            class0_sum_reg <= 4'd0;
            class1_sum_reg <= 4'd0;
            class2_sum_reg <= 4'd0;
            class3_sum_reg <= 4'd0;
            valid_s2       <= 1'b0;
        end
        else begin
            class0_sum_reg <= class0_sum_comb;
            class1_sum_reg <= class1_sum_comb;
            class2_sum_reg <= class2_sum_comb;
            class3_sum_reg <= class3_sum_comb;
            valid_s2       <= valid_s1;
        end
    end

    // ----------------------------
    // Decision logic (combinational)
    // ----------------------------
    wire [1:0] class_out_comb;

    decision_logic u_decision_logic (
        .class0_sum(class0_sum_reg),
        .class1_sum(class1_sum_reg),
        .class2_sum(class2_sum_reg),
        .class3_sum(class3_sum_reg),
        .class_out(class_out_comb)
    );

    // ----------------------------
    // Stage 3: output register
    // ----------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            class_out <= 2'd0;
            out_valid <= 1'b0;
        end
        else begin
            class_out <= class_out_comb;
            out_valid <= valid_s2;
        end
    end

endmodule