module packet_logger_tb();

logic clk;
logic rst_n;
logic start;

logic [479:0] packet_data;
logic complete;
logic tx_out;
logic [2:0] state_probe;
logic [6:0] byte_count_probe;
logic [8:0] byte_count_start_probe;

packet_logging packet_logging_inst(
    .clk(clk),
    .rst_n(rst_n),
    .start(start),

    .packet_data(packet_data),
    
    .complete(complete),
    .tx_out(tx_out),

    .state_probe(state_probe),
    .byte_count_probe(byte_count_probe),
    .byte_count_start_probe(byte_count_start_probe)
);

initial begin
    clk = 0;
    forever #2.5 clk = ~clk; // 200mhz
end

initial begin
    packet_data = $urandom_range(480'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, 0);
    rst_n = 0;
    start = 1;
    @(posedge clk);
    rst_n = 1;

    wait(complete);

    #100;
    $stop;
end

endmodule