`ifndef UIF_AGT
`define UIF_AGT

class Uif_agt extends uvm_agent;

    Uif_mon     monitor;
    Uif_drv     driver;
    Uif_seqr    sequencer;
    Uif_cfg     cfg;

    `uvm_component_utils(Uif_agt)
        `uvm_field_object(cfg, UVM_DEFAULT)
    `uvm_component_utils_end

    function new(string name = "Uif_agt", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        cfg = Uif_cfg::type_id::create("cfg", this);
        if (!cfg.randomize()) begin
            `uvm_fatal(get_type_name(), $sformatf("cfg randomize failed, initial cfg: %s", cfg.sprint()))
        end
        is_active = cfg.is_active;
        cfg.uvc_mode = SLAVE_MODE;

        monitor = Uif_mon::type_id::create("monitor", this);

        if (cfg.uvc_mode == SLAVE_MODE) begin
            driver  = Uif_drv::type_id::create("driver", this);
            sequencer = Uif_seqr::type_id::create("sequencer", this);
        end
    endfunction : build_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (cfg.uvc_mode == SLAVE_MODE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
            
            driver.cfg = cfg;
            monitor.cfg = cfg;
        end
    endfunction : connect_phase

endclass : Uif_agt

`endif // UIF_AGT