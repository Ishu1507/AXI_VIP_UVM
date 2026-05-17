class axi_base_seq extends uvm_sequence;
  `uvm_object_utils(axi_base_seq)
  
  axi_env_config axi_env_config_h;
  
  bit [5:0] arlen;
  bit [10:0] araddr;
  bit [5:0] arid;

  //Write channel variables
  bit [ID_WIDTH - 1] awid;
  bit [BURST_LEN_WIDTH-1:0] awlen;
  
  
  int num_requests;
  
  function new (string name = "axi_base_seq");
    super.new (name);
    
  endfunction

  task body();
    //super.body();
    
    if (!uvm_config_db #(axi_env_config)::get (null, "", "axi_cfg", axi_env_config_h))
      `uvm_error (get_type_name(), $psprintf("Not able to get config db for cfg object"))
                  
    arlen = axi_env_config_h.arlen_val_m;
    	`uvm_info (get_type_name(), $psprintf("Value of arlen = %d", arlen), UVM_HIGH)
    
    num_requests = axi_env_config_h.num_of_requests_val_m;
    	`uvm_info (get_type_name(), $psprintf("Value of num_requests = %d", num_requests), UVM_HIGH)
  
    awlen = axi_env_config_h.awlen_val_m;
    	`uvm_info (get_type_name(), $psprintf("Value of awlen = %d", awlen), UVM_HIGH)                
  endtask
  
endclass
