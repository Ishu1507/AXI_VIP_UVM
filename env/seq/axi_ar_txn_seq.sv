class axi_ar_txn_seq extends axi_base_seq;
  `uvm_object_utils(axi_ar_txn_seq)
  
  axi_seq_item req_item;
  
  function new (string name = "axi_ar_txn_seq");
    super.new (name);
  endfunction
  
  
  task body();
    super.body();
    
    
    req_item = axi_seq_item::type_id::create ("req_item");
    
    for (int i = 0; i < num_requests; i++)
    
    if (axi_env_config_h.arlen_switch_cfg)   
    	`uvm_do_with (req_item, {req_item.rst == 0; req_item.drv_txn == 1; req_item.ARVALID == 1; req_item.ARLEN == arlen;})
    else
    begin
    	start_item (req_item);
        req_item.randomize () with {rst == 0; drv_txn == 1; ARVALID == 1;};
    	finish_item(req_item);
    end
  endtask
  
endclass
  