`ifndef UIF_PKG
`define UIF_PKG

package Uif_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    typedef enum bit[1:0] {
        MASTER_MODE     = 2'b00,
        SLAVE_MODE      = 2'b01,
        MIXED_MODE      = 2'b10
    }uvc_mode_t;
    `include "Uif_define.sv"
    `include "Uif_trans.sv"
    `include "Uif_cfg.sv"
    `include "Uif_drv.sv"
    `include "Uif_mon.sv"
    `include "Uif_seqr.sv"
    `include "Uif_sb.sv"
    `include "Uif_seqlib.sv"
    `include "Uif_agt.sv"
    `include "Uif_env.sv"

endpackage : Uif_pkg

`endifPKG