class axi_memory extends uvm_component;
	`uvm_component_utils(axi_memory)

	rand bit [MEM_WIDTH-1:0] mem [MEM_DEPTH];

	function new (string name = "axi_memory", uvm_component parent = null);
		super.new(name, parent);

	endfunction

	function void build_phase (uvm_phase phase);
		super.build_phase (phase);

		for (int i = 0; i<MEM_DEPTH; i++)
		begin//{
			mem[i] = $urandom_range (0, {MEM_WIDTH{1'b1}});
			`uvm_info (get_type_name(), $psprintf ("Mem Data: ADDR: %0h, DATA= %0h", i, mem[i]), UVM_HIGH) 
		end //}
	endfunction 
endclass

