class axi_reset_seq extends uvm_sequence; 
  `uvm_object_utils(axi_reset_seq)
  
  function new (string name = "axi_reset_seq");
    super.new (name);
  endfunction
                
  task body();
    //super.body ();
    
    axi_seq_item req_item;
    req_item = axi_seq_item::type_id::create ("req_item");
    
    `uvm_do_with (req_item, {req_item.rst == 1;})
    
  endtask
  
endclass