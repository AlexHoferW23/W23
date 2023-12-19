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

    parameter FILTER_POWER = 2; // Example window length
    localparam DATA_IN_LEN = 8;
    localparam FILTER_SIZE = 1 << FILTER_POWER; // Power of 2 for filter size
    localparam SUM_WIDTH = DATA_IN_LEN + FILTER_POWER; // Adjusted sum width
    localparam PAD_WIDTH = SUM_WIDTH - DATA_IN_LEN; // Padding

    wire reset = !rst_n;
    wire [DATA_IN_LEN - 1:0] data_i = ui_in; 
    wire strobe_i = uio_in[0];
    assign uio_oe[0] = 1'b0;   

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
	
    assign uo_out = avg_sum; //assign output of the filter
    assign uio_oe[1] = 1'b1;   
    assign uio_out[1] = (state == AVERAGE) ? 1'b1 : 1'b0; // Strobe output 
    
     // Assign default values to unused bits of uio_out and uio_oe
     
    assign uio_out[7:2] = 6'bz;  // High-impedance for unused output bits
    assign uio_out[0] = 1'bz;    // High-impedance for unused output bit
    
    assign uio_oe[7:2] = 6'b0;   // Configure unused pins as inputs
     
endmodule
