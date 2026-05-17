class axi_mst_drv extends uvm_driver #(axi_seq_item);
  `uvm_component_utils (axi_mst_drv)
  
  
  virtual axi_interface axi_if;
  
  uvm_analysis_port #(axi_seq_item) arch_mon_port;
  
  bit next_rdy; 
  axi_seq_item req_item;
  axi_env_config axi_env_config_h;
 
  axi_memory axi_memory_h;

  axi_seq_item wdata_q [$];
 
  function new (string name = "axi_mst_drv", uvm_component parent = null);
    	super.new (name, parent);
  endfunction
  
  virtual function void build_phase (uvm_phase phase);
    super.build_phase (phase);
    
    if (!uvm_config_db #(virtual axi_interface):: get (this, "", "axi_interface", axi_if))
      `uvm_fatal (get_type_name(), $psprintf("Could not get AXI master interface instance"));

    if (!uvm_config_db #(axi_env_config):: get (this, "", "axi_cfg", axi_env_config_h))
        `uvm_fatal (get_type_name(), $psprintf("Could not get AXI config object"));

   
    arch_mon_port = new ("arch_mon_port", this);
    
  endfunction
    
  task check_req_readiness ();
	bit induce_stall;

	induce_stall = $urandom_range (0,3);
	repeat (induce_stall)
		@(posedge axi_if.axi_clk);	
  endtask
  task drv_rst();
    
	axi_if.ARADDR	<= 32'b0;
	axi_if.ARVALID <= 1'b0;
   	axi_if.ARLEN 	<= 1'b0;
	axi_if.ARID 	<= 6'b0; 
    
    	axi_if.RREADY 	<= 1'b0;

	axi_if.AWADDR	<= {ADDR_WIDTH{1'b0}};
	axi_if.AWVALID  <= 1'b0;
   	axi_if.AWLEN 	<= 1'b0;
	axi_if.AWID 	<= 6'b0;

	axi_if.WDATA	<= {DATA_WIDTH{1'b0}};
	axi_if.WVALID  	<= 1'b0;
	axi_if.WLAST  	<= 1'b0;
	axi_if.WSTRB  	<= {STRB_WIDTH{1'b0}};
   	 
    	axi_if.BREADY 	<= 1'b0;
 
    
    	axi_if.BREADY 	<= 1'b0;
	
	@(posedge axi_if.axi_clk);
  endtask
  
  task drv_txn (); //Task to drive AR channel transactions
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
      
	if(axi_env_config_h.arvld_rnd_en_val_m)
	begin //{
		next_rdy = ($urandom_range (0,3) == 0) ? 0:1;

		if (!next_rdy)
			check_req_readiness ();
	end //} 
    end
    else 
      axi_if.ARVALID <= req_item.ARVALID;
  endtask
 
  task drv_wch_awtxn (); //Task to drive AW channel transactions
    if (req_item.AWVALID)
    begin //{
      	axi_if.AWVALID 	<= req_item.AWVALID;
        axi_if.AWADDR  	<= req_item.AWADDR;
        axi_if.AWLEN  	<= req_item.AWLEN;
        axi_if.AWID	<= req_item.AWID;
      
        do
    	begin
          @(posedge axi_if.axi_clk);
    	end
        while (!axi_if.AWREADY);
        
        axi_if.AWVALID 	<= 1'b0;
	
    end //}
  endtask

  task drv_wch_data (); //Task to drive WDATA beats
	axi_seq_item axi_seq_item_h;
	
	bit [ADDR_WIDTH-1:0] curr_addr;
	bit [BURST_LEN_WIDTH-1:0] awlen;
	bit [STRB_WIDTH-1:0] strb;

	int i;
	

	`uvm_info (get_type_name(), $psprintf ("Inside drive WDATA task"), UVM_HIGH)
	
	forever
	begin //{

		wait (wdata_q.size() != 0);
		axi_seq_item_h = wdata_q.pop_front ();
		
		awlen = axi_seq_item_h.AWLEN; 
		curr_addr = axi_seq_item_h.AWADDR;
		strb = axi_seq_item_h.WSTRB;
		i = 0;
		`uvm_info (get_type_name (), $psprintf ("AW txn to serve: AWADDR = %0h, AWLEN = %0h, STTB = %0h", curr_addr, awlen, strb), UVM_HIGH)
		 
		while (i < awlen + 1)
		begin //{
			axi_if.WDATA	<= {axi_memory_h.mem[curr_addr + 3], axi_memory_h.mem[curr_addr + 2], axi_memory_h.mem[curr_addr + 1], axi_memory_h.mem[curr_addr]};
			axi_if.WSTRB	<= strb;
			axi_if.WVALID 	<= 1'b1;
			
			if (i == awlen)
				axi_if.WLAST 	<= 1'b1;			 

			do
    			begin //{
          			@(posedge axi_if.axi_clk);
    			end //}
        		while (!axi_if.WREADY);

			axi_if.WVALID 	<= 1'b0;
			axi_if.WLAST 	<= 1'b0;
			curr_addr = curr_addr + 4;
			i++;
		end //}
	end //}	 	
  endtask
 
  task drv_rdy();
  	int rnd_val; 
  	if (axi_env_config_h.rrdy_rnd_en_val_m)
  	begin //{
  	      `uvm_info (get_type_name(), $psprintf ("RRDY randomization enableled"), UVM_HIGH)	
  	      do
  	      begin //{
  	      	rnd_val = $urandom_range(0,100);
  	      	`uvm_info (get_type_name (), $psprintf ("rnd_val = %d", rnd_val), UVM_HIGH)	
  	      	if (rnd_val < 30)
  	      	begin
  	      		axi_if.RREADY <= 1'b1;
  	      	end
  	      	else
  	      		axi_if.RREADY <= 1'b0;
		
		@(posedge axi_if.axi_clk);
  	      end //}			
  	      while (1);		 
  	end //}
  	else
  	begin //{
  	      axi_if.RREADY <= 1'b1;
  	end //}
			 
  endtask
  
  task run_phase (uvm_phase phase);
    //super.new (phase);
   
   
   fork
   begin
     drv_rdy();
   end
   begin
	do
		drv_wch_data();
        while (!wdata_q.size());
   end 
   begin //{  
   	forever
   	begin //{
    		seq_item_port.get_next_item (req_item);
      
    		if (req_item.rst)
      			drv_rst();
    		else if (req_item.drv_txn)
		begin //{
			if (req_item.tr_type == WRITE)
			begin //{
					wdata_q.push_back(req_item);
					drv_wch_awtxn ();
			end //}
			else
      				drv_txn();
		end //}
      
     		seq_item_port.item_done();
    	end //}     
   end //}
   join
  endtask		
      
endclass
