`ifndef UIF_TRANS
`define UIF_TRANS

class Uif_trans extends uvm_sequence_item;

    rand bit                                 uif_cmd_vld         ;
    rand bit [CTL_CMD_ADDR_W-1:0]            uif_cmd_addr        ;
    rand bit [CTL_CMD_ID_W-1:0]              uif_cmd_id          ;
    rand bit [1:0]                           uif_cmd_prio        ;
    rand bit [1:0]                           uif_cmd_type        ;
    rand bit [1:0]                           uif_cmd_bc          ;
    rand bit                                 uif_gpr_go2critical ;
    rand bit                                 uif_gpw_go2critical ;
    
    rand bit                                 uif_wr_vld          ;
    rand bit [CTL_DATA_W-1:0]                uif_wr_data         ;
    rand bit [CTL_DATA/8-1:0]                uif_wr_mask         ;
    rand bit                                 uif_wdp_mwr_flag    ;
    rand bit                                 uif_wr_end          ;
    rand bit                                 uif_wr_posion       ;
 
    rand bit [CTL_CMD_NUM_BYTES_W-1:0]       uif_cmd_num_bytes   ;
    rand bit [CTL_CMD_OFFSET_W-1:0]          uif_cmd_offset      ;
    rand source_e                            uif_cmd_source      ;

    bit req_comp=0;
    int wr_cmd_id=0;
    int wr_data_id=0;
    int raw=0;
    int war=0;

    `uvm_object_utils_begin(Uif_trans)
        `uvm_field_int(uif_cmd_vld              , UVM_ALL_ON)
        `uvm_field_int(uif_cmd_addr             , UVM_ALL_ON)
        `uvm_field_int(uif_cmd_id               , UVM_ALL_ON)
        `uvm_field_int(uif_cmd_prio             , UVM_ALL_ON)
        `uvm_field_int(uif_cmd_type             , UVM_ALL_ON)
        `uvm_field_int(uif_cmd_bc               , UVM_ALL_ON)
        `uvm_field_int(uif_gpr_go2critical      , UVM_ALL_ON)
        `uvm_field_int(uif_gpw_go2critical      , UVM_ALL_ON)

        `uvm_field_int(uif_wr_vld               , UVM_ALL_ON)
        `uvm_field_int(uif_wr_data              , UVM_ALL_ON)
        `uvm_field_int(uif_wr_mask              , UVM_ALL_ON)
        `uvm_field_int(uif_wdp_mwr_flag         , UVM_ALL_ON)
        `uvm_field_int(uif_wr_end               , UVM_ALL_ON)
        `uvm_field_int(uif_wr_posion            , UVM_ALL_ON)
        `uvm_field_int(uif_cmd_num_bytes        , UVM_ALL_ON)
        `uvm_field_int(uif_cmd_offset           , UVM_ALL_ON)
        `uvm_field_enum(source_e, uif_cmd_source, UVM_ALL_ON)

        `uvm_field_int(req_completed            , UVM_ALL_ON)
        `uvm_field_int(raw                      , UVM_ALL_ON)
        `uvm_field_int(war                      , UVM_ALL_ON)
        if(uif_cmd_type!=0)begin
            `uvm_field_int(wr_cmd_id            , UVM_ALL_ON)
            `uvm_field_int(wr_data_id           , UVM_ALL_ON)
        end
    `uvm_object_utils_end

    function new(string name = "Uif_trans");
        super.new(name);

    endfunction

    function print_info (Uif_trans tr);
    
    endfunction:print_info

endclass : Uif_trans

`endif