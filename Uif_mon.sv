`ifndef UIF_MON
`define UIF_MON

class Uif_mon extends uvm_monitor;

    virtual Uif_if vif;
    Uif_cfg cfg;

    `uvm_component_utils(Uif_mon)

    function new(string name = "Uif_mon", uvm_component parent = null);
        super.new(name, parent);

    endfunction:new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db #(virtual interface Uif_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", {"virtual interface must be set for: ", get_full_name(), ".vif"})
    endfunction :build_phase

    virtual function void end_of_elaboration_phase (uvm_phase phase);
        super.end_of_elaboration_phase(phase);

    endfunction : end_of_elaboration_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

    endfunction :connect_phase

    virtual task run_phase(uvm_phase phase);

    endtask : run_phase
endclass : Uif_mon
`endif
