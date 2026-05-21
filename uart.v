module uart #(
    parameter CLK_FREQ  = 200_000_000,  // System clock frequency
    parameter BAUD_RATE = 115200        // UART baud rate
)(
    input wire clk,
    input wire rst_n,

    input wire rx_in,

    output wire rx_busy,
    output wire rx_done,
    output wire [7:0] rx_data_out,

    output wire rx_baudclk

    input wire [7:0] tx_data_in,
    input wire tx_send,

    output wire tx_out,
    output wire tx_busy,
    output wire tx_done,

    output wire tx_baudclk
);

reg [15:0] clk_counter;   // counts system clocks
reg baud_pulse;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        clk_counter <= '0;
        baud_pulse <= '0;
    end
    else begin
        if (clk_counter == CLKS_PER_BIT - 1) begin
            clk_counter <= '0;
            baud_pulse <= '1;
        end
        else begin
            baud_pulse <= '0;
            clk_counter <= clk_counter + 1;
        end
    end
end

uart_rx #(
    .CLK_FREQ(CLK_FREQ),  // System clock frequency
    .BAUD_RATE(BAUD_RATE)        // UART baud rate
) rx_inst(
    .clk(clk),
    .rst_n(rst_n),
    .rx_in(rx_in),
    .baud_pulse(baud_pulse),

    .busy(rx_busy),
    .done(rx_done),
    .data_out(rx_data_out),

    .baudclk(rx_baudclk)
);

uart_tx #(
    .CLK_FREQ(CLK_FREQ),  // System clock frequency
    .BAUD_RATE(BAUD_RATE)        // UART baud rate
) tx_inst (
    .clk(clk),       // System clock
    .rst_n(rst_n),     // Active-low reset
    .data_in(tx_data_in),   // Byte to transmit
    .send(tx_send),      // Trigger transmission
    .baud16_pulse(baud_pulse)

    .tx_out(tx_out),    // UART TX line
    .busy(tx_busy),      // High while transmitting
    .done(tx_done),      // Pulse high when transmission done

    .baud16_clk(tx_baudclk) //Pulse after BAUDRATE/16 seconds have passed. For debugging
);

endmodule