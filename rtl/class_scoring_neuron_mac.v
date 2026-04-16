// MAC-style class scoring neuron.
// Input is the same 4-bit "compressed LUT address" used by the LUT neuron,
// but instead of a case-table, we compute class scores using small fixed-point
// multiply-accumulate operations.
module class_scoring_neuron_mac #(
    parameter LUT_IN_WIDTH = 4,
    parameter SCORE_WIDTH  = 3
)(
    input  clk,
    input  rst_n,
    input  [LUT_IN_WIDTH-1:0] in_bits,
    output reg [SCORE_WIDTH-1:0] class0_score,
    output reg [SCORE_WIDTH-1:0] class1_score,
    output reg [SCORE_WIDTH-1:0] class2_score,
    output reg [SCORE_WIDTH-1:0] class3_score
);

    // Small constant weights per class per input bit.
    // Note: in_bits is typically 0/1 per bit (derived from feature LSBs), but we
    // still implement explicit multiplies to keep the MAC baseline style.
    localparam integer W0_0 = 3'd1; localparam integer W0_1 = 3'd2; localparam integer W0_2 = 3'd1; localparam integer W0_3 = 3'd0;
    localparam integer W1_0 = 3'd0; localparam integer W1_1 = 3'd1; localparam integer W1_2 = 3'd3; localparam integer W1_3 = 3'd2;
    localparam integer W2_0 = 3'd2; localparam integer W2_1 = 3'd0; localparam integer W2_2 = 3'd1; localparam integer W2_3 = 3'd1;
    localparam integer W3_0 = 3'd1; localparam integer W3_1 = 3'd1; localparam integer W3_2 = 3'd0; localparam integer W3_3 = 3'd3;

    // Stage 1 registers the individual products (mult_result <= a*b).
    reg [2:0] m00, m01, m02, m03; // class0 * in_bits
    reg [2:0] m10, m11, m12, m13; // class1 * in_bits
    reg [2:0] m20, m21, m22, m23; // class2 * in_bits
    reg [2:0] m30, m31, m32, m33; // class3 * in_bits

    // Stage 2 registers the accumulated + saturated scores.
    reg [6:0] acc0;
    reg [6:0] acc1;
    reg [6:0] acc2;
    reg [6:0] acc3;

    // Temporary combinational accumulations for stage2.
    reg [6:0] acc0_calc;
    reg [6:0] acc1_calc;
    reg [6:0] acc2_calc;
    reg [6:0] acc3_calc;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m00 <= 3'd0; m01 <= 3'd0; m02 <= 3'd0; m03 <= 3'd0;
            m10 <= 3'd0; m11 <= 3'd0; m12 <= 3'd0; m13 <= 3'd0;
            m20 <= 3'd0; m21 <= 3'd0; m22 <= 3'd0; m23 <= 3'd0;
            m30 <= 3'd0; m31 <= 3'd0; m32 <= 3'd0; m33 <= 3'd0;

            acc0 <= 7'd0; acc1 <= 7'd0; acc2 <= 7'd0; acc3 <= 7'd0;
            class0_score <= {SCORE_WIDTH{1'b0}};
            class1_score <= {SCORE_WIDTH{1'b0}};
            class2_score <= {SCORE_WIDTH{1'b0}};
            class3_score <= {SCORE_WIDTH{1'b0}};
        end else begin
            // Stage 1: register products for each class.
            m00 <= in_bits[0] * W0_0; m01 <= in_bits[1] * W0_1; m02 <= in_bits[2] * W0_2; m03 <= in_bits[3] * W0_3;
            m10 <= in_bits[0] * W1_0; m11 <= in_bits[1] * W1_1; m12 <= in_bits[2] * W1_2; m13 <= in_bits[3] * W1_3;
            m20 <= in_bits[0] * W2_0; m21 <= in_bits[1] * W2_1; m22 <= in_bits[2] * W2_2; m23 <= in_bits[3] * W2_3;
            m30 <= in_bits[0] * W3_0; m31 <= in_bits[1] * W3_1; m32 <= in_bits[2] * W3_2; m33 <= in_bits[3] * W3_3;

            // Stage 2: accumulate from previous stage-1 products.
            // Note: use *_calc computed from the OLD m** values (this posedge),
            // because m** are updated with nonblocking assignments above.
            acc0_calc = m00 + m01 + m02 + m03;
            acc1_calc = m10 + m11 + m12 + m13;
            acc2_calc = m20 + m21 + m22 + m23;
            acc3_calc = m30 + m31 + m32 + m33;

            acc0 <= acc0_calc;
            acc1 <= acc1_calc;
            acc2 <= acc2_calc;
            acc3 <= acc3_calc;

            // Saturate to SCORE_WIDTH (default 3-bit -> cap at 7).
            if (acc0_calc > ((1 << SCORE_WIDTH) - 1)) class0_score <= {SCORE_WIDTH{1'b1}};
            else                                         class0_score <= acc0_calc[SCORE_WIDTH-1:0];

            if (acc1_calc > ((1 << SCORE_WIDTH) - 1)) class1_score <= {SCORE_WIDTH{1'b1}};
            else                                         class1_score <= acc1_calc[SCORE_WIDTH-1:0];

            if (acc2_calc > ((1 << SCORE_WIDTH) - 1)) class2_score <= {SCORE_WIDTH{1'b1}};
            else                                         class2_score <= acc2_calc[SCORE_WIDTH-1:0];

            if (acc3_calc > ((1 << SCORE_WIDTH) - 1)) class3_score <= {SCORE_WIDTH{1'b1}};
            else                                         class3_score <= acc3_calc[SCORE_WIDTH-1:0];
        end
    end

endmodule

