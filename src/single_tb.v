`default_nettype none
`timescale 1ns/1ps

module tb;
    // Testbench Signals
    reg [7:0] ui_in = 0; // 8-bit Input for the moving averager
    wire [7:0] uo_out;   // 8-bit Output for the moving averager
    reg [7:0] uio_in;    // Bidirectional Input path
    wire [7:0] uio_out;  // Bidirectional Output path
    wire [7:0] uio_oe;   // Bidirectional Enable path
    reg clk = 0;         // Clock
    reg rst_n = 1;       // Reset (active low)
    reg ena;             // Enable

    // Instantiate the Unit Under Test (UUT)
    tt_um_moving_average uut (
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_in(uio_in),
        .uio_out(uio_out),
        .uio_oe(uio_oe),
        .clk(clk),
        .rst_n(rst_n),
        .ena(ena)
    );

    // Clock Generation
    always #10 clk = ~clk;

    initial begin
        $dumpfile ("tb.vcd");
        $dumpvars (0, tb);

        // Reset the system
        rst_n = 0;
        #20;
        rst_n = 1;
        #40;

        // Test Cases Generation
        for (integer i = 0; i < 1000; i++) begin
            // Generate 10-bit test data
            uio_in[3:2] = i[9:8]; // Upper 2 bits
            ui_in = i[7:0];       // Lower 8 bits
            uio_in[0] = 1;        // Strobe signal active
            #20;
            uio_in[0] = 0;        // Strobe signal inactive
            #20;
        end

        // Finish the simulation
        $finish;
    end
endmodule














