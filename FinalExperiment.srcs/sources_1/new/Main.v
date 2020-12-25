`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/11/12 12:06:49
// Design Name: 
// Module Name: Main
// Project Name: VGA-eye-chart
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module setclk( //将clk四分频
input clk, //100MHz
input rst,
output reg clk_vga  //25MHz
    );
reg clk_temp;
always@(posedge clk,posedge rst) //实现clk信号二分频到ckl_temp
begin
    if(rst)
        clk_temp<=0;
    else clk_temp<=~clk_temp;
end
always@(posedge clk_temp,posedge rst)  //将ckl_temp二分频到clk_vga,最终使clk信号四分频
begin
    if(rst)
        clk_vga<=0;
    else clk_vga<=~clk_vga;
end
endmodule


module vga_top(
input clk,  //系统时钟
input rst,  //时钟复位端
input [1:0] r,    //选择行
input [1:0] c,    //选择列
output [2:0] disp_RGB,
output hs,  //行同步信号 换行的时钟信号
output vs   //场同步信号 换帧的时钟信号
);
reg [9:0] hcnt; //行扫描计数器
reg [9:0] vcnt; //场扫描计数器
reg [2:0] data; //数据
wire vga_clk; //将要生成的vga时钟
wire h_over; //行扫描结束位
wire v_over; //场扫描结束位
wire data_act; //data是否有效，data只有在中间的显示阶段有效

//VGA行、场扫描时序参数表
parameter hsync_end = 10'd95, //行同步信号（低电平）结束位 同步信号为1的时候，可以显示
hdata_begin = 10'd143, //行显示开始 
hdata_end = 10'd783, //行显示结束  中间640pixel data有效，中间data_act为有效信号
hpixel_end = 10'd799, //行显示前延结束 
vsync_end = 10'd1,   //场同步信号结束
vdata_begin = 10'd34,  //场显示开始
vdata_end = 10'd514,   //场显示结束  中间480pixel data有效，data_act为有效信号
vline_end =10'd524;    //一帧最后一行

parameter [2:0] R=3'b100,B=3'b001;   //参数型红蓝颜色
reg [2:0] y [11:0];  //存放每个E的颜色RGB
setclk myclk(
.clk(clk),
.rst(rst),
.clk_vga(vga_clk)  
);

//vga驱动程序
//行扫描
always@(posedge vga_clk)
begin
    if(h_over)     //如果行结束标志为1，换行
        hcnt<=10'd0;  //将行计数器置0
    else
        hcnt<=hcnt+10'd1;  //行计数，每来一个vga_clk上升沿加一
end
assign h_over=(hcnt==hpixel_end); //行扫描计数器为799，将行结束标志赋1
always@(posedge vga_clk)
begin
    if(h_over)    //行扫描计数到最后一行
    begin
        if(v_over)  //如果场扫描也为最后一个像素，场计数器重置
            vcnt<=10'd0;
        else
            vcnt<=vcnt+10'd1;    //否则加一计数
    end       
end
assign v_over=(vcnt==vline_end); //场计数器等于524，场结束信号赋1

assign data_act=((hcnt>=hdata_begin)&&(hcnt<=hdata_end)&&(vcnt>=vdata_begin)&&(vcnt<=vdata_end));//data是否显示，即data_act是否为有效
assign hs=(hcnt>hsync_end); //行计数器大于 95 行同步信号置1
assign vs=(vcnt>vsync_end); //场计数器大于1 ，场同步信号置1
assign disp_RGB=(data_act)?data:3'b000;

always@(*)
begin
    y[0]=B;   //先全部设置为蓝色
    y[1]=B;
    y[2]=B;
    y[3]=B;
    y[4]=B;
    y[5]=B;
    y[6]=B;
    y[7]=B;
    y[8]=B;
    y[9]=B;
    y[10]=B;
    y[11]=B;
    case({c,r})   //根据选择的位置来改变原来的颜色
    4'b0000:y[0]=R;
    4'b0001:y[0]=R;
    4'b0010:y[1]=R;
    4'b0011:y[1]=R;
    4'b0100:y[2]=R;
    4'b0101:y[2]=R;
    4'b0110:y[3]=R;
    4'b0111:y[3]=R;
    4'b1000:y[4]=R;
    4'b1001:y[5]=R;
    4'b1010:y[6]=R;
    4'b1011:y[7]=R;
    4'b1100:y[8]=R;
    4'b1101:y[9]=R;
    4'b1110:y[10]=R;
    4'b1111:y[11]=R;
    endcase
end


always@(*)            //显示区域
begin
    if((hcnt>=hdata_begin+10'd28)&&(hcnt<=hdata_begin+10'd228)&&(vcnt>=vdata_begin+10'd20)&&(vcnt<=vdata_begin+10'd220))  
    begin
        if((hcnt>=hdata_begin+10'd68)&&(hcnt<=hdata_begin+10'd228)&&(vcnt>=vdata_begin+10'd60)&&(vcnt<=vdata_begin+10'd100))
            data=3'b111;
        else if((hcnt>=hdata_begin+10'd68)&&(hcnt<=hdata_begin+10'd228)&&(vcnt>=vdata_begin+10'd140)&&(vcnt<=vdata_begin+10'd180))
            data=3'b111;
        else data=y[0];
    end
    else if((hcnt>=hdata_begin+10'd28)&&(hcnt<=hdata_begin+10'd228)&&(vcnt>=vdata_begin+10'd260)&&(vcnt<=vdata_begin+10'd460))
    begin
        if((hcnt>=hdata_begin+10'd28)&&(hcnt<=hdata_begin+10'd188)&&(vcnt>=vdata_begin+10'd300)&&(vcnt<=vdata_begin+10'd340))
            data=3'b111;
        else if((hcnt>=hdata_begin+10'd28)&&(hcnt<=hdata_begin+10'd188)&&(vcnt>=vdata_begin+10'd380)&&(vcnt<=vdata_begin+10'd420))
            data=3'b111;
        else data=y[1];
    end
    else if((hcnt>=hdata_begin+10'd277)&&(hcnt<=hdata_begin+10'd427)&&(vcnt>=vdata_begin+10'd45)&&(vcnt<=vdata_begin+10'd195))
    begin
        if((hcnt>=hdata_begin+10'd307)&&(hcnt<=hdata_begin+10'd337)&&(vcnt>=vdata_begin+10'd45)&&(vcnt<=vdata_begin+10'd165))
            data=3'b111;
        else if((hcnt>=hdata_begin+10'd367)&&(hcnt<=hdata_begin+10'd397)&&(vcnt>=vdata_begin+10'd45)&&(vcnt<=vdata_begin+10'd165))
            data=3'b111;
        else data=y[2];
    end
    else if((hcnt>=hdata_begin+10'd277)&&(hcnt<=hdata_begin+10'd427)&&(vcnt>=vdata_begin+10'd285)&&(vcnt<=vdata_begin+10'd435))
    begin
        if((hcnt>=hdata_begin+10'd307)&&(hcnt<=hdata_begin+10'd337)&&(vcnt>=vdata_begin+10'd315)&&(vcnt<=vdata_begin+10'd435))
            data=3'b111;
        else if((hcnt>=hdata_begin+10'd367)&&(hcnt<=hdata_begin+10'd397)&&(vcnt>=vdata_begin+10'd315)&&(vcnt<=vdata_begin+10'd435))
            data=3'b111;
        else data=y[3];
    end
    else if((hcnt>=hdata_begin+10'd462)&&(hcnt<=hdata_begin+10'd562)&&(vcnt>=vdata_begin+10'd10)&&(vcnt<=vdata_begin+10'd110))
    begin
        if((hcnt>=hdata_begin+10'd482)&&(hcnt<=hdata_begin+10'd562)&&(vcnt>=vdata_begin+10'd30)&&(vcnt<=vdata_begin+10'd50))
            data=3'b111;
        else if((hcnt>=hdata_begin+10'd482)&&(hcnt<=hdata_begin+10'd562)&&(vcnt>=vdata_begin+10'd70)&&(vcnt<=vdata_begin+10'd90))
            data=3'b111;
        else data=y[4];
    end
    else if((hcnt>=hdata_begin+10'd462)&&(hcnt<=hdata_begin+10'd562)&&(vcnt>=vdata_begin+10'd130)&&(vcnt<=vdata_begin+10'd230))
    begin
        if((hcnt>=hdata_begin+10'd482)&&(hcnt<=hdata_begin+10'd562)&&(vcnt>=vdata_begin+10'd150)&&(vcnt<=vdata_begin+10'd170))
            data=3'b111;
        else if((hcnt>=hdata_begin+10'd482)&&(hcnt<=hdata_begin+10'd562)&&(vcnt>=vdata_begin+10'd190)&&(vcnt<=vdata_begin+10'd210))
            data=3'b111;
        else data=y[5];
    end
    else if((hcnt>=hdata_begin+10'd462)&&(hcnt<=hdata_begin+10'd562)&&(vcnt>=vdata_begin+10'd250)&&(vcnt<=vdata_begin+10'd350))
    begin
        if((hcnt>=hdata_begin+10'd462)&&(hcnt<=hdata_begin+10'd542)&&(vcnt>=vdata_begin+10'd270)&&(vcnt<=vdata_begin+10'd290))
            data=3'b111;
        else if((hcnt>=hdata_begin+10'd462)&&(hcnt<=hdata_begin+10'd542)&&(vcnt>=vdata_begin+10'd310)&&(vcnt<=vdata_begin+10'd330))
            data=3'b111;
        else data=y[6];
    end
    else if((hcnt>=hdata_begin+10'd462)&&(hcnt<=hdata_begin+10'd562)&&(vcnt>=vdata_begin+10'd370)&&(vcnt<=vdata_begin+10'd470))
    begin
        if((hcnt>=hdata_begin+10'd482)&&(hcnt<=hdata_begin+10'd502)&&(vcnt>=vdata_begin+10'd370)&&(vcnt<=vdata_begin+10'd450))
            data=3'b111;
        else if((hcnt>=hdata_begin+10'd522)&&(hcnt<=hdata_begin+10'd542)&&(vcnt>=vdata_begin+10'd370)&&(vcnt<=vdata_begin+10'd450))
            data=3'b111;
        else data=y[7];
    end
    else if((hcnt>=hdata_begin+10'd583)&&(hcnt<=hdata_begin+10'd633)&&(vcnt>=vdata_begin+10'd35)&&(vcnt<=vdata_begin+10'd85))
    begin
        if((hcnt>=hdata_begin+10'd593)&&(hcnt<=hdata_begin+10'd603)&&(vcnt>=vdata_begin+10'd35)&&(vcnt<=vdata_begin+10'd75))
            data=3'b111;
        else if((hcnt>=hdata_begin+10'd613)&&(hcnt<=hdata_begin+10'd623)&&(vcnt>=vdata_begin+10'd35)&&(vcnt<=vdata_begin+10'd75))
            data=3'b111;
        else data=y[8];
    end
    else if((hcnt>=hdata_begin+10'd583)&&(hcnt<=hdata_begin+10'd633)&&(vcnt>=vdata_begin+10'd155)&&(vcnt<=vdata_begin+10'd205))
    begin
        if((hcnt>=hdata_begin+10'd583)&&(hcnt<=hdata_begin+10'd623)&&(vcnt>=vdata_begin+10'd165)&&(vcnt<=vdata_begin+10'd175))
            data=3'b111;
        else if((hcnt>=hdata_begin+10'd583)&&(hcnt<=hdata_begin+10'd623)&&(vcnt>=vdata_begin+10'd185)&&(vcnt<=vdata_begin+10'd195))
            data=3'b111;
        else data=y[9];
    end
    else if((hcnt>=hdata_begin+10'd583)&&(hcnt<=hdata_begin+10'd633)&&(vcnt>=vdata_begin+10'd275)&&(vcnt<=vdata_begin+10'd325))
    begin
        if((hcnt>=hdata_begin+10'd593)&&(hcnt<=hdata_begin+10'd603)&&(vcnt>=vdata_begin+10'd285)&&(vcnt<=vdata_begin+10'd325))
            data=3'b111;
        else if((hcnt>=hdata_begin+10'd613)&&(hcnt<=hdata_begin+10'd623)&&(vcnt>=vdata_begin+10'd285)&&(vcnt<=vdata_begin+10'd325))
            data=3'b111;
        else data=y[10];
    end
    else if((hcnt>=hdata_begin+10'd583)&&(hcnt<=hdata_begin+10'd633)&&(vcnt>=vdata_begin+10'd395)&&(vcnt<=vdata_begin+10'd445))
    begin
        if((hcnt>=hdata_begin+10'd593)&&(hcnt<=hdata_begin+10'd603)&&(vcnt>=vdata_begin+10'd405)&&(vcnt<=vdata_begin+10'd445))
            data=3'b111;
        else if((hcnt>=hdata_begin+10'd613)&&(hcnt<=hdata_begin+10'd623)&&(vcnt>=vdata_begin+10'd405)&&(vcnt<=vdata_begin+10'd445))
            data=3'b111;
        else data=y[11];
    end
        
    else data=3'b111;
end
endmodule

module score(
input clk,
input rst,
input up,
input down,
input left,
input right,
input [1:0] r, //选择行
input [1:0] c, //选择列
output reg sound,
output reg [6:0] s //得分
);
reg bool; //标志位，是否有警告声 高电平有效
always@(*)
begin
    if((c==2'b01&&r[1]==0)||(c==2'b10&&r==2'b11)||(c==2'b11&&r==2'b00))
    begin
        if(down==1||left==1||right==1)
            bool=1;
        else 
            bool=0;
    end
    else if((c==2'b01&&r[1]==1)||(c==2'b11&&r==2'b10)||(c==2'b11&&r==2'b11))
    begin
        if(up==1||left==1||right==1)
            bool=1;
        else
            bool=0;
    end
    else if((c==2'b00&&r[1]==1)||(c==2'b10&&r==2'b10)||(c==2'b11&&r==2'b01))
    begin
        if(up==1||down==1||right==1)
            bool=1;
        else 
            bool=0;
    end
    else if((c==2'b00&&r[1]==0)||(c==2'b10&&r==2'b00)||(c==2'b10&&r==2'b01))
    begin
        if(up==1||down==1||left==1)
            bool=1;
        else 
            bool=0;
    end
end
reg [6:0] s1,s2,s3,s4;
always@(posedge rst,posedge up)
begin
    if(rst)
        s1<=0;
    else if((up==1)&&((c==2'b01&&r[1]==0)||(c==2'b10&&r==2'b11)||(c==2'b11&&r==2'b00)))
        s1<=s1+10;
    else s1<=s1;
end
always@(posedge rst,posedge down)
begin
    if(rst)
        s2<=0;
    else if((down==1)&&((c==2'b01&&r[1]==1)||(c==2'b11&&r==2'b10)||(c==2'b11&&r==2'b11)))
        s2<=s2+10;
    else s2<=s2;
end
always@(posedge rst,posedge left)
begin
    if(rst)
        s3<=0;
    else if((left==1)&&((c==2'b00&&r[1]==1)||(c==2'b10&&r==2'b10)||(c==2'b11&&r==2'b01)))
        s3<=s3+10;
    else s3<=s3;
end
always@(posedge rst,posedge right)
begin
    if(rst)
        s4<=0;
    else if((right==1)&&((c==2'b00&&r[1]==0)||(c==2'b10&&r==2'b00)||(c==2'b10&&r==2'b01)))
        s4<=s4+10;
    else s4<=s4;
end
always@(posedge clk,posedge rst)
    if(rst)
        s<=0;
    else
        s=s1+s2+s3+s4;

//警告声
reg oclk;
parameter M=16'hC350; //分频参数
reg [16:0] cnt;  //计数器
always@(posedge clk,posedge rst)
begin
    if(rst)
    begin
        cnt=0;
        oclk=0;
    end
    else
    begin
        cnt=cnt+1;
        if(cnt==M)
        begin
            cnt=0;
            oclk=~oclk;
        end
    end
end
always@(posedge oclk,posedge rst)
begin
    if(rst)
        sound=0;
    else 
        if(bool)
        sound=~sound;
end



endmodule

module display(
input clk,
input rst,
input [6:0] s,
output reg [7:0] an,
output reg [6:0] sseg
);
parameter N=20;
reg [N-1:0] cnt; //计数器，将系统时钟clk信号分频 100MHz/1M=100Hz
always@(posedge clk,posedge rst)
begin
    if(rst)
        cnt<=0;
    else 
    begin
        cnt<=cnt+1;
        case(cnt[N-1:N-2])
        2'b00:
        begin
            an<=8'b11111110;
            sseg<=7'b0000001;
        end
        2'b01:
        begin
            an<=8'b11111101;
            case(s)
            7'd0:sseg<=7'b0000001;
            7'd10:sseg<=7'b1001111;
            7'd20:sseg<=7'b0010010;
            7'd30:sseg<=7'b0000110;
            7'd40:sseg<=7'b1001100;
            7'd50:sseg<=7'b0100100;
            7'd60:sseg<=7'b0100000;
            7'd70:sseg<=7'b0001111;
            7'd80:sseg<=7'b0000000;
            7'd90:sseg<=7'b0000100;
            default:sseg<=7'b0000001;
            endcase
        end
        2'b10:
        begin
            an<=8'b11111011;
            if(s==7'd100)
                sseg<=7'b1001111;
            else sseg<=7'b0000001;
        end
        default:
            an<=8'b11111111;
        endcase
    end
end
endmodule

module Main(   //主模块
input clk,
input rst,
input up,
input down,
input left,
input right,
input [1:0] select_of_r, //选择行
input [1:0] select_of_c, //选择列
output sound,
output [7:0] an,
output [6:0] sseg,

output [2:0] disp_RGB,
output hs,  //行同步信号 换行的时钟信号
output vs   //场同步信号 换帧的时钟信号
);
wire [6:0] s;
vga_top myvga(clk,rst,select_of_r,select_of_c,disp_RGB,hs,vs); 

score getscore(clk,rst,up,down,left,right,select_of_r,select_of_c,sound,s);  //调用子模块score
display dis_s(clk,rst,s,an,sseg);
endmodule

