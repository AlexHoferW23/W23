`default_nettype none

module moving_average_e #(
    parameter FILTER_POWER = 2   // Example window length
) (
    input  wire [7:0] ui_in,         // Dedicated inputs - Input for the moving averager
    output wire [7:0] uo_out,        // Dedicated outputs - Output for the moving averager
    input  wire [7:0] uio_in,        // IOs: Bidirectional Input path
    output wire [7:0] uio_out,       // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,        // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input  wire       ena,           // will go high when the design is enabled
    input  wire       clk,           // clock
    input  wire       rst_n          // reset_n - low to reset
);

    localparam DATA_IN_LEN = 10;

    /*
        uio Pin Assignments:
        - uio[0] and uio[1]: Additional input bits for moving averager (set as inputs)
        - uio[2] and uio[3]: Additional output bits for moving averager (set as outputs)
        - uio[4]: Strobe input (set as input)
        - uio[5]: Strobe output (set as output)
        - uio[6] and uio[7]: Filter power settings input (set as inputs)
        Configuration:
        - 0 in uio_oe array represents an input configuration
        - 1 in uio_oe array represents an output configuration
    */
    assign uio_oe = 8'b00101100;  // Set uio pins as inputs/outputs based on the specified functionalities

    wire reset = !rst_n;

    // 10-bit data input: lower 8 bits from ui_in, upper 2 bits from uio_in[1:0]
    wire [DATA_IN_LEN - 1:0] data_i = {uio_in[1:0], ui_in};

    // Define strobe input and output
    wire strobe_i = uio_in[4];       // Strobe input from uio_in[4]
    wire strobe_o;                   // Strobe output
    // Assign filter power bits (assuming not used in this code)
    // wire [2:0] filter_power_bits = uio_in[7:5]; // Use if needed
    wire [DATA_IN_LEN - 1:0] data_o;

    localparam FILTER_SIZE = 1 << FILTER_POWER;  // Power of 2 for filter size
    localparam SUM_WIDTH = DATA_IN_LEN + FILTER_POWER;

    // FSM states
    typedef enum {WAIT_FOR_STROBE, ADD, AVERAGE} t_fsm;
    t_fsm fsm_state, next_fsm_state;

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
            fsm_state <= WAIT_FOR_STROBE;
            sum <= 0;
            avg_sum <= 0;
            mov_avg_valid_strobe <= 0;
            for (int i = 0; i < FILTER_SIZE; i++) begin
                shift_reg[i] <= 0;
            end
        end else begin
            counter_value <= next_counter;
            fsm_state <= next_fsm_state;
            sum <= next_sum;
            avg_sum <= next_avg_sum;
            mov_avg_valid_strobe <= next_mov_avg_valid_strobe;
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
                    next_sum = {SUM_WIDTH - DATA_IN_LEN{1'b0}} | data_i;
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

    // Valid strobe signal
    assign strobe_o = (fsm_state == AVERAGE) ? 1'b1 : 1'b0;

    // Output data
    assign {uio_out[2:1], uo_out} = data_o; // Split 10-bit output between uo_out and uio_out[2:1]
    assign uio_out[3] = strobe_o;           // Assign strobe output to uio_out[3]
endmodule
