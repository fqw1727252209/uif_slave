parameter CTL_CREDIT_W           =   6   ;
parameter CTL_DATA_W             =   256 ;
parameter CTL_CMD_ID_W           =   18  ;
parameter CTL_CMD_ADDR_W         =   35  ;
parameter CTL_CMD_NUM_BYTES_W    =   3   ;
parameter CTL_CMD_OFFSET_W       =   6   ;

`define UIF_TB_DLY 50ps

typedef enum bit [1:0] {PORT=2'b00,MPG=2'b01,Scrubber=2'b10} source_e;