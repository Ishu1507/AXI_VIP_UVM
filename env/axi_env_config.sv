class axi_env_config extends uvm_object;
  `uvm_object_utils(axi_env_config)
  
  bit [5:0] arlen_val, arlen_val_m;
  bit [5:0] num_of_requests_val, num_of_requests_val_m;
  bit arlen_switch_cfg;
  bit ooo_en_val_m, intrlv_en_val_m;
  bit arrand_en_m, arrdy_rnd_en_val_m; 
  
  bit rvld_rnd_en_val_m; 
  bit arvld_rnd_en_val_m; 
  
  function new (string name = "axi_env_config");
    super.new (name);
  endfunction
  
  
  function void run_time_args();
   
  if ($value$plusargs("ARLEN=%d", arlen_val))
  begin
  	arlen_val_m = arlen_val;
    	arlen_switch_cfg = 1;
    	`uvm_info(get_type_name(), $psprintf("Value of arlen_val_m= %d", arlen_val_m), UVM_NONE)
  end
  
  if ($value$plusargs("NUM_REQS=%d", num_of_requests_val))
  begin
  	num_of_requests_val_m = num_of_requests_val;
  	`uvm_info(get_type_name(), $psprintf("Value of num_of_requests = %d", num_of_requests_val_m), UVM_NONE)
  end
  else
  	num_of_requests_val_m = 1;
    
  if ($test$plusargs("OOO"))
  begin
  	ooo_en_val_m = 1;
  	`uvm_info(get_type_name(), $psprintf("OOO enabled"), UVM_NONE)
  end
  else
  	ooo_en_val_m = 0;
  
  if ($test$plusargs("INTRLV"))
  begin
  	intrlv_en_val_m = 1;
  	`uvm_info(get_type_name(), $psprintf("OOO enabled"), UVM_NONE)
  end
  else
  	intrlv_en_val_m = 0;

  if ($test$plusargs("ARRDY_RND_EN"))
  begin
  	arrdy_rnd_en_val_m = 1;
  	`uvm_info(get_type_name(), $psprintf("ARREADY randomization enabled"), UVM_NONE)
  end
  else
	arrdy_rnd_en_val_m = 0;  

  if ($test$plusargs("RVLD_RND_EN"))
  begin
  	rvld_rnd_en_val_m = 1;
  	`uvm_info(get_type_name(), $psprintf("RVALID randomization enabled"), UVM_NONE)
  end
  else
	rvld_rnd_en_val_m = 0;

  if ($test$plusargs("ARVLD_RND_EN"))
  begin
  	arvld_rnd_en_val_m = 1;
  	`uvm_info(get_type_name(), $psprintf("ARVALID randomization enabled"), UVM_NONE)
  end
  else
	arvld_rnd_en_val_m = 0;


endfunction
  
endclass
