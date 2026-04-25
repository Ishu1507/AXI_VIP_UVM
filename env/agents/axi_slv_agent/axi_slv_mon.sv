class axi_slv_mon extends uvm_monitor;
  `uvm_component_utils (axi_slv_mon)
  
  virtual axi_interface axi_if;
  
  axi_seq_item req_item;
  
  uvm_analysis_port #(axi_seq_item) rch_mon_port;
  
  function new (string name = "axi_slv_mon", uvm_component parent = null);
    super.new (name, parent);
    
  endfunction
  
  function void build_phase (uvm_phase phase);
    super.build_phase (phase);
    
    if (!uvm_config_db #(virtual axi_interface):: get (this, "", "axi_interface", axi_if))
      `uvm_info (get_type_name(), $psprintf("Could not get AXI master interface instance"), UVM_NONE);
    
        
    if (!uvm_config_db #(virtual axi_interface):: get (this, "", "axi_interface", axi_if))
      `uvm_info (get_type_name(), $psprintf("Could not get AXI master interface instance"), UVM_NONE);
  
    rch_mon_port = new("rch_mon_port", this);
  endfunction
  
  task run_phase (uvm_phase phase);
    super.run_phase(phase);
    
    
    forever
      begin
        @(posedge axi_if.axi_clk);
		
        req_item = axi_seq_item::type_id::create ("req_item");
        
        if (axi_if.RVALID == 1 && axi_if.RREADY == 1)
        begin
             req_item.RDATA		=	axi_if.RDATA;
  			 req_item.RVALID	=	axi_if.RVALID;
   			 req_item.RREADY	=	axi_if.RREADY;
   			 req_item.RLAST		=	axi_if.RLAST;
			 req_item.RID 		= 	axi_if.RID;
          
          `uvm_info (get_type_name(), $psprintf ("Monitor capture, RDATA = %h, RVALID = %h, RREADY = %h, RLAST = %h, RID = %h", req_item.RDATA, req_item.RVALID, req_item.RREADY, req_item.RLAST, req_item.RID), UVM_HIGH)
             
             rch_mon_port.write (req_item);
             
                     
        end
      end
    
  endtask
  
  
endclass