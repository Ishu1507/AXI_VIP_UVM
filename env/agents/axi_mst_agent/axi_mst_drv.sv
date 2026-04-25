class axi_mst_drv extends uvm_driver #(axi_seq_item);
  `uvm_component_utils (axi_mst_drv)
  
  
  virtual axi_interface axi_if;
  
  uvm_analysis_port #(axi_seq_item) arch_mon_port;
  
  axi_seq_item req_item;
  
  function new (string name = "axi_mst_drv", uvm_component parent = null);
    	super.new (name, parent);
  endfunction
  
  virtual function void build_phase (uvm_phase phase);
    super.build_phase (phase);
    
    if (!uvm_config_db #(virtual axi_interface):: get (this, "", "axi_interface", axi_if))
      `uvm_info (get_type_name(), $psprintf("Could not get AXI master interface instance"), UVM_NONE);
   
    arch_mon_port = new ("arch_mon_port", this);
    
  endfunction
    

  task drv_rst();
    
	axi_if.ARADDR	<= 32'b0;
	axi_if.ARVALID <= 1'b0;
   	axi_if.ARLEN 	<= 1'b0;
	axi_if.ARID 	<= 6'b0; 
    
    axi_if.RREADY 	<= 1'b0;
  endtask
  
  task drv_txn ();
    `uvm_info(get_type_name(), "Entered drv_txn task in mst drv", UVM_NONE)
    
    if (req_item.ARVALID)
    begin

      
      	axi_if.ARVALID 	<= req_item.ARVALID;
        axi_if.ARADDR  	<= req_item.ARADDR;
        axi_if.ARLEN  	<= req_item.ARLEN;
        axi_if.ARID		<= req_item.ARID;
      
        do
    	begin
          @(posedge axi_if.axi_clk);
    	end
        while (!axi_if.ARREADY);
        
        axi_if.ARVALID 	<= 1'b0;
      
        arch_mon_port.write (req_item);
        
      
    end
    else 
      axi_if.ARVALID <= req_item.ARVALID;
  
  endtask
  
  task drv_rdy();
    
    do
    begin
    	@(posedge axi_if.axi_clk);
		axi_if.RREADY <= 1'b1;
    end
    while (!axi_if.RVALID);
  endtask
  
  
  
  
  
  task run_phase (uvm_phase phase);
    //super.new (phase);
   
   
   fork
   begin
     drv_rdy();
   end
   
   begin   
   	forever
   	begin
    
    	seq_item_port.get_next_item (req_item);
      
    	if (req_item.rst)
      		drv_rst();
    	else if (req_item.drv_txn)
      		drv_txn();
      
     	seq_item_port.item_done();
    end      
   end
   join
  endtask		
      
endclass