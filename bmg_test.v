/*--------------------------------------
Author:ehao@bupt.edu.cn
Comment:Test bench for bmg module
--------------------------------------*/
`timescale 1ns/1ns
`include "params.v"
`include "bmg.v"

module bmg_test();  
/*----------------------Variable Statement------------------------------*/
  reg Reset,Clock2;
  reg [`WD_FSM-1:0] ACSSegment;
  reg [`WD_CODE-1:0] Code;
  reg [`WD_CODE-1:0] CodeRegister;
  wire [`WD_DIST*2*`N_ACS-1:0] Distance;
/*-----------------Intanticate the module BMG--------------------------*/
BMG BMG_test(.Reset(Reset),.Clock2(Clock2),.ACSSegment(ACSSegment),.Code(Code),
  .CodeRegister(CodeRegister),.Distance(Distance));
/*-----------------Add the Stimulate signals---------------------------*/  
 //clock
  initial Clock2=1;
  always #(`FULL) Clock2=~Clock2;
  //Reset
  initial begin
     Reset=0;
     #600 Reset=1;    
  end
  //Acssegmet
  initial begin
      ACSSegment=6'b111_111;
      #600 ACSSegment=6'b000_000;
      forever begin
          #(`FULL*2) ACSSegment=ACSSegment+1;
      end
  end
  //code
  initial begin
      Code=2'b00;
      #475 Code=2'b11;
      #`DPERIOD Code=2'b00;
      #`DPERIOD Code=2'b01;
      #`DPERIOD Code=2'b10;
      #`DPERIOD Code=2'b11;
  end
/*--------------------Check the Output--------------------------------*/   

endmodule