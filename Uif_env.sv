`ifndef UIF_ENV
`define UIF_ENV

class Uif_env extends uvm_env;

    `uvm_component_utils(Uif_env)

    Uif_agt agent;
    Uif_sb  sb;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_db #(uvm_active_passive_enum)::set(this, "agent", "is_active", UVM_ACTIVE);
        agent = Uif_agt::type_id::create("agent", this);
        sb    = Uif_sb::type_id::create("sb", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction

endclass
`endif