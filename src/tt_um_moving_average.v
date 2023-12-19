`default_nettype none
`timescale 1ns/1ps

module tt_um_moving_average(
    input wire [7:0] ui_in,    // Dedicated inputs - Input for the moving averager
    output wire [7:0] uo_out,  // Dedicated outputs - Output for the moving averager
    input wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out, // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,  // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input wire clk,            // Clock
    input wire rst_n,           // Reset (active low)
    input wire ena
);

    parameter FILTER_POWER = 4; // Example window length
    localparam DATA_IN_LEN = 10;
    
    localparam FILTER_SIZE = 1 << FILTER_POWER; // Power of 2 for filter size
    localparam SUM_WIDTH = DATA_IN_LEN + FILTER_POWER; // Adjusted sum width
    localparam PAD_WIDTH = SUM_WIDTH - DATA_IN_LEN; // Padding
	
	//invert reset
    wire reset = !rst_n;
    
    // (2 + 8)bits from uio_in[3:2] and ui_in
    wire [DATA_IN_LEN - 1:0] data_i = {uio_in[3:2], ui_in};
    wire strobe_i = uio_in[0];
    
    // uio_oe configuration
    assign uio_oe[0] = 1'b0;    // Strobe input set as input
    assign uio_oe[1] = 1'b1;    // Strobe output set as output
    assign uio_oe[3:2] = 2'b00; // Additional input bits for data
    assign uio_oe[5:4] = 2'b11; // Additional output bits for data
    assign uio_oe[7:6] = 2'b00; // Unused pins set as inputs

    // uio_out configuration
    assign {uio_out[5:4], uo_out} = avg_sum; // 10-bit output split between uo_out and uio_out[5:4]
    assign uio_out[1] = (state == AVERAGE) ? 1'b1 : 1'b0; // Strobe output
    assign uio_out[7:6] = 2'bz;  // High-impedance for unused output bits
    assign uio_out[3:2] = 2'bz;  // High-impedance for unused output bits
    assign uio_out[0] = 1'bz;    // High-impedance for unused output bit


    
    // uio_oe and uio_out pin usage:
    // uio_oe[0] - Strobe input (configured as input)
    // uio_oe[1] - Unused (configured as input)
    // uio_oe[2] - Unused (configured as input)
    // uio_oe[3] - Unused (configured as input)
    // uio_oe[4] - Additional output bit (configured as output)
    // uio_oe[5] - Additional output bit (configured as output)
    // uio_oe[6] - Unused (configured as input)
    // uio_oe[7] - Unused (configured as input)

    // uio_out[0] - High impedance (unused output bit)
    // uio_out[1] - Strobe output
    // uio_out[2] - High impedance (unused output bit)
    // uio_out[3] - High impedance (unused output bit)
    // uio_out[4] - Additional output bit (part of 10-bit output)
    // uio_out[5] - Additional output bit (part of 10-bit output)
    // uio_out[6] - High impedance (unused output bit)
    // uio_out[7] - High impedance (unused output bit)
    
    
    
    // FSM states
    reg [1:0] state, next_state;
    localparam WAIT_FOR_STROBE = 2'b00;
    localparam ADD             = 2'b01;
    localparam AVERAGE         = 2'b11;

    // Data buffer type
    reg [DATA_IN_LEN - 1:0] shift_reg [FILTER_SIZE - 1:0];
    reg [DATA_IN_LEN - 1:0] next_shift_reg [FILTER_SIZE - 1:0];

    // Other signals
    reg [FILTER_POWER - 1:0] counter_value, next_counter_value;
    reg [SUM_WIDTH - 1:0] sum, next_sum;
    reg [DATA_IN_LEN - 1:0] avg_sum, next_avg_sum;
	
    // Main FSM logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter_value <= 0;
            state <= WAIT_FOR_STROBE;
            sum <= 0;
            avg_sum <= 0;
            for (integer i = 0; i < FILTER_SIZE; i = i + 1) begin
                shift_reg[i] <= 0;
            end
        end else begin
            counter_value <= next_counter_value;
            state <= next_state;
            sum <= next_sum;
            avg_sum <= next_avg_sum;
            for (integer i = 0; i < FILTER_SIZE; i = i + 1) begin
                shift_reg[i] <= next_shift_reg[i];
            end
        end
    end
	
    // FSM
    always @(state, sum, avg_sum, counter_value, strobe_i) begin
        next_state <= state;
        for (integer i = 0; i < FILTER_SIZE; i = i + 1) begin
            next_shift_reg[i] <= shift_reg[i];
        end
        next_sum <= sum;
        next_avg_sum <= avg_sum;
        next_counter_value <= counter_value;
		
        case(state) 
            WAIT_FOR_STROBE: begin
                if (strobe_i) begin
                    next_sum <= {{PAD_WIDTH{1'b0}}, data_i}; //zero padding
                    next_state <= ADD;
                end
            end
			
            ADD: begin
                if (counter_value == FILTER_SIZE - 1) begin
                    next_counter_value <= 0;
                    next_state <= AVERAGE;
                end else begin
                    next_sum <= sum + {{PAD_WIDTH{1'b0}}, shift_reg[counter_value]};
                    next_counter_value <= counter_value + 1'b1;
                end
            end
			
            AVERAGE: begin
                next_shift_reg[0] <= data_i;
                for (integer i = 1; i < FILTER_SIZE; i = i + 1) begin
                    next_shift_reg[i] <= shift_reg[i - 1];
                end
                next_avg_sum <= sum[SUM_WIDTH-1:FILTER_POWER];
                next_state <= WAIT_FOR_STROBE;
            end
            default: next_state <= WAIT_FOR_STROBE;
        endcase
    end
	
     
endmodule
