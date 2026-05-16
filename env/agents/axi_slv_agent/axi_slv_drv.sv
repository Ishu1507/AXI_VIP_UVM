class axi_slv_drv extends uvm_driver #(axi_seq_item);
  `uvm_component_utils (axi_slv_drv)
  
  
  virtual axi_interface axi_if;
  
  axi_seq_item req_item;
  axi_env_config axi_env_config_h;
  
  axi_id_scheduler axi_id_scheduler_h;
  
  bit [DATA_WIDTH-1:0] slave_mem [0:MEM_DEPTH-1];
  
  uvm_event id_available_event;

  int outstanding_read;
  

  
  function new (string name = "axi_slv_drv", uvm_component parent = null);
    	super.new (name, parent);
  endfunction
  
  virtual function void build_phase (uvm_phase phase);
    super.build_phase (phase);
    
    if (!uvm_config_db #(virtual axi_interface):: get (this, "", "axi_interface", axi_if))
      `uvm_fatal (get_type_name(), $psprintf("Could not get AXI master interface instance"));

    if (!uvm_config_db #(axi_env_config):: get (this, "", "axi_cfg", axi_env_config_h))
        `uvm_fatal (get_type_name(), $psprintf("Could not get AXI config object"));

    id_available_event = uvm_event_pool::get_global("id_available_event");
    
    foreach (slave_mem[i])
    begin
      slave_mem[i] = i;
      `uvm_info (get_type_name(), $psprintf("slave_mem[%0d] = %0h", i, slave_mem[i]), UVM_DEBUG)
    end
    
    
  endfunction
    
  task check_beat_readiness ();
  
  	bit [1:0] induce_stall;

	induce_stall = $urandom_range (0,3);

	repeat (induce_stall)
		@(posedge axi_if.axi_clk);
  endtask
  
  task drv_rst(); 
  	axi_if.RDATA		<= 256'b0;
   	axi_if.RVALID		<= 1'b0;
   	axi_if.RLAST		<= 1'b0;
   	axi_if.RRESP		<= 1'b0;
   	axi_if.RID			<= 6'b0; 
    
    axi_if.ARREADY 		<= 1'b0;
  endtask
  
  task drv_rdy();
    fork
    begin //{
	if (axi_if.ARVALID && axi_if.ARREADY)
	begin//{
		outstanding_read++;
	end//}
	else if (axi_if.RVALID && axi_if.RREADY && axi_if.RLAST)
	begin //{
		outstanding_read--;
	end //}
    end 
    begin
	if (axi_env_config_h.arrdy_rnd_en_val_m) //ARREADY randomization enabled
	begin //{
		if (outstanding_read <= MAX_OUTSTANDING_READ)
		begin //{
		          axi_if.ARREADY <= 1;
		end //}
		else if (outstanding_read > MAX_OUTSTANDING_READ)
		begin //{
			axi_if.ARREADY <= 0;
		end //}
	end //}
	else
		axi_if.ARREADY <= 1; //ARREADY fixed to high
    end
    join
    `uvm_info (get_type_name(), $psprintf ("Current outstanding read count = %d, Max outstanding limit = %d", outstanding_read, MAX_OUTSTANDING_READ), UVM_HIGH) 
    @(posedge axi_if.axi_clk);
  endtask
  
  task drv_txn ();
    
    if (req_item.RVALID)
    begin
      	axi_if.RVALID 	<= req_item.RVALID;
        axi_if.RDATA  	<= req_item.RDATA;
        axi_if.RLAST	<= req_item.RLAST;
        axi_if.RRESP	<= req_item.RRESP;
        axi_if.RID		<= req_item.RID;
        
        do
    	begin
          @(posedge axi_if.axi_clk);
    	end
        while (!axi_if.RREADY);
        
        axi_if.RVALID  <= 1'b0; 
    end
    else 
      axi_if.RVALID <= req_item.RVALID;
  
  endtask
  
  task initiate_drive_r_ch ();
    ar_ch_tr ar_ch_tr_rd_h;
    bit next_rdy;
 
    logic [5:0]  rd_addr;
    int len_of_burst;
    bit [5:0] serve_id;
    
    
    id_available_event.wait_trigger();

    
    while (axi_id_scheduler_h.id_database.num() > 0)
    begin
      $display ("id_database.num() = %d", axi_id_scheduler_h.id_database.num());
      axi_id_scheduler_h.get_next_txn (ar_ch_tr_rd_h); //Scheduler providing next ID to be served.
      
      //len_of_burst = ar_ch_tr_rd_h.arlen + 1;
      //rd_addr = ar_ch_tr_rd_h.araddr;
     `uvm_info (get_type_name(), $psprintf("Start of Rdata channel, ID = %h, start addr = %0h, length of burst = %d", ar_ch_tr_rd_h.arid, ar_ch_tr_rd_h.araddr, ar_ch_tr_rd_h.arlen + 1), UVM_NONE)
        
        
        
        //for (int i = 0; i < len_of_burst; i ++)
        //begin
            
      axi_if.RDATA  <= slave_mem[ar_ch_tr_rd_h.araddr];
      axi_if.RVALID <= 1'b1;
      axi_if.RID    <= ar_ch_tr_rd_h.arid; //ID being served
      	  
      if (ar_ch_tr_rd_h.count == ar_ch_tr_rd_h.arlen + 1)
      	axi_if.RLAST <= 1'b1;
      else
      	axi_if.RLAST <= 1'b0;
          
          
      do
      begin
      	@(posedge axi_if.axi_clk);
      end
      while (!axi_if.RREADY);
          
      `uvm_info(get_type_name(), $psprintf("ID served = %0h, Beat number = %d, current_addr = %0h, data from memory = %0h", axi_if.RID, ar_ch_tr_rd_h.count, ar_ch_tr_rd_h.araddr, axi_if.RDATA), UVM_NONE)
          
      axi_if.RVALID <= 1'b0;
      axi_if.RLAST  <= 1'b0;
        
      if(axi_env_config_h.rvld_rnd_en_val_m) begin //{
	next_rdy = ($urandom_range (0,3) == 0) ? 0:1;
	if (!next_rdy)
      		check_beat_readiness();       
      end //}
      
    end
           
  endtask
  
  task run_phase (uvm_phase phase);
    super.run_phase (phase);
   fork
   begin 
     forever
       drv_rdy(); //Driving ARREADY
   end
     
   begin
     initiate_drive_r_ch ();
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
