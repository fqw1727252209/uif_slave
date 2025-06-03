`ifndef UIF_SC
`define UIF_SC
class Uif_sc extends uvm_scoreboard;

    `uvm_component_utils(Uif_sc)

    function new(string name = "Uif_sb", uvm_component parent = null);
        super.new(name, parent);

    endfunction :new
    Uif_cfg cfg;

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);

    endfunction :build_phase
    
endclass : Uif_sb
`endif