`timescale 1ns/1ps

module inference_top_tb;
    // Shared stimulus + comparison TB for:
    //   1) LUT feature extraction + LUT-style scoring (inference_top)
    //   2) LUT feature extraction + MAC-style scoring (inference_top_mac)
    //
    // Logs per input-run latency and class outputs into:
    //   comparison_results.csv

    reg clk;
    reg rst_n;
    reg in_valid;
    reg [31:0] in_bits;
    reg [31:0] mask_bus;

    wire out_valid_lut;
    wire [1:0] class_out_lut;
    wire out_valid_mac;
    wire [1:0] class_out_mac;
    wire stg1_valid_lut;
    wire stg2_valid_lut;
    wire stg3_valid_lut;
    wire stg1_valid_mac;
    wire stg2_valid_mac;
    wire stg3_valid_mac;

    // Instantiate LUT path (existing design).
    inference_top uut_lut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .in_bits(in_bits),
        .mask_bus(mask_bus),
        .out_valid(out_valid_lut),
        .stg1_valid(stg1_valid_lut),
        .stg2_valid(stg2_valid_lut),
        .stg3_valid(stg3_valid_lut),
        .class_out(class_out_lut)
    );

    // Instantiate MAC path (baseline).
    inference_top_mac uut_mac (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .in_bits(in_bits),
        .mask_bus(mask_bus),
        .out_valid(out_valid_mac),
        .stg1_valid(stg1_valid_mac),
        .stg2_valid(stg2_valid_mac),
        .stg3_valid(stg3_valid_mac),
        .class_out(class_out_mac)
    );

    // Clock: 10ns period (same as your original TB).
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Dump waveform (keep existing behavior; this is still useful for pipeline timing).
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, inference_top_tb);
    end

    // ----------------------------
    // Cycle counter + latency bookkeeping
    // ----------------------------
    integer cycle_count;
    integer cycle_now;

    // Edge detection (event-based latency).
    reg in_valid_d;
    reg out_valid_lut_d;
    reg out_valid_mac_d;

    // Per-transaction bookkeeping.
    integer in_cycle;
    integer latency_lut;
    integer latency_mac;
    reg lut_seen;
    reg mac_seen;
    reg run_logged;
    integer run_id_latched;

    // CSV logging.
    integer csv_fd;
    integer run_id;
    integer logged_rows;

    // Constants for structural metadata.
    localparam integer DATA_WIDTH = 32;

    // Helper task for 1-cycle in_valid pulses.
    task send_one_input;
        input [31:0] bits;
        input [31:0] mask;
    begin
        @(negedge clk);
        in_bits      = bits;
        mask_bus     = mask;
        in_valid     = 1'b1;

        @(negedge clk);
        in_valid     = 1'b0;
    end
    endtask

    // Event-based cycle tracking:
    // - capture cycle at rising edge of `in_valid`
    // - capture cycle at rising edges of `out_valid_lut` and `out_valid_mac`
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_count = 0;
            cycle_now   = 0;

            in_valid_d       = 1'b0;
            out_valid_lut_d  = 1'b0;
            out_valid_mac_d  = 1'b0;

            in_cycle   = 0;
            latency_lut = 0;
            latency_mac = 0;

            lut_seen    = 1'b0;
            mac_seen    = 1'b0;
            run_logged  = 1'b0;
            run_id_latched = 0;
        end else begin
            cycle_count = cycle_count + 1;
            cycle_now   = cycle_count;

            // 1) Detect start of transaction on rising edge of in_valid.
            if (in_valid && !in_valid_d) begin
                in_cycle = cycle_now;

                lut_seen   = 1'b0;
                mac_seen   = 1'b0;
                run_logged = 1'b0;

                run_id_latched = run_id;
            end

            // 2) Detect rising edge of out_valid_lut.
            if (out_valid_lut && !out_valid_lut_d && !lut_seen) begin
                latency_lut = cycle_now - in_cycle;
                lut_seen = 1'b1;
            end

            // 3) Detect rising edge of out_valid_mac.
            if (out_valid_mac && !out_valid_mac_d && !mac_seen) begin
                latency_mac = cycle_now - in_cycle;
                mac_seen = 1'b1;
            end

            // 4) Log once both latencies are known.
            if (lut_seen && mac_seen && !run_logged) begin
                $fwrite(csv_fd, "%0d,%0d,%0d\n", run_id_latched, latency_lut, latency_mac);
                logged_rows = logged_rows + 1;
                run_logged = 1'b1;
            end

            // Update delayed versions for edge detection.
            in_valid_d      = in_valid;
            out_valid_lut_d = out_valid_lut;
            out_valid_mac_d = out_valid_mac;
        end
    end

    // ----------------------------
    // Main test sequence
    // ----------------------------
    localparam integer NUM_REPEATS    = 2;
    localparam integer NUM_INPUTS     = 9;
    localparam integer TOTAL_RUNS     = NUM_REPEATS * NUM_INPUTS;
    localparam integer MAX_WAIT_CYCLES = 50;

    initial begin
        // CSV setup.
        csv_fd = $fopen("results/comparison_results.csv", "w");
        if (csv_fd == 0) begin
            $display("ERROR: Failed to open results/comparison_results.csv for writing.");
            $finish;
        end

        $fwrite(csv_fd,
                "run_id,latency_lut,latency_mac\n");

        logged_rows = 0;

        // Default drive values.
        rst_n = 1'b0;
        in_valid = 1'b0;
        in_bits = 32'h0000_0000;
        mask_bus = 32'hFFFF_FFFF;
        in_valid = 1'b0;

        // Clock settles.
        #12;

        for (run_id = 0; run_id < TOTAL_RUNS; run_id = run_id + 1) begin
            integer in_idx;
            integer wait_cycles;
            reg [31:0] bits;
            reg [31:0] mask;

            // Which input stimulus for this run.
            in_idx = run_id % NUM_INPUTS;

            // Select (in_bits, mask_bus) pairs.
            case (in_idx)
                0: begin bits = 32'h0000_0000; mask = 32'hFFFF_FFFF; end
                1: begin bits = 32'h1234_ABCD; mask = 32'hFFFF_FFFF; end
                2: begin bits = 32'h89AB_CDEF; mask = 32'h0F0F_F0F0; end
                3: begin bits = 32'h55AA_33CC; mask = 32'hFF00_FF00; end
                4: begin bits = 32'h1111_2222; mask = 32'hFFFF_FFFF; end
                5: begin bits = 32'h3333_4444; mask = 32'hFFFF_0FFF; end
                6: begin bits = 32'hAAAA_5555; mask = 32'hF0F0_F0F0; end
                7: begin bits = 32'hDEAD_BEEF; mask = 32'hFFFF_FFFF; end
                default: begin bits = 32'h1234_ABCD; mask = 32'h0F0F_F0F0; end
            endcase

            // Reset between runs so each run has a single transaction and
            // event-based latency pairing stays unambiguous.
            @(negedge clk);
            rst_n = 1'b0;
            in_valid = 1'b0;

            repeat (2) @(negedge clk);
            rst_n = 1'b1;

            // Give one extra cycle after reset deassertion.
            @(negedge clk);

            // Clear run-done flag; latencies will be set by event capture.
            run_logged = 1'b0;
            lut_seen   = 1'b0;
            mac_seen   = 1'b0;

            // Start transaction (1-cycle in_valid pulse).
            send_one_input(bits, mask);

            // Wait until both out_valid_rises are captured and logged.
            wait_cycles = 0;
            while (!run_logged && wait_cycles < MAX_WAIT_CYCLES) begin
                @(posedge clk);
                wait_cycles = wait_cycles + 1;
            end

            if (!run_logged) begin
                $display("ERROR: Timeout waiting for latencies. run_id=%0d in_idx=%0d", run_id, in_idx);
            end

            // Small inter-run gap before next reset.
            @(negedge clk);
        end

        $fclose(csv_fd);

        $display("Simulation finished.");
        $display("Logged latency rows: %0d (expected %0d)", logged_rows, TOTAL_RUNS);
        $finish;
    end

endmodule
