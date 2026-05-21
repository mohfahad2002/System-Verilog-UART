`timescale 1ns/1ps

module buffer_packet_logger #(
    parameter CLK_FREQ  = 200_000_000,  // System clock frequency
    parameter BAUD_RATE = 115200,       // UART baud rate
    parameter TRANS_DELAY = 600000000,
    parameter DATA_SIZE = 455,     //Delay = Time delay in seconds * CLK_FREQ
    parameter BYTE_SIZE = 57,
    parameter ADDRESS_SIZE = 7
) (
    input [DATA_SIZE:0] packet,
    input rst_n,
    input clk,
    input fp_det, //fp_det, External Signal to write to buffer
    output full, //Signal when buffer is full
    output uart_tx_out, //Output of uart
    output empty, //Flag to show that all data has been sent
    output uart_start, //Flag to show that uart has started transmission
    output complete, //Flag to show that uart has completed one whole transmission

    output [ADDRESS_SIZE:0] rbin_probe,
    output [ADDRESS_SIZE:0] wbin_probe,
    output [2:0] state_probe,
    output [6:0] byte_count_probe
);

wire [DATA_SIZE:0] buffer_out;
reg empty_b1, empty_b2;

always @(posedge clk) begin
    if (!rst_n)
        {empty_b2, empty_b1} <= 2'b00;
    else
        {empty_b2, empty_b1} <= {empty_b1, empty};
end

assign uart_start = ~empty & ~empty_b1 && ~empty_b2;

packet_logging #(.DATA_SIZE(DATA_SIZE), .BYTE_SIZE(BYTE_SIZE)) inst_pkt_logger(
    .rst_n(rst_n),
    .clk(clk),
    .start(uart_start),
    .complete(complete),

    .packet_data(buffer_out),
    .tx_out(uart_tx_out)
    // .state_probe(state_probe),
    // .byte_count_probe(byte_count_probe)
);

async_fifo #(.DSIZE(DATA_SIZE), .ASIZE(ADDRESS_SIZE)) inst_async_fifo_buffer (
    .i_wclk  (clk),
    .i_wrst_n(rst_n),
    .i_wr    (fp_det),
    .i_wdata (packet),
    .o_wfull (full),
    .i_rclk  (clk),
    .i_rrst_n(rst_n),
    .i_rd    (complete),
    .o_rdata (buffer_out),
    .o_rempty(empty)
    
    // .rbin_probe(rbin_probe),
    // .wbin_probe(wbin_probe)
);
endmodule