`ifndef UIF_SEQR
`define UIF_SEQR

class Uif_seqr extends uvm_sequencer #(Uif_trans);
   virtual interface Uif_if vif;

    `uvm_component_utils(Uif_seqr)

    function new(string name = "Uif_seqr", uvm_component parent = null);
        super.new(name, parent);

    endfunction :new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db #(virtual interface Uif_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", {"virtual interface must be set for: ", get_full_name(), ".vif"})
    endfunction :build_phase

endclass : Uif_seqr

`endif 