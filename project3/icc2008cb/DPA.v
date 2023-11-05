module DPA (
    clk,//1Mhz = 0.000001s = 0.001ms = 1us = 1000ns
    reset,
    IM_A,
    IM_Q,
    IM_D,
    IM_WEN,
    CR_A,
    CR_Q
);
input         clk;
input         reset;
output [19:0] IM_A;
input  [23:0] IM_Q;
output [23:0] IM_D;
output        IM_WEN;
output  [8:0] CR_A;
input  [12:0] CR_Q;

//==========user code=============
reg [23:0] init_time;    //offset = 0
reg [23:0] fb_addr;      //offset = 1
reg [23:0] photo_num;    //offset = 2
reg [23:0] p1_addr;      //offset = 3
reg [23:0] p1_szie;      //offset = 4
reg [23:0] p2_addr;      //offset = 5
reg [23:0] p2_szie;      //offset = 6
reg [23:0] p3_addr;      //offset = 7
reg [23:0] p3_szie;      //offset = 8
reg [23:0] p4_addr;      //offset = 9
reg [23:0] p4_szie;      //offset = 10

reg        im_read;
reg [19:0] im_read_addr;
//make read command and read address delay one cycle 
//to match the protocol of the memory read.
always @(posedge clk or posedge reset) begin
    if(reset)begin
        im_read      <= 0;
        im_read_addr <= 0;
    end else begin
        im_read      <= IM_WEN;
        im_read_addr <= IM_A;
    end
end
//get image memory header
always @(posedge clk or posedge reset) begin
    if(reset)begin
        init_time <= 0;
        fb_addr   <= 0;
        photo_num <= 0;
        p1_addr   <= 0;
        p1_szie   <= 0;
        p2_addr   <= 0;
        p2_szie   <= 0;
        p3_addr   <= 0;
        p3_szie   <= 0;
        p4_addr   <= 0;
        p4_szie   <= 0;
    end else begin
        if (im_read) begin
            case(im_read_addr)
                0: init_time <= IM_Q;
                1: fb_addr   <= IM_Q;
                2: photo_num <= IM_Q;
                3: p1_addr   <= IM_Q;
                4: p1_szie   <= IM_Q;
                5: p2_addr   <= IM_Q;
                6: p2_szie   <= IM_Q;
                7: p3_addr   <= IM_Q;
                8: p3_szie   <= IM_Q;
                9: p4_addr   <= IM_Q;
                10:p4_szie   <= IM_Q;
            endcase
        end
    end
end

//1 second timer, when reach 1 second it will trigger a pulse 
reg [3:0] hour[0:1];
reg [7:0] minute[0:1];
reg [7:0] second[0:1];

//200ms timer
reg [17:0] cnt_200ms;
reg        timeout_200ms; 
always @(posedge clk or negedge reset) begin
    if(reset)begin
        cnt_200ms     <= 0;
        timeout_200ms <= 0;
    end else begin
        if(cnt_200ms ==(200000-1))begin
            cnt_200ms     <= 0;
            timeout_200ms <= 1'b1;
        end else begin
            cnt_200ms     <= cnt_200ms+1;
            timeout_200ms <= 1'b0;
        end
    end
end

//1s timer
reg [8:0] cnt_1s;
reg       timeout_1s;
always @(posedge clk or posedge reset) begin
    if(reset)begin
        cnt_1s     <= 0;
        timeout_1s <= 0;
    end else begin
        if(timeout_200ms)begin
            if(cnt_1s == (500-1))begin
                cnt_1s     <= 0;
                timeout_1s <= 1'b1;
            end else begin
                cnt_1s     <= cnt_1s+1;
                timeout_1s <= 1'b0;
            end
        end
    end
end

always @(posedge clk or negedge reset) begin
    if(reset)begin
        hour   <= 0;
        minute <= 0;
        second <= 0;
    end else begin
        if(im_read && (im_read_addr == 0))begin
            {hour, minute, second} = IM_Q;
        end else begin
            if()begin
            end    
        end
    end
end
wire pixel_buffer;
//write fram bufffer logic
endmodule
