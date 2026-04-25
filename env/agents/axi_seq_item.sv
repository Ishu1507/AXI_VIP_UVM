class axi_seq_item extends uvm_sequence_item;
  `uvm_object_utils (axi_seq_item)
  
  
  function new (string name = "axi_seq_item");
    super.new (name);
  endfunction
  
  rand bit rst;
  rand bit drv_txn;
  
  //AR channel signals
   rand logic [31:0] ARADDR;
   rand logic        ARVALID;
   rand logic [7:0]  ARLEN;
   rand logic [5:0]  ARID;
  
   logic 	     ARREADY;
  
   // Rchannel signals
   logic [255:0]	RDATA;
   logic 			RVALID;
   logic 			RREADY;
   logic 			RLAST;
   logic 			RRESP;
   logic [5:0]		RID; 
  
  
  constraint c_arlen {ARLEN inside {[0:3]};}
  
endclass

class ar_ch_tr;
  logic [5:0]   araddr;
  logic [7:0]   arlen;
  logic [5:0] 	arid;
  
  bit [7:0] count;
  bit rdy_to_srv;
  
  rand bit [3:0] delay;
endclass
  
  
