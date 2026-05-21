module data_logger_tb ();

logic clk;
logic rst_n;
logic tx_out;
logic done;
logic [2:0] state_probe;
logic [5:0] data_index_probe;
logic [2:0] bcd_index_probe;
logic update;
logic [4:0] tenk;
logic [4:0] thousands;
logic [4:0] hundreds;
logic [4:0] tens;
logic [4:0] units;

logic [15:0] fp_num0;
logic [15:0] fp_num1;
logic [15:0] fp_num2;
logic [15:0] fp_num3;
logic [15:0] fp_num4;
logic [15:0] fp_num5;
logic [15:0] fp_num6;
logic [15:0] fp_num7;
logic [15:0] fp_num8;
logic [15:0] fp_num9;
logic [15:0] fp_num10;
logic [15:0] fp_num11;
logic [15:0] fp_num12;
logic [15:0] fp_num13;
logic [15:0] fp_num14;
logic [15:0] fp_num15;
logic [15:0] fp_num16;
logic [15:0] fp_num17;

data_logging #(
    .TRANS_DELAY(1000000)
) inst_logger (
    .rst_n(rst_n),
    .clk(clk),
    .update(update),

    .fp_num0(fp_num0),   .fp_num1(fp_num1),
    .fp_num2(fp_num2),   .fp_num3(fp_num3),
    .fp_num4(fp_num4),   .fp_num5(fp_num5),
    .fp_num6(fp_num6),   .fp_num7(fp_num7),
    .fp_num8(fp_num8),   .fp_num9(fp_num9),
    .fp_num10(fp_num10), .fp_num11(fp_num11),
    .fp_num12(fp_num12), .fp_num13(fp_num13),
    .fp_num14(fp_num14), .fp_num15(fp_num15),
    .fp_num16(fp_num16), .fp_num17(fp_num17),

    .tx_out(tx_out),
    .done(done),

    .state_probe(state_probe),
    .data_index_probe(data_index_probe),
    .bcd_index_probe(bcd_index_probe),
    .tenk(tenk),
    .thousands(thousands),
    .hundreds(hundreds),
    .tens(tens),
    .units(units)

);

initial begin
    clk = 0;
    forever #2.5 clk = ~clk; // 200mhz
end
// logic counter;
initial begin
    fp_num0 = 16'd10;
    fp_num1 = 16'd30;
    fp_num2 = 16'd40;
    fp_num3 = 16'd50;
    fp_num4 = 16'd60;
    fp_num5 = 16'd70;
    fp_num6 = 16'd80;
    fp_num7 = 16'd90;
    fp_num8 = 16'd100;
    fp_num9 = 16'd110;
    fp_num10 = 16'd120;
    fp_num11 = 16'd130;
    fp_num12 = 16'd140;
    fp_num13 = 16'd150;
    fp_num14 = 16'd160;
    fp_num15 = 16'd170;
    fp_num16 = 16'd180;
    fp_num17 = 16'd190;

    rst_n = 0;
    @(posedge clk);
    rst_n = 1;

    wait(done);

    #100;
    $stop;
end


endmodule