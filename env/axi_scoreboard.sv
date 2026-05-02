`uvm_analysis_imp_decl (_mst_ar)
`uvm_analysis_imp_decl (_slv_r)

typedef bit [ID_WIDTH-1:0] id;
class axi_scoreboard extends uvm_scoreboard;
  `uvm_component_utils (axi_scoreboard)
  
  axi_seq_item capture_queue_req_ar[id][$]; //For capturing AR channel received requests
  
  bit [DATA_WIDTH-1:0] capture_queue_req_r[id][$]; // For capturing beats for particular ID.
  
  axi_slv_drv axi_slv_drv_h; // To refer reference memory
  
  virtual axi_interface axi_if;
  
  
  uvm_analysis_imp_mst_ar #(axi_seq_item, axi_scoreboard) axi_mst_ar_imp;
  uvm_analysis_imp_slv_r #(axi_seq_item, axi_scoreboard) axi_slv_r_imp;
  
  function new (string name = "axi_scoreboard", uvm_component parent = null);
    super.new (name, parent);
  
  endfunction 
  
  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    
    axi_mst_ar_imp = new("axi_mst_ar_imp", this);
    axi_slv_r_imp = new ("axi_slv_r_imp", this);
    
    if (!uvm_config_db #(virtual axi_interface):: get (this, "", "axi_interface", axi_if))
      `uvm_info (get_type_name(), $psprintf("Could not get AXI interface instance"), UVM_NONE);
    
  endfunction
  
  
  function void write_mst_ar(axi_seq_item axi_tr);
    
    capture_queue_req_ar[axi_tr.ARID].push_back(axi_tr);
    
    `uvm_info (get_full_name(), $psprintf("AR channel: Txn ID received = %0h, ARADDR = %0h", axi_tr.ARID, axi_tr.ARADDR), UVM_HIGH)
    
  endfunction
  
   function void write_slv_r(axi_seq_item axi_tr); 
   
     capture_queue_req_r [axi_tr.RID].push_back(axi_tr.RDATA);
     
     if (axi_tr.RLAST)
     begin
       trig_checker (axi_tr);
     end
     
     `uvm_info (get_full_name(), $psprintf("R channel: Txn ID receieved = %0h, data = %0h", axi_tr.RID, axi_tr.RDATA), UVM_HIGH)
     
   endfunction
  
  function void trig_checker(axi_seq_item axi_tr);
    
    axi_seq_item axi_ar_txn;
    
    bit [DATA_WIDTH-1:0] data_frm_ref_mem;
    bit [DATA_WIDTH-1:0] data_frm_ref_mem_queue[$];
    
    bit [ADDR_WIDTH-1:0] init_addr;
    
    bit [DATA_WIDTH-1:0] golden_data, actual_data;
    
    `uvm_info (get_type_name(), $psprintf("Inside trig checker function for ID = %0h", axi_tr.RID), UVM_HIGH)
    
    if (capture_queue_req_ar.exists(axi_tr.RID)) //Check for ID in AR requests
    begin
      `uvm_info (get_type_name(), $psprintf("ID exists, ID: %0h", axi_tr.RID), UVM_HIGH)
      
      axi_ar_txn = capture_queue_req_ar[axi_tr.RID][0]; //Point first handle as per protocol - Same ID transactions have to be served in order. First handle data compared against R channel data
      
      init_addr = axi_ar_txn.ARADDR;
      `uvm_info(get_type_name(), $psprintf(" ARID: %0h, Memory address accessed = %0h", axi_ar_txn.ARID, axi_ar_txn.ARADDR), UVM_HIGH)
      
      capture_queue_req_ar[axi_tr.RID].delete(0); //Deleting first handle in the queue. Already chosen for comparison.
      
      for (int i = 0; i < axi_ar_txn.ARLEN + 1; i++)
      begin
        
        data_frm_ref_mem = axi_slv_drv_h.slave_mem[init_addr];
        init_addr++;
        data_frm_ref_mem_queue.push_back(data_frm_ref_mem); //Pushing data from reference mem into queue
      end
    end
    else
      `uvm_error (get_type_name(), $psprintf("AR request not raised for this ID %0h", axi_tr.RID))
      
      while(data_frm_ref_mem_queue.size())
      begin
        golden_data = data_frm_ref_mem_queue.pop_front();
        actual_data = capture_queue_req_r[axi_tr.RID].pop_front();
        
        if (actual_data == golden_data)
          `uvm_info(get_type_name(), $psprintf("PASS: ID %h, Ref data from Mem = %0h, Actual data = %0h", axi_tr.RID, golden_data, actual_data), UVM_HIGH)
        else if (actual_data != golden_data)
          `uvm_error(get_type_name (), $psprintf("FAIL: ID %h, Ref data from Mem = %0h, Actual data = %0h", axi_tr.RID, golden_data, actual_data))
          
      end    
      
      if (capture_queue_req_r[axi_tr.RID].size() == 0) //No beat should remain after trasaction check
          capture_queue_req_r.delete(axi_tr.RID);
      else
        `uvm_error(get_type_name(), $psprintf("FAIL: Captured data queue not empty, remaining beats = %d", capture_queue_req_r[axi_tr.RID].size()))
       
  endfunction
  
  
endclass