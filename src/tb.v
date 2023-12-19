`default_nettype none
`timescale 1ns/1ps

module tb;
	
    // Testbench Signals
    reg [7:0] ui_in = 0; // Input for the moving averager
    wire [7:0] uo_out; // Output for the moving averager
    reg [7:0] uio_in; // Bidirectional Input path
    wire [7:0] uio_out; // Bidirectional Output path
    wire [7:0] uio_oe; // Bidirectional Enable path
    reg clk = 0; // Clock
    reg rst_n = 1; // Reset (active low)
	reg ena; //enable
	
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
        #1;
    end
    // Test Stimulus
    initial begin
        // Initialize Inputs
        ui_in = 0;
        uio_in = 0;
        rst_n = 1;

        // Reset the system
        #20;
        rst_n = 0;
        #20;
        rst_n = 1;
        #40;

        // Apply test data
        uio_in[0] = 1; // Strobe signal active
        ui_in = 8'h01; // Test data
        #20;
        uio_in[0] = 0; // Strobe signal inactive
        #20;

        // Apply next set of test data
        uio_in[0] = 1;
        ui_in = 8'h02;
        #20;
        uio_in[0] = 0;
        #20;

        // Continue with additional test data
        uio_in[0] = 1;
        ui_in = 8'h03; // Full-scale value
        #20;
        uio_in[0] = 0;
        #20;

        uio_in[0] = 1;
        ui_in = 8'h04; // Zero value
        #20;
        uio_in[0] = 0;
        #20;
        
        uio_in[0] = 1;
        ui_in = 8'h00; // Full-scale value
        #20;
        uio_in[0] = 0;
        #20;

        uio_in[0] = 1;
        ui_in = 8'h01; // Zero value
        #20;
        uio_in[0] = 0;
        #20;

		 uio_in[0] = 1;
        ui_in = 8'h02; // Full-scale value
        #20;
        uio_in[0] = 0;
        #20;

        uio_in[0] = 1;
        ui_in = 8'h03; // Zero value
        #20;
        uio_in[0] = 0;
        #20;
        
        // Finish the simulation
        $finish;
    end

endmodule













