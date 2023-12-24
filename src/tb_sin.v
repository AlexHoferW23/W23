`timescale 1ns / 1ps

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
    integer scan_result;  // Variable to store the result of $fscanf
    reg [9:0] sine_wave[0:999];  // Array size for 1000 data points

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
    
    always # 250 strobe_in =~ strobe_in;

    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb);

        // Open the file with sine wave data for reading
        input_file = $fopen("sine_wave_input.txt", "r");
        // Open a file for writing the output data
        output_file = $fopen("data_out.txt", "w");

        if (input_file) begin
            for (i = 0; i < 1000; i = i + 1) begin
                scan_result = $fscanf(input_file, "%d\n", sine_wave[i]);
                // Check if the reading is successful
                if (scan_result != 1) begin
                    $display("Error reading sine_wave_input.txt at line %d", i+1);
                    $fclose(input_file);
                    $finish;
                end
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
        filter_select = 2'b01;	
        for (i = 0; i < 1000; i = i + 1) begin
            data_in = sine_wave[i];
            #500; // Reduced delay to capture more frequent output data
        end

        #1000; // Additional delay to capture last changes in output
        $fclose(output_file); // Close the output file
        $finish; // Finish the simulation
    end
    
        // Capture data_out and strobe_out changes
    always @(posedge clk) begin
        if (strobe_out) begin
            $fwrite(output_file, "%t, %d, %d\n", $time, data_in, data_out);
        end
    end
    
endmodule

