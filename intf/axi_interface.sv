 interface axi_interface (input bit axi_clk);
  
   import axi_env_pkg::*;
 
/////////////////////Read Address channel signals/////////////////  
  //AR channel signals
   logic [5:0]  ARADDR;
   logic        ARVALID;
   logic 	    ARREADY;
   logic [7:0]  ARLEN;
   logic [5:0] 	ARID;
  
////////////////////Read channel data signals////////////////////
   logic [255:0]	RDATA;
   logic 			RVALID;
   logic 			RREADY;
   logic 			RLAST;
   logic 			RRESP;
   logic [5:0]		RID;


////////////////////Write Address channel signals//////////////////

   logic [ID_WIDTH-1:0] AWID;
   logic [ADDR_WIDTH-1:0] AWADDR;
   logic [BURST_LEN_WIDTH-1:0] AWLEN;
   logic [1:0] AWBURST;
   logic AWVALID;
   logic AWREADY;

///////////////////Write data channel signals////////////////////
   
   //logic [ID_WIDTH-1:0] WID;
   logic [DATA_WIDTH-1:0] WDATA;
   logic [STRB_WIDTH-1:0] WSTRB; 
   logic WREADY;
   logic WVALID;
   logic WLAST;

//////////////////Write response signals///////////////////////

   logic [ID_WIDTH-1:0] BID;
   logic [1:0] BRESP;
   logic BVALID;
   logic BREADY;
  
  
endinterface
