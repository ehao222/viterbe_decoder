/*Encoder
      ---------- SUM=Y1--------------
     /   /       |        |      |   \
 W8,In  w7   w6| w5| w4| w3| w2| w1| w0|
     \                |   |   |       /
     ------------SUM=Y2---------------
  Change its state on the posedge of clock
*/

/******************************************************/ 
module viterbi_encoder(X,Y,Clock,Reset);
//viterbi encoder
/******************************************************/ 
input X, Clock, Reset;//clock and key reset
output [1:0] Y;//encoded
wire [1:0] Yt;//encoded buffer
wire X, Clock, Reset;
wire [8:0] PolyA, PolyB;//Poly
wire [8:0] wA, wB, ShReg;//wA,wB are middle variable,shReg is（9bit）ShifterRegister

assign PolyA = 9'b110_101_111; 
assign PolyB = 9'b100_011_101;
//corresponding bit &,rid of the useless bits
assign wA = PolyA & ShReg; 
assign wB = PolyB & ShReg;
//9 bit shift register
assign ShReg[8] = X;
pDFF dff7(ShReg[8], ShReg[7], Clock, Reset); 
pDFF dff6(ShReg[7], ShReg[6], Clock, Reset); 
pDFF dff5(ShReg[6], ShReg[5], Clock, Reset); 
pDFF dff4(ShReg[5], ShReg[4], Clock, Reset); 
pDFF dff3(ShReg[4], ShReg[3], Clock, Reset); 
pDFF dff2(ShReg[3], ShReg[2], Clock, Reset); 
pDFF dff1(ShReg[2], ShReg[1], Clock, Reset); 
pDFF dff0(ShReg[1], ShReg[0], Clock, Reset);

assign Yt[1] = wA[0] ^ wA[1] ^ wA[2] ^ wA[3] ^ wA[4] ^ wA[5] ^ wA[6] ^ wA[7] ^ wA[8]; 
assign Yt[0] = wB[0] ^ wB[1] ^ wB[2] ^ wB[3] ^ wB[4] ^ wB[5] ^ wB[6] ^ wB[7] ^ wB[8];
pDFF dffy1(Yt[1], Y[1], Clock, Reset);
pDFF dffy0(Yt[0], Y[0], Clock, Reset); 
endmodule