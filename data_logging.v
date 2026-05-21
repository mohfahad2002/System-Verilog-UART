module data_logging #(
    parameter CLK_FREQ  = 200_000_000,  // System clock frequency
    parameter BAUD_RATE = 115200,       // UART baud rate
    parameter TRANS_DELAY = 600000000     //Delay = Time delay in seconds * CLK_FREQ
)(
    input rst_n,
    input clk,

    input [15:0] fp_num0,
    input [15:0] fp_num1,
    input [15:0] fp_num2,
    input [15:0] fp_num3,
    input [15:0] fp_num4,
    input [15:0] fp_num5,
    input [15:0] fp_num6,
    input [15:0] fp_num7,
    input [15:0] fp_num8,
    input [15:0] fp_num9,
    input [15:0] fp_num10,
    input [15:0] fp_num11,
    input [15:0] fp_num12,
    input [15:0] fp_num13,
    input [15:0] fp_num14,
    input [15:0] fp_num15,
    input [15:0] fp_num16,
    input [15:0] fp_num17,

    output tx_out,
    output reg busy,
    output reg done,
    output reg update,

    output [2:0] state_probe,
    output [5:0] data_index_probe,
    output [2:0] bcd_index_probe,

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

reg conversion_start;
reg [15:0] conversion_data;
wire [3:0] bcd_buffer [0:4];
wire conversion_done;

bin2bcd inst_bcd(
    .clk(clk),
    .start(conversion_start),
    .rst_n(rst_n),
    .binary(conversion_data),
    .ten_thousands(bcd_buffer[0]),
    .thousands(bcd_buffer[1]),
    .hundreds(bcd_buffer[2]),
    .tens(bcd_buffer[3]),
    .units(bcd_buffer[4]),
    .done(conversion_done)
);

reg [15:0] data_buffer [0:17]; //Only using 2 registers right now

reg [32:0] clock_cnt;
always @(posedge clk) begin
    if (!rst_n) begin
        clock_cnt <= 32'b0;
        data_buffer[0] <= 16'b0;
        data_buffer[1] <= 16'b0;
        data_buffer[2] <= 16'b0;
        data_buffer[3] <= 16'b0;
        data_buffer[4] <= 16'b0;
        data_buffer[5] <= 16'b0;
        data_buffer[6] <= 16'b0;
        data_buffer[7] <= 16'b0;
        data_buffer[8] <= 16'b0;
        data_buffer[9] <= 16'b0;
        data_buffer[10] <= 16'b0;
        data_buffer[11] <= 16'b0;
        data_buffer[12] <= 16'b0;
        data_buffer[13] <= 16'b0;
        data_buffer[14] <= 16'b0;
        data_buffer[15] <= 16'b0;
        data_buffer[16] <= 16'b0;
        data_buffer[17] <= 16'b0;
        update <= 1'b0;
    end
    else begin
        if (clock_cnt == TRANS_DELAY) begin
            clock_cnt <= 1'b0;
            data_buffer[0] <= fp_num0;
            data_buffer[1] <= fp_num1;
            data_buffer[2] <= fp_num2;
            data_buffer[3] <= fp_num3;
            data_buffer[4] <= fp_num4;
            data_buffer[5] <= fp_num5;
            data_buffer[6] <= fp_num6;
            data_buffer[7] <= fp_num7;
            data_buffer[8] <= fp_num8;
            data_buffer[9] <= fp_num9;
            data_buffer[10] <= fp_num10;
            data_buffer[11] <= fp_num11;
            data_buffer[12] <= fp_num12;
            data_buffer[13] <= fp_num13;
            data_buffer[14] <= fp_num14;
            data_buffer[15] <= fp_num15;
            data_buffer[16] <= fp_num16;
            data_buffer[17] <= fp_num17;
            update <= 1'b1; 
        end
        else begin
            clock_cnt <= clock_cnt + 1;
            update <= 1'b0;
        end
    end
end

localparam integer START_CONVERSION = 4'b000;
localparam integer CONVERT = 4'b001;
localparam integer START_TRANSMISSION = 4'b010;
localparam integer TRANSMIT = 3'b011;
localparam integer NEWLINE = 3'b100;
localparam integer IDLE = 3'b111;

reg [2:0] state;
reg [5:0] data_index;
reg [2:0] bcd_index;
reg new_line; 
always @(posedge clk) begin
    if (!rst_n) begin
        data_index <= 0;
        state <= IDLE;
        bcd_index <= 0;
        done <= 1'b0;
        new_line <= 0;
    end
    else begin
        if (update && state == IDLE) begin
            bcd_index <= 0;
            data_index <= 0;
            state <= START_CONVERSION;
            new_line <= 0;
        end

        case (state)
        START_CONVERSION: begin
            if (data_index == 18) begin
                bcd_index <= 1'b0;
                state <= NEWLINE;
            end
            else if (data_index > 18) begin
                data_index <= 0;
                done <= 1'b1;
                state <= IDLE;
            end
            else begin
                conversion_data <= data_buffer[data_index];
                conversion_start <= 1'b1;
                state <= CONVERT;
            end
        end
        CONVERT: begin
            if (conversion_done) begin //wait for hex to bcd conversion
                state <= START_TRANSMISSION;
            end
        end
        START_TRANSMISSION: begin
            if (bcd_index == 5) begin
                state <= NEWLINE;
                bcd_index <= 1'b0;
                // done <= 1'b1;
            end
            else begin
                tx_data <= bcd_buffer[bcd_index] + 8'd48; //ascii = bcd + 48
                transmission_send <= 1'b1;
                state <= TRANSMIT;
            end
        end
        TRANSMIT: begin
            if (transmission_done) begin
                if (new_line) begin
                    state <= START_CONVERSION;
                    transmission_send <= 1'b0;
                    data_index <= data_index + 1;
                    new_line <= 1'b0;
                end
                else begin
                    state <= START_TRANSMISSION;
                    transmission_send <= 1'b0;
                    bcd_index <= bcd_index + 1;
                end
            end
        end
        NEWLINE: begin
            tx_data <= 8'd10; //ASCII character for new line
            transmission_send <= 1'b1; 
            new_line <= 1'b1;
            state <= TRANSMIT;
        end
        IDLE: begin
            // data_index <= 1'b0;
            bcd_index <= 1'b0;
            done <= 1'b0;
            new_line <= 1'b0;
        end
        endcase

    end
end

assign state_probe = state;
assign bcd_index_probe = bcd_index;
assign data_index_probe = data_index;
assign tenk = bcd_buffer[0];
assign thousands = bcd_buffer[1];
assign hundreds = bcd_buffer[2];
assign tens = bcd_buffer[3];
assign units = bcd_buffer[4];
endmodule
