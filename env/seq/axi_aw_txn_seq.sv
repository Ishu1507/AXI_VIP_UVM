class axi_aw_txn_seq extends axi_base_seq;
  `uvm_object_utils(axi_aw_txn_seq)
  
  axi_env_config axi_env_config_h;
  
  axi_seq_item axi_seq_item_aw_master_h;
  
  function new (string name = "axi_base_seq");
    super.new (name);
    
  endfunction

  task body();
    super.body();
    
    for (int i=0; i<num_requests; i++)
    begin //{
 	axi_seq_item axi_seq_item_aw_master_h;
	
	axi_seq_item_aw_master_h = axi_seq_item::type_id::create("axi_seq_item_aw_master_h");

        axi_seq_item_aw_master_h.tr_type = WRITE;
	//`uvm_do_with (axi_seq_item_aw_master_h, {rst == 0; drv_txn == 1; AWVALID == 1; AWLEN == local::awlen; WSTRB == ({STRB_WIDTH{1'b1}});});
	`uvm_do_with (axi_seq_item_aw_master_h, {rst == 0; drv_txn == 1; AWVALID == 1; WSTRB == ({STRB_WIDTH{1'b1}});});
	
	
    end //}     
  endtask
    
    
  
endclass
