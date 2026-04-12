`timescale 1ns/1ps

module inference_top_tb;

    reg clk;
    reg rst_n;
    reg in_valid;
    reg [31:0] in_bits;
    reg [31:0] mask_bus;

    wire out_valid;
    wire [1:0] class_out;

    inference_top uut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .in_bits(in_bits),
        .mask_bus(mask_bus),
        .out_valid(out_valid),
        .class_out(class_out)
    );

    // Clock: 10ns period
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Dump waveform
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, inference_top_tb);
    end

    // Monitor
    initial begin
        $display("time\tclk\trst_n\tin_valid\tin_bits\t\t\tmask_bus\t\t\tout_valid\tclass_out");
        $monitor("%0t\t%b\t%b\t%b\t\t%h\t%h\t%b\t\t%0d",
                 $time, clk, rst_n, in_valid, in_bits, mask_bus, out_valid, class_out);
    end

    initial begin
        // ----------------------------
        // Reset
        // ----------------------------
        rst_n    = 1'b0;
        in_valid = 1'b0;
        in_bits  = 32'h0000_0000;
        mask_bus = 32'hFFFF_FFFF;

        #18;
        rst_n = 1'b1;

        #10;

        // --------------------------------------------------
        // Test 1: full mask, all-zero input
        // --------------------------------------------------
        @(negedge clk);
        in_valid = 1'b1;
        in_bits  = 32'h0000_0000;
        mask_bus = 32'hFFFF_FFFF;

        @(negedge clk);
        in_valid = 1'b0;
        in_bits  = 32'h0000_0000;

        #40;

        // --------------------------------------------------
        // Test 2: full mask, mixed pattern
        // --------------------------------------------------
        @(negedge clk);
        in_valid = 1'b1;
        in_bits  = 32'h1234_ABCD;
        mask_bus = 32'hFFFF_FFFF;

        @(negedge clk);
        in_valid = 1'b0;
        in_bits  = 32'h0000_0000;

        #40;

        // --------------------------------------------------
        // Test 3: partial mask
        // Some input bits are effectively pruned
        // --------------------------------------------------
        @(negedge clk);
        in_valid = 1'b1;
        in_bits  = 32'h89AB_CDEF;
        mask_bus = 32'h0F0F_F0F0;

        @(negedge clk);
        in_valid = 1'b0;
        in_bits  = 32'h0000_0000;

        #40;

        // --------------------------------------------------
        // Test 4: another partial mask, different input
        // --------------------------------------------------
        @(negedge clk);
        in_valid = 1'b1;
        in_bits  = 32'h55AA_33CC;
        mask_bus = 32'hFF00_FF00;

        @(negedge clk);
        in_valid = 1'b0;
        in_bits  = 32'h0000_0000;

        #40;

        // --------------------------------------------------
        // Test 5: back-to-back inputs
        // --------------------------------------------------
        @(negedge clk);
        in_valid = 1'b1;
        in_bits  = 32'h1111_2222;
        mask_bus = 32'hFFFF_FFFF;

        @(negedge clk);
        in_valid = 1'b1;
        in_bits  = 32'h3333_4444;
        mask_bus = 32'hFFFF_0FFF;

        @(negedge clk);
        in_valid = 1'b1;
        in_bits  = 32'hAAAA_5555;
        mask_bus = 32'hF0F0_F0F0;

        @(negedge clk);
        in_valid = 1'b0;
        in_bits  = 32'h0000_0000;
        mask_bus = 32'hFFFF_FFFF;

        #60;

        // --------------------------------------------------
        // Test 6: reset during simulation
        // --------------------------------------------------
        @(negedge clk);
        rst_n    = 1'b0;
        in_valid = 1'b0;
        in_bits  = 32'h0000_0000;
        mask_bus = 32'h0000_0000;

        #15;
        rst_n = 1'b1;

        #20;

        // --------------------------------------------------
        // Test 7: post-reset operation
        // --------------------------------------------------
        @(negedge clk);
        in_valid = 1'b1;
        in_bits  = 32'hDEAD_BEEF;
        mask_bus = 32'hFFFF_FFFF;

        @(negedge clk);
        in_valid = 1'b0;
        in_bits  = 32'h0000_0000;

        #60;

        $display("Simulation finished.");
        $finish;
    end

endmodule