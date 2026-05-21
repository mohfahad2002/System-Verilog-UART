module uart_tx #(
    parameter CLK_FREQ  = 200_000_000,  // System clock frequency
    parameter BAUD_RATE = 115200        // UART baud rate
)(
    input  wire       clk,       // System clock
    input  wire       rst_n,     // Active-low reset
    input  wire [7:0] data_in,   // Byte to transmit
    input  wire       send,      // Trigger transmission

    output reg        tx_out,    // UART TX line
    output reg        busy,      // High while transmitting
    output reg        done,      // Pulse high when transmission done

    output            baud16_clk //Pulse after BAUDRATE/16 seconds have passed. For debugging
);

    // --------------------------------------------
    // Oversampling: 16x
    // --------------------------------------------
    localparam integer CLKS_PER_BIT = (CLK_FREQ + (BAUD_RATE*8)) / (BAUD_RATE*16); 
    // Round nearest integer

    // FSM states
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    reg [1:0] state;

    // Counters and registers
    reg [15:0] clk_counter;   // counts system clocks
    reg [3:0]  oversample_cnt; // counts 0..15 (16×)
    reg [2:0]  bit_index;     // 0..7 data bits
    reg [7:0]  tx_data;

    // --------------------------------------------
    // 16x Baud clock generation (pulse for 1 clk)
    // --------------------------------------------
    reg baud16_pulse;
    assign baud16_clk = baud16_pulse;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_counter   <= 0;
            baud16_pulse  <= 0;
        end else if (clk_counter == CLKS_PER_BIT-1) begin
            clk_counter  <= 0;
            baud16_pulse <= 1; // single-cycle pulse
        end else begin
            clk_counter  <= clk_counter + 1;
            baud16_pulse <= 0;
        end
    end

    // --------------------------------------------
    // UART FSM using oversampled clock
    // Each bit lasts 16 ticks
    // --------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= IDLE;
            tx_out       <= 1'b1; // idle high
            busy         <= 0;
            done         <= 0;
            bit_index    <= 0;
            oversample_cnt <= 0;
            tx_data      <= 0;
        end else begin
            done <= 0; // pulse once
            if (baud16_pulse) begin
                case(state)
                    IDLE: begin
                        tx_out <= 1'b1;
                        busy   <= 0;
                        oversample_cnt <= 0;
                        if (send) begin
                            tx_data <= data_in;
                            state   <= START;
                            busy    <= 1;
                        end
                    end

                    START: begin
                        tx_out <= 1'b0; // start bit
                        oversample_cnt <= oversample_cnt + 1;
                        if (oversample_cnt == 15) begin
                            oversample_cnt <= 0;
                            state <= DATA;
                            bit_index <= 0;
                        end
                    end

                    DATA: begin
                        tx_out <= tx_data[bit_index];
                        oversample_cnt <= oversample_cnt + 1;
                        if (oversample_cnt == 15) begin
                            oversample_cnt <= 0;
                            if (bit_index == 7) begin
                                state <= STOP;
                            end else begin
                                bit_index <= bit_index + 1;
                            end
                        end
                    end

                    STOP: begin
                        tx_out <= 1'b1; // stop bit
                        oversample_cnt <= oversample_cnt + 1;
                        if (oversample_cnt == 15) begin
                            oversample_cnt <= 0;
                            state <= IDLE;
                            busy  <= 0;
                            done  <= 1;
                        end
                    end

                    default: state <= IDLE;
                endcase
            end
        end
    end

endmodule