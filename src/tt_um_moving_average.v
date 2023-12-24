// Copyright 2023 Alexander Hofer 
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE−2.0
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and
// limitations under the License.

`default_nettype none

module tt_um_moving_average #(
    parameter FILTER_POWER = 2,  // Window length as a power of 2
    parameter DATA_IN_LEN = 10   // Number of bits for input data
)(
    input wire [DATA_IN_LEN-1:0] data_in,    // Input data
    output wire [DATA_IN_LEN-1:0] data_out,   // Output data
    input wire strobe_in,                    // Strobe input signal
    output wire strobe_out,                  // Strobe output signal
    input wire clk,                          // Clock
    input wire reset                         // Reset signal (active high)
);

    localparam FILTER_SIZE = 1 << FILTER_POWER; // Filter size
    localparam SUM_WIDTH = DATA_IN_LEN + FILTER_POWER;
    localparam PAD_WIDTH = FILTER_POWER;

    // FSM states
    reg [1:0] state, next_state;
    localparam WAIT_FOR_STROBE = 2'b00;
    localparam ADD             = 2'b01;
    localparam AVERAGE         = 2'b11;

    // Data buffer
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
    always @(*) begin
        next_state = state;
        for (integer i = 0; i < FILTER_SIZE; i = i + 1) begin
            next_shift_reg[i] = shift_reg[i];
        end
        next_sum = sum;
        next_avg_sum = avg_sum;
        next_counter_value = counter_value;
		
        case(state) 
            WAIT_FOR_STROBE: begin
                if (strobe_in) begin
                    next_sum = {{PAD_WIDTH{1'b0}}, data_in}; //zero padding
                    next_state = ADD;
                end
            end
			
            ADD: begin
                if (counter_value == FILTER_SIZE - 1) begin
                    next_counter_value = 0;
                    next_state = AVERAGE;
                end else begin
                    next_sum = sum + {{PAD_WIDTH{1'b0}}, shift_reg[counter_value]};
                    next_counter_value = counter_value + 1'b1;
                end
            end
			
            AVERAGE: begin
                next_shift_reg[0] = data_in;
                for (integer i = 1; i < FILTER_SIZE; i = i + 1) begin
                    next_shift_reg[i] = shift_reg[i - 1];
                end
                next_avg_sum = sum[SUM_WIDTH-1:FILTER_POWER];
                next_state = WAIT_FOR_STROBE;
            end
            default: next_state = WAIT_FOR_STROBE;
        endcase
    end

    assign data_out = avg_sum;
    assign strobe_out = (state == AVERAGE) ? 1'b1 : 1'b0;

endmodule
