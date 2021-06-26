`include "params.v"
/*-----------------------------------*/
// Module: TBU
// File : tbu.v
// Description : Description of TBU Unit in Viterbi Decoder // Simulator : Modelsim 6.5 / Windows 7/10 
/*-----------------------------------*/
// Revision Number : 1
// Description : Initial Design
 /*-----------------------------------*/
 //从Ram中读取幸存信息
 /*
 Question:什么时候开始回溯？
 答：当ACSpages数目达到63时开始进行路径回溯。解释：
回溯深度深度至少为 5*(L-1)【实验表明，对于约束长度为 K的卷积码，回溯深度为 5K就不会带来性能损
失】，不算上最后的(L-1)个全0bit，5*(L-1)=45,[Log[40]]=6，当取6bit时，不妨为取回溯深度为63
 */
module TBU (Reset, Clock1, Clock2, TB_EN, Init, Hold, InitState, 
       DecodedData, DataTB, AddressTB);
//reset信号进行复位操作
//Clock1,Clock2=>div_4,相位相差90度
//Hold：用于确定解码结束
//Init：确定解码开始
/*--------------------------Control Sigal--------------------------------
       Init=1       Hold=1             TB_EN=1
  Start decoding   End decoding   Start Tracing back
------------------------------------------------------------------------*/
input Reset, Clock1, Clock2, Init, Hold; 
input [`WD_STATE-1:0] InitState; //初始状态
input TB_EN;//当ACSpages数目达到63时开始进行路径回溯
input [`WD_RAM_DATA-1:0] DataTB;//数据总线
output [`WD_RAM_ADDRESS-`WD_FSM-1:0] AddressTB;//地址总线，宽度为11-6+1=6
output DecodedData;//输出解码数据
wire [`WD_STATE-1:0] OutStateTB;
TRACEUNIT tb (Reset, Clock1, Clock2, TB_EN, InitState, Init, Hold,
   DataTB, AddressTB, OutStateTB);//调用路径回溯模块
   
   //由寄存器结构易知：解码输出为第一位
assign DecodedData = OutStateTB [`WD_STATE-1];
endmodule

/*-----------------------------------*/
module TRACEUNIT (Reset, Clock1, Clock2, Enable, InitState, Init, Hold,
Survivor, AddressTB, OutState); 
/*-----------------------------------*/
input Reset, Clock1, Clock2, Enable;
//Clock2超前Clock1 90度
//Clock1:更新加比选模块，更新BMG分支度量和加比选输出
//Clock2:用作产生放入地址总线的时间标志
//Hold：用于确定解码结束
//Init：确定解码开始
input [`WD_STATE-1:0] InitState; 
input Init, Hold;
input [`WD_RAM_DATA-1:0] Survivor;
output [`WD_STATE-1:0] OutState;
output [`WD_RAM_ADDRESS-`WD_FSM-1:0] AddressTB;
reg [`WD_STATE-1:0] CurrentState; 
reg [`WD_STATE-1:0] NextState; 
reg [`WD_STATE-1:0] OutState;
reg SurvivorBit;
always @(negedge Clock1 or negedge Reset) 
begin
//异步复位
  if (~Reset) 
  begin
   CurrentState <=0; OutState <=0;
  end
//使能信号有效
  else if (Enable)
  begin
    if (Init) CurrentState <= InitState;//解码初态
    else CurrentState <= NextState;//下一节译码
    if (Hold) OutState <= NextState;//解码结束，下一个状态
  end
end
//地址总线为高5位,本页：(256个幸存路径)/(survival8位)=2^5
assign AddressTB = CurrentState [`WD_STATE-1:`WD_STATE-5];
always @(negedge Clock2 or negedge Reset) 
begin
  if (~Reset) NextState <= 0; else
    if (Enable) NextState <= {CurrentState [`WD_STATE-2:0],SurvivorBit}; //shift left
end

//求幸存值
always@(Clock1 or Clock2 or Init or CurrentState or Survivor)begin
  SurvivorBit =(Clock1 && Clock2 && ~Init) ? Survivor [CurrentState [2:0]]:'bz;
end
endmodule