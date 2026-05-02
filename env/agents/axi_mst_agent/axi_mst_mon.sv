class axi_mst_mon extends uvm_monitor;
  `uvm_component_utils (axi_mst_mon)
  
  virtual axi_interface axi_if;
  
  axi_seq_item req_item;
  
  uvm_analysis_port #(axi_seq_item) arch_mon_port;
  
  function new (string name = "axi_mst_mon", uvm_component parent = null);
    super.new (name, parent);
    
  endfunction
  
  function void build_phase (uvm_phase phase);
    super.build_phase (phase);
    
    if (!uvm_config_db #(virtual axi_interface):: get (this, "", "axi_interface", axi_if))
      `uvm_info (get_type_name(), $psprintf("Could not get AXI master interface instance"), UVM_NONE);
  
    arch_mon_port = new("arch_mon_port", this);
  endfunction
  
  task run_phase (uvm_phase phase);
    super.run_phase(phase);
    
    
    forever
      begin
        @(posedge axi_if.axi_clk);
		
        req_item = axi_seq_item::type_id::create ("req_item");
        
        if (axi_if.ARVALID == 1 && axi_if.ARREADY == 1)
        begin
          
          req_item.ARVALID = axi_if.ARVALID;
          req_item.ARREADY = axi_if.ARREADY;
          req_item.ARADDR = axi_if.ARADDR;
          req_item.ARLEN = axi_if.ARLEN;
          req_item.ARID = axi_if.ARID;
          
          arch_mon_port.write (req_item);
          `uvm_info (get_type_name(), $psprintf ("Master Monitor: ARID: %0h, ARADDR = %0h", req_item.ARID, req_item.ARADDR), UVM_HIGH)
          
        end
      end
  endtask
  
endclass
  