`timescale 1ns/1ps

module buffer_logger_tb ();
localparam ADDRESS_SIZE = 7;

logic clk;
logic rst_n;
logic fp_det;

logic [455:0] packet;
logic complete;
logic uart_tx_out;
logic full;
logic empty;
logic [ADDRESS_SIZE:0] rbin_probe;
logic [ADDRESS_SIZE:0] wbin_probe;
logic [2:0] state_probe;
logic [6:0] byte_count_probe;
logic uart_start;

buffer_packet_logger #(
    .ADDRESS_SIZE(ADDRESS_SIZE)
)
buffer_logger_inst (
    .packet(packet),
    .rst_n(rst_n),
    .clk(clk),
    .fp_det(fp_det),
    .full(full),
    .uart_tx_out(uart_tx_out),
    .empty(empty),
    .wbin_probe(wbin_probe),
    .rbin_probe(rbin_probe),
    .state_probe(state_probe),
    .byte_count_probe(byte_count_probe),
    .complete(complete),
    .uart_start(uart_start)
);

initial begin
    clk = 0;
    forever #2.5 clk = ~clk; // 200mhz
end

initial begin
    rst_n = 0;
    @(posedge clk);
    packet = $urandom_range(455'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, 0);
    rst_n = 1;
    fp_det = 1;
    @(posedge clk);
    
    
    
    // @(posedge clk);
    packet = $urandom_range(455'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, 0);
    fp_det = 1;
    @(posedge clk);
    fp_det = 0;
    wait(complete);
    @(posedge clk);
    @(posedge clk);

    packet = $urandom_range(455'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, 0);
    fp_det = 1;
    @(posedge clk);
    fp_det = 0;
    // @(posedge clk);
    // @(posedge clk);
    // @(posedge clk);
    // @(posedge clk);
    wait(complete);
    @(posedge clk);
    @(posedge clk);
    wait(complete);

    #100;
    $stop;
end


endmodule