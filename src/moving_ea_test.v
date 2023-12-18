`default_nettype none

module moving_average_e #(
    parameter FILTER_POWER = 2   // Example window length
) (
    input  wire [7:0] ui_in,    // Dedicated inputs - Input for the moving averager
    output wire [7:0] uo_out,   // Dedicated outputs - Output for the moving averager
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input  wire       clk,      // Clock
    input  wire       rst_n     // Reset (active low)
);

    localparam DATA_IN_LEN = 8;

    wire reset = !rst_n;
    wire [DATA_IN_LEN - 1:0] data_i = ui_in;
    wire [DATA_IN_LEN - 1:0] data_o;

    localparam FILTER_SIZE = 1 << FILTER_POWER; // Power of 2 for filter size
    localparam SUM_WIDTH = DATA_IN_LEN + FILTER_POWER; // Adjusted sum width

    // FSM states
    reg [2:0] state, next_state;
    localparam WAIT_FOR_STROBE = 2'b00;
    localparam ADD             = 2'b01;
    localparam AVERAGE         = 2'b11;

    // Data buffer type
    reg [DATA_IN_LEN - 1:0] shift_reg [FILTER_SIZE - 1:0];
    reg [DATA_IN_LEN - 1:0] next_shift_reg [FILTER_SIZE - 1:0];

    // Other signals
    reg [FILTER_SIZE - 1:0] counter_value, next_counter;
    reg [SUM_WIDTH - 1:0] sum, next_sum;
    reg [DATA_IN_LEN - 1:0] avg_sum, next_avg_sum;
    reg mov_avg_valid_strobe, next_mov_avg_valid_strobe;

      // Main FSM logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter_value <= 0;
            state <= WAIT_FOR_STROBE;
            sum <= 0;
            avg_sum <= 0;
            mov_avg_valid_strobe <= 0;
            for (int i = 0; i < FILTER_SIZE; i= i+1) begin
                shift_reg[i] <= 0;
            end
        end else begin
            counter_value <= next_counter;
            state <= next_state;
            sum <= next_sum;
            avg_sum <= next_avg_sum;
            mov_avg_valid_strobe <= next_mov_avg_valid_strobe;
            for (int i = 0; i < FILTER_SIZE; i = i+1) begin
                shift_reg[i] <= next_shift_reg[i];
            end
        end
    end
    
endmodule
