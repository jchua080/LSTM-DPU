`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.11.2022 14:57:19
// Design Name: 
// Module Name: dram_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


    module dram_tb;
    
    localparam integer RAM_WIDTH = 32;
    localparam integer RAM_DEPTH = 16;
    localparam integer RAM_ADDR_WIDTH = 4;
    
    reg clk = 1;
    reg wen = 0;
    reg [RAM_ADDR_WIDTH-1 : 0] waddr;
    reg [RAM_ADDR_WIDTH-1 : 0] raddr;
    reg [RAM_WIDTH-1 : 0] din;
    wire [RAM_WIDTH-1 : 0] dout;
    
    integer index;
    
    dram # (
        .RAM_WIDTH(RAM_WIDTH),
        .RAM_DEPTH(RAM_DEPTH),
        .RAM_ADDR_WIDTH(RAM_ADDR_WIDTH)
    ) dram_inst (
        .clk(clk),
        .wen(wen),
        .waddr(waddr),
        .raddr(raddr),
        .din(din),
        .dout(dout)
    );
                 
    always #5 clk = ~clk;
    
    initial begin
        #15 wen = 1;
        
        for (index = 0; index < RAM_DEPTH; index = index + 1) begin
            waddr = index;
            din = (index + 1) << 1;
            #10;
        end
        
        wen = 0;
        for (index = 0; index < RAM_DEPTH; index = index + 1) begin
            raddr = index;
            #10;
        end
        
        #10 $finish;
    end
    
    endmodule
