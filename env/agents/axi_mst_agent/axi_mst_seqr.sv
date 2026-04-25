class axi_mst_seqr extends uvm_sequencer  #(axi_seq_item);
  `uvm_component_utils (axi_mst_seqr)
  
  function new (string name = "axi_mst_seqr", uvm_component parent = null);
    super.new (name, parent);
  endfunction
  
//   function build_phase (uvm_phase phase);
//     super.new (phase);
    
    
//   endfunction
  
  
endclass