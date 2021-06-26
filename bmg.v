`include "params.v"
/*-----------------------------------*/
// Module: BMG
// File : bmg.v
// Description : Description of BMG Unit in Viterbi Decoder 
//Function:
// Simulator : Modelsim 6.5 / Windows 7/10
/*-----------------------------------*/
// Revision Number : 1
// Description : Initial Design
/*-----------------------------------*/
module BMG (Reset, Clock2, ACSSegment, Code, Distance);
input Reset, Clock2;
input [`WD_FSM-1:0] ACSSegment;
input [`WD_CODE-1:0] Code;
output [`WD_DIST*2*`N_ACS-1:0] Distance;
wire [`WD_STATE:0] PolyA, PolyB; 
wire [`WD_STATE:0] wA, wB;
assign PolyA = 9'b110_101_111; // polynomial code used 
assign PolyB = 9'b100_011_101;
wire [`WD_STATE:0] B0,B1,B2,B3,B4,B5,B6,B7;
wire [`WD_CODE-1:0] G0,G1,G2,G3,G4,G5,G6,G7; 
wire [`WD_DIST-1:0] D0,D1,D2,D3,D4,D5,D6,D7; 
reg [`WD_CODE-1:0] CodeRegister;

always @(posedge Clock2 or negedge Reset) begin
if (~Reset) CodeRegister <= 0;
// branch output to be calculated
// output distances 
else if (ACSSegment == 6'h3F) CodeRegister <= Code; 
end

// The branch to be calculated is determined by ACSSegment
assign B0 = {ACSSegment,3'b000};
assign B1 = {ACSSegment,3'b001}; 
assign B2 = {ACSSegment,3'b010}; 
assign B3 = {ACSSegment,3'b011}; 
assign B4 = {ACSSegment,3'b100}; 
assign B5 = {ACSSegment,3'b101}; 
assign B6 = {ACSSegment,3'b110}; 
assign B7 = {ACSSegment,3'b111};

ENC EN0(PolyA,PolyB,B0,G0); 
//ENC EN0(PolyA,PolyB,B1,G1);from the encoding rules,we can tell  G1 = ~G0; 
assign G1 = ~G0; 
ENC EN2(PolyA,PolyB,B2,G2); 
assign G3 = ~G2; // branch metric
ENC EN4(PolyA,PolyB,B4,G4); 
assign G5 = ~G4;
ENC EN6(PolyA,PolyB,B6,G6); 
assign G7 = ~G6;
//further improvement:
/*
ENC EN0(PolyA,PolyB,B0,G0);
assign G1 = ~G0; 
assign G2[0]=G0[0];
assign G2[1]=~G0[1];
assign G3=~G2;
assign G4=~G0;
assign G5=G0;
assign G6[0]=~G0[0];
assign G6[1]=G0[1];
assign G7=~G6;
*/

HARD_DIST_CALC HD0(CodeRegister,G0,D0);
HARD_DIST_CALC HD1(CodeRegister,G1,D1);
HARD_DIST_CALC HD2(CodeRegister,G2,D2); 
HARD_DIST_CALC HD3(CodeRegister,G3,D3); 
HARD_DIST_CALC HD4(CodeRegister,G4,D4); 
HARD_DIST_CALC HD5(CodeRegister,G5,D5); 
HARD_DIST_CALC HD6(CodeRegister,G6,D6); 
HARD_DIST_CALC HD7(CodeRegister,G7,D7);
assign Distance = {D7,D6,D5,D4,D3,D2,D1,D0}; // bus of distances 距离总线
endmodule

// Calculate its hamming distance
/*-----------------------------------*/
module HARD_DIST_CALC (InputSymbol, BranchOutput, OutputDistance);
/*-----------------------------------*/
//author : Dian Tresna Nugraha
//desc. : performs 2 bits hamming DISTance calculation 
// delay : N/A
/*-----------------------------------*/
input [`WD_CODE-1:0] InputSymbol, BranchOutput; 
output [`WD_DIST-1:0] OutputDistance;
reg [`WD_DIST-1:0] OutputDistance;
wire MS, LS;
//i.e.{MS,LS}=InputSymbol^BranchOutput.
assign MS = (InputSymbol[1] ^ BranchOutput[1]);
assign LS = (InputSymbol[0] ^ BranchOutput[0]);
//half adder MS+LS=Output[1:0]
always @(MS or LS) begin
OutputDistance[1] <= MS & LS;
OutputDistance[0] <= MS ^ LS; 
end
endmodule

/*-----------------------------------*/
module ENC (PolyA, PolyB, BranchID, EncOut);
/*-----------------------------------*/
// author : Dian Tresna Nugraha
//desc. : encoder to determine branch output 
//delay : N/A
/*-----------------------------------*/
input [`WD_STATE:0] PolyA,PolyB; 
input [`WD_STATE:0] BranchID; //ID the 512 branches
output [`WD_CODE-1:0] EncOut; //decoding input 2bit
wire [`WD_STATE:0] wA, wB; //Generator polynomial wA，wB
reg [`WD_CODE-1:0] EncOut;
assign wA = PolyA & BranchID; 
assign wB = PolyB & BranchID;
always @(wA or wB) begin
//Another Expression:use Reducer. e.g. ^a<=>((a[0]^a[1])^a[2])^a[3]
    //i.e.Encout[1]=^wA;
    //Encout[2]=^wB;
EncOut[1] = (((wA[0]^wA[1]) ^ (wA[2]^wA[3]))^((wA[4]^wA[5]) ^ (wA[6]^wA[7]))^wA[8]);
EncOut[0] = (((wB[0]^wB[1]) ^ (wB[2]^wB[3]))^((wB[4]^wB[5]) ^ (wB[6]^wB[7]))^wB[8]);
end
endmodule