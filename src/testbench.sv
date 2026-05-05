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

        bit [127:0] mem[*];
        rand_cl rand_data = new();

        bit [29:0] actual_addr;

        always @(posedge clk) begin
              actual_addr = req.addr[31:2];
              data.ready = '0;

              if (!mem.exists(actual_addr)) begin        //random initialize DRAM data on-demand
                      void'(rand_data.randomize());
                      mem[actual_addr] = rand_data.v;
                      $display("SHOULD HAVE RANDOM'D -> %x", mem[actual_addr]);
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

        default clocking cb @(posedge clk);
        endclocking

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

            iu_req.rw = '0;
            iu_req.addr[11:2] = 2;           //index 2
            iu_req.addr[31:12] = 'h12345;
            iu_req.valid = '1;
            $display("%t: [CPU] read addr=%x | tag=%x | index=%x | offset=%x", $time,
                iu_req.addr,
                iu_req.addr[31:12],
                iu_req.addr[11:2],
                iu_req.addr[1:0]
            );
            wait(iu_res.ready == '1);
            $display("%t: [CPU] get data=%x", $time, iu_res.data);
            iu_req.valid = '0;
            ##5;

            //read hit clean line
            iu_req.addr[1:0] = 'b0;   // Offset
            iu_req.valid = '1;
            $display("%t: [CPU] read addr=%x | tag=%x | index=%x | offset=%x", $time,
                iu_req.addr,
                iu_req.addr[31:12],
                iu_req.addr[11:2],
                iu_req.addr[1:0]
            );
            wait(iu_res.ready == '1);
            $display("%t: [CPU] get data=%x", $time, iu_res.data);
            iu_req.valid = '0;
            ##5;

            //write hit clean line (cache line is dirty afterwards)
            iu_req.rw = '1;
            iu_req.addr[1:0] = 'b10;   // Offset
            iu_req.data = 32'hdeadbeef;
            iu_req.valid = '1;
            $display("%t: [CPU] write addr=%x | tag=%x | index=%x | offset=%x with data=%x", $time,
                iu_req.addr,
                iu_req.addr[31:12],
                iu_req.addr[11:2],
                iu_req.addr[1:0],
                iu_req.data
            );
            wait(iu_res.ready == '1);
            $display("%t: [CPU] write done", $time);
            iu_req.valid = '0;
            ##5;

            //write conflict miss (write back then allocate, cache line dirty)
            iu_req.addr[31:12] = 'h43215;
            iu_req.data = 32'hcafebeef;
            iu_req.valid = '1;
            $display("%t: [CPU] write addr=%x | tag=%x | index=%x | offset=%x with data=%x", $time,
                iu_req.addr,
                iu_req.addr[31:12],
                iu_req.addr[11:2],
                iu_req.addr[1:0],
                iu_req.data
            );
            wait(iu_res.ready == '1);
            $display("%t: [CPU] write done", $time);
            iu_req.valid = '0;
            ##5;

            //read hit dirty line from the same word written above
            iu_req.rw = '0;
            iu_req.addr[1:0] = 'b10;            // Offset
            iu_req.valid = '1;
            $display("%t: [CPU] read addr=%x | tag=%x | index=%x | offset=%x", $time,
                iu_req.addr,
                iu_req.addr[31:12],
                iu_req.addr[11:2],
                iu_req.addr[1:0]
            );
            wait(iu_res.ready == '1);
            $display("%t: [CPU] get data=%x", $time, iu_res.data);
            iu_req.valid = '0;
            ##5;

            //read conflict miss dirty line (write back then allocate, cache line is clean)
            iu_req.addr[31:12] = 'h56789;
            iu_req.addr[1:0] = 'b0;         // Offset
            iu_req.valid = '1;
            $display("%t: [CPU] read addr=%x | tag=%x | index=%x | offset=%x", $time,
                iu_req.addr,
                iu_req.addr[31:12],
                iu_req.addr[11:2],
                iu_req.addr[1:0]
            );
            wait(iu_res.ready == '1);
            $display("%t: [CPU] get data=%x", $time, iu_res.data);
            iu_req.valid = '0;
            ##5;

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
