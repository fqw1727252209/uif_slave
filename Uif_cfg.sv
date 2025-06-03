`ifndef UIF_CFG
`define UIF_CFG

class Uif_cfg extends uvm_object;
    uvm_active_passive_enum is_active = UVM_ACTIVE;

    uvm_mode_t uvm_mode;

    bit crc_en=0;

    int recv_hpr_cmd_num;
    int recv_lpr_cmd_num;
    int recv_gpr_cmd_num;
    int recv_tpw_cmd_num;
    int recv_gpw_cmd_num;

    int recv_rd_cmd_num;
    int recv_wr_cmd_num;
    int recv_rmw_cmd_num;

    int recv_wr_data_bytes_num;
    int send_rd_data_bytes_num;

//config uif dly
    int dly_cmd_stall_high_range_min=1;
    int dly_cmd_stall_high_range_max=20;

    int dly_cmd_stall_low_range_min=100;
    int dly_cmd_stall_low_range_max=200;

//config uif credit num range
    bit credit_rand_mode=1;
    int lpr_credit_num_range_min=0;
    int lpr_credit_num_range_max=64;
    int hpr_credit_num_range_min=0;
    int hpr_credit_num_range_max=64;
    int tpw_credit_num_range_min=0;
    int tpw_credit_num_range_max=64;
//when used credit_rand_mode=0, the credit num is fixed
    // bit credit_rand_mode=0;
    bit [CTL_CREDIT_W-1:0] tpw_initial_credit_num=63;
    bit [CTL_CREDIT_W-1:0] lpr_initial_credit_num=31;
    bit [CTL_CREDIT_W-1:0] hpr_initial_credit_num=62-lpr_initial_credit_num;

    `uvm_object_utils_begin(Uif_cfg)
        `uvm_field_enum(uvc_mode_t,uvc_mode,UVM_ALL_ON)
        `uvm_field_int(dly_cmd_stall_high_range_min,UVM_ALL_ON)
        `uvm_field_int(dly_cmd_stall_high_range_max,UVM_ALL_ON)
        `uvm_field_int(dly_cmd_stall_low_range_min,UVM_ALL_ON)
        `uvm_field_int(dly_cmd_stall_low_range_max,UVM_ALL_ON)
        `uvm_field_int(credit_rand_mode,UVM_ALL_ON)
        if(credit_rand_mode==1) begin
            `uvm_field_int(lpr_credit_num_range_min,UVM_ALL_ON)
            `uvm_field_int(lpr_credit_num_range_max,UVM_ALL_ON)
            `uvm_field_int(hpr_credit_num_range_min,UVM_ALL_ON)
            `uvm_field_int(hpr_credit_num_range_max,UVM_ALL_ON)
            `uvm_field_int(tpw_credit_num_range_min,UVM_ALL_ON)
            `uvm_field_int(tpw_credit_num_range_max,UVM_ALL_ON)
        end else begin
            `uvm_field_int(tpw_initial_credit_num,UVM_ALL_ON)
            `uvm_field_int(lpr_initial_credit_num,UVM_ALL_ON)
            `uvm_field_int(hpr_initial_credit_num,UVM_ALL_ON)
        end
    `uvm_object_utils_end

    function new(string name = "Uif_cfg");
        super.new(name);
        
    endfunction

endclass : Uif_cfg

`endif