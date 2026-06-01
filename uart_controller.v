module uart_controller (
    input  wire clk_200_p,
    input  wire clk_200_n,
    input  wire reset_in,
    
    input  wire rx_in,
    input  wire CTS,
    output wire RTS,
    output wire tx_out 
    
);


wire clk;
wire clk_locked;

wire resetn_in;
assign resetn_in = ~reset_in;

wire rst_n;
assign rst_n = clk_locked & resetn_in;

wire rx_busy;
wire rx_done;
wire [7:0] rx_data_out;

reg [7:0] tx_data_in;
reg tx_send;
wire tx_done;
wire tx_busy;

assign RTS = 1'b0;

clk clk_wiz_inst (
    .CLK_IN1_P (clk_200_p),
    .CLK_IN1_N (clk_200_n),
    .CLK_OUT1  (clk), 
    .LOCKED    (clk_locked),
    .RESET     (reset_in)
);

uart uart_inst(
    .clk(clk),
    .rst_n(rst_n),

    .rx_in(rx_in),

    .rx_busy(rx_busy),
    .rx_done(rx_done),
    .rx_data_out(rx_data_out),

    .tx_data_in(tx_data_in),
    .tx_send(tx_send),

    .tx_out(tx_out),
    .tx_busy(tx_busy),
    .tx_done(tx_done)
);

localparam WAITING_Rx = 3'b000;
localparam RECEIVING = 3'b001;
localparam WAITING_Tx = 3'b010;
localparam SENDING = 3'b011;
localparam IDLE = 3'b100;

reg [2:0] state;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        tx_send <= 1'b0;
    end
    else begin
        case (state)
            IDLE: begin
                if (rx_busy) begin
                    state <= RECEIVING;
                end
            end
            RECEIVING: begin
                if (rx_done) begin
                    state <= WAITING_Tx;
                end
            end
            WAITING_Tx: begin
                tx_data_in <= rx_data_out;
                tx_send <= 1'b1;
                state <= SENDING;
            end
            SENDING: begin
                tx_send <= 1'b0;
                if (tx_done) begin
                    state <= IDLE;
                end
            end
            default: begin
                state <= IDLE;
                tx_send <= 1'b0;
            end
        endcase
    end 
end
    
endmodule