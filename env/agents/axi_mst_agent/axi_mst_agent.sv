class axi_mst_agent extends uvm_agent;
  `uvm_component_utils(axi_mst_agent)
  
  axi_mst_drv axi_mst_drv_h;
  axi_mst_seqr axi_mst_seqr_h;
  axi_mst_mon axi_mst_mon_h;
  
  
  function new (string name = "axi_mst_agent", uvm_component parent = null);
    super.new (name, parent);
  endfunction
  
  virtual function void build_phase (uvm_phase phase);
    super.build_phase (phase);
    
    axi_mst_drv_h  = axi_mst_drv::type_id::create ("axi_mst_drv_h", this);
    axi_mst_seqr_h = axi_mst_seqr::type_id::create ("axi_mst_seqr_h", this);
    axi_mst_mon_h = axi_mst_mon::type_id::create ("axi_mst_mon_h", this);
    
  endfunction
  
  virtual function void connect_phase (uvm_phase phase);
    super.connect_phase(phase);
    
    axi_mst_drv_h.seq_item_port.connect(axi_mst_seqr_h.seq_item_export);
   
  endfunction
  
endclass