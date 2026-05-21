`timescale 1ns/1ps

module uart_rx_tb ();

logic clk;
logic rst_n;
logic rx_in;

logic busy;
logic done;
logic [7:0] data_out;

logic baudclk;

logic [7:0] test_data = 8'b11101110;

uart_rx #(
    .CLK_FREQ(200_000_000),  // System clock frequency
    .BAUD_RATE(115200)        // UART baud rate
) rx_inst(
    .clk(clk),
    .rst_n(rst_n),
    .rx_in(rx_in),

    .busy(busy),
    .done(done),
    .data_out(data_out),

    .baudclk(baudclk)
);

initial begin
    clk = 0;
    forever #2.5 clk = ~clk; // 200mhz
end

task automatic wait_baud(int num_samples = 16);
    for (int i = 0; i < num_samples; i++) begin
        @(posedge baudclk);
    end
endtask

initial begin
    rst_n = 0;
    rx_in = 1;

    @(posedge clk);
    rst_n = 1;
    wait_baud();
    rx_in = 0;

    wait_baud();

    for (int i = 0; i < 8; i++) begin
        rx_in = test_data[0];
        test_data = test_data >> 1;
        wait_baud();
    end

    @(posedge done);

    $stop;
end

endmodule