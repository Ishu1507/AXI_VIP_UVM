`uvm_analysis_imp_decl (_arch_mon_imp)
`uvm_analysis_imp_decl (_rch_mon_imp)

`uvm_analysis_imp_decl (_awch_mon_imp)
`uvm_analysis_imp_decl (_wch_mon_imp)

typedef ar_ch_tr queue_id [$];
class axi_id_scheduler extends uvm_component;
  `uvm_component_utils(axi_id_scheduler)
  
  virtual axi_interface axi_if;
  
  ar_ch_tr ar_ch_tr_queue [$];
  
  ar_ch_tr latency_model_queue [$];
  
  bit [5:0] ooo_resp_id [$];
  
  bit [5:0] serve_id;
  
  queue_id id_database [bit [5:0]];
  
  bit [5:0] my_id;
  
  bit initialized, initial_id_rdy_to_srv;
  
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
  
  task run_phase (uvm_phase phase);
    
    ar_ch_tr ar_ch_tr_h; 
    
  	super.run_phase (phase);   
    
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
         
  endtask

/////////// Functions for Write channel////////////////               
 function write_awch_mon_imp (axi_seq_item aw_mst_txn);

 endfunction
 
function write_wch_mon_imp (axi_seq_item w_mst_txn);

 endfunction

  
  
  
endclass
