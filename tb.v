`timescale 1ns/1ps
module tb;
    reg x, y;
    wire s, c;

    initial begin
    x = 0;
    y = 0;
    #5;
    $display("s=%d, c=%d", s, c);
    x = 1;
    y = 0;
    #5;
    $display("s=%d, c=%d", s, c);
    x = 0;
    y = 1;
    #5;
    $display("s=%d, c=%d", s, c);
    x = 1;
    y = 1;
    #5;
    $display("s=%d, c=%d", s, c);    

    $finish;
    end
    half_adder DUT(x, y, s, c);
endmodule