// Code your testbench here
// or browse Examples

`include "axi_interface.sv"
`include "axi_env_pkg.sv";

module axi_tb_top;
	
  bit axi_clk;
  

  
  axi_interface axi_if(axi_clk);
  
 
  
  always  #5 axi_clk = !axi_clk;
  
  initial
  begin

    axi_clk = 0;
    $dumpfile("dump.vcd");
    $dumpvars(0, axi_tb_top);
    //#100 $finish;
  end
    
  
  initial
  begin
    
    uvm_config_db #(virtual axi_interface)::set (null, "uvm_test_top.axi_env_h.*", "axi_interface", axi_if);
    
    run_test (); 
    
  end
endmodule