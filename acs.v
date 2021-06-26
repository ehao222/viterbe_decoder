`include "params.v"
/*-----------------------------------*/
// Module : ACSUNIT
// File : acs.v
// Description : Description of ACS Unit in Viterbi Decoder
// Simulator : Modelsim 6.5 / Windows 7/10
/*-----------------------------------*/
// Revision Number : 1
// Description : Initial Design
/*-----------------------------------*/
module ACSUNIT (Reset, Clock1, Clock2, Active, Init, Hold, CompareStart,
                ACSSegment, Distance, Survivors, LowestState,MMReadAddress,
                 MMWriteAddress, MMBlockSelect, MMMetric,MMPathMetric);
/*-------------------------------------------------------------------------------------------------
// ACS UNIT consists of :
// - 4 ACS modules (ACS)
// - RAM Interface
// - State with smallest metric finder (LOWESTPICK)
-------------------------------------------------------------------------------------------------*/
input Reset, Clock1, Clock2, Active, Init, Hold, CompareStart;
input [`WD_FSM-1:0] ACSSegment;
input [`WD_DIST*2*`N_ACS-1:0] Distance;
// to Survivor Memory
output [`N_ACS-1:0] Survivors;
// to TB Unit
output [`WD_STATE-1:0] LowestState;
// to Memory Metric
output [`WD_FSM-2:0] MMReadAddress;
output [`WD_FSM-1:0] MMWriteAddress;
output MMBlockSelect;
output [`WD_METR*`N_ACS-1:0] MMMetric;
input [`WD_METR*2*`N_ACS-1:0] MMPathMetric;
wire [`WD_DIST-1:0] Distance7,Distance6,Distance5,Distance4,Distance3,Distance2,Distance1,Distance0;
wire [`WD_METR*`N_ACS-1:0] Metric;
wire [`WD_METR-1:0] Metric0, Metric1, Metric2, Metric3;
wire [`WD_METR*2*`N_ACS-1:0] PathMetric;//8*2*4=32bit
wire [`WD_METR-1:0] PathMetric7,PathMetric6,PathMetric5,PathMetric4,PathMetric3,PathMetric2,PathMetric1,PathMetric0;
wire [`WD_METR-1:0] LowestMetric;
assign {Distance7,Distance6,Distance5,Distance4,Distance3,Distance2,Distance1,Distance0} = Distance;
assign {PathMetric7,PathMetric6,PathMetric5,PathMetric4,PathMetric3,PathMetric2,PathMetric1,PathMetric0} = PathMetric;
/*-----------------------------------*/
//Add+Compare+select every PathMetric that inputs the state.
/*-----------------------------------*/
ACS acs0 (CompareStart, Distance1,Distance0,PathMetric1,PathMetric0,ACSData0, Metric0);
ACS acs1 (CompareStart, Distance3,Distance2,PathMetric3,PathMetric2,ACSData1, Metric1);
ACS acs2 (CompareStart, Distance5,Distance4,PathMetric5,PathMetric4,ACSData2, Metric2);
ACS acs3 (CompareStart, Distance7,Distance6,PathMetric7,PathMetric6,ACSData3, Metric3);
/*-----------------------------------*/
//Interface used for communicate betweenn ACS and RAM
/*-----------------------------------*/
RAMINTERFACE ri (Reset, Clock2, Hold, ACSSegment, Metric, PathMetric,
MMReadAddress, MMWriteAddress, MMBlockSelect, MMMetric,MMPathMetric);
/*-----------------------------------*/
//Instantiate the LowestPick Unit
/*-----------------------------------*/
LOWESTPICK lp (Reset, Active, Hold, Init, Clock1, Clock2, ACSSegment,
Metric3, Metric2, Metric1, Metric0,LowestMetric, LowestState);

assign Metric = {Metric3, Metric2, Metric1, Metric0};
assign Survivors = {ACSData3,ACSData2,ACSData1,ACSData0};
endmodule


/*-----------------------------------------------------------
-------------------Two blocks in the mmu-----------------------------
 -    BlockA                                 BlockB
 -  {PathMetric0,...PathMetric7}       {SurvivePathMetric0,...SurvivePathMetric3}
 -  6bit Address bus<=2*(2^8)/8=2^6     5bit Address bus<=2*(2^8)/8=2^5                       
--------------------------------------------------------------------------------*/
module RAMINTERFACE (Reset, Clock2, Hold, ACSSegment, Metric, PathMetric,
    MMReadAddress, MMWriteAddress, MMBlockSelect,MMMetric, MMPathMetric);
/*-----------------------------------*/
// connection to ACS Unit 
input Reset, Clock2, Hold;
input [`WD_FSM-1:0] ACSSegment;//State base Address
input [`WD_METR*`N_ACS-1:0] Metric;//input from the module ACS,(new):32bit
output [`WD_METR*2*`N_ACS-1:0] PathMetric;//output to the module ACS,(old):64bit

// connection to metric memory 
input [`WD_METR*2*`N_ACS-1:0] MMPathMetric;//WritePathMetric:read from memory(old) 64b={PathMetric0,...PathMetric7}
output [`WD_METR*`N_ACS-1:0] MMMetric;//ReadPathMetric:write to the memory 32bit, 32b={SurvivePathMetric0,...SurvivePathMetric6}
output [`WD_FSM-2:0] MMReadAddress;//memory read address 5bit
output [`WD_FSM-1:0] MMWriteAddress;//write address 6bit
output MMBlockSelect;//store block select A/B
reg [`WD_FSM-2:0] MMReadAddress;//5bit
reg MMBlockSelect;

//get the read address
always @(ACSSegment or Reset)begin
  if (~Reset) MMReadAddress <= 0;
  else MMReadAddress <= ACSSegment [`WD_FSM-2:0];  //5位
end

//read<->write
always @(posedge Clock2 or negedge Reset)begin
  if (~Reset) MMBlockSelect <=0;
  //end decodig
  else if (Hold) MMBlockSelect <= ~MMBlockSelect;
end

//read MMPathMetric from momery
assign PathMetric = MMPathMetric;
//the NEW PathMetic
assign MMMetric = Metric;
//get the write address
assign MMWriteAddress = ACSSegment;
endmodule

/*-----------------------------------*/
module ACS (CompareEnable, Distance1, Distance0, PathMetric1,PathMetric0, Survivor, Metric);
/*-------------------------------------------------------------------------------------------------
   ｜-(32bit)PathMetric0---|------|
   ｜                      | ADD  |----\ | /------------\ | /
   ｜  (2bit)Distance0-----|------|   |-----|           |---|
ACSx｜                                | CMP |---------> |SEL|-------->(32'b)Metric 
   ｜-(32bit)PathMetric0---|------|   |     |    |      |   |
   ｜                      | ADD  |   |-----|    |      |---|
   ｜- (2bit)Distance1-----|------|----/ | \-----|------/ | \
                                                |------------------->Survivor(0/1) AcsData0
// ACS Module, based on Modified Comparison Rule, [Shung90]
-------------------------------------------------------------------------------------------------*/
input [`WD_DIST-1:0] Distance1,Distance0;
input [`WD_METR-1:0] PathMetric1,PathMetric0;
input CompareEnable;
output Survivor;
output [`WD_METR-1:0] Metric;
wire [`WD_METR-1:0] ADD0, ADD1;
wire Survivor;
wire [`WD_METR-1:0] Temp_Metric, Metric;
// should 2's complement adder explicitly instantiated ?
//Answer:Of course.
//@1:ADD
assign ADD0 = Distance0 + PathMetric0;
assign ADD1 = Distance1 + PathMetric1;
//@2:Compare
COMPARATOR C1(CompareEnable, ADD1, ADD0, Survivor);
//@3:Select
assign Temp_Metric = (Survivor)? ADD1: ADD0;
assign Metric = (CompareEnable)? Temp_Metric:ADD0;
endmodule

/*------------------------------------------*/
module COMPARATOR (CompareEnable, Metric1, Metric0, Survivor);
// 2's complement comparator to find which is the smaller between Metric1 and Metric0. 
//MSB:most significant bit, [7:0];
//LSB:least significant bit,[0:7];
// Survivor : 
//1 --> Metric1 is the smaller one. Metric1 Smaller
//0 --> Metric0 is the smaller one. Metric0 Smaller
/*---------------Truth List--------------------------------
M1msb  M0msb  |M1msb_xor_M0msb| M1unsignedcompM0| Survivor
 0      0          0                 0                0
 0      0          0                 1                1
 0      1          1                 0                0
 0      1          1                 1                0
 1      0          1                 0                1
 1      0          1                 1                1
 1      1          0                 0                0
 1      1          0                 1                1
 0      1          1                 0                0
 1      0          1                 0                1
 0      0          0                 0                x
 1      1          0                 0                x
---------------------------------------------------------*/
input [`WD_METR-1:0] Metric1,Metric0;
input CompareEnable;
output Survivor;
wire M1msb, M0msb;
wire [`WD_METR-1:0] M1unsigned, M0unsigned;
wire M1msb_xor_M0msb, M1unsignedcompM0;
assign M1msb=Metric1 [`WD_METR-1];
assign M0msb=Metric0 [`WD_METR-1];
assign M1unsigned={1'b0, Metric1 [`WD_METR-2:0]};
assign M0unsigned={1'b0, Metric0 [`WD_METR-2:0]};
assign M1msb_xor_M0msb = M1msb^M0msb;
//Use RTL level discription
assign M1unsignedcompM0 = (M1unsigned > M0unsigned)? 0:1;
//Survivor bit
assign Survivor = (CompareEnable) ? M1msb_xor_M0msb ^ M1unsignedcompM0:'b0;
endmodule

/*-----------------------------------*/
module LOWESTPICK (Reset, Active, Hold, Init, Clock1, Clock2, ACSSegment,
Metric3, Metric2, Metric1, Metric0,LowestMetric, LowestState);
//
// This module is used to find which of 256 states has the smallest metric.
// The value will be very useful for : 
// - determine the first point of traceback
// - debugging your ACS Unit (Should no error on received data occured,
// you'll find the state with the smallest metric is exactly based on
// the encoder input (X), and the lowest metric value should be 0)
/*-----------------------------------*/
input Reset, Active, Clock1, Clock2, Hold, Init;
input [`WD_FSM-1:0] ACSSegment;
input [`WD_METR-1:0] Metric3, Metric2, Metric1, Metric0;
output [`WD_METR-1:0] LowestMetric;
output [`WD_STATE-1:0] LowestState;
reg [`WD_METR-1:0] LowestMetric, Reg_Metric;
reg [`WD_STATE-1:0] LowestState, Reg_State;
wire [`WD_METR-1:0] MetricCompareResult;
wire [`WD_STATE-1:0] StateCompareResult;
wire [`WD_METR-1:0] Lowest_Metric4;
wire [`WD_STATE-1:0] Lowest_State4;
// find state with the lowest metrics for current input ?
LOWEST_OF_FOUR lof (Active, ACSSegment, Metric3, Metric2,Metric1, Metric0,Lowest_State4, Lowest_Metric4);
// compare the 'previous lowest metric' with the
// 'lowest metric of current input'
COMPARATOR comp (Active, Reg_Metric, Lowest_Metric4, CompareBit);
assign MetricCompareResult = (CompareBit) ? Reg_Metric:Lowest_Metric4;
assign StateCompareResult = (CompareBit) ? Reg_State:Lowest_State4;
// on negedge Clock2, update internal registers 
always @(negedge Clock2 or negedge Reset)
begin
if (~Reset)
begin
Reg_Metric <=0;
Reg_State <= 0;
end
else if (Active)
begin
  //decoding begins
if (Init)
begin
Reg_Metric <= Lowest_Metric4;
Reg_State <= Lowest_State4;
end
else
begin
Reg_Metric <= MetricCompareResult;
Reg_State <= StateCompareResult;
end
end
end
// on negedge Clock1 and when Hold is active, Register Outputs
always @(negedge Clock1 or negedge Reset)
begin
if (~Reset)
begin
LowestMetric <=0;
LowestState <= 0;
end
else if (Active)
begin
if (Hold)
begin LowestMetric <= Reg_Metric;
LowestState <= Reg_State;
end
end
end
endmodule

/*-----------------------------------*/
module LOWEST_OF_FOUR (Active, ACSSegment, Metric3, Metric2, Metric1,
Metric0, Lowest_State4, Lowest_Metric4);
//
// This module is used to find ONE STATE among FOUR survivor and metric
// calculated in every cycle which has the smallest metric.
/*-----------------------------------*/
input Active;
input [`WD_FSM-1:0] ACSSegment;
input [`WD_METR-1:0] Metric3, Metric2, Metric1, Metric0;
output [`WD_STATE-1:0] Lowest_State4;
output [`WD_METR-1:0] Lowest_Metric4;
wire Surv1, Surv2, Surv3, Bit_One;
wire [`WD_METR-1:0] MetricX, MetricY;
// compare metric1 and metric0
COMPARATOR comp1 (Active, Metric1, Metric0, Surv1);
// compare metric3 and metric2
COMPARATOR comp2 (Active, Metric3, Metric2, Surv2);
// MetricX --> Smaller metric between Metric1 and Metric0
// MetricY --> Smaller metric between Metric3 and Metric2
assign MetricX = (Surv1) ? Metric1:Metric0;
assign MetricY = (Surv2) ? Metric3:Metric2;
// Compare MetricY and MetricX.
COMPARATOR comp3 (Active, MetricY, MetricX, Surv3);
// Assign the state with smallest metric 
/*---------------------------------------------------------------------------
Lowest_State |  Survive1| Survive2 |Survive3 | Bit_One=(Surv3) ? Surv2:Surv1
  00                0         x        0         0
  01                1         x        0         1
  10                x         0        1         0
  11                x         1        1         1
--------------------------------------------------------------------------*/
assign Bit_One = (Surv3) ? Surv2:Surv1;
assign Lowest_State4 = {ACSSegment, Surv3, Bit_One};
// Assign the smallest metric
assign Lowest_Metric4 = (Surv3) ? MetricY:MetricX;
endmodule