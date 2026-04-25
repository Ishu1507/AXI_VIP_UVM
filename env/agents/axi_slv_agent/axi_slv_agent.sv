class axi_slv_agent extends uvm_agent;
  `uvm_component_utils(axi_slv_agent)
  
  axi_slv_drv axi_slv_drv_h;
  axi_slv_seqr axi_slv_seqr_h;
  
  axi_slv_mon axi_slv_mon_h;
  
  function new (string name = "axi_slv_agent", uvm_component parent = null);
    super.new (name, parent);
  endfunction
  
  virtual function void build_phase (uvm_phase phase);
    super.build_phase (phase);
    
    axi_slv_drv_h  = axi_slv_drv::type_id::create ("axi_slv_drv_h", this);
    axi_slv_seqr_h = axi_slv_seqr::type_id::create ("axi_slv_seqr_h", this);
    
    axi_slv_mon_h = axi_slv_mon::type_id::create("axi_slv_mon_h", this);
  endfunction
  
  virtual function void connect_phase (uvm_phase phase);
    super.connect_phase(phase);
    
    axi_slv_drv_h.seq_item_port.connect(axi_slv_seqr_h.seq_item_export);
   
  endfunction
  
endclass