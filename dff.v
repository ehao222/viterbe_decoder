/******************************************************/ 
module pDFF(DATA,QOUT,CLOCK,RESET);
//Fuction：D触发器（上升沿触发）状态方程
// Q(n+1)=D·(cp ^ )
//              |
/******************************************************/ 
parameter WIDTH = 1;
input [WIDTH-1:0] DATA; 
input CLOCK, RESET;
output [WIDTH-1:0] QOUT; 
reg [WIDTH-1:0] QOUT;
always @(posedge CLOCK or negedge RESET)
if (~RESET) QOUT <= 0; //active low reset 使用低电平异步复位
else QOUT <= DATA; //时钟触发后
endmodule