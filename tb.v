`timescale 1ns/1ps
module tb;
    reg x, y;
    wire s, c;

    initial begin
        x = 0;
        y = 0;
        #5;
        $display("s=%d, c=%d", s, c); // =0
        x = 1;
        y = 0;
        #5;
        $display("s=%d, c=%d", s, c); // = 1
        x = 0;
        y = 1;
        #5;
        $display("s=%d, c=%d", s, c); // =1
        x = 1;
        y = 1;
        #5;
        $display("s=%d, c=%d", s, c);  // = 1 1 

        $finish;
    end
    half_adder DUT(x, y, s, c);
endmodule