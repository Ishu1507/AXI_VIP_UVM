class axi_ar_txn_test extends axi_base_test;
  `uvm_component_utils (axi_ar_txn_test)
  
  axi_ar_txn_seq axi_ar_txn_seq_h;
  
  function new (string name = "axi_ar_txn_test", uvm_component parent = null);
    super.new (name, parent);
  endfunction
  
  function void build_phase (uvm_phase phase);
    super.build_phase (phase);
    
    axi_ar_txn_seq_h = axi_ar_txn_seq::type_id::create ("axi_ar_txn_seq_h");
    
  endfunction
  
  task run_phase (uvm_phase phase);
    super.run_phase (phase);
    
    `uvm_info(get_type_name(), "axi_ar_txn_test RUN PHASE ENTERED", UVM_NONE)
    
    phase.raise_objection(this);
    axi_ar_txn_seq_h.start(axi_env_h.axi_mst_agent_h.axi_mst_seqr_h);
    
     #10000;
    phase.drop_objection (this);
    
    
  endtask
  
endclass