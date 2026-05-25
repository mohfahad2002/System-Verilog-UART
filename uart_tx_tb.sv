`timescale 1ns/1ps

module uart_tx_tb ();

logic clk;
logic rst_n;
logic tx_out;

logic tx_busy;
logic tx_done;
logic [7:0] data_in;
logic send;

logic tx_baudclk;

logic rx_in;

logic rx_busy;
logic rx_done;
logic [7:0] data_out;

logic rx_baudclk;

logic [7:0] test_data = 8'b11101110;
logic [7:0] tx_received = 'd0;

logic uart_clk;
logic tx_bit_transition;

uart #(
    .CLK_FREQ(200_000_000),  // System clock frequency
    .BAUD_RATE(115200)        // UART baud rate
) rx_inst(
    .clk(clk),
    .rst_n(rst_n),
    .rx_in(rx_in),

    .rx_busy(rx_busy),
    .rx_done(rx_done),
    .rx_data_out(data_out),

    .rx_baudclk(rx_baudclk),

    .tx_data_in(data_in),
    .tx_send(send),

    .tx_out(tx_out),
    .tx_busy(tx_busy),
    .tx_done(tx_done),

    .tx_bit_transition(tx_bit_transition),
    .tx_baudclk(tx_baudclk)
);

initial begin
    clk = 0;
    uart_clk = 0;
    forever #2.5 clk = ~clk; // 200mhz
end

task wait_baud(int num_samples = 16, int pulse = 1);
    for (int i = 0; i < num_samples; i++) begin
        @(posedge tx_baudclk);
    end
    if (pulse) uart_clk = ~uart_clk;
endtask

task automatic test_rx();
    rx_in = 1;

    @(posedge clk);
    wait_baud();
    rx_in = 0;

    wait_baud();

    for (int i = 0; i < 8; i++) begin
        rx_in = test_data[0];
        test_data = test_data >> 1;
        wait_baud();
    end

    @(posedge rx_done);
endtask

task automatic test_tx();
    data_in = test_data;
    send = 'b1;

    @(posedge tx_baudclk);
    

    wait_baud();

    send = 'b0;

    wait_baud(8);
    // @(posedge clk);
    // @(posedge clk);
    // @(posedge clk);
    // @(posedge clk);
    // @(posedge clk);

    for (int i = 0; i < 8; i++) begin
        tx_received[i] = tx_out;
        wait_baud();
    end

    @(posedge tx_done);
 
endtask

initial begin
    rst_n = 0;

    @(posedge clk);

    rst_n = 1;
    test_tx();

    $stop;
end

endmodule