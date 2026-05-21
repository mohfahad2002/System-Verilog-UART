module packet_logging #(
    parameter CLK_FREQ  = 200_000_000,  // System clock frequency
    parameter BAUD_RATE = 115200,       // UART baud rate
    parameter TRANS_DELAY = 600000000,
    parameter DATA_SIZE = 479,     //Delay = Time delay in seconds * CLK_FREQ
    parameter BYTE_SIZE = 60
)(
    input clk,
    input rst_n,
    input start,

    input [DATA_SIZE:0] packet_data,
    
    output reg complete,
    output tx_out,

    output [2:0] state_probe,
    output [6:0] byte_count_probe,
    output [8:0] byte_count_start_probe,

    output [4:0] tenk,
    output [4:0] thousands,
    output [4:0] hundreds,
    output [4:0] tens,
    output [4:0] units
);

reg transmission_send;
reg [7:0] tx_data;
wire transmission_done;

uart_tx tx_inst(
    .data_in(tx_data),
    .clk(clk),
    .rst_n(rst_n),
    .send(transmission_send),
    .done(transmission_done),
    .tx_out(tx_out)
);


localparam [2:0] START_TRANSMISSION = 3'b000;
localparam [2:0] TRANSMIT = 3'b001;
localparam [2:0] IDLE = 3'b111;
// localparam [8:0] table_size = DATA_SIZE;

reg [2:0] state;
reg [6:0] byte_count; //Counting the number of packets sent
reg [8:0] byte_count_start; //Used to find the starting index of data to send
reg [DATA_SIZE:0] in_data_buffer;

always @(posedge clk) begin
    if (!rst_n) begin
        state <= IDLE;
        byte_count_start <= 0;
        byte_count <= 0;
        complete <= 0;
    end
    else begin
        if (start && state == IDLE) begin
            state <= START_TRANSMISSION;
            in_data_buffer <= packet_data;
            byte_count_start <= 0;
            byte_count <= 0;
            complete <= 1'b0;
        end
        else begin
            case(state) 
                START_TRANSMISSION: begin
                    if (byte_count < BYTE_SIZE) begin
                        tx_data <= in_data_buffer[DATA_SIZE - byte_count_start -: 8];
                        transmission_send <= 1'b1;
                        state <= TRANSMIT;
                        byte_count_start <= byte_count_start + 8;
                        byte_count <= byte_count + 1;
                    end
                    else begin
                        state <= IDLE;
                        complete <= 1'b0;
                    end
                end
                TRANSMIT: begin
                    if (transmission_done) begin
                        state <= START_TRANSMISSION;
                        transmission_send <= 1'b0;

                        if (byte_count >= BYTE_SIZE) begin
                            complete <= 1'b1;
                        end
                    end
                end
                IDLE: begin
                    byte_count_start <= 0;
                    byte_count <= 0;
                    complete <= 1'b0;
                end
            endcase
        end

    end
end

assign byte_count_probe = byte_count;
assign byte_count_start_probe = byte_count_start;
assign state_probe = state;
endmodule