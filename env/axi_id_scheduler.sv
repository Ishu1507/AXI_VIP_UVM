`uvm_analysis_imp_decl (_arch_mon_imp)
`uvm_analysis_imp_decl (_rch_mon_imp)

`uvm_analysis_imp_decl (_awch_mon_imp)
`uvm_analysis_imp_decl (_wch_mon_imp)

typedef ar_ch_tr queue_id [$];
typedef logic [ID_WIDTH-1:0] write_id; 
class axi_id_scheduler extends uvm_component;
  `uvm_component_utils(axi_id_scheduler)
  
  virtual axi_interface axi_if;
 
  //////////////For Write channels/////////////

  b_ch_tr wr_rsp_database [write_id][$]; //Data base for write channels
  aw_ch_tr awtxn_q [$]; //Stores AW transaction requets  
  axi_seq_item wdata_q [$]; //Stores WDATA beats
  b_ch_tr bch_q [$]; 
 
  //////////////For Read channels////////////// 
  ar_ch_tr ar_ch_tr_queue [$];
  
  ar_ch_tr latency_model_queue [$];
  
  bit [5:0] ooo_resp_id [$];
  
  bit [5:0] serve_id;
  
  queue_id id_database [bit [5:0]];
  
  bit [5:0] my_id;
  
  bit initialized, initial_id_rdy_to_srv;
  bit wr_rsp_initialized, wr_rsp_initial_id_rdy_to_srv;
  
  axi_env_config axi_env_config_h;
  
  uvm_event id_available_event;
 
  uvm_analysis_imp_arch_mon_imp #(axi_seq_item, axi_id_scheduler) arch_mon_imp;
  uvm_analysis_imp_rch_mon_imp #(axi_seq_item, axi_id_scheduler) rch_mon_imp;
  
  uvm_analysis_imp_awch_mon_imp #(axi_seq_item, axi_id_scheduler) awch_mon_imp;
  uvm_analysis_imp_wch_mon_imp #(axi_seq_item, axi_id_scheduler) wch_mon_imp;
  
  function new (string name = "axi_id_scheduler", uvm_component parent = null);
    super.new (name, parent);
  
  endfunction 
                
  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    //////////Read channel imp port creation///////////
    arch_mon_imp = new ("arch_mon_imp", this);
    rch_mon_imp = new ("rch_mon_imp", this);

    ////////Write channle imp port creation////////////
    awch_mon_imp = new ("awch_mon_imp", this);
    wch_mon_imp = new ("wch_mon_imp", this);
    
    if (!uvm_config_db #(axi_env_config):: get (this, "", "axi_cfg", axi_env_config_h))
      `uvm_info (get_type_name(), $psprintf("Could not get AXI config object"), UVM_NONE);
    
    if (!uvm_config_db #(virtual axi_interface):: get (this, "", "axi_interface", axi_if))
      `uvm_info (get_type_name(), $psprintf("Could not get AXI master interface instance"), UVM_NONE);
    
    id_available_event = uvm_event_pool::get_global("id_available_event");
    
  endfunction
  
  task automatic latency_model (ar_ch_tr ar_ch_tr_h);
    //bit [3:0] count;
    
    fork
      begin
      	repeat (ar_ch_tr_h.delay)
       		@(posedge axi_if.axi_clk); 

       		`uvm_info (get_type_name (), $psprintf ("ID ready for response = %0h", ar_ch_tr_h.arid), UVM_HIGH)
       		ar_ch_tr_h.rdy_to_srv = 1; //Used for in order serving of requests 
       
       		//ooo_resp_id.push_back (ar_ch_tr_h.arid);
      end
    join_none
  endtask 

  task automatic wr_rsp_latency (b_ch_tr b_ch_tr_h);
    //bit [3:0] count;
    
    fork
      begin
        `uvm_info (get_type_name(), $psprintf("bresp latency delay = %d", b_ch_tr_h.delay), UVM_HIGH)
      	repeat (b_ch_tr_h.delay)
       		@(posedge axi_if.axi_clk); 

       		`uvm_info (get_type_name (), $psprintf ("BID ready for response = %0h", b_ch_tr_h.bid), UVM_HIGH)
       		b_ch_tr_h.brsp_rdy_to_srv = 1; //Used for in order serving of requests 
       
       		//ooo_resp_id.push_back (ar_ch_tr_h.arid);
      end
    join_none
  endtask
  
  task search_database(output bit [5:0] selected_id);
    
    if (!initialized)
    begin
  	  id_database.first(selected_id);
         
      while (id_database[selected_id][0].rdy_to_srv == 0)
      begin
        if (!id_database.next(selected_id))
        	id_database.first(selected_id);	
        
      	@(posedge axi_if.axi_clk);
      end
      
      $display ("MY initialized ID = %0h", my_id);
    
    end
     
    if (axi_env_config_h.ooo_en_val_m && initialized)
    begin
        if (id_database[selected_id][0].count == id_database[selected_id][0].arlen + 1)
        begin
          	do
            begin
              if (id_database.next(selected_id))
                id_database.first(selected_id);	              	
            end
            while (id_database[selected_id][0].rdy_to_srv == 0);
         
        end
    end
    else if (axi_env_config_h.intrlv_en_val_m && initialized)
    begin
      `uvm_info (get_type_name(), $psprintf ("Inside interleaving logic"), UVM_HIGH)
      do
      begin
        if (!id_database.next(selected_id))
	begin
          id_database.first(selected_id);
          wait (id_database[selected_id][0].rdy_to_srv == 1); // Wait for last transaction to complete latency. Do not subject it to continous looping
          break;
        end
      end  
      while (id_database[selected_id][0].rdy_to_srv == 0);
    end
     
    initialized = 1;
  
  endtask
  
  task call_scheduler (output ar_ch_tr ar_ch_tr_h);
    
    search_database (my_id); // Provides ID
    
    `uvm_info (get_type_name (), $psprintf("SCHEDULER ID ready ARID = %0h", id_database[my_id][0].arid), UVM_HIGH)
              
    if (id_database[my_id][0].count == id_database[my_id][0].arlen)
    begin
      ar_ch_tr_h = id_database[my_id].pop_front(); //Serve this transaction
      ar_ch_tr_h.count++;   
    end
    else
    begin
    	ar_ch_tr_h = id_database[my_id][0];
        ar_ch_tr_h.count++;
    end
              
    if (ar_ch_tr_h.count > 1 )
    	ar_ch_tr_h.araddr = ar_ch_tr_h.araddr + 1;

 
    if (id_database [my_id].size () == 0)
    begin     
          id_database.delete (my_id);
          $display ("ID deleted %0h", my_id);
    end

     
  endtask
                
  task get_next_txn (output ar_ch_tr ar_ch_tr_h); //Provides transactions ready to be served.
  	
    int index;

    while (ar_ch_tr_queue.size() == 0)
      @(posedge axi_if.axi_clk);
    
    if (axi_env_config_h.ooo_en_val_m || axi_env_config_h.intrlv_en_val_m) //OOO logic
    begin
      
      //while (id_database.num())	
      	call_scheduler (ar_ch_tr_h);
      	 
     end
     else //In order logic
     begin
         
     	while (ar_ch_tr_queue[0].rdy_to_srv == 0) //Latency check
          @(posedge axi_if.axi_clk);
        
        ar_ch_tr_h = ar_ch_tr_queue.pop_front(); // In order response after latency check

      end

  endtask              
  
  function void write_arch_mon_imp (axi_seq_item mst_txn);
    
    ar_ch_tr ar_ch_tr_h; 
    
    ar_ch_tr_h = new ();
        
    ar_ch_tr_h.arid 	= mst_txn.ARID; 
    ar_ch_tr_h.arlen 	= mst_txn.ARLEN;
    ar_ch_tr_h.araddr 	= mst_txn.ARADDR;
        
    ar_ch_tr_h.randomize(); //delay randomization. This is fed to latency model.
        
        
    ar_ch_tr_queue.push_back(ar_ch_tr_h);
 
    id_database[ar_ch_tr_h.arid].push_back (ar_ch_tr_h);
    
    id_available_event.trigger();
    
    latency_model_queue.push_back(ar_ch_tr_h);
        
    `uvm_info (get_type_name(), $psprintf("AR Channel requests monitored arid = %0h, delay = %0d, arlen = %0h, araddr = %0h", ar_ch_tr_h.arid, ar_ch_tr_h.delay, ar_ch_tr_h.arlen, ar_ch_tr_h.araddr), UVM_LOW)
           
  endfunction
   
  function void write_rch_mon_imp (axi_seq_item slv_txn);
    
  endfunction

  /////////// Functions for Write channel////////////////               
 function write_awch_mon_imp (axi_seq_item aw_mst_txn); // Write function for AW requests
	//if (aw_mst_txn.AWREADY && aw_mst_txn.AWVALID)
	//begin //{	
		aw_ch_tr aw_ch_tr_h = new (); // Object creation for a received AW request
		
		aw_ch_tr_h.awid = aw_mst_txn.AWID;
		aw_ch_tr_h.awaddr = aw_mst_txn.AWADDR;
		aw_ch_tr_h.awlen = aw_mst_txn.AWLEN;
		aw_ch_tr_h.beat_count = 0; // Initializing beat count to 0 for raised AW request
		aw_ch_tr_h.wlast = 0; // Initializing WLAST to 0 for raised AW request
		
		`uvm_info (get_type_name(), $psprintf("AWID = %0h pushed to scheduler database", aw_ch_tr_h.awid), UVM_HIGH)
		//write_database[aw_ch_tr_h.awid].push_back(aw_ch_tr_h); // Raised AW request pushed to database handling writes.
		awtxn_q.push_back (aw_ch_tr_h);
	//end //}

 endfunction
 
 function write_wch_mon_imp (axi_seq_item w_mst_txn); // Write function for Wdata beats
	//if (w_mst_txn.WREADY && w_mst_txn.WVALID)
	//begin //{
		wdata_q.push_back(w_mst_txn); // Queue collecting wdata beats in order
		`uvm_info(get_type_name(), $psprintf("Beat data = %h WLAST = %h", w_mst_txn.WDATA, w_mst_txn.WLAST), UVM_HIGH)
	//end //}
 endfunction

  task get_bch_resp_txn (output b_ch_tr b_ch_tr_h);
	
       	write_id sel_id;
	
	if (axi_env_config_h.wresp_ooo_val_m)
	begin //{
		`uvm_info (get_type_name(), $psprintf("OOO bresp enabled"), UVM_HIGH)
		wait (wr_rsp_database.num())
		if (!wr_rsp_initialized)
		begin //{
			wr_rsp_database.first(sel_id);
			`uvm_info (get_type_name(), $psprintf("First bresp ID = %0h", sel_id), UVM_HIGH)
			wr_rsp_initialized = 1;
		end //}
	
		do
		begin //{
			if (!wr_rsp_database.next(sel_id))
				wr_rsp_database.first(sel_id);

			@(posedge axi_if.axi_clk);
			`uvm_info (get_type_name(), $psprintf("Current bresp ID = %0h", sel_id), UVM_HIGH)
		end //}
		while (!wr_rsp_database[sel_id][0].brsp_rdy_to_srv);
			
	
		`uvm_info (get_type_name(), $psprintf("B response ID selected to srv = %0h", sel_id), UVM_HIGH)	
		b_ch_tr_h = wr_rsp_database[sel_id].pop_front(); //Provides ID with rdy to srv response
		if (wr_rsp_database[sel_id].size() == 0)
		begin //{
			wr_rsp_database.delete(sel_id);
			`uvm_info (get_type_name(), $psprintf ("Bresp ID = %0h deleted, Entries in database = %d", sel_id, wr_rsp_database.num()), UVM_HIGH)
		end //}
	end //}
	else
	begin
		wait(bch_q.size() > 0);
		b_ch_tr_h = bch_q.pop_front();
	end

	//axi_seq_item_h.tr_type = WRITE;		
	//axi_seq_item_h.BID = b_ch_tr_h.bid; 
	//axi_seq_item_h.BRESP = b_ch_tr_h.bresp; 
		

  endtask

  task run_phase (uvm_phase phase);
    
    ar_ch_tr ar_ch_tr_h; 
    
    aw_ch_tr aw_ch_tr_h;

    b_ch_tr b_ch_tr_h;
 
    axi_seq_item axi_seq_item_h;
    super.run_phase (phase);   
    
    fork
    begin //{ Thread for Read requests latency modelling
    	forever //Logic to feed AR requests to Latency model.
    	begin
    	    
    	  if (latency_model_queue.size() > 0)
    	  begin
    	     ar_ch_tr_h = latency_model_queue.pop_front();
    	     latency_model (ar_ch_tr_h); //Sending currently receieved AR channel request to latency model
    	     `uvm_info (get_type_name (), $psprintf("To latency model ARID= %0h, Delay = %0d", ar_ch_tr_h.arid, ar_ch_tr_h.delay), UVM_HIGH)
    	  end
    	  else
    	    @(posedge axi_if.axi_clk); //Wait for next AR request to feed latency model
    	end
    end //}
    ///////////////////////Write channel threads///////////////////
    begin //{ Thread for AW and W channel monitoring and B channel response generation
	
	forever
	begin //{
		if (awtxn_q.size() > 0)
		begin //{
			aw_ch_tr_h = awtxn_q.pop_front ();
			`uvm_info (get_type_name (), $psprintf("Popped ID: %0h beat_count = %0d, awlen = %0d", aw_ch_tr_h.awid, aw_ch_tr_h.beat_count, aw_ch_tr_h.awlen), UVM_HIGH)
			do
			begin //{
				axi_seq_item_h = wdata_q.pop_front();
				aw_ch_tr_h.beat_count = aw_ch_tr_h.beat_count + 1; //Incrementing beat count for AW transaction request raised
				`uvm_info (get_type_name (), $psprintf("ID: %0h, Beat count = %0d,  Beat data = %0h, Beat last = %0h, awtxn_q.size() = %0d, wdata_q.size() = %0d", aw_ch_tr_h.awid, aw_ch_tr_h.beat_count, axi_seq_item_h.WDATA, axi_seq_item_h.WLAST, awtxn_q.size(), wdata_q.size()), UVM_HIGH)
				@(posedge axi_if.axi_clk); 
			end //}
			while (!axi_seq_item_h.WLAST);
			`uvm_info (get_type_name (), $psprintf("OUT OF DO WHILE LAST ID: %0h beat_count = %0d, awlen = %0d, WDATA= %0h, WLAST = 0h", aw_ch_tr_h.awid, aw_ch_tr_h.beat_count, aw_ch_tr_h.awlen, axi_seq_item_h.WDATA, axi_seq_item_h.WLAST), UVM_HIGH)	
			if (aw_ch_tr_h.beat_count == aw_ch_tr_h.awlen + 1)
			begin //{
				`uvm_info (get_type_name (), $psprintf("ID: %0h, Number of beats %d matches AWLEN + 1: %d", aw_ch_tr_h.awid, aw_ch_tr_h.beat_count, aw_ch_tr_h.awlen + 1), UVM_HIGH)
				 b_ch_tr_h = new();

				 b_ch_tr_h.bid = aw_ch_tr_h.awid; 
				 b_ch_tr_h.bresp = 2'b00;
				 b_ch_tr_h.randomize();
				 wr_rsp_latency(b_ch_tr_h); //Rsp txn subjected to latency. Rsp is given out based on latency completion for OOO response.
				 wr_rsp_database[b_ch_tr_h.bid].push_back(b_ch_tr_h); // Wr Response database needed for maintaining in order response for multiple outstanding transactions per ID.    
				 bch_q.push_back(b_ch_tr_h);
			end //}				
		end //}
		else
			@(posedge axi_if.axi_clk);

	end //}
    end //}
    
    join
         
  endtask
endclass  




