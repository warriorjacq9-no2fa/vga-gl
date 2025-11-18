`timescale 1ns/1ps

module tb;

    // Clock & reset
    reg clk = 0;
    reg rst_n = 0;

    // DUT inputs
    reg [7:0] ui_in   = 0;
    reg [7:0] uio_in  = 0;
    reg       ena     = 1;

    // DUT outputs
    wire [7:0] uo_out;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

    // Clock generation
    always #10 clk = ~clk; // 50 MHz

    // Instantiate the DUT
    dut_wrapper dut (
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_in(uio_in),
        .uio_out(uio_out),
        .uio_oe(uio_oe),
        .ena(ena),
        .clk(clk),
        .rst_n(rst_n)
    );

    // Simulation parameters
    localparam integer TOTAL_CYCLES = 420_000;
    integer cycle_count;
    integer file;

    initial begin
        file = $fopen("dump.bin", "wb");
        if (!file) begin
            $display("ERROR: Cannot open output file.");
            $finish;
        end

        // Reset pulse
        rst_n = 0;
        #50;
        rst_n = 1;
        // Write number of cycles
        for (int i = 0; i < 8; i++) begin
            $fwrite(file, "%c", (TOTAL_CYCLES >> (8*i)) & 8'hFF);
        end
        // Run simulation for TOTAL_CYCLES
        for (cycle_count = 0; cycle_count < TOTAL_CYCLES; cycle_count = cycle_count + 1) begin
            @(posedge clk);
            $fwrite(file, "%c%c", uo_out, uio_out);
        end

        $fclose(file);
        $finish;
    end

endmodule

// -----------------------------------------------------
// Wrapper that instantiates the selected TOP_MODULE
// -----------------------------------------------------
module dut_wrapper (
    input  [7:0] ui_in,
    input  [7:0] uio_in,
    input        ena,
    input        clk,
    input        rst_n,
    output [7:0] uo_out,
    output [7:0] uio_out,
    output [7:0] uio_oe
);
    `TOP_MODULE dut (
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_in(uio_in),
        .uio_out(uio_out),
        .uio_oe(uio_oe),
        .ena(ena),
        .clk(clk),
        .rst_n(rst_n)
    );
endmodule
