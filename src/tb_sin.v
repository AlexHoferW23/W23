`timescale 1ns/1ps

module tb;
    // Testbench Signals
    reg [9:0] data_in = 0;
    wire [9:0] data_out;
    reg strobe_in = 0;
    wire strobe_out;
    reg clk = 0;
    reg rst_n = 1;
    reg ena = 1;
    reg [1:0] filter_select = 0;

    integer i;
    integer input_file, output_file;
    reg [9:0] sine_wave[0:999]; // Array size for 1000 data points

    // Instantiate the Unit Under Test (UUT)
    // ... [UUT instantiation] ...

    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb);

        // Open the file with sine wave data for reading
        input_file = $fopen("sine_wave_input.txt", "r");
        // Open a file for writing the output data
        output_file = $fopen("data_out.txt", "w");

        if (input_file) {
            for (i = 0; i < 1000; i = i + 1) begin
                $fscanf(input_file, "%d\n", sine_wave[i]);
            end
            $fclose(input_file);
        end else begin
            $display("Error: sine_wave_input.txt file not found!");
            $finish;
        end

        // Reset the system
        rst_n = 0;
        #20;
        rst_n = 1;
        #40;

        // Apply the sine wave to the filter and write output to file
        filter_select = 2'b10;	
        for (i = 0; i < 1000; i = i + 1) begin
            data_in = sine_wave[i];
            #20; // Time delay for your simulation
            // Write the output data to the file
            $fwrite(output_file, "%d\n", data_out);
        end

        $fclose(output_file); // Close the output file
        $finish; // Finish the simulation
    end
endmodule
