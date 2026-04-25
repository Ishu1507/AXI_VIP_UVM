class axi_base_test extends uvm_test;
  `uvm_component_utils (axi_base_test)
  
  axi_env	axi_env_h;
  axi_env_config axi_env_config_h;
  axi_reset_seq axi_reset_seq_h;
  
  
  function new (string name = "axi_base_test", uvm_component parent = null);
    super.new (name, parent);
  endfunction
  
  function void build_phase (uvm_phase phase);
    super.build_phase (phase);  
    axi_env_h     = axi_env::type_id::create ("axi_env_h", this);
    
    axi_env_config_h = axi_env_config::type_id::create ("axi_env_config_h", this);
    
    axi_env_config_h.run_time_args();
    
    uvm_config_db #(axi_env_config)::set (null, "*", "axi_cfg", axi_env_config_h);
    
    	
    axi_reset_seq_h = axi_reset_seq::type_id::create("axi_reset_seq_h");
    
  endfunction
  
  task run_phase(uvm_phase phase);
    super.run_phase (phase);
    `uvm_info(get_type_name(), "axi_base_test RUN PHASE ENTERED", UVM_NONE)
    
    phase.raise_objection(this);
    
    axi_reset_seq_h.start(axi_env_h.axi_mst_agent_h.axi_mst_seqr_h);
    axi_reset_seq_h.start(axi_env_h.axi_slv_agent_h.axi_slv_seqr_h);
    
   
    phase.drop_objection(this);
    
  endtask
endclass