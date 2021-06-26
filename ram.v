`include "params.v"
/*-----------------------------------*/
// Module: RAMs
// File : ram.v
// Description : The RAMs definition.
//Function：
//@1:RAM for survival bits
//@2:RAM for PathMetric
// -- mainly used on functional simulation only
// Simulator : Modelsim 6.5 / Windows 7/10
/*-----------------------------------*/
// Revision Number : 1  
// Description : Initial Design
/*-----------------------------------*/


/*-----------------------------------*/
//instanciate the RAM module for Survival bits
module RAM (RAMEnable, AddressRAM, DataRAM,
   RWSelect, ReadClock, WriteClock);
//此模?��调?���RAMMODULE?��?���?�说明见RAMMODULE
// Survivor memory instantiation ?��存存?���?�例?�� 
/*-----------------------------------*/
input RAMEnable, RWSelect, ReadClock, WriteClock; 
input [`WD_RAM_ADDRESS-1:0] AddressRAM; 
inout [`WD_RAM_DATA-1:0] DataRAM;
//?���#?��参
RAMMODULE #(2048,8,11) ram (RAMEnable, DataRAM, AddressRAM, RWSelect, ReadClock, WriteClock);
//11跟?��址?��线：Log[（256�??��态/每�??���?8�?survive）*�?径深度64]=11
endmodule

//幸�?��?径?��?��
/*-----------------------------------*/
module RAMMODULE (_Enable, Data, Address, RWSelect, RClock, WClock);
//Ports：
//Enable_:s寄存?���?�写?��作?��使能�?�低?��平?��?��；
//Address：11位?��址线�?�寻址2048�?8bit?��?��（8位?���??��线）
//Data：读写8bit?���?寄存?���
//RWSelect:读写����?��。0�?1?��
//WCLock：?��?���??��钟 下����沿有?��
// RAM Enable : Active Low 使�? RAM 低?��平激�? 
/*-----------------------------------*/
parameter SIZE = 2048; 
parameter DATABITS = 8;
parameter ADDRESSBITS = 7;
inout [DATABITS-1:0] Data;//inout类型
input [ADDRESSBITS-1:0] Address;
input RWSelect; // 0:Write 1:Read 
input RClock,WClock,_Enable;//读写?��钟使�?
reg [DATABITS-1:0] Data_Regs [SIZE-1:0]; //幸�?��?径寄存?��� 大��：2048*8bit Data_Regs[1]为�?��?Databits位宽的reg?��?������
reg [DATABITS-1:0] DataBuff;//Data缓?��噡� RWSelect�?1（read）?����8bit幸�?�bit信�?�?����?���data

// Write
always @(negedge WClock) begin
  if (~_Enable) Data_Regs [Address] <= Data; 
end

// Read
always @(negedge RClock) begin
  if (~_Enable) DataBuff <= Data_Regs [Address]; 
end
assign Data = (RWSelect) ? DataBuff:'bz; 
endmodule

/*-----------------------------------*/
module METRICMEMORY (Reset, Clock1, Active, MMReadAddress,
            MMWriteAddress, MMBlockSelect, MMMetric, MMPathMetric);
//
// This module is used as metric memory who holds the metric values. //这�?模块�??���?�?���?��?����?�?
/*-----------------------------------*/
input Reset, Clock1, Active, MMBlockSelect;
input [`WD_METR*`N_ACS-1:0] MMMetric;
input [`WD_FSM-1:0] MMWriteAddress; 
input [`WD_FSM-2:0] MMReadAddress;
output [`WD_METR*2*`N_ACS-1:0] MMPathMetric;
reg [`WD_METR*2*`N_ACS-1:0] MMPathMetric;
reg [`WD_METR*`N_ACS-1:0] M_REG_A [`N_ITER-1:0]; //A存?��块 64*32 <=（8bit*4�?acs?��?��=32bit）， 256/4=64bit
reg [`WD_METR*`N_ACS-1:0] M_REG_B [`N_ITER-1:0];//B存?��块 64*32

//?��?���?
always @(negedge Clock1 or negedge Reset) begin
if (~Reset) begin
  /*
  for (i =0 ;i<64 ;i++ ) begin
    M_REG_A [i] <= 0;
  end
  */
  //注意 M_REG_A [i]为�?��?位宽为Databits*N_ACS?��reg?��?������
M_REG_A [63] <= 0;M_REG_A [62] <= 0;M_REG_A [61] <= 0; M_REG_A [60] <= 0;M_REG_A [59] <= 0;
M_REG_A [58] <= 0; M_REG_A [57] <= 0;M_REG_A [56] <= 0;
M_REG_A [55] <= 0;M_REG_A [54] <= 0;M_REG_A [53] <= 0; M_REG_A [52] <= 0;M_REG_A [51] <= 0;
M_REG_A [50] <= 0;M_REG_A [49] <= 0;M_REG_A [48] <= 0; M_REG_A [47] <= 0;M_REG_A [46] <= 0;
M_REG_A [45] <= 0;M_REG_A [44] <= 0;M_REG_A [43] <= 0; M_REG_A [42] <= 0;M_REG_A [41] <= 0;
M_REG_A [40] <= 0;M_REG_A [39] <= 0;M_REG_A [38] <= 0; M_REG_A [37] <= 0;M_REG_A [36] <= 0;
M_REG_A [35] <= 0;M_REG_A [34] <= 0;M_REG_A [33] <= 0; M_REG_A [32] <= 0;M_REG_A [31] <= 0;
M_REG_A [30] <= 0;M_REG_A [29] <= 0;M_REG_A [28] <= 0; M_REG_A [27] <= 0;M_REG_A [26] <= 0;
M_REG_A [25] <= 0;M_REG_A [24] <= 0;M_REG_A [23] <= 0; M_REG_A [22] <= 0;M_REG_A [21] <= 0;
M_REG_A [20] <= 0;M_REG_A [19] <= 0;M_REG_A [18] <= 0; M_REG_A [17] <= 0;M_REG_A [16] <= 0;
M_REG_A [15] <= 0;M_REG_A [14] <= 0;M_REG_A [13] <= 0; M_REG_A [12] <= 0;M_REG_A [11] <= 0;
M_REG_A [10] <= 0;M_REG_A [9] <= 0;M_REG_A [8] <= 0; M_REG_A [7] <= 0;M_REG_A [6] <= 0;
M_REG_A [5] <= 0;M_REG_A [4] <= 0;M_REG_A [3] <= 0; M_REG_A [2] <= 0;M_REG_A [1] <= 0;M_REG_A [0] <= 0;
M_REG_B [63] <= 0;M_REG_B [62] <= 0;M_REG_B [61] <= 0; M_REG_B [60] <= 0;M_REG_B [59] <= 0;
M_REG_B [58] <= 0; M_REG_B [57] <= 0;M_REG_B [56] <= 0;
M_REG_B [55] <= 0;M_REG_B [54] <= 0;M_REG_B [53] <= 0; M_REG_B [52] <= 0;M_REG_B [51] <= 0;
M_REG_B [50] <= 0;M_REG_B [49] <= 0;M_REG_B [48] <= 0; M_REG_B [47] <= 0;M_REG_B [46] <= 0;
M_REG_B [45] <= 0;M_REG_B [44] <= 0;M_REG_B [43] <= 0; M_REG_B [42] <= 0;M_REG_B [41] <= 0;
M_REG_B [40] <= 0;M_REG_B [39] <= 0;M_REG_B [38] <= 0; M_REG_B [37] <= 0;M_REG_B [36] <= 0;
M_REG_B [35] <= 0;M_REG_B [34] <= 0;M_REG_B [33] <= 0; M_REG_B [32] <= 0;M_REG_B [31] <= 0;
M_REG_B [30] <= 0;M_REG_B [29] <= 0;M_REG_B [28] <= 0; M_REG_B [27] <= 0;M_REG_B [26] <= 0;
M_REG_B [25] <= 0;M_REG_B [24] <= 0;M_REG_B [23] <= 0; M_REG_B [22] <= 0;M_REG_B [21] <= 0;
M_REG_B [20] <= 0;M_REG_B [19] <= 0;M_REG_B [18] <= 0; M_REG_B [17] <= 0;M_REG_B [16] <= 0;
M_REG_B [15] <= 0;M_REG_B [14] <= 0;M_REG_B [13] <= 0; M_REG_B [12] <= 0;M_REG_B [11] <= 0;
M_REG_B [10] <= 0;M_REG_B [9] <= 0;M_REG_B [8] <= 0; M_REG_B [7] <= 0;M_REG_B [6] <= 0;
M_REG_B [5] <= 0;M_REG_B [4] <= 0;M_REG_B [3] <= 0; M_REG_B [2] <= 0;M_REG_B [1] <= 0;
M_REG_B [0] <= 0;
end
else begin
if (Active)
case (MMBlockSelect)//?��?�?4byte�?径�?����?�?
0 : M_REG_A [MMWriteAddress] <= MMMetric; 
1 : M_REG_B [MMWriteAddress] <= MMMetric;
endcase 
end
end

//读数�?
always @(MMReadAddress or Reset) begin//读地址?��?��立?���?�敡�
if (~Reset) MMPathMetric <=0; //异步��位
else begin
case (MMBlockSelect)//�?8bit�?径�?����?�?
0 : 
case (MMReadAddress)
0 : MMPathMetric <= {M_REG_B [1],M_REG_B[0]};
1 : MMPathMetric <= {M_REG_B [3],M_REG_B[2]};
2 : MMPathMetric <= {M_REG_B [5],M_REG_B[4]};
3 : MMPathMetric <= {M_REG_B [7],M_REG_B[6]};
4 : MMPathMetric <= {M_REG_B [9],M_REG_B[8]};
5 : MMPathMetric <= {M_REG_B [11],M_REG_B[10]}; 
6 : MMPathMetric <= {M_REG_B [13],M_REG_B[12]}; 
7 : MMPathMetric <= {M_REG_B [15],M_REG_B[14]};
8 : MMPathMetric <= {M_REG_B [17],M_REG_B[16]};
9 : MMPathMetric <= {M_REG_B [19],M_REG_B[18]}; 
10: MMPathMetric <= {M_REG_B [21],M_REG_B[20]}; 
11: MMPathMetric <= {M_REG_B [23],M_REG_B[22]};
12: MMPathMetric <= {M_REG_B [25],M_REG_B[24]}; 
13: MMPathMetric <= {M_REG_B [27],M_REG_B[26]}; 
14: MMPathMetric <= {M_REG_B [29],M_REG_B[28]}; 
15: MMPathMetric <= {M_REG_B [31],M_REG_B[30]};
16: MMPathMetric <= {M_REG_B [33],M_REG_B[32]}; 
17: MMPathMetric <= {M_REG_B [35],M_REG_B[34]}; 
18: MMPathMetric <= {M_REG_B [37],M_REG_B[36]}; 
19: MMPathMetric <= {M_REG_B [39],M_REG_B[38]}; 
20: MMPathMetric <= {M_REG_B [41],M_REG_B[40]}; 
21: MMPathMetric <= {M_REG_B [43],M_REG_B[42]}; 
22: MMPathMetric <= {M_REG_B [45],M_REG_B[44]}; 
23: MMPathMetric <= {M_REG_B [47],M_REG_B[46]};
24: MMPathMetric <= {M_REG_B [49],M_REG_B[48]}; 
25: MMPathMetric <= {M_REG_B [51],M_REG_B[50]}; 
26: MMPathMetric <= {M_REG_B [53],M_REG_B[52]}; 
27: MMPathMetric <= {M_REG_B [55],M_REG_B[54]}; 
28: MMPathMetric <= {M_REG_B [57],M_REG_B[56]}; 
29: MMPathMetric <= {M_REG_B [59],M_REG_B[58]}; 
30: MMPathMetric <= {M_REG_B [61],M_REG_B[60]}; 
31: MMPathMetric <= {M_REG_B [63],M_REG_B[62]};
endcase
1 : 
case (MMReadAddress)
0 : MMPathMetric <= {M_REG_A [1],M_REG_A[0]};
1 : MMPathMetric <= {M_REG_A [3],M_REG_A[2]};
2 : MMPathMetric <= {M_REG_A [5],M_REG_A[4]};
3 : MMPathMetric <= {M_REG_A [7],M_REG_A[6]};
4 : MMPathMetric <= {M_REG_A [9],M_REG_A[8]};
5 : MMPathMetric <= {M_REG_A [11],M_REG_A[10]}; 
6 : MMPathMetric <= {M_REG_A [13],M_REG_A[12]}; 
7 : MMPathMetric <= {M_REG_A [15],M_REG_A[14]};
8 : MMPathMetric <= {M_REG_A [17],M_REG_A[16]};
9 : MMPathMetric <= {M_REG_A [19],M_REG_A[18]}; 
10: MMPathMetric <= {M_REG_A [21],M_REG_A[20]}; 
11: MMPathMetric <= {M_REG_A [23],M_REG_A[22]}; 
12: MMPathMetric <= {M_REG_A [25],M_REG_A[24]}; 
13: MMPathMetric <= {M_REG_A [27],M_REG_A[26]}; 
14: MMPathMetric <= {M_REG_A [29],M_REG_A[28]}; 
15: MMPathMetric <= {M_REG_A [31],M_REG_A[30]};
16: MMPathMetric <= {M_REG_A [33],M_REG_A[32]};
17: MMPathMetric <= {M_REG_A [35],M_REG_A[34]}; 
18: MMPathMetric <= {M_REG_A [37],M_REG_A[36]}; 
19: MMPathMetric <= {M_REG_A [39],M_REG_A[38]}; 
20: MMPathMetric <= {M_REG_A [41],M_REG_A[40]};
21: MMPathMetric <= {M_REG_A [43],M_REG_A[42]}; 
22: MMPathMetric <= {M_REG_A [45],M_REG_A[44]}; 
23: MMPathMetric <= {M_REG_A [47],M_REG_A[46]};
24: MMPathMetric <= {M_REG_A [49],M_REG_A[48]}; 
25: MMPathMetric <= {M_REG_A [51],M_REG_A[50]}; 
26: MMPathMetric <= {M_REG_A [53],M_REG_A[52]}; 
27: MMPathMetric <= {M_REG_A [55],M_REG_A[54]}; 
28: MMPathMetric <= {M_REG_A [57],M_REG_A[56]}; 
29: MMPathMetric <= {M_REG_A [59],M_REG_A[58]};
30: MMPathMetric <= {M_REG_A [61],M_REG_A[60]};
31: MMPathMetric <= {M_REG_A [63],M_REG_A[62]};
endcase
endcase
end 
end
endmodule