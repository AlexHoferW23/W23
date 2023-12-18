`default_nettype none

module moving_average_e #(
    parameter FILTER_POWER = 2  // Example window length
) (
    input  wire [7:0] ui_in,    // Dedicated inputs - Input for the moving averager
    output wire [7:0] uo_out,   // Dedicated outputs - Output for the moving averager
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
    
    localparam DATA_IN_LEN = 10;
    wire reset = !rst_n;

    // Concatenate for 10-bit data input
    wire [DATA_IN_LEN - 1:0] data_i = {uio_in[1:0], ui_in};

    wire strobe_i = uio_in[4];  // Strobe input
    wire [DATA_IN_LEN - 1:0] data_o;
    wire strobe_o;

    localparam FILTER_SIZE = 1 << FILTER_POWER;
    localparam SUM_WIDTH = DATA_IN_LEN + FILTER_POWER;

    typedef enum {WAIT_FOR_STROBE, ADD, AVERAGE} t_fsm;
    t_fsm fsm_state, next_fsm_state;

    reg [DATA_IN_LEN - 1:0] shift_reg [FILTER_SIZE - 1:0];
    reg [DATA_IN_LEN - 1:0] next_shift_reg [FILTER_SIZE - 1:0];

    reg [FILTER_SIZE - 1:0] counter_value, next_counter;
    reg [SUM_WIDTH - 1:0] sum, next_sum;
    reg [DATA_IN_LEN - 1:0] avg_sum, next_avg_sum;

    // Main FSM logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter_value <= 0;
            fsm_state <= WAIT_FOR_STROBE;
            sum <= 0;
            avg_sum <= 0;
            for (int i = 0; i < FILTER_SIZE; i++) begin
                shift_reg[i] <= 0;
            end
        end else begin
            counter_value <= next_counter;
            fsm_state <= next_fsm_state;
            sum <= next_sum;
            avg_sum <= next_avg_sum;
            for (int i = 0; i < FILTER_SIZE; i++) begin
                shift_reg[i] <= next_shift_reg[i];
            end
        end
    end

    // FSM behavior
    always @(*) begin
        next_fsm_state = fsm_state;
        for (int i = 0; i < FILTER_SIZE; i++) begin
            next_shift_reg[i] = shift_reg[i];
        end
        next_sum = sum;
        next_avg_sum = avg_sum;
        next_counter = counter_value;

        case (fsm_state)
            WAIT_FOR_STROBE: begin
                if (strobe_i) begin
                    next_sum = {{SUM_WIDTH - DATA_IN_LEN{1'b0}}, data_i};
                    next_fsm_state = ADD;
                end
            end

            ADD: begin
                if (counter_value == FILTER_SIZE - 1) begin
                    next_counter = 0;
                    next_fsm_state = AVERAGE;
                end else begin
                    next_sum = sum + shift_reg[counter_value];
                    next_counter = counter_value + 1;
                end
            end

            AVERAGE: begin
                next_shift_reg[0] = data_i;
                for (int i = 1; i < FILTER_SIZE; i++) begin
                    next_shift_reg[i] = shift_reg[i - 1];
                end
                next_avg_sum = sum >> FILTER_POWER;
                next_fsm_state = WAIT_FOR_STROBE;
            end

            default: next_fsm_state = WAIT_FOR_STROBE;
        endcase
    end

    // Output assignments
    assign strobe_o = (fsm_state == AVERAGE) ? 1'b1 : 1'b0;
    assign {uio_out[2:1], uo_out} = data_o; // Split 10-bit output
    assign uio_out[
