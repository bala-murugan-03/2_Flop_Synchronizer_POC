`timescale 1ns / 1ps

module cdc_experiment (
    input  wire        clk_a,
    input  wire        clk_b,
    input  wire        rst_n,
    output reg  [31:0] total_samples,
    output reg  [31:0] single_ff_glitches, // Divergence errors on 1-FF
    output reg  [31:0] sync_2ff_glitches   // Divergence errors on 2-FF
);

    // ==========================================
    // Domain A: Toggle Generator
    // ==========================================
    reg toggle_a;
    always @(posedge clk_a or negedge rst_n) begin
        if (!rst_n)
            toggle_a <= 1'b0;
        else
            toggle_a <= ~toggle_a; // Continuous transitions to force setup/hold violations
    end

    // ==========================================
    // PATH 1: Unsynchronized Single-FF
    // ==========================================
    (* DONT_TOUCH = "TRUE" *) reg y_single;
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n)
            y_single <= 1'b0;
        else
            y_single <= toggle_a;
    end

    // Fan out to TWO separate registers in Domain B
    (* DONT_TOUCH = "TRUE" *) reg y_dest1;
    (* DONT_TOUCH = "TRUE" *) reg y_dest2;

    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            y_dest1 <= 1'b0;
            y_dest2 <= 1'b0;
        end else begin
            y_dest1 <= y_single;
            y_dest2 <= y_single;
        end
    end

    // ==========================================
    // PATH 2: 2-FF Synchronizer
    // ==========================================
    (* ASYNC_REG = "TRUE" *) reg meta_stage1;
    (* ASYNC_REG = "TRUE" *) reg z_sync;

    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            meta_stage1 <= 1'b0;
            z_sync      <= 1'b0;
        end else begin
            meta_stage1 <= toggle_a;
            z_sync      <= meta_stage1;
        end
    end

    // Fan out to TWO separate registers in Domain B
    (* DONT_TOUCH = "TRUE" *) reg z_dest1;
    (* DONT_TOUCH = "TRUE" *) reg z_dest2;

    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            z_dest1 <= 1'b0;
            z_dest2 <= 1'b0;
        end else begin
            z_dest1 <= z_sync;
            z_dest2 <= z_sync;
        end
    end

    // ==========================================
    // Domain B: Error / Inconsistency Checker
    // ==========================================
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            total_samples      <= 32'd0;
            single_ff_glitches <= 32'd0;
            sync_2ff_glitches  <= 32'd0;
        end else begin
            total_samples <= total_samples + 1'b1;

            // In an ideal circuit, y_dest1 == y_dest2 always.
            // If y_single violates timing or goes X, they diverge or become X:
            if ((y_dest1 !== y_dest2) || (y_dest1 === 1'bx) || (y_dest2 === 1'bx))
                single_ff_glitches <= single_ff_glitches + 1'b1;

            // 2-FF path gives a full clock period for resolution:
            if ((z_dest1 !== z_dest2) || (z_dest1 === 1'bx) || (z_dest2 === 1'bx))
                sync_2ff_glitches <= sync_2ff_glitches + 1'b1;
        end
    end

endmodule