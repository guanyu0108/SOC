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
reg [17:0] cnt_1us;
reg        timeout_200ms; 
always @(posedge clk or negedge reset) begin
    if(reset)begin
        cnt_1us       <= 0;
        timeout_200ms <= 0;
    end else begin
        if(cnt_1us ==(200000-1))begin
            cnt_1us       <= 0;
            timeout_200ms <= 1'b1;
        end else begin
            cnt_1us       <= cnt_1us + 1'b1;
            timeout_200ms <= 1'b0;
        end
    end
end
//px_cnt
reg       cnt_1s;
reg       update_px;
reg [1:0] px_idx;
always @(posedge clk or negedge reset) begin
    if(reset)begin
        cnt_1s <= 0;
        px_idx <= 0;
    end else begin
        if(timeout_1s)begin
            if(cnt_1s)begin
                update_px <= 1'b1;
                cnt_1s    <= 0;
                if(px_idx == photo_num-1)begin
                    px_idx    <= 0;
                end else begin
                    px_idx    <= px_idx + 1'b1;
                end                    
            end else begin
                update_px <= 1'b0;
                cnt_1s    <= cnt_1s + 1'b1;
            end    
        end
    end
end
//1s timer
reg [8:0] cnt_200ms;
wire      timeout_1s = cnt_200ms == (500-1);
reg       trans_flag;
always @(posedge clk or posedge reset) begin
    if(reset)begin
        cnt_200ms  <= 0;
        trans_flag <= 0;
    end else begin
        if(timeout_200ms)begin
            if(cnt_200ms == (500-1))begin
                cnt_200ms  <= 0;
                trans_flag <= 1'b1;
            end else begin
                cnt_200ms  <= cnt_200ms + 1'b1;
            end
        end
    end
end
reg [3:0] hour;
reg [7:0] minute;
reg [7:0] second;
always @(posedge clk or negedge reset) begin
    if(reset)begin
        hour   <= 0;
        minute <= 0;
        second <= 0;
    end else begin
        if(im_read && (im_read_addr == 0))begin
            {hour, minute, second} <= IM_Q;
        end else begin
            if (timeout_1s) begin
                if(second == 59)begin
                    second <= 0;
                    if (minute == 59) begin
                        minute <= 0;
                        if (hour == 23) begin
                            hour <= 0;
                        end else begin
                            hour <= hour + 1'b1;
                        end
                    end else begin
                        minute <= minute + 1'b1;
                    end
                end else begin
                    second <= second + 1'b1;
                end
            end    
        end
    end
end

//time decode table
localparam OFFSET_0     = 9'd0;
localparam OFFSET_1     = 9'd24;
localparam OFFSET_2     = 9'd48;
localparam OFFSET_2     = 9'd72;
localparam OFFSET_4     = 9'd96;
localparam OFFSET_5     = 9'd120;
localparam OFFSET_6     = 9'd144;
localparam OFFSET_7     = 9'd168;
localparam OFFSET_8     = 9'd192;
localparam OFFSET_9     = 9'd216;
localparam OFFSET_COLON = 9'd240;
reg [8:0] s0;
reg [8:0] s1;
reg [8:0] m0;
reg [8:0] m1;
reg [8:0] h0;
reg [8:0] h1;
always @(second) begin
    case(second)
        7'd0: begin s1 = OFFSET_0; s0 = OFFSET_0; end
        7'd1: begin s1 = OFFSET_0; s0 = OFFSET_1; end
        7'd2: begin s1 = OFFSET_0; s0 = OFFSET_2; end
        7'd3: begin s1 = OFFSET_0; s0 = OFFSET_3; end
        7'd4: begin s1 = OFFSET_0; s0 = OFFSET_4; end
        7'd5: begin s1 = OFFSET_0; s0 = OFFSET_5; end
        7'd6: begin s1 = OFFSET_0; s0 = OFFSET_6; end
        7'd7: begin s1 = OFFSET_0; s0 = OFFSET_7; end
        7'd8: begin s1 = OFFSET_0; s0 = OFFSET_8; end
        7'd9: begin s1 = OFFSET_0; s0 = OFFSET_9; end
        7'd10:begin s1 = OFFSET_1; s0 = OFFSET_0; end
        7'd11:begin s1 = OFFSET_1; s0 = OFFSET_1; end
        7'd12:begin s1 = OFFSET_1; s0 = OFFSET_2; end
        7'd13:begin s1 = OFFSET_1; s0 = OFFSET_3; end
        7'd14:begin s1 = OFFSET_1; s0 = OFFSET_4; end
        7'd15:begin s1 = OFFSET_1; s0 = OFFSET_5; end
        7'd16:begin s1 = OFFSET_1; s0 = OFFSET_6; end
        7'd17:begin s1 = OFFSET_1; s0 = OFFSET_7; end
        7'd18:begin s1 = OFFSET_1; s0 = OFFSET_8; end
        7'd19:begin s1 = OFFSET_1; s0 = OFFSET_9; end
        7'd20:begin s1 = OFFSET_2; s0 = OFFSET_0; end
        7'd21:begin s1 = OFFSET_2; s0 = OFFSET_1; end
        7'd22:begin s1 = OFFSET_2; s0 = OFFSET_2; end
        7'd23:begin s1 = OFFSET_2; s0 = OFFSET_3; end
        7'd24:begin s1 = OFFSET_2; s0 = OFFSET_4; end
        7'd25:begin s1 = OFFSET_2; s0 = OFFSET_5; end
        7'd26:begin s1 = OFFSET_2; s0 = OFFSET_6; end
        7'd27:begin s1 = OFFSET_2; s0 = OFFSET_7; end
        7'd28:begin s1 = OFFSET_2; s0 = OFFSET_8; end
        7'd29:begin s1 = OFFSET_2; s0 = OFFSET_9; end
        7'd30:begin s1 = OFFSET_3; s0 = OFFSET_0; end
        7'd31:begin s1 = OFFSET_3; s0 = OFFSET_1; end
        7'd32:begin s1 = OFFSET_3; s0 = OFFSET_2; end
        7'd33:begin s1 = OFFSET_3; s0 = OFFSET_3; end
        7'd34:begin s1 = OFFSET_3; s0 = OFFSET_4; end
        7'd35:begin s1 = OFFSET_3; s0 = OFFSET_5; end
        7'd36:begin s1 = OFFSET_3; s0 = OFFSET_6; end
        7'd37:begin s1 = OFFSET_3; s0 = OFFSET_7; end
        7'd38:begin s1 = OFFSET_3; s0 = OFFSET_8; end
        7'd39:begin s1 = OFFSET_3; s0 = OFFSET_9; end
        7'd40:begin s1 = OFFSET_4; s0 = OFFSET_0; end
        7'd41:begin s1 = OFFSET_4; s0 = OFFSET_1; end
        7'd42:begin s1 = OFFSET_4; s0 = OFFSET_2; end
        7'd43:begin s1 = OFFSET_4; s0 = OFFSET_3; end
        7'd44:begin s1 = OFFSET_4; s0 = OFFSET_4; end
        7'd45:begin s1 = OFFSET_4; s0 = OFFSET_5; end
        7'd46:begin s1 = OFFSET_4; s0 = OFFSET_6; end
        7'd47:begin s1 = OFFSET_4; s0 = OFFSET_7; end
        7'd48:begin s1 = OFFSET_4; s0 = OFFSET_8; end
        7'd49:begin s1 = OFFSET_4; s0 = OFFSET_9; end
        7'd50:begin s1 = OFFSET_5; s0 = OFFSET_0; end
        7'd51:begin s1 = OFFSET_5; s0 = OFFSET_1; end
        7'd52:begin s1 = OFFSET_5; s0 = OFFSET_2; end
        7'd53:begin s1 = OFFSET_5; s0 = OFFSET_3; end
        7'd54:begin s1 = OFFSET_5; s0 = OFFSET_4; end
        7'd55:begin s1 = OFFSET_5; s0 = OFFSET_5; end
        7'd56:begin s1 = OFFSET_5; s0 = OFFSET_6; end
        7'd57:begin s1 = OFFSET_5; s0 = OFFSET_7; end
        7'd58:begin s1 = OFFSET_5; s0 = OFFSET_8; end
        7'd59:begin s1 = OFFSET_5; s0 = OFFSET_9; end
        default:begin s1 = 0; s0 = 0; end
    endcase
end

always @(minute) begin
    case(minute)
        7'd0: begin m1 = OFFSET_0; m0 = OFFSET_0; end
        7'd1: begin m1 = OFFSET_0; m0 = OFFSET_1; end
        7'd2: begin m1 = OFFSET_0; m0 = OFFSET_2; end
        7'd3: begin m1 = OFFSET_0; m0 = OFFSET_3; end
        7'd4: begin m1 = OFFSET_0; m0 = OFFSET_4; end
        7'd5: begin m1 = OFFSET_0; m0 = OFFSET_5; end
        7'd6: begin m1 = OFFSET_0; m0 = OFFSET_6; end
        7'd7: begin m1 = OFFSET_0; m0 = OFFSET_7; end
        7'd8: begin m1 = OFFSET_0; m0 = OFFSET_8; end
        7'd9: begin m1 = OFFSET_0; m0 = OFFSET_9; end
        7'd10:begin m1 = OFFSET_1; m0 = OFFSET_0; end
        7'd11:begin m1 = OFFSET_1; m0 = OFFSET_1; end
        7'd12:begin m1 = OFFSET_1; m0 = OFFSET_2; end
        7'd13:begin m1 = OFFSET_1; m0 = OFFSET_3; end
        7'd14:begin m1 = OFFSET_1; m0 = OFFSET_4; end
        7'd15:begin m1 = OFFSET_1; m0 = OFFSET_5; end
        7'd16:begin m1 = OFFSET_1; m0 = OFFSET_6; end
        7'd17:begin m1 = OFFSET_1; m0 = OFFSET_7; end
        7'd18:begin m1 = OFFSET_1; m0 = OFFSET_8; end
        7'd19:begin m1 = OFFSET_1; m0 = OFFSET_9; end
        7'd20:begin m1 = OFFSET_2; m0 = OFFSET_0; end
        7'd21:begin m1 = OFFSET_2; m0 = OFFSET_1; end
        7'd22:begin m1 = OFFSET_2; m0 = OFFSET_2; end
        7'd23:begin m1 = OFFSET_2; m0 = OFFSET_3; end
        7'd24:begin m1 = OFFSET_2; m0 = OFFSET_4; end
        7'd25:begin m1 = OFFSET_2; m0 = OFFSET_5; end
        7'd26:begin m1 = OFFSET_2; m0 = OFFSET_6; end
        7'd27:begin m1 = OFFSET_2; m0 = OFFSET_7; end
        7'd28:begin m1 = OFFSET_2; m0 = OFFSET_8; end
        7'd29:begin m1 = OFFSET_2; m0 = OFFSET_9; end
        7'd30:begin m1 = OFFSET_3; m0 = OFFSET_0; end
        7'd31:begin m1 = OFFSET_3; m0 = OFFSET_1; end
        7'd32:begin m1 = OFFSET_3; m0 = OFFSET_2; end
        7'd33:begin m1 = OFFSET_3; m0 = OFFSET_3; end
        7'd34:begin m1 = OFFSET_3; m0 = OFFSET_4; end
        7'd35:begin m1 = OFFSET_3; m0 = OFFSET_5; end
        7'd36:begin m1 = OFFSET_3; m0 = OFFSET_6; end
        7'd37:begin m1 = OFFSET_3; m0 = OFFSET_7; end
        7'd38:begin m1 = OFFSET_3; m0 = OFFSET_8; end
        7'd39:begin m1 = OFFSET_3; m0 = OFFSET_9; end
        7'd40:begin m1 = OFFSET_4; m0 = OFFSET_0; end
        7'd41:begin m1 = OFFSET_4; m0 = OFFSET_1; end
        7'd42:begin m1 = OFFSET_4; m0 = OFFSET_2; end
        7'd43:begin m1 = OFFSET_4; m0 = OFFSET_3; end
        7'd44:begin m1 = OFFSET_4; m0 = OFFSET_4; end
        7'd45:begin m1 = OFFSET_4; m0 = OFFSET_5; end
        7'd46:begin m1 = OFFSET_4; m0 = OFFSET_6; end
        7'd47:begin m1 = OFFSET_4; m0 = OFFSET_7; end
        7'd48:begin m1 = OFFSET_4; m0 = OFFSET_8; end
        7'd49:begin m1 = OFFSET_4; m0 = OFFSET_9; end
        7'd50:begin m1 = OFFSET_5; m0 = OFFSET_0; end
        7'd51:begin m1 = OFFSET_5; m0 = OFFSET_1; end
        7'd52:begin m1 = OFFSET_5; m0 = OFFSET_2; end
        7'd53:begin m1 = OFFSET_5; m0 = OFFSET_3; end
        7'd54:begin m1 = OFFSET_5; m0 = OFFSET_4; end
        7'd55:begin m1 = OFFSET_5; m0 = OFFSET_5; end
        7'd56:begin m1 = OFFSET_5; m0 = OFFSET_6; end
        7'd57:begin m1 = OFFSET_5; m0 = OFFSET_7; end
        7'd58:begin m1 = OFFSET_5; m0 = OFFSET_8; end
        7'd59:begin m1 = OFFSET_5; m0 = OFFSET_9; end
        default:begin m1 = 0; m0 = 0; end
    endcase
end

always @(hour) begin
    case(hour)
        7'd0: begin h1 = OFFSET_0; h0 = OFFSET_0; end
        7'd1: begin h1 = OFFSET_0; h0 = OFFSET_1; end
        7'd2: begin h1 = OFFSET_0; h0 = OFFSET_2; end
        7'd3: begin h1 = OFFSET_0; h0 = OFFSET_3; end
        7'd4: begin h1 = OFFSET_0; h0 = OFFSET_4; end
        7'd5: begin h1 = OFFSET_0; h0 = OFFSET_5; end
        7'd6: begin h1 = OFFSET_0; h0 = OFFSET_6; end
        7'd7: begin h1 = OFFSET_0; h0 = OFFSET_7; end
        7'd8: begin h1 = OFFSET_0; h0 = OFFSET_8; end
        7'd9: begin h1 = OFFSET_0; h0 = OFFSET_9; end
        7'd10:begin h1 = OFFSET_1; h0 = OFFSET_0; end
        7'd11:begin h1 = OFFSET_1; h0 = OFFSET_1; end
        7'd12:begin h1 = OFFSET_1; h0 = OFFSET_2; end
        7'd13:begin h1 = OFFSET_1; h0 = OFFSET_3; end
        7'd14:begin h1 = OFFSET_1; h0 = OFFSET_4; end
        7'd15:begin h1 = OFFSET_1; h0 = OFFSET_5; end
        7'd16:begin h1 = OFFSET_1; h0 = OFFSET_6; end
        7'd17:begin h1 = OFFSET_1; h0 = OFFSET_7; end
        7'd18:begin h1 = OFFSET_1; h0 = OFFSET_8; end
        7'd19:begin h1 = OFFSET_1; h0 = OFFSET_9; end
        7'd20:begin h1 = OFFSET_2; h0 = OFFSET_0; end
        7'd21:begin h1 = OFFSET_2; h0 = OFFSET_1; end
        7'd22:begin h1 = OFFSET_2; h0 = OFFSET_2; end
        7'd23:begin h1 = OFFSET_2; h0 = OFFSET_3; end
        7'd24:begin h1 = OFFSET_2; h0 = OFFSET_4; end
        7'd25:begin h1 = OFFSET_2; h0 = OFFSET_5; end
        7'd26:begin h1 = OFFSET_2; h0 = OFFSET_6; end
        7'd27:begin h1 = OFFSET_2; h0 = OFFSET_7; end
        7'd28:begin h1 = OFFSET_2; h0 = OFFSET_8; end
        7'd29:begin h1 = OFFSET_2; h0 = OFFSET_9; end
        7'd30:begin h1 = OFFSET_3; h0 = OFFSET_0; end
        7'd31:begin h1 = OFFSET_3; h0 = OFFSET_1; end
        7'd32:begin h1 = OFFSET_3; h0 = OFFSET_2; end
        7'd33:begin h1 = OFFSET_3; h0 = OFFSET_3; end
        7'd34:begin h1 = OFFSET_3; h0 = OFFSET_4; end
        7'd35:begin h1 = OFFSET_3; h0 = OFFSET_5; end
        7'd36:begin h1 = OFFSET_3; h0 = OFFSET_6; end
        7'd37:begin h1 = OFFSET_3; h0 = OFFSET_7; end
        7'd38:begin h1 = OFFSET_3; h0 = OFFSET_8; end
        7'd39:begin h1 = OFFSET_3; h0 = OFFSET_9; end
        7'd40:begin h1 = OFFSET_4; h0 = OFFSET_0; end
        7'd41:begin h1 = OFFSET_4; h0 = OFFSET_1; end
        7'd42:begin h1 = OFFSET_4; h0 = OFFSET_2; end
        7'd43:begin h1 = OFFSET_4; h0 = OFFSET_3; end
        7'd44:begin h1 = OFFSET_4; h0 = OFFSET_4; end
        7'd45:begin h1 = OFFSET_4; h0 = OFFSET_5; end
        7'd46:begin h1 = OFFSET_4; h0 = OFFSET_6; end
        7'd47:begin h1 = OFFSET_4; h0 = OFFSET_7; end
        7'd48:begin h1 = OFFSET_4; h0 = OFFSET_8; end
        7'd49:begin h1 = OFFSET_4; h0 = OFFSET_9; end
        7'd50:begin h1 = OFFSET_5; h0 = OFFSET_0; end
        7'd51:begin h1 = OFFSET_5; h0 = OFFSET_1; end
        7'd52:begin h1 = OFFSET_5; h0 = OFFSET_2; end
        7'd53:begin h1 = OFFSET_5; h0 = OFFSET_3; end
        7'd54:begin h1 = OFFSET_5; h0 = OFFSET_4; end
        7'd55:begin h1 = OFFSET_5; h0 = OFFSET_5; end
        7'd56:begin h1 = OFFSET_5; h0 = OFFSET_6; end
        7'd57:begin h1 = OFFSET_5; h0 = OFFSET_7; end
        7'd58:begin h1 = OFFSET_5; h0 = OFFSET_8; end
        7'd59:begin h1 = OFFSET_5; h0 = OFFSET_9; end
        default:begin h1 = 0; h0 = 0; end
    endcase
end
//===================FSM===========================
localparam IDLE             = 3'd0;
localparam GET_HEADER       = 3'd1;
localparam SHOW_INIT_TIME   = 3'd2;
localparam SHOW_P1          = 3'd3;
localparam WAIT_UPDATE_TIME = 3'd4;
localparam SHOW_TIME        = 3'd5;
localparam PX_TRANS1        = 3'd6;
localparam PX_TRANS2        = 3'd7;

reg [2:0] state;
reg [2:0] next_state;
//=================FSM state register==============
always @(posedge clk or posedge reset) begin
    if(reset)begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end
//==============FSM next state logic==================
always @* begin
    case(state)
        IDLE:next_state = GET_HEADER;
        GET_HEADER:begin
            if(get_header_done)
                next_state = SHOW_TIME;
            else
                next_state = GET_HEADER;
        end 
        SHOW_INIT_TIME:begin
            if(show_time_done)
                next_state = SHOW_P1;
            else 
                next_state = SHOW_INIT_TIME;
        end 
        SHOW_P1:begin
            if(p1_done)
                next_state = WAIT_UPDATE;
            else
                next_state = SHOW_P1;
        end 
        WAIT_UPDATE_TIME:begin
            if(timeout_1s)
                next_state = SHOW_TIME;
            else
                next_state = WAIT_UPDATE_TIME;
        end 
        SHOW_TIME:begin
            if(!show_time_done)begin
                next_state = SHOW_TIME;
            end else if (update_px) begin
                next_state = PX_TRANS1;
            end else begin
                next_state = WAIT_UPDATE_TIME;
            end
        end 
        PX_TRANS1:begin
            if(trans1_done)
                next_state = PX_TRANS2;
            else
                next_state = PX_TRANS1;
        end
        PX_TRANS2:begin
            if(trans2_done)
                next_state = WAIT_UPDATE;
            else
                next_state = PX_TRANS2;
        end
    endcase
end
//==============FSM output logic==================
wire   get_header_en;
assign get_header_en = (state == GET_HEADER);


//get header logic
reg [3:0] header_cnt;
reg       get_header_done;
always @(posedge clk or negedge reset) begin
    if(reset)begin
        header_cnt      <= 0;
        get_header_done <= 0;
    end else begin
        if(get_header_en)begin
            if(header_cnt == 10)begin
                get_header_done <= 1'b1;
            end else begin
                header_cnt <= header_cnt + 1'b1;
            end
        end
    end
end
//===========show time logic===========


reg [23:0] frame_buffer[0:65535];
always @(posedge clk or posedge reset) begin
    if(frame_valid)begin
    end
    if(resize == 1)begin//zoom in

    end else if(resize == 2)begin//zoom out

    end else begin//nothing
        frame_buffer[i] = IM_Q; 
    end
end
reg [15:0] pixel_cnt;
always @(posedge clk or posedge reset) begin
    pixel_cnt += 1;
    pixel_cnt += 2;
end
reg pixel_o = frame_buffer[]
always @(posedge clk or posedge reset) begin
    
end
//address and write data arbitrator

output [19:0] IM_A;
input  [23:0] IM_Q;
output [23:0] IM_D;
output        IM_WEN;
output  [8:0] CR_A;
input  [12:0] CR_Q;

assign IM_A = ()?header_cnt:;
assign IM_WEN = ()?get_header_en:;
always @* begin
    case()

    endcase
end

always @() begin
    
end
endmodule
