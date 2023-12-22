`default_nettype none
`timescale 1ns/1ps

module tb;
    // Testbench Signals
    reg [9:0] data_in = 0;       // 10-bit Input for the moving averager
    wire [9:0] data_out;         // 10-bit Output for the moving averager
    reg strobe_in = 0;           // Strobe Input
    wire strobe_out;             // Strobe Output
    reg clk = 0;                 // Clock
    reg rst_n = 1;               // Reset (active low)
    reg ena = 1;                 // Enable
    reg [1:0] filter_select = 0; // Filter selection bits

    wire [7:0] uio_out_wire; // Wire for uio_out port

    // Instantiate the Unit Under Test (UUT)
    tt_um_moving_average_master uut (
        .ui_in(data_in[7:0]),
        .uo_out(data_out[7:0]),
        .uio_in({filter_select, 2'b00, data_in[9:8], 1'b0, strobe_in}),
        .uio_out(uio_out_wire),
        .uio_oe(),
        .clk(clk),
        .rst_n(rst_n),
        .ena(ena)
    );

    // Assign the data_out upper bits and strobe_out from the uio_out wire
    assign {data_out[9:8], strobe_out} = {uio_out_wire[5:4], uio_out_wire[1]};

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

        // Test for Filter Size 2
        filter_select = 2'b00;
        perform_test();
		#1000;

        // Finish the simulation
        $finish;
    end

    task perform_test;
        for (integer i = 0; i < 50; i++) begin
            if (i == 10) begin
            	data_in = 1023;
		        strobe_in = 1; // Strobe signal active
		        #20;
		        strobe_in = 0; // Strobe signal inactive
		        #20;
		    end else begin
		        data_in = 0; // Generate 10-bit test data
		        strobe_in = 1; // Strobe signal active
		        #20;
		        strobe_in = 0; // Strobe signal inactive
		        #20;
            end
	    end
    endtask
endmodule

