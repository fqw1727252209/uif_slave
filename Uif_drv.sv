`ifndef UIF_DRV
`define UIF_DRV

class Uif_drv extends uvm_driver #(Uif_trans);
    virtual interface Uif_if vif;

    `uvm_component_utils(Uif_drv)

    Uif_cfg cfg;
    int wr_cmd_id=0;
    int rd_data_id=0;

    Uif_trans uif_slave_receive_wr_cmd_q[$];
    Uif_trans uif_slave_receive_rd_cmd_q[$];

    logic [7:0] MEM[bit[63:0]];
    logic [7:0] MEM_POISON[bit[63:0]];

    bit lpr_flag;
    bit hpr_flag;
    bit rd_crc_tmp=0;

    function new(string name, uvm_component parent);
        super.new(name, parent);

    endfunction:new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db #(virtual interface Uif_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", {"virtual interface must be set for: ", get_full_name(), ".vif"})
    endfunction :build_phase

    virtual task reset_phase(uvm_phase phase);
        phase.raise_objection(this);

        vif.drv_cb.uif_cmd_stall        <= 0;
        vif.drv_cb.uif_tpw_credit       <= 0;
        vif.drv_cb.uif_lpr_credit       <= 0;
        vif.drv_cb.uif_hpr_credit       <= 0;

        vif.drv_cb.uif_wr_req           <= 0;
        vif.drv_cb.uif_port_num         <= $urandom_range(1);

        vif.drv_cb.uif_rd_vld           <= 0;
        vif.drv_cb.uif_rd_data          <= 0;
        vif.drv_cb.uif_rd_data_phase    <= 0;
        vif.drv_cb.uif_rd_id            <= 0;
        vif.drv_cb.uif_rd_posion        <= 0;
        vif.drv_cb.rdp_uif_crc_err      <= 0;

        vif.drv_cb.uif_cmd_stall_0      <= 0;
        vif.drv_cb.uif_cmd_stall_1      <= 0;

        vif.drv_cb.uif_wr_port_id       <= 0;

        @vif.drv_cb;
        phase.drop_objection(this);
    endtask :reset_phase

    virtual task main_phase(uvm_phase phase);
        super.main_phase(phase);
        uvm_config_db #(Uif_cfg)::wait_modified(this, "", "uif_cfg");
        uvm_config_db #(Uif_cfg)::get(this, "", "uif_cfg", uif_cfg);



        fork
            get_uif_stall();
            begin
                if(cfg.credit_rand_mode)
                    gen_uif_credit_randmode();
                else
                    gen_uif_credit();
            end

            collect_cmd_from_master();
            collect_wr_data_from_master();
            read_back_to_master();
        join

    endtask :main_phase

    virtual task collect_cmd_from_master();
        Uif_trans trans;

        forever begin

            if(vif.uif_cmd_vld)begin
                trans = new();

                trans.uif_cmd_addr          = vif.uif_cmd_addr;
                trans.uif_cmd_id            = vif.uif_cmd_id;
                trans.uif_cmd_prio          = vif.uif_cmd_prio;
                trans.uif_cmd_type          = vif.uif_cmd_type;
                trans.uif_cmd_bc            = vif.uif_cmd_bc;
                trans.uif_cmd_source        = vif.uif_cmd_id[CTL_CMD_ID_W-1:CTL_CMD_ID_W-2];
                trans.uif_cmd_num_bytes     = vif.uif_cmd_id[CTL_CMD_ID_W-3-:CTL_CMD_NUM_BYTES_W];
                trans.uif_cmd_offset       = vif.uif_cmd_id[CTL_CMD_ID_W-3-CTL_CMD_NUM_BYTES_W-:CTL_CMD_OFFSET_W];

                if(vif.uif_cmd_type != 0) begin // 2'b01:write/2'b10:mask write/2'b11:read modify write

                    trans.wr_cmd_id = wr_cmd_id;
                    wr_cmd_id++;
                    foreach(uif_slave_receive_rd_cmd_q[i])begin
                        if(uif_slave_receive_rd_cmd_q[i].uif_cmd_addr == trans.uif_cmd_addr)begin
                            trans.raw = 1;
                            vif.uif_cmd_stall_0 = 1'b1;
                        end
                    end


                    uif_slave_receive_wr_cmd_q.push_back(trans);

                    if(vif.uif_cmd_type == 1 || vif.uif_cmd_type == 2) begin // write or mask write
                        cfg.recv_wr_cmd_num++;
                    end
                    else if(vif.uif_cmd_type == 3)begin// read modify write
                        cfg.recv_rmw_cmd_num++;
                    end

                    if(vif.uif_cmd_prio == 1) begin
                        cfg.recv_tpw_cmd_num++;
                    end
                    else if(vif.uif_cmd_prio == 2) begin
                        cfg.recv_gpw_cmd_num++;
                    end
                    else begin
                        `uvm_error("WR Priority Error!",$sformatf("uif_cmd_prio=%0d",vif.uif_cmd_prio))
                    end
                end
                else if(vif.uif_cmd_type == 0)begin
                    foreach(uif_slave_receive_wr_cmd_q[i]) begin
                        if(uif_slave_receive_wr_cmd_q[i].uif_cmd_addr == trans.uif_cmd_addr) begin

                            trans.war=1;
                            vif.uif_cmd_stall_0 = 1'b1;
                    end
                end


                uif_slave_receive_rd_cmd_q.push_back(trans);
                if(vif.uif_cmd_type == 0) begin
                    cfg.recv_rd_cmd_num++;
                end
                if(vif.uif_cmd_prio == 0) begin
                    cfg.recv_hpr_cmd_num++;
                end
                else if(vif.uif_cmd_prio == 1) begin
                    cfg.recv_lpr_cmd_num++;
                end
                else if(vif.uif_cmd_prio == 2) begin
                    cfg.recv_gpr_cmd_num++;
                end
                else begin
                    `uvm_error("RD Priority Error!",$sformatf("uif_cmd_prio = %0d",vif.uif_cmd_prio))
                end
            end
        end

        @(vif.drv_cb)
    end
    endtask :collect_cmd_from_master

    virtual task collect_wr_data_from_master();
        Uif_trans trans,trans_first;
        Uif_trans trans_from_cmd;
        int rd_id_hit[$];
        int wr_id_hit[$];
        int rd_id;
        int phase_cnt;
        bit [63:0] dram_addr;
        int delay;
        bit flag = 1;

        forever begin
            wait(uif_slave_receive_wr_cmd_q.size() > 0);
            if(flag) begin
                delay = $urandom_range(0, 10);
                repeat(delay) @(posedge vif.clk);

                flag = 0;
            end
            #11ps;
            vif.uif_wr_req = 1'b1;

            if(vif.uif_wr_vld && vif.uif_wr_req) begin
                trans = new();

                trans_from_cmd = uif_slave_receive_wr_cmd_q[0];
                trans.copy(trans_from_cmd);











                dram_addr = trans.uif_cmd_addr<<6;
                if(trans.uif_cmd_num_bytes <=5)begin   //low or equal 32Byte
                    if(vif.uif_wr_end) begin
                        trans.uif_wr_data       =   vif.uif_wr_data         ;
                        trans.uif_wr_mask       =   vif.uif_wr_mask         ;
                        trans.uif_wdp_mwr_flag  =   vif.uif_wdp_mwr_flag    ;
                        trans.uif_wr_posion     =   vif.uif_wr_posion       ;
                        trans.uif_wr_end        =   vif.uif_wr_end          ;

                        trans.wr_data_id        =   vif.uif_wr_end          ;
                        wr_data_id++;
                        if(trans.raw)begin
                            foreach(uif_slave_receive_rd_cmd_q[i])begin
                                if(uif_slave_receive_rd_cmd_q[i].uif_cmd_addr==trans.uif_cmd_addr && uif_slave_receive_rd_cmd_q[i].war==0 && uif_slave_receive_rd_cmd_q[i].req_comp==0)begin
                                    rd_id_hit.push_back(i);
                                end
                            end
                            while(rd_id_hit.size()!=0) begin


                                @vif.drv_cb;
                                #1ps;
                                vif.uif_wr_req = 0;
                                rd_id_hit.delete();
                                foreach(uif_slave_receive_rd_cmd_q[i])begin
                                    if(uif_slave_receive_rd_cmd_q[i].uif_cmd_addr==trans.uif_cmd_addr && uif_slave_receive_rd_cmd_q[i].war==0 && uif_slave_receive_rd_cmd_q[i].req_comp==0)begin
                                        rd_id_hit.push_back(i);
                                    end
                                end
                            end
                            vif.uif_cmd_stall_0 = 1'b0; //done
                        end
                        


                        if(~trans.uif_cmd_offset[5])begin
                            for(int i=0; i<CTL_DATA_W/8; i++)begin
                                if(trans.uif_wr_mask[i])begin
                                    MEM[dram_addr + i] = trans.uif_wr_data[i*8 +: 8];
                                    cfg.recv_wr_data_bytes_num++;
                                end
                            end

                            MEM_POISON[dram_addr][3:0] = trans.uif_wr_posion;
                            MEM_POISON[dram_addr][7:4] = 'h0;
                        end
                        else begin
                            for(int i=0; i<CTL_DATA_W/8; i++)begin
                                if(trans.uif_wr_mask[i])begin
                                    MEM[dram_addr + i + 32] = trans.uif_wr_data[i*8 +: 8];
                                    cfg.recv_wr_data_bytes_num++;
                                end
                            end

                            MEM_POISON[dram_addr][3:0] = 'h0;
                            MEM_POISON[dram_addr][7:4] = trans.uif_wr_posion;
                        end

                        flag = 1;
                    end
                    else begin
                    `uvm_error("Uif_wr_end Error!","")
                    end

                    uif_slave_receive_wr_cmd_q[0].req_comp=1;
                    foreach(uif_slave_receive_rd_cmd_q[i])begin
                        if(uif_slave_receive_rd_cmd_q[i].uif_cmd_addr==trans.uif_cmd_addr && uif_slave_receive_rd_cmd_q[i].war==1 && uif_slave_receive_rd_cmd_q[i].req_comp==0) begin
                            foreach(uif_slave_receive_wr_cmd_q[i])begin
                                if(uif_slave_receive_wr_cmd_q[i].uif_cmd_addr==trans.uif_cmd_addr && uif_slave_receive_wr_cmd_q[i].req_comp==0) begin
                                    wr_id_hit.push_back(i);
                                end
                            end
                            if(wr_id_hit.size()==0) begin
                                uif_slave_receive_rd_cmd_q[i].war=0;
                                vif.uif_cmd_stall_0 = 1'b0; //done
                            end
                        end
                    end
                    wr_id_hit.delete();
                    #0;uif_slave_receive_wr_cmd_q.delete(0);
                end
                else if(trans.uif_cmd_num_bytes==6) begin //64B
                    if(~vif.uif_wr_end)begin
                        phase_cnt++;
                        trans_first = new();
                        trans_first.copy(trans);
                        trans_first.uif_wr_data         = vif.uif_wr_data        ;
                        trans_first.uif_wr_mask         = vif.uif_wr_mask        ;
                        trans_first.uif_wdp_mwr_flag    = vif.uif_wdp_mwr_flag   ;
                        trans_first.uif_wr_posion       = vif.uif_wr_posion      ;
                        trans_first.uif_wr_end          = vif.uif_wr_end         ;

                        trans_first.wr_data_id          = wr_data_id             ;



                    end
                    else begin



                        trans.uif_wr_data               = vif.uif_wr_data         ;
                        trans.uif_wr_mask               = vif.uif_wr_mask         ;
                        trans.uif_wdp_mwr_flag          = vif.uif_wdp_mwr_flag    ;
                        trans.uif_wr_posion             = vif.uif_wr_posion       ;
                        trans.uif_wr_end                = vif.uif_wr_end          ;

                        trans.wr_data_id                = wr_data_id              ;
                        wr_data_id++;


                        
                        if(trans.raw) begin
                            foreach(uif_slave_receive_rd_cmd_q[i])begin
                                if(uif_slave_receive_rd_cmd_q[i].uif_cmd_addr == trans.uif_cmd_addr && uif_slave_receive_rd_cmd_q[i].war==0 && uif_slave_receive_rd_cmd_q[i].req_comp==0)begin
                                    rd_id_hit.push_back(i);
                                end
                            end
                            while(rd_id_hit.size()!=0)begin


                                @vif.drv_cb;
                                #1ps;
                                vif.uif_wr_req = 0;
                                rd_id_hit.delete();
                                foreach(uif_slave_receive_rd_cmd_q[i])begin
                                    if(uif_slave_receive_rd_cmd_q[i].uif_cmd_addr == trans.uif_cmd_addr && uif_slave_receive_rd_cmd_q[i].war==0 && uif_slave_receive_rd_cmd_q[i].req_comp==0)begin
                                        rd_id_hit.push_back(i);
                                    end
                                end
                            end
                            vif.uif_cmd_stall_0 = 1'b0;//done
                        end

                        if(~trans_first.uif_cmd_bc[0] || (trans_first.uif_cmd_bc[0] && ~trans_first.uif_cmd_bc[1]))begin
                            for(int i=0; i<CTL_DATA_W/8; i++) begin
                                if(trans_first.uif_wr_mask[i]) begin
                                    MEM[dram_addr+i] = trans_first.uif_wr_data[8*i+:8];
                                    cfg.recv_wr_data_bytes_num++;
                                end
                            end
                        end

                        MEM_POSION[dram_addr][3:0] = trans_first.uif_wr_posion;

                        if(~trans.uif_cmd_bc[0] || (trans.uif_cmd_bc[0] && trans.uif_cmd_bc[1]))begin
                            for(int i=0; i<CTL_DATA_W/8; i++) begin
                                if(trans.uif_wr_mask[i]) begin
                                    MEM[dram_addr + i + 32] = trans.uif_wr_data[8*i+:8];
                                    cfg.recv_wr_data_bytes_num++;
                                end
                            end
                        end
                        MEM_POSION[dram_addr][7:4] = trans.uif_wr_posion;

                        phase_cnt = 0;
                        uif_slave_receive_wr_cmd_q[0].req_comp=1;
                        foreach(uif_slave_receive_rd_cmd_q[i])begin
                            if(uif_slave_receive_rd_cmd_q[i].uif_cmd_addr == trans.uif_cmd_addr && uif_slave_receive_rd_cmd_q[i].war==1 && uif_slave_receive_rd_cmd_q[i].req_comp==0)begin
                                foreach(uif_slave_receive_wr_cmd_q[i])begin
                                    if(uif_slave_receive_wr_cmd_q[i].uif_cmd_addr == trans.uif_cmd_addr && uif_slave_receive_wr_cmd_q[i].req_comp==0)begin
                                        wr_id_hit.push_back(i);
                                    end
                                end
                                if(wr_id_hit.size()==0)begin
                                    uif_slave_receive_rd_cmd_q[i].war=0;
                                    vif.uif_cmd_stall_0 = 1'b0;
                                end
                            end
                        end

                        wr_id_hit.delete();
                      #0;uif_slave_receive_wr_cmd_q.delete(0);

                      flag = 1;
                    end
                end
                else begin
                    `uvm_error("WR:Error uif_cmd_num_bytes!",$sformatf("uif_cmd_num_bytes:%0d",trans.uif_cmd_num_bytes))
                end

            end

            @(vif.mon_cb);
            #1ps;
            vif.uif_wr_req = 0;
        end //forever
    endtask :collect_wr_dasta_from_master

    virtual task read_back_to_master();
        int             rd_idx;
        int             rd_delay;
        Uif_trans       trans;
        bit [63:0]      dram_addr;
        int             wr_id_hit[$];
        int             wr_id;
        int             rd_ready[$];
        int             id;

        forever begin
            wait(uif_slave_receive_rd_cmd_q.size() > 0);


            foreach(uif_slave_receive_rd_cmd_q[i])begin
                if(uif_slave_receive_rd_cmd_q[i].war==0)
                    rd_ready.push_back(i);
            end
            while(rd_ready.size()==0)begin







                @(vid.drv_cb);
                foreach(uif_slave_receive_rd_cmd_q[i])begin
                    if(uif_slave_receive_rd_cmd_q[i].war==0)begin
                        rd_ready.push_back(i);
                        vif.uif_cmd_stall_0 = 1'b0; //done
                    end
                end
            end
            id  = $urandom_range(0,rd_ready.size()-1);
            id_idx = rd_ready[id];
            trans = uif_slave_receive_rd_cmd_q[id_idx];
            rd_reday.delete;

            dram_addr = trans.uif_cmd_addr<<6;


            std::randomize(rd_delay) with {rd_delay dist {[0:/25,[1:5]:/25,[6:99]:/25,100:/25]};};
            repeat(rd_delay) @(posedge vif.clk);

            if(trans.uif_cmd_num_bytes <= 5) begin
                vif.drv_cb.uif_rd_data_phase <= 0;
                vif.drv_cb.uif_rd_id <= trans.uif_cmd_id;

                if(~trans.uif_cmd_offset[5])begin
                    if(MEM_POISON.exists(dram_addr))begin
                        vif.drv_cb.uif_rd_posion    <=  MEM_POSION[dram_addr][3:0];
                    end
                    else begin
                        vif.drv_cb.uif_rd_posion    <=  0;
                    end

                    for(int i=0; i<CTL_DATA_W/8; i++) begin
                        if(MEM.exists(dram_addr+i))begin
                            vif.drv_cb.uif_rd_data[8*i +:8] <= MEM[dram_addr + i];
                            cfg.send_rd_data_bytes_num++;
                        end
                        else begin
                            vif.drv_cb.uif_rd_data[8*i +:8] <= 0;
                        end
                    end
                    if(cfg.crc_en==1)
                        rd_crc_tmp      <=  $urandom_range(0,1);
                end
                else begin
                    if(MEM_POISON.exists(dram_addr)) begin
                        vif.drv_cb.uif_rd_posion <= MEM_POISON[dram_addr][7:4];
                    end
                    else begin
                        vif.drv_cb.uif_rd_posion <= 0;
                    end

                    for(int i=0; i<CTL_DATA_W/8; i++) begin
                        if(MEM.exists(dram_addr + i + 32)) begin
                            vif.drv_cb.uif_rd_data[i*8+:8] <= MEM[dram_addr + i + 32];
                            cfg.send_rd_data_bytes_num++;
                        end
                        else begin
                            vif.drv_cb.uif_rd_data[i*8+:8] <= 0;
                        end
                    end
                    if(cfg.crc_en==1)
                        vif.rdp_uif_crc_err  <=  $urandom_range(0,1);
                end
                vif.drv_cb.uif_rd_posion <=  1;
            end
            else if(trans.uif_cmd_num_bytes == 6)begin
                vif.drv_cb.uif_rd_data_phase    <=  0;
                vif.drv_cb.uif_rd_id            <=  trans.uif_cmd_id;
                
                if(MEM_POISON.exists(dram_addr))begin
                    vif.drv_cb.uif_rd_posion <=  MEM_POISON[dram_addr][3:0];
                end
                else begin
                    vif.drv_cb.uif_rd_posion <=  0;
                end
                for (int i = 0; i < CTL_DATA_W/8; i++)begin
                    if(MEM_POISON.exists(dram_addr+i))begin
                        vif.drv_cb.uif_rd_data[i*8+:8] <=  MEM[dram_addr+i];
                        cfg.send_rd_data_bytes_num++;
                    end
                    else begin
                        vif.drv_cb.uif_rd_data[i*8+:8] <= 0;
                    end
                end
                vif.drv_cb.uif_rd_vld          <=  1;

                @(posedge vif.clk); //Enter Phase 1
                vif.drv_cb.uif_rd_data_phase   <=  1;
                vif.drv_cb.uif_rd_id           <=  trans.uif_cmd_id;

                if(MEM_POISON.exists(dram_addr)) begin
                    vif.drv_cb.uif_rd_posion   <=  MEM_POISON[dram_addr][7:4];
                end
                else begin
                    vif.drv_cb.uif_rd_posion   <=  0;
                end
                for(int i=0; i<CTL_DATA_W/8; i++) begin
                    if(MEM.exists(dram_addr + i + 32)) begin
                        vif.drv_cb.uif_rd_data[i*8+:8] <= MEM[dram_addr + i + 32];
                        cfg.send_rd_data_bytes_num++;
                    end
                    else begin
                        vif.drv_cb.uif_rd_data[i*8+:8] <= 0;
                    end
                end
                vif.drv_cb.uif_rd_vld <= 1;
                if(cfg.crc_en==1)
                    vif.rdp_uif_crc_err  <=  $urandom_range(0,1);
            end
            else begin
                `uvm_error("RD:Error uif_cmd_num_bytes!",$sformatf("uif_cmd_num_bytes=%0d",trans.uif_cmd_num_bytes))
            end

            if(trans.uif_cmd_prio==1 || trans.uif_cmd_prio==2)
                lpr_flag = 1;
            else
                hpr_flag = 1;
            
            uif_slave_receive_rd_cmd_q[rd_idx].req_comp=1;
            #0;uif_slave_receive_rd_cmd_q.delete(rd_idx);
          fork
            begin
                @(posedge vif.clk);
                vif.drv_cb.uif_rd_data          <=   0;
                vif.drv_cb.uif_rd_data_phase    <=   0;
                vif.drv_cb.uif_rd_id            <=   0;
                vif.drv_cb.uif_rd_vld           <=   0;
                vif.drv_cb.uif_rd_posion        <=   0;
            end
            begin
                @(posedge vif.clk);
                if(rd_crc_tmp)begin
                    vif.rdp_uif_crc_err         <=   1;
                    rd_crc_tmp                   =   0;
                    @(posedge vif.clk);
                    vif.rdp_uif_crc_err         <=   0;
                end
                else
                    vif.rdp_uif_crc_err         <=   0;
            end
          join
        end //forever
    endtask : read_back_to_master

    virtual task gen_uif_stall();
        int dly_clk;
        bit en0;

        fork
            forever begin
                en0 = $urandom_range(1);
                vif.uif_cmd_stall_1 <= en0;

                if(en0)
                    dly_clk = $urandom_range(cfg.dly_cmd_stall_high_range_min,cfg.dly_cmd_stall_high_range_max);
                else
                    dly_clk = $urandom_range(cfg.dly_cmd_stall_low_range_min,cfg.dly_cmd_stall_low_range_max);
                repeat(dly_clk) @vif.drv_cb;
            end

            forever begin
                vif.uif_cmd_stall = vif.uif_cmd_stall_0 | vif.uif_cmd_stall_1;

                @(posedge vif.clk);
            end
        join
    endtask : gen_uif_stall

    virtual task gen_uif_credit_randmode(); 
        int dly_clk0, dly_clk1, dly_clk2;

        fork
            forever begin
                vif.drv_cb.uif_hpr_credit <= $urandom_range(cfg.hpr_credit_num_range_min,cfg.hpr_credit_num_range_max);

                dly_clk0 = $urandom_range(1,20);
                repeat(dly_clk0) @vif.drv_cb;
            end

            forever begin
                vif.drv_cb.uif_lpr_credit <= $urandom_range(cfg.lpr_credit_num_range_min,cfg.lpr_credit_num_range_max);

                dly_clk1 = $urandom_range(1,20);
                repeat(dly_clk1) @vif.drv_cb;
            end

            forever begin
                vif.drv_cb.uif_tpw_credit <= $urandom_range(cfg.tpw_credit_num_range_min,cfg.tpw_credit_num_range_max);

                dly_clk2 = $urandom_range(1,20);
                repeat(dly_clk2) @vif.drv_cb;
            end
        join
    endtask : gen_uif_credit_randmode

    virtual task gen_uif_credit();
        int dly_clk0, dly_clk1, dly_clk2;
        bit tpw_flag;
        bit [CTL_CREDIT_W-1:0] tpw_credit_num=cfg.tpw_initial_credit_num;
        bit [CTL_CREDIT_W-1:0] lpr_credit_num=cfg.lpr_initial_credit_num;
        bit [CTL_CREDIT_W-1:0] hpr_credit_num=cfg.hpr_initial_credit_num;
        fork
            forever begin
                begin
                    @vif.drv_cb;
                    vif.drv_cb.uif_hpr_credit <= hpr_credit_num;
                    if(vif.uif_cmd_vld && ~vif.uif_cmd_stall && vif.uif_cmd_type==0 && vif.uif_cmd_prio ==0)begin
                        if(hpr_flag)begin
                            hpr_credit_num = hpr_credit_num;
                            hpr_flag = 0;
                        end
                        else if(|hpr_credit_num!=0)
                            hpr_credit_num = hpr_credit_num - 1;
                        else
                            hpr_credit_num = hpr_credit_num;
                    end else if(hpr_flag) begin
                        hpr_flag=0;
                        if(hpr_credit_num==cfg.hpr_initial_credit_num)
                            hpr_credit_num = hpr_credit_num;
                        else
                            hpr_credit_num = hpr_credit_num + 1;
                    end else 
                        hpr_credit_num = hpr_credit_num;
                end
            end

            forever begin
                @vid.drv_cb;
                vif.drv_cb.uif_lpr_credit <= lpr_credit_num;
                if(vif.uif_cmd_vld && ~vif.uif_cmd_stall && ((vif.uif_cmd_type==0 && vif.uif_cmd_prio != 0)|| vif.uif_cmd_type==3)) begin
                    if(lpr_flag)begin
                        lpr_credit_num = lpr_credit_num;
                        lpr_flag = 0;
                    end
                    else if(|lpr_credit_num !=0)
                        lpr_credit_num = lpr_credit_num - 1;
                    else
                        lpr_credit_num = lpr_credit_num;
                end else if(lpr_flag) begin
                    lpr_flag=0;
                    if(|lpr_credit_num == cfg.lpr_initial_credit_num)
                        lpr_credit_num = lpr_credit_num;
                    else
                        lpr_credit_num = lpr_credit_num + 1;
                end else
                    lpr_credit_num = lpr_credit_num;
            end

            fork
                begin
                    forever begin
                        @vif.drv_cb;
                        vif.drv_cb.uif_tpw_credit <= tpw_credit_num;
                        if(vif.uif_cmd_vld && ~vif.uif_cmd_stall && vif.uif_cmd_type==1 && vif.uif_cmd_prio !=0)begin //tpw/gpr
                            if(tpw_flag)begin
                                tpw_credit_num = tpw_credit_num;
                                tpw_flag = 0;
                            end
                            else if(|tpw_credit_num !=0)
                                tpw_credit_num = tpw_credit_num - 1;
                            else
                                tpw_credit_num = tpw_credit_num;
                        end else if(tpw_flag) begin
                            tpw_flag =0;
                            if(tpw_credit_num==cfg.tpw_initial_credit_num)
                                tpw_credit_num = tpw_credit_num;
                            else
                                tpw_credit_num = tpw_credit_num + 1;
                        end else
                            tpw_credit_num = tpw_credit_num;
                    end
                end
                begin
                    forever begin
                        @vif.drv_cb;
                        if(vif.uif_wr_vld && vif.uif_wr_req && vif.uif_wr_end)begin
                            dly_clk2 = $urandom_range(1,20);
                            repeat(dly_clk2) @vif.drv_cb;
                            tpw_flag=1;
                        end
                    end
                end
            join
        join

    endtask : gen_uif_credit



    virtual function  void report_phase(uvm_phase phase);
        










    endfunction : report_phase

endclass : Uif_drv

`endif 