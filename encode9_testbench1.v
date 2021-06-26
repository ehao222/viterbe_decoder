`timescale 1ns/1ns  //定义时间单位
module encode9_testbench;    
reg reset, clk,x;  
wire [1:0] y;     //输入x为1bit，输出y为2bit 
viterbi_encoder r1(x, y, clk, reset);      
/*-----------------------------------*/
//时钟周期设定（周期为10ns）
/*-----------------------------------*/
initial begin 
clk = 0;
forever begin 
#5 clk = 1'b1;
#5 clk = 1'b0;
end 
end 

initial
begin  
    $timeformat(-9,1,"ns",9);
    $monitor("time=%t,reset=%b,x= %b,y= %b",$stime,reset,x,y);  
end
/*-----------------------------------*/
//任务expect定义
/*-----------------------------------*/
task expect;
input [1:0] expects;
if(y !== expects) 
begin
    $display ("At time %t y is %b but should be %b",$time,y,expects);
    $display ("TEST FAILED");
    $finish;
end
endtask
/*-----------------------------------*/
//expct值和reset值设定
/*-----------------------------------*/
initial begin 
@(negedge clk)
{reset, x}=2'b0_1; @(negedge clk) expect(2'b00);
{reset, x}=2'b1_1; @(negedge clk) expect(2'b11);
{reset, x}=2'b1_0; @(negedge clk) expect(2'b10);
{reset, x}=2'b1_0; @(negedge clk) expect(2'b00);
{reset, x}=2'b1_1; @(negedge clk) expect(2'b01);
{reset, x}=2'b1_1; @(negedge clk) expect(2'b00);
$display("TEST PASSED");
$finish;
end 
endmodule


