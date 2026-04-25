class axi_env extends uvm_env;
  `uvm_component_utils (axi_env)
  
  axi_mst_agent axi_mst_agent_h;
  axi_slv_agent axi_slv_agent_h;
  
  axi_id_scheduler axi_id_scheduler_h;
  
  function new (string name = "axi_env", uvm_component parent = null);
    super.new (name, parent);
  endfunction
  
  function void build_phase (uvm_phase phase);
    super.build_phase(phase);    
    	axi_mst_agent_h = axi_mst_agent::type_id::create ("axi_mst_agent_h", this); 
    	axi_slv_agent_h = axi_slv_agent::type_id::create ("axi_slv_agent_h", this);
    
    	axi_id_scheduler_h = axi_id_scheduler::type_id::create ("axi_id_scheduler_h", this);
    	
  endfunction
  
  function void connect_phase (uvm_phase phase);
    super.connect_phase(phase);
    
    axi_mst_agent_h.axi_mst_drv_h.arch_mon_port.connect (axi_id_scheduler_h.arch_mon_imp);
    axi_slv_agent_h.axi_slv_mon_h.rch_mon_port.connect(axi_id_scheduler_h.rch_mon_imp);
    
    axi_slv_agent_h.axi_slv_drv_h.axi_id_scheduler_h = axi_id_scheduler_h;
    
  endfunction  
  
endclass