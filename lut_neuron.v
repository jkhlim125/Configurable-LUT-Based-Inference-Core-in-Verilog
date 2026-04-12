module lut_neuron (
    input  [1:0] in_bits,
    output reg [1:0] score0,
    output reg [1:0] score1,
    output reg [1:0] score2,
    output reg [1:0] score3
);

    // Simple hand-defined LUT contents.
    // Each input pattern maps to 4 class scores.
    // This is not trained data; it is just a small example for RTL inference flow.
    always @(*) begin
        case (in_bits)
            2'b00: begin
                score0 = 2'd3;
                score1 = 2'd1;
                score2 = 2'd0;
                score3 = 2'd0;
            end

            2'b01: begin
                score0 = 2'd1;
                score1 = 2'd3;
                score2 = 2'd1;
                score3 = 2'd0;
            end

            2'b10: begin
                score0 = 2'd0;
                score1 = 2'd1;
                score2 = 2'd3;
                score3 = 2'd1;
            end

            2'b11: begin
                score0 = 2'd0;
                score1 = 2'd0;
                score2 = 2'd1;
                score3 = 2'd3;
            end

            default: begin
                score0 = 2'd0;
                score1 = 2'd0;
                score2 = 2'd0;
                score3 = 2'd0;
            end
        endcase
    end

endmodule