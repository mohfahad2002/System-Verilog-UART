module uart_test(
    input clk_in_p,
    input clk_in_n,
    input reset_in,
    input CTS,
    
    output RTS,
    output done,
    output rst_n,
    output uart_tx_out
);

clk clk_wiz_inst (
    .CLK_IN1_P (clk_in_p),
    .CLK_IN1_N (clk_in_n),
    .CLK_OUT1  (clk_200), // Internal logic
    .LOCKED    (clk_locked),
    .RESET     (reset_in)
);

reg send;
wire done;

wire [7:0] tx_data;

assign tx_data = 8'd65;
assign RTS = 1'b0;
assign rst_n = clk_locked & (~reset_in);

reg [32:0] clock_cnt;
reg clk_check;
//Send the data after every second
always @(posedge clk_200) begin
    if (!rst_n) begin
        clock_cnt <= 0;
        clk_check <= 0;
    end
    else begin
        if (clock_cnt == 2000000) begin
            clock_cnt <= 0;
            send <= 1;
        end
        else begin
            clock_cnt <= clock_cnt + 1;
            send <= 0;
        end
        clk_check <= ~clk_check;
    end 
end

wire busy;
wire baud16_clk;

uart_tx tx_inst(
    .data_in(tx_data),
    .clk(clk_200),
    .rst_n(rst_n),
    .send(send),
    .done(done),
    .tx_out(uart_tx_out),
    .busy(busy),
    .baud16_clk(baud16_clk)
);

wire [35:0] control0;

// ICON instance
uart_test_icon icon_inst (
    .CONTROL0(control0)
);

uart_test_ila ila_inst (
    .CONTROL(control0),
    .CLK(clk_200),
    .TRIG0(send),
    .TRIG1(done),
    .TRIG2(busy),
    .TRIG3(tx_data),
    .TRIG4 (clock_cnt)
);
endmodule



