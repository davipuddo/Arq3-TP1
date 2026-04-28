package cache_def;
    timeunit 1ns;
    timeprecision 1ps;

    // data structures for cache tag & data
    parameter int TAGMSB = 31;
    parameter int TAGLSB = 14;

    // 128-bit cache line data
    typedef bit [127:0] CacheLine;

    typedef struct packed {
        bit valid; //valid bit
        bit dirty; //dirty bit
        bit [TAGMSB:TAGLSB] tag; //tag bits
    } tag_t;
    typedef tag_t Tag;

    // cache memory request
    typedef struct {
        bit [9:0] index; // line index
        bit we;          // write enable
    } cache_req_t;
    typedef cache_req_t CacheRequest;

    // Data structures for CPU<->Cache Controller interface
    // CPU Request (CPU->Cache controller)
    typedef struct {
        bit [31:0] addr; //32-bit request addr
        bit [31:0] data; //32-bit request data (used when write)
        bit rw;          //request type : 0 = read, 1 = write
        bit valid;       //request is valid
    } cpu_request_t;
    typedef cpu_request_t CPURequest;

    // Cache result (cache controller->cpu)
    typedef struct {
        bit [31:0] data; //32-bit data
        bit ready;       //result is ready
    } cpu_result_t;
    typedef cpu_result_t CPUResult;

    // data structures for cache controller<->memory interface
    // memory request (cache controller->memory)
    typedef struct {
        bit [31:0] addr; //32-bit request addr
        bit [127:0] data; //32-bit request data (used when write)
        bit rw;          //request type : 0 = read, 1 = write
        bit valid;       //request is valid
    } mem_req_t;
    typedef mem_req_t MemRequest;

    //----------------------------------------------------------------------

    // memory controller response (memory -> cache controller)
    typedef struct {
        CacheLine data; //128-bit read back data
        bit ready;            //data is ready
    } mem_data_t;
    typedef mem_data_t MemData;

endpackage

import cache_def::*;

/*cache: data memory, single port, 1024 blocks*/
module dm_cache_data(
        input bit clk,
        input CacheRequest data_req,           //data request/command, e.g. RW, valid
        input CacheLine data_write,           //write port (128-bit line)
        output CacheLine data_read            //read port
    );
    timeunit 1ns; timeprecision 1ps;

    CacheLine data_mem[1024];

    initial begin
        for (int i=0; i<1024; i++)
            data_mem[i] = '0;
        end
        assign data_read = data_mem[data_req.index];
        always_ff @(posedge(clk)) begin
            if (data_req.we)
                data_mem[data_req.index] <= data_write;
        end
endmodule

/*cache: tag memory, single port, 1024 blocks*/
module dm_cache_tag(
        input bit clk, //write clock
        input CacheRequest tag_req,       //tag request/command, e.g. RW, valid
        input Tag tag_write,     //write port
        output Tag tag_read      //read port
    );
    timeunit 1ns; timeprecision 1ps;

    Tag tag_mem[1024];

    initial begin
        for (int i=0; i<1024; i++)
            tag_mem[i] = '0;
    end

    assign tag_read = tag_mem[tag_req.index];

    always_ff @(posedge(clk)) begin
        if (tag_req.we)
            tag_mem[tag_req.index] <= tag_write;
    end

endmodule


/*cache finite state machine*/
module dm_cache_fsm(
        input bit clk,
        input bit rst,
        input CPURequest cpu_req,     //CPU request input (CPU->cache)
        input MemData mem_data,   //memory response (memory->cache)
        output MemRequest mem_req,    //memory request (cache->memory)
        output CPUResult cpu_res  //cache result (cache->CPU)
    );

    timeunit 1ns; timeprecision 1ps;

    /*write clock*/
    typedef enum {
        idle,
        compare_tag,
        allocate,
        write_back
    } cache_state_t;
    typedef cache_state_t CacheState;

    /*FSM state register*/
    CacheState vstate, rstate;

    /*interface signals to tag memory*/
    Tag tag_read;                //tag read result
    Tag tag_write;               //tag write data
    CacheRequest tag_req;        //tag request

    /*interface signals to cache data memory*/
    CacheLine data_read;     //cache line read data
    CacheLine data_write;    //cache line write data
    CacheRequest data_req;   //data req

    /*temporary variable for cache controller result*/
    CPUResult v_cpu_res;

    /*temporary variable for memory controller request*/
    MemRequest v_mem_req;
    assign mem_req = v_mem_req;         //connect to output ports
    assign cpu_res = v_cpu_res;

    always_comb begin
        /*-------------------------default values for all signals------------*/
        /*no state change by default*/

        vstate = rstate;
        v_cpu_res = '{0, 0};
        tag_write = '{0, 0, 0};
        v_mem_req = '{default:0};

        /*read tag by default*/
        tag_req.we = '0;

        /*direct map index for tag*/
        tag_req.index = cpu_req.addr[13:4];

        /*read current cache line by default*/
        data_req.we = '0;

        /*direct map index for cache data*/
        data_req.index = cpu_req.addr[13:4];

        /*modify correct word (32-bit) based on address*/
        data_write = data_read;

        case (cpu_req.addr[3:2])
            2'b00:data_write[31:0] = cpu_req.data;
            2'b01:data_write[63:32] = cpu_req.data;
            2'b10:data_write[95:64] = cpu_req.data;
            2'b11:data_write[127:96] = cpu_req.data;
        endcase

        /*read out correct word(32-bit) from cache (to CPU)*/
        case (cpu_req.addr[3:2])
            2'b00:v_cpu_res.data = data_read[31:0];
            2'b01:v_cpu_res.data = data_read[63:32];
            2'b10:v_cpu_res.data = data_read[95:64];
            2'b11:v_cpu_res.data = data_read[127:96];
        endcase

        /*memory request address (sampled from CPU request)*/
        v_mem_req.addr = cpu_req.addr;

        /*memory request data (used in write)*/
        v_mem_req.data = data_read;
        v_mem_req.rw = '0;

        //------------------------------------Cache FSM-------------------------
        case (rstate)
            /*idle state*/
            idle : begin
                /*If there is a CPU request, then compare cache tag*/
                if (cpu_req.valid)
                    vstate = compare_tag;
                end

            /*compare_tag state*/
            compare_tag : begin
                /*cache hit (tag match and cache entry is valid)*/
                if (cpu_req.addr[TAGMSB:TAGLSB] == tag_read.tag && tag_read.valid) begin
                    v_cpu_res.ready = '1;
                    /*write hit*/
                    if (cpu_req.rw) begin
                        /*read/modify cache line*/
                        tag_req.we = '1; data_req.we = '1;
                        /*no change in tag*/
                        tag_write.tag = tag_read.tag;
                        tag_write.valid = '1;
                        /*cache line is dirty*/
                        tag_write.dirty = '1;
                    end
                    /*xaction is finished*/
                    vstate = idle;
                end
                else begin   /*cache miss*/

                    /*generate new tag*/
                    tag_req.we = '1;
                    tag_write.valid = '1;

                    /*new tag*/
                    tag_write.tag = cpu_req.addr[TAGMSB:TAGLSB];

                    /*cache line is dirty if write*/
                    tag_write.dirty = cpu_req.rw;

                    /*generate memory request on miss*/
                    v_mem_req.valid = '1;

                    /*compulsory miss or miss with clean block*/
                    if (tag_read.valid == 1'b0 || tag_read.dirty == 1'b0)
                        /*wait till a new block is allocated*/
                        vstate = allocate;
                    else begin
                        /*miss with dirty line*/
                        /*write back address*/
                        v_mem_req.addr = {tag_read.tag, cpu_req.addr[TAGLSB-1:0]};
                        v_mem_req.rw = '1;
                        /*wait till write is completed*/
                        vstate = write_back;
                    end
                end
            end

            /*wait for allocating a new cache line*/
            allocate: begin
                /*keep the refill request asserted until memory responds*/
                v_mem_req.valid = '1;
                v_mem_req.rw = '0;

                /*memory controller has responded*/
                if (mem_data.ready) begin
                    /*re-compare tag for write miss (need modify correct word)*/
                    vstate = compare_tag;
                    data_write = mem_data.data;
                    /*update cache line data*/
                    data_req.we = '1;
                end
            end

            /*wait for writing back dirty cache line*/
            write_back : begin
                /*write back is completed*/
                if (mem_data.ready) begin
                    /*issue new memory request (allocating a new line)*/
                    v_mem_req.valid = '1;
                    v_mem_req.rw = '0;
                    vstate = allocate;
                end
            end
        endcase
    end

    always_ff @(posedge(clk)) begin
        if (rst)
            rstate <= idle; // reset to idle state
                // <-
        else
            rstate <= vstate;
                // <-
    end

    /*connect cache tag/data memory*/
    dm_cache_tag ctag(.*);
    dm_cache_data cdata(.*);

endmodule
