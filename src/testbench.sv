`include "./src/cache_def.sv"

import cache_def::*;

//simulated memory

`timescale 1ns/1ps


class rand_cl;
   rand bit [127:0] v;
endclass

module sim_mem(
            input bit clk,
            input  MemRequest req,
            output MemData data
        );
        default clocking cb @(posedge clk);
        endclocking

        localparam MEM_DELAY = 100;

        bit [127:0] mem[reg[29:0]];
        //bit [127:0] mem[*];
        rand_cl rand_data = new();

        bit [29:0] actual_addr;

        always @(posedge clk) begin
              actual_addr = req.addr[29:0];
              data.ready = '0;

              if (!mem.exists(actual_addr)) begin        //random initialize DRAM data on-demand
                      void'(rand_data.randomize());
                      mem[actual_addr] = rand_data.v;
                      // $display("SHOULD HAVE RANDOM'D -> %x", mem[actual_addr]);
                      mem[actual_addr] = rand_data.v;
              end


              if (req.valid) begin
                $display("%t: [Memory] %s @ addr=%x with data=%x", $time, (req.rw) ? "Write" : "Read", req.addr,
                        (req.rw) ? req.data : mem[actual_addr]);
                ##MEM_DELAY
                if (req.rw)
                        mem[actual_addr] = req.data;
                else begin
                        data.data = mem[actual_addr];
                end

                $display("%t: [Memory] request finished", $time);
                data.ready = '1;
              end
        end
endmodule

module test_main;
        bit clk;
        initial forever #2 clk = ~clk;

        MemRequest mem_req;
        MemData mem_data;
        CPURequest iu_req;
        CPUResult iu_res;

        bit rst;

        bit[31:0] prev_data;
        bit prev_hit;
        bit prev_wb;
        bit prev_valid;
        bit[19:0] prev_tag;

        default clocking cb @(posedge clk);
        endclocking

        task read(input bit[31:0] address);
            iu_req.rw = '0;
            iu_req.addr = address;
            iu_req.valid = '1;
            wait(iu_res.ready == '1);
        endtask

        task write(input bit[31:0] address, input bit[31:0] data);
            iu_req.rw = '1;
            iu_req.addr = address;
            iu_req.data = data;
            iu_req.valid = '1;
            wait(iu_res.ready == '1);
        endtask

        `define mksection(number, title) \
            $display("\033[35m%s\033[0m: \033[36m%s\033[0m", number, title);

        `define check_test(name, lhs, rhs, op) \
            if (lhs op rhs) begin \
                $display("\t\033[34mtest [%s]\033[0m: \033[32mok\033[0m", name); \
            end else begin \
                $display("\t\033[34mtest [%s]\033[0m: \033[31mfailed\033[0m", name); \
            end \
            $display("\t\tCondition: \033[36m%s\033[0m (\033[33m%h\033[0m) \033[35m%s\033[0m \033[36m%s\033[0m (\033[33m%h\033[0m)", `"lhs`", lhs, `"op`", `"rhs`", rhs); \
            iu_req.valid = 0; \
            #5;
        
        //simulated CPU
        initial begin
            rst = '0;
            ##5;
            rst = '1;
            ##10;
            rst = '0;

            iu_req = '{default:0};

            //note that: The CPU needs to reset all cache tags in a real ASIC implementation
            //In this testbench, all tags are automatically initialized to 0 because the use of the systemverilog bit data type
            //For an FPGA implementation, all RAMs are initialized to be 0 by default.
            //read clean miss (allocate)
            $timeformat(-9, 3, "ns", 10);

            /* 7.1.1 Access with cache hit -----------------------------------------*/

            `mksection("7.1.1", "Access with cache hit");
           
            read(0);
            read(0);
            `check_test("checking hit on read", iu_res.hit, 1, &);

            /*----------------------------------------------------------------------*/

            /* 7.1.2 Access with cache hit followed by memory load -----------------*/
            `mksection("7.1.2", "Access with cache hit followed by memory load");
                        
            write('h00000000, 'hF00DCAFE);
            write('h00001000, 'hCAFEBABE);

            read('h00000000);
            prev_data = iu_res.data; 
            #5;
            read('h00001000);
            `check_test(
                "checking miss data change on read", 
                prev_data, iu_res.data, !=
            );
            `check_test(
                "checking miss on read", 
                ~iu_res.hit, 1, &
            );

            /*----------------------------------------------------------------------*/

            /* 7.1.3 Tag & valid bit values ----------------------------------------*/
            `mksection("7.1.3", "Tag & valid bit values");

            read('hCAFFE000);
            `check_test(
                "checking tag value",
                iu_res.line_tag.tag, 'hCAFFE, ==
            );
            `check_test(
                "checking valid bit value",
                iu_res.line_tag.valid, '0, ==
            );
            read('hCAFFE000);
            `check_test(
                "checking valid bit value",
                iu_res.line_tag.valid, '1, ==
            );

            /* 7.2.1 Write with hit ------------------------------------------------*/
            `mksection("7.2.1", "Write with hit");
            read('h00002000);
            `check_test("allocating block for write", iu_res.hit, 0, ==);
            write('h00002000, 'hDEADBEEF);
            prev_hit = iu_res.hit;
            `check_test("checking write hit", prev_hit, 1, ==);
            read('h00002000);
            prev_data = iu_res.data;
            `check_test("checking data written on hit", prev_data, 'hDEADBEEF, ==);

            /*----------------------------------------------------------------------*/
            
            /* 7.2.2 Write with miss -----------------------------------------------*/
            `mksection("7.2.2", "Write with miss");
            write('h00003000, 'hBEEFCAFE);
            prev_hit = iu_res.hit;
            `check_test("checking write miss", prev_hit, 0, ==);
            read('h00003000);
            prev_data = iu_res.data;
            `check_test("checking data written on miss", prev_data, 'hBEEFCAFE, ==);

            /*----------------------------------------------------------------------*/
            
            /* 7.2.3 Write policy --------------------------------------------------*/
            `mksection("7.2.3", "Write policy");
            write('h00004000, 'h12345678);
            `check_test("allocating for policy check", iu_res.hit, 0, ==);
            read('h00004000);
            prev_hit = iu_res.line_tag.dirty; // Note: using prev_hit as a generic bit
            `check_test("checking dirty bit on write", prev_hit, 1, ==);

            /*----------------------------------------------------------------------*/
            
            /* 7.3.1 Cache fill & block substitution -------------------------------*/
            `mksection("7.3.1", "Cache fill & block substitution");
            read('h00005000);
            `check_test("checking fill miss", iu_res.hit, 0, ==);
            read('h00006000);
            prev_hit = iu_res.hit;
            `check_test("checking substitution miss", prev_hit, 0, ==);

            /*----------------------------------------------------------------------*/
            
            /* 7.3.2 Cache substitution policy -------------------------------------*/
            `mksection("7.3.2", "Cache substitution policy");
            read('h00005000);
            prev_hit = iu_res.hit;
            `check_test("checking direct mapped eviction", prev_hit, 0, ==);

            /*----------------------------------------------------------------------*/

            /* 7.3.3 Write-back ----------------------------------------------------*/
            `mksection("7.3.3", "Write-back");
            write('h00007000, 'hAABBCCDD);
            `check_test("write allocating 7000", iu_res.hit, 0, ==);
            read('h00008000);
            prev_wb = iu_res.write_back;
            `check_test("checking write-back occurred", prev_wb, 1, ==);

            /*----------------------------------------------------------------------*/

            /* 7.4.1 Data coherence ------------------------------------------------*/
            `mksection("7.4.1", "Data coherence");
            write('h00009000, 'h99999999);
            `check_test("write allocating 9000", iu_res.hit, 0, ==);
            read('h00009000);
            prev_data = iu_res.data;
            `check_test("checking data coherence read after write", prev_data, 'h99999999, ==);

            /*----------------------------------------------------------------------*/

            /* 7.4.2 Repeated address access ---------------------------------------*/
            `mksection("7.4.2", "Repeated address access");
            read('h0000A000);
            `check_test("first read miss", iu_res.hit, 0, ==);
            read('h0000A000);
            prev_hit = iu_res.hit;
            `check_test("checking hit on repeated access", prev_hit, 1, ==);
            read('h0000A000);
            prev_hit = iu_res.hit;
            `check_test("checking hit on 3rd access", prev_hit, 1, ==);

            /*----------------------------------------------------------------------*/

            /* 7.4.3 Conflicts -----------------------------------------------------*/
            `mksection("7.4.3", "Conflicts");
            read('h0000B000);
            `check_test("first read B000", iu_res.hit, 0, ==);
            read('h0000C000);
            `check_test("first read C000", iu_res.hit, 0, ==);
            read('h0000B000);
            prev_hit = iu_res.hit;
            `check_test("checking conflict miss", prev_hit, 0, ==);

            /*----------------------------------------------------------------------*/

            /* 7.5.1 Edge case access ----------------------------------------------*/
            `mksection("7.5.1", "Edge case access");
            read('hFFFFFFFF);
            prev_hit = iu_res.hit;
            `check_test("checking edge case miss FFFFFFFF", prev_hit, 0, ==);
            read('hFFFFFFF0);
            prev_hit = iu_res.hit;
            `check_test("checking edge case FFFFFFF0", prev_hit, 0, ==);

            /*----------------------------------------------------------------------*/

            /* 7.5.2 Cache initialization ------------------------------------------*/
            `mksection("7.5.2", "Cache initialization");
            read('h0000D000);
            prev_hit = iu_res.hit;
            `check_test("checking initialization miss on untouched address", prev_hit, 0, ==);

            /*----------------------------------------------------------------------*/

            /* 7.5.3 Fully invalid cache behavior ----------------------------------*/
            `mksection("7.5.3", "Fully invalid cache behavior");
            read('h0000E000);
            prev_hit = iu_res.hit;
            `check_test("checking miss E000", prev_hit, 0, ==);
            read('h0000F000);
            prev_hit = iu_res.hit;
            `check_test("checking miss F000", prev_hit, 0, ==);

            /*----------------------------------------------------------------------*/

            $finish();
        end
    dm_cache_fsm dm_cache_inst(
        .clk(clk),
        .rst(rst),
        .cpu_req(iu_req),
        .mem_data(mem_data),
        .mem_req(mem_req),
        .cpu_res(iu_res)
    );
    sim_mem dram_inst(.*, .req(mem_req), .data(mem_data));
endmodule
