module lut_layer (
    input  [7:0] in_bits,

    output [3:0] class0_sum,
    output [3:0] class1_sum,
    output [3:0] class2_sum,
    output [3:0] class3_sum
);

    // Scores from each LUT neuron
    wire [1:0] n0_c0, n0_c1, n0_c2, n0_c3;
    wire [1:0] n1_c0, n1_c1, n1_c2, n1_c3;
    wire [1:0] n2_c0, n2_c1, n2_c2, n2_c3;
    wire [1:0] n3_c0, n3_c1, n3_c2, n3_c3;

    // Four parallel LUT neurons
    lut_neuron u_neuron0 (
        .in_bits(in_bits[1:0]),
        .score0(n0_c0),
        .score1(n0_c1),
        .score2(n0_c2),
        .score3(n0_c3)
    );

    lut_neuron u_neuron1 (
        .in_bits(in_bits[3:2]),
        .score0(n1_c0),
        .score1(n1_c1),
        .score2(n1_c2),
        .score3(n1_c3)
    );

    lut_neuron u_neuron2 (
        .in_bits(in_bits[5:4]),
        .score0(n2_c0),
        .score1(n2_c1),
        .score2(n2_c2),
        .score3(n2_c3)
    );

    lut_neuron u_neuron3 (
        .in_bits(in_bits[7:6]),
        .score0(n3_c0),
        .score1(n3_c1),
        .score2(n3_c2),
        .score3(n3_c3)
    );

    // Aggregate scores across neurons
    assign class0_sum = n0_c0 + n1_c0 + n2_c0 + n3_c0;
    assign class1_sum = n0_c1 + n1_c1 + n2_c1 + n3_c1;
    assign class2_sum = n0_c2 + n1_c2 + n2_c2 + n3_c2;
    assign class3_sum = n0_c3 + n1_c3 + n2_c3 + n3_c3;

endmodule