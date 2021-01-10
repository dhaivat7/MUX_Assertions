`timescale 1 ns / 1 ns

module top ;

  parameter PERIOD  = 10; // clock period
  parameter CLENGTH = 30; // command length (maximum)
  integer   breakpoint;

  reg CLK, A, B, C, J, K, X ;

  task do_test;
      input [CLENGTH*8:1] seq;
      reg [7:0] c;
      integer i;
    begin
      @(posedge CLK);
      for (i=1;i<=CLENGTH;i=i+1)
        begin
          c = seq[CLENGTH*8:CLENGTH*8-7];
          seq = seq << 8;
          case (c)
            "A" : A <= 1;
            "B" : B <= 1;
            "C" : C <= 1;
            "J" : J <= 1;
            "K" : K <= 1;
            "X" : X <= 1;
            ";" : begin
                    @(posedge CLK);
                    A<=0; B<=0; C<=0; J<=0; K<=0; X<=0;
                  end
          endcase
        end
      @(posedge CLK);
      A<=0; B<=0; C<=0; J<=0; K<=0; X<=0;
      @(posedge CLK);
      breakpoint=breakpoint+1;
    end
  endtask

  always
    begin
      CLK <= 0 ;
      #(PERIOD/2) ;
      CLK <= 1 ;
      #(PERIOD/2) ;
    end

  initial
    begin : TEST
      $timeformat(-9,0,"ns:",6);
      breakpoint=0;
      @(posedge CLK);
      A<=0; B<=0; C<=0; J<=0; K<=0; X<=0;

     $display("TESTING COMPLEX SEQUENCE");
     $display("%t Testing incomplete enabling sequence",$time);
     do_test("C;B;B;B");
     $display("%t Testing passing fulfilling sequence",$time);
     do_test("C;B;A;J;J;J;J;K");
     $display("%t Testing passing fulfilling sequence",$time);
     do_test("C;B;B;B;A;J;J;J;J;K");
     $display("%t Testing disabled enabling sequence",$time);
     do_test("C;B;B;B;X;J;J;J;J;;K");
     $display("%t Testing disabled fulfilling sequence",$time);
     do_test("C;B;B;A;J;J;J;J;X");
     $display("%t Testing failing fulfilling sequence",$time);
     do_test("C;B;A;J;J;J;J;;K");

      $display("TESTING IS COMPLETE");
      $finish;
    end

// assertions 
  property SIMPLE_SEQ;
    @(negedge CLK) disable iff (X)
     (A ##1 B ##1 C) |=> (J ##1 K);
  endproperty

  assert property (SIMPLE_SEQ);

  property COMPLEX_SEQ;
    @(negedge CLK) disable iff (X)
     (C ##1 B[*1:3] ##1 A) |=> (J[*4] ##1 K);
  endproperty

  assert property (COMPLEX_SEQ);


endmodule
