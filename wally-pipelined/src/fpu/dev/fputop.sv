`include "../../config/rv64icfd/wally-config.vh"

module fputop (
  input  logic [2:0]       FrmW,
  input  logic             reset,
  input  logic             clear,
  input  logic             clk,
  input  logic [31:0]      InstrD,
  input  logic [`XLEN-1:0] SrcAE,
  input  logic [`XLEN-1:0] SrcAW,
  output logic [31:0]      FSROutW,
  output logic             DivSqrtDoneE,
  output logic             FInvalInstrD,
  output logic [`XLEN-1:0] FPUResultW);
 
  /*fctrl ();

  //regfile instantiation and decode stage
  //freg1adr ();
  
  //freg2adr ();
  
  //freg2adr ();

  //freg2adr ();

  freg3adr ();

  //can easily be merged into privledged core
  //if necessary
  //fcsr ();

  //E pipe and execution stage
 
  fpdivsqrt ();

  fma1 ();

  fpaddcvt1 ();

  fpcmp1 ();

  fpsign ();

  //M pipe and memory stage 

  fma2 ();

  fpaddcvt2 ();

  fpcmp2 ();

  //W pipe and writeback stage

  //flag signal mux
  
  //result mux
*/
endmodule
