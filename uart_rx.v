module uart_rx #(
    parameter CLK_FREQ  = 200_000_000,  // System clock frequency
    parameter BAUD_RATE = 115200        // UART baud rate
)(
    input wire clk,
    input wire rst_n,
    input wire rx_in,
    input wire baud_pulse,

    output reg busy,
    output reg done,
    output reg [7:0] data_out,

    input wire baudclk
);

// --------------------------------------------
// Oversampling: 16x
// --------------------------------------------
localparam integer CLKS_PER_BIT = (CLK_FREQ + (BAUD_RATE*8)) / (BAUD_RATE*16); 
// Round nearest integer

//----------------------------------------------
// FSM States
//----------------------------------------------
localparam IDLE = 2'b00;
localparam RECEIVE = 2'b01;
localparam STOP = 2'b10;

// Reg for FSM
reg [1:0] state;

// reg [15:0] clk_counter;   // counts system clocks
// reg baud_pulse;

// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         clk_counter <= '0;
//         baud_pulse <= '0;
//     end
//     else begin
//         if (clk_counter == CLKS_PER_BIT - 1) begin
//             clk_counter <= '0;
//             baud_pulse <= '1;
//         end
//         else begin
//             baud_pulse <= '0;
//             clk_counter <= clk_counter + 1;
//         end
//     end
// end

reg [3:0]  oversample_cnt; // counts 0..15 (16×)
reg [2:0]  bit_index;     // 0..7 data bits
reg [7:0]  rx_data;
// reg [3:0]  data_sample;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        oversample_cnt <= 'b0;
        bit_index <= 'b0;
        rx_data <= 'b0;
        done <= 'b0;
        busy <= 'b0;
        data_out <= 'b0;
    end
    else begin
        done <= 'b0;
        if (baud_pulse) begin
            case (state)
                IDLE: begin
                    if (!rx_in) begin
                        if (oversample_cnt == 'd8) begin
                            oversample_cnt <= 'b0;
                            state <= RECEIVE;
                            busy <= 'b1;
                        end
                        else begin
                            oversample_cnt <= oversample_cnt + 1;
                        end   
                    end
                    else begin
                        oversample_cnt <= 'b0;
                    end
                end
                RECEIVE: begin
                    if (oversample_cnt == 'd15) begin
                        rx_data[bit_index] <= rx_in;
                        if (bit_index == 'd7) begin
                            bit_index <= 'b0;
                            oversample_cnt <= 'b0;
                            state <= STOP;
                        end
                        else begin
                            bit_index <= bit_index + 1;
                            oversample_cnt <= 'b0;
                        end
                    end
                    else begin
                        oversample_cnt <= oversample_cnt + 1;
                    end
                end
                STOP: begin
                    if (oversample_cnt == 'd8) begin
                        done <= 'b1;
                        busy <= 'b0;
                        oversample_cnt <= 'b0;
                        state <= IDLE;
                        data_out <= rx_data;
                    end

                    oversample_cnt <= oversample_cnt + 1;
                end
            endcase
        end
    end
end

assign baudclk = baud_pulse;
endmodule