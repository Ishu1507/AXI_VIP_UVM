typedef enum {WRITE, READ} trans_type;
class axi_seq_item extends uvm_sequence_item;
  `uvm_object_utils (axi_seq_item)
  
  
  function new (string name = "axi_seq_item");
    super.new (name);
  endfunction
  
  rand bit rst;
  rand bit drv_txn;
 
  trans_type tr_type; 
   
  
 /////////////////////Read address channel signals//////////////////
   rand logic [31:0] ARADDR;
   rand logic        ARVALID;
   rand logic [7:0]  ARLEN;
   rand logic [5:0]  ARID;
  
   logic 	     ARREADY;
  
 /////////////////////Read Data channel signals////////////////////
   logic [255:0] RDATA;
   logic 	 RVALID;
   logic 	 RREADY;
   logic 	 RLAST;
   logic 	 RRESP;
   logic [5:0]	 RID;


////////////////////Write Address channel signals//////////////////

   rand logic [ID_WIDTH-1:0] AWID;
   rand logic [ADDR_WIDTH-1:0] AWADDR;
   rand logic [BURST_LEN_WIDTH-1:0] AWLEN;
   rand logic [1:0] AWBURST;
   rand logic AWVALID;
   logic AWREADY;

///////////////////Write Data channel signals////////////////////
   
   logic [ID_WIDTH-1:0] WID;
   logic [DATA_WIDTH-1:0] WDATA;
   rand logic [STRB_WIDTH-1:0] WSTRB; 
   logic WREADY;
   logic WVALID;
   logic WLAST;

//////////////////Write Response signals///////////////////////

   logic [ID_WIDTH-1:0] BID;
   logic [1:0] BRESP;
   logic BVALID;
   logic BREADY;

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
  
  
