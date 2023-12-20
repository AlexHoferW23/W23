`default_nettype none
`timescale 1ns/1ps

module tt_um_moving_average_master(
    input wire [7:0] ui_in,    // Dedicated inputs - Input for the moving averager
    output wire [7:0] uo_out,  // Dedicated outputs - Output for the moving averager
    input wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out, // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,  // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input wire clk,            // Clock
    input wire rst_n,          // Reset (active low)
    input wire ena
);

    localparam DATA_IN_LEN = 10;
    wire reset = !rst_n;
    wire [DATA_IN_LEN - 1:0] data_i = {uio_in[3:2], ui_in};
    wire strobe_i = uio_in[0];
    wire [1:0] filter_select = uio_in[7:6]; // Filter width control

    // Filter instantiations
    wire [DATA_IN_LEN - 1 :0] filter_out_2, filter_out_4, filter_out_8, filter_out_16;
    wire strobe_out_2, strobe_out_4, strobe_out_8, strobe_out_16;

    // Filter with window length 2
    tt_um_moving_average #(.FILTER_POWER(1), .DATA_IN_LEN(10)) filter_2 (
        .data_in(data_i),
        .data_out(filter_out_2),
        .strobe_in(strobe_i),
        .strobe_out(strobe_out_2),
        .clk(clk),
        .reset(reset)
    );

    // Filter with window length 4
    tt_um_moving_average #(.FILTER_POWER(2), .DATA_IN_LEN(10)) filter_4 (
        .data_in(data_i),
        .data_out(filter_out_4),
        .strobe_in(strobe_i),
        .strobe_out(strobe_out_4),
        .clk(clk),
        .reset(reset)
    );

    // Filter with window length 8
    tt_um_moving_average #(.FILTER_POWER(3), .DATA_IN_LEN(10)) filter_8 (
        .data_in(data_i),
        .data_out(filter_out_8),
        .strobe_in(strobe_i),
        .strobe_out(strobe_out_8),
        .clk(clk),
        .reset(reset)
    );

    // Filter with window length 16
    tt_um_moving_average #(.FILTER_POWER(4), .DATA_IN_LEN(10)) filter_16 (
        .data_in(data_i),
        .data_out(filter_out_16),
        .strobe_in(strobe_i),
        .strobe_out(strobe_out_16),
        .clk(clk),
        .reset(reset)
    );

    // Multiplexer for selecting output based on filter_select
    reg [9:0] selected_filter_out;
    reg selected_strobe_out;

    always @(posedge clk) begin
        if (reset) begin
            selected_filter_out <= 0;
            selected_strobe_out <= 0;
        end else begin
            case(filter_select)
                2'b00: begin
                    selected_filter_out <= filter_out_2;
                    selected_strobe_out <= strobe_out_2;
                end
                2'b01: begin
                    selected_filter_out <= filter_out_4;
                    selected_strobe_out <= strobe_out_4;
                end
                2'b10: begin
                    selected_filter_out <= filter_out_8;
                    selected_strobe_out <= strobe_out_8;
                end
                2'b11: begin
                    selected_filter_out <= filter_out_16;
                    selected_strobe_out <= strobe_out_16;
                end
                default: begin
                    selected_filter_out <= 0;
                    selected_strobe_out <= 0;
                end
            endcase
        end
    end
    
    // uio_in  and uio_out pin usage:
    // uio_in[0] - Strobe input (configured as input)
    // uio_in[1] - Unused (configured as input)
    // uio_in[2] - Unused (configured as input)
    // uio_in[3] - Unused (configured as input)
    // uio_in[4] - Additional output bit (configured as output)
    // uio_in[5] - Additional output bit (configured as output)
    // uio_in[6] - Filter width input
    // uio_in[7] - Filter width input

    // uio_out[0] - High impedance (unused output bit)
    // uio_out[1] - Strobe output
    // uio_out[2] - High impedance (unused output bit)
    // uio_out[3] - High impedance (unused output bit)
    // uio_out[4] - Additional output bit (part of 10-bit output)
    // uio_out[5] - Additional output bit (part of 10-bit output)
    // uio_out[6] - High impedance (unused output bit)
    // uio_out[7] - High impedance (unused output bit)
    
    
    // Assigning output to selected filter output
    assign {uio_out[5:4], uo_out} = selected_filter_out;
    assign uio_out[1] = selected_strobe_out;

    // IOs configuration
    assign uio_oe[0] = 1'b0; // Strobe input set as input
    assign uio_oe[1] = 1'b1; // Strobe output set as output
    assign uio_oe[3:2] = 2'b00; // Additional input bits for data
    assign uio_oe[5:4] = 2'b11; // Additional output bits for data
    assign uio_oe[7:6] = 2'b00; // Filter select input

    // Default configuration for unused output bits
    assign uio_out[7:6] = 2'bz;
    assign uio_out[3:2] = 2'bz;
    assign uio_out[0] = 1'bz;

endmodule

