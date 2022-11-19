`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.11.2022 14:57:19
// Design Name: 
// Module Name: pe_tb
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


    module pe_tb;
    
    localparam integer BIT_WIDTH = 8;
    localparam integer ACC_WIDTH = 32;
    
    reg clk = 0;
    reg resetn = 0;
    reg en = 0;
    reg [BIT_WIDTH-1 : 0] up;
    reg [BIT_WIDTH-1 : 0] left;
    wire [BIT_WIDTH-1 : 0] down;
    wire [BIT_WIDTH-1 : 0] right;
    wire [ACC_WIDTH-1 : 0] acc;
    
    pe # (
        .BIT_WIDTH(BIT_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) pe_inst (
        .clk(clk),
        .resetn(resetn),
        .en(en),
        .up(up),
        .left(left),
        .down(down),
        .right(right),
        .acc(acc)
    );
               
    always #5 clk = ~clk;
    
    initial begin
        #12.5 resetn = 1;
        en = 1;
        #10;
        up = 5;
        left = 3;
        #10;
        up = 2;
        left = 1;
        #10 resetn = 0;
        #10 $finish;
    end
    
    endmodule
