 interface axi_interface (input bit axi_clk);
  
   
  
  //AR channel signals
   logic [5:0]  ARADDR;
   logic        ARVALID;
   logic 	    ARREADY;
   logic [7:0]  ARLEN;
   logic [5:0] 	ARID;
  
   // Rchannel signals
   logic [255:0]	RDATA;
   logic 			RVALID;
   logic 			RREADY;
   logic 			RLAST;
   logic 			RRESP;
   logic [5:0]		RID; 
  
  
endinterface