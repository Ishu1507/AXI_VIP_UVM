package axi_env_pkg;
	import uvm_pkg::*;

     parameter int ID_WIDTH    = 6;
     parameter int ADDR_WIDTH  = 10;
     parameter int DATA_WIDTH  = 32;
     parameter int MEM_DEPTH   = 65536; //64 KB of memory
     parameter int MEM_WIDTH   = 8; //memory stores byte data
     parameter int BURST_LEN_WIDTH = 8;
     parameter int STRB_WIDTH = DATA_WIDTH/8;

     parameter MAX_OUTSTANDING_READ = 5;

	
    	`include "axi_seq_item.sv"
	`include "axi_memory.sv" 
    	`include "axi_env_config.sv"
	`include "axi_id_scheduler.sv"
	
	`include "axi_mst_drv.sv"
	`include "axi_mst_seqr.sv"
	`include "axi_mst_mon.sv"
	`include "axi_mst_agent.sv"
	
	`include "axi_slv_drv.sv"
	`include "axi_slv_seqr.sv"
	`include "axi_slv_mon.sv" 
	`include "axi_slv_agent.sv"
	
	`include "axi_scoreboard.sv"

	`include "axi_env.sv"
	
	`include "axi_reset_seq.sv"
	`include "axi_base_seq.sv"
	`include "axi_ar_txn_seq.sv"
	`include "axi_aw_txn_seq.sv"
	`include "axi_base_test.sv"
	`include "axi_ar_txn_test.sv"
	`include "axi_aw_txn_test.sv"

endpackage
