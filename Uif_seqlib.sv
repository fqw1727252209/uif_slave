`ifndef UIF_SEQUENCE
`define UIF_SEQUENCE

class UifSequence extends uvm_sequence;

    Uif_trans trans;

    `uvm_object_utils(UifSequence)

    `uvm_declare_p_sequencer(Uif_seqr)

    function new(string name = "UifSequence");
        super.new(name);

    endfunction :new

endclass : UifSequence

class UifBaseSeq extends UifSequence;
    rand int repeat_cnt;

    `uvm_object_utils(UifBaseSeq)
    `uvm_object_utils_end

    function new(string name = "UifBaseSeq");
        super.new(name);

    endfunction :new

    virtual task body();

    endtask

endclass : UifBaseSeq

`endif
