`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.11.2022 14:56:29
// Design Name: 
// Module Name: dram
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


    module dram # (
        parameter integer RAM_WIDTH = 32,
        parameter integer RAM_DEPTH = 4096,
        parameter integer RAM_ADDR_WIDTH = 12
    )
    (
        input wire clk,
        input wire wen,
        input wire [RAM_ADDR_WIDTH-1 : 0] waddr,
        input wire [RAM_ADDR_WIDTH-1 : 0] raddr,
        input wire [RAM_WIDTH-1 : 0] din,
        output wire [RAM_WIDTH-1 : 0] dout
    );
    
    (* ram_style="distributed" *)
    reg [RAM_WIDTH-1 : 0] ram [0 : RAM_DEPTH-1];
    
    assign dout = ram[raddr];
    
    always @(posedge clk)
        if (wen)
            ram[waddr] <= din;
    
    endmodule
