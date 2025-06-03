`ifndef UIF_IF
`define UIF_IF

interface Uif_if (input logic clk, input logic rst_n);

    logic                                 uif_cmd_stall         ;
    logic [CTL_CREDIT_W-1:0]              uif_tpw_credit        ;
    logic [CTL_CREDIT_W-1:0]              uif_lpr_credit        ;
    logic [CTL_CREDIT_W-1:0]              uif_hpr_credit        ;

    logic                                 uif_wr_req            ;
    logic                                 uif_port_num          ;

    logic                                 uif_rd_vld            ;
    logic [CTL_DATA_W-1:0]                uif_rd_data           ;
    logic [1:0]                           uif_rd_data_phase     ;
    logic [CTL_CMD_ID_W-1:0]              uif_rd_id             ;   

    logic                                 rdp_uif_crc_err       ;
    logic [3:0]                           uif_rd_posion         ;
    logic                                 uif_wr_port_id        ;   
    
    
    //From Master
    logic                                 uif_cmd_vld           ;
    logic [CTL_CMD_ADDR_W-1:0]            uif_cmd_addr          ;
    logic [CTL_CMD_ID_W-1:0]              uif_cmd_id            ;
    logic [1:0]                           uif_cmd_prio          ;
    logic [1:0]                           uif_cmd_type          ;
    logic [1:0]                           uif_cmd_bc            ;
    logic                                 uif_gpr_go2critical   ;
    logic                                 uif_gpw_go2critical   ;

    logic                                 uif_wr_vld            ;   
    logic [CTL_DATA_W-1:0]                uif_wr_data           ;
    logic [CTL_DATA_W/8-1:0]              uif_wr_mask           ;
    logic                                 uif_wdp_mwr_flag      ;
    logic                                 uif_wr_end            ;

    logic [3:0]                           uif_wr_posion         ;   

    logic                                 uif_cmd_stall_0       ;
    logic                                 uif_cmd_stall_1       ;

    clocking drv_cb @(posedge clk);
        //default input #1 output #1;
        output  uif_cmd_stall       ;
        output  uif_tpw_credit      ;
        output  uif_lpr_credit      ;
        output  uif_hpr_credit      ;

        output  uif_wr_req          ;
        output  uif_port_num        ;

        output  uif_rd_vld          ;
        output  uif_rd_data         ;
        output  uif_rd_data_phase   ;
        output  uif_rd_id           ;

        output  rdp_uif_crc_err     ;

        output  uif_rd_posion       ;

        output  uif_cmd_stall_0     ;
        output  uif_cmd_stall_1     ;

        output  uif_wr_port_id      ;
    endclocking

    clocking mon_cb @(posedge clk);
    
    endclocking

endinterface
`endif