`timescale 1ns/1ps

module tb_inference_top;

    reg        clk;
    reg        rst_n;
    reg        in_valid;
    reg [7:0]  in_bits;

    wire       out_valid;
    wire [1:0] class_out;

    // DUT
    inference_top uut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .in_bits(in_bits),
        .out_valid(out_valid),
        .class_out(class_out)
    );

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_inference_top);
    end
    
    // Clock: 10ns period
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Simple monitor
    initial begin
        $display("Time\tclk\trst_n\tin_valid\tin_bits\t\tout_valid\tclass_out");
        $monitor("%0t\t%b\t%b\t%b\t\t%08b\t%b\t\t%02b",
                 $time, clk, rst_n, in_valid, in_bits, out_valid, class_out);
    end

    initial begin
        // ----------------------------
        // Initial state
        // ----------------------------
        rst_n    = 1'b0;
        in_valid = 1'b0;
        in_bits  = 8'b00000000;

        // Keep reset active for a few cycles
        #18;
        rst_n = 1'b1;

        // Wait a bit after reset release
        #10;

        // --------------------------------------------------
        // Test 1: all zeros
        // Purpose:
        // - basic LUT lookup check
        // - easy reference case
        // --------------------------------------------------
        @(negedge clk);
        in_valid = 1'b1;
        in_bits  = 8'b00000000;

        @(negedge clk);
        in_valid = 1'b0;
        in_bits  = 8'b00000000;

        // Wait enough cycles to see pipelined output
        #30;

        // --------------------------------------------------
        // Test 2: all ones
        // Purpose:
        // - verify another extreme input
        // - check output changes from previous case
        // --------------------------------------------------
        @(negedge clk);
        in_valid = 1'b1;
        in_bits  = 8'b11111111;

        @(negedge clk);
        in_valid = 1'b0;
        in_bits  = 8'b00000000;

        #30;

        // --------------------------------------------------
        // Test 3: alternating pattern 10101010
        // Purpose:
        // - mixed LUT addresses across neurons
        // - check class score aggregation
        // --------------------------------------------------
        @(negedge clk);
        in_valid = 1'b1;
        in_bits  = 8'b10101010;

        @(negedge clk);
        in_valid = 1'b0;
        in_bits  = 8'b00000000;

        #30;

        // --------------------------------------------------
        // Test 4: alternating pattern 01010101
        // Purpose:
        // - compare against previous alternating input
        // - see whether final class changes
        // --------------------------------------------------
        @(negedge clk);
        in_valid = 1'b1;
        in_bits  = 8'b01010101;

        @(negedge clk);
        in_valid = 1'b0;
        in_bits  = 8'b00000000;

        #30;

        // --------------------------------------------------
        // Test 5: back-to-back valid inputs
        // Purpose:
        // - check pipeline behavior under continuous inputs
        // - verify out_valid alignment
        // --------------------------------------------------
        @(negedge clk);
        in_valid = 1'b1;
        in_bits  = 8'b00011011;

        @(negedge clk);
        in_valid = 1'b1;
        in_bits  = 8'b11100100;

        @(negedge clk);
        in_valid = 1'b1;
        in_bits  = 8'b00111100;

        @(negedge clk);
        in_valid = 1'b0;
        in_bits  = 8'b00000000;

        #50;

        // --------------------------------------------------
        // Test 6: reset during simulation
        // Purpose:
        // - make sure pipeline registers clear correctly
        // --------------------------------------------------
        @(negedge clk);
        rst_n = 1'b0;
        in_valid = 1'b0;
        in_bits = 8'b00000000;

        #15;
        rst_n = 1'b1;

        #20;

        // --------------------------------------------------
        // Test 7: one more post-reset input
        // Purpose:
        // - confirm normal operation resumes after reset
        // --------------------------------------------------
        @(negedge clk);
        in_valid = 1'b1;
        in_bits  = 8'b11001001;

        @(negedge clk);
        in_valid = 1'b0;
        in_bits  = 8'b00000000;

        #40;

        $display("Simulation finished.");
        $finish;
    end

endmodule