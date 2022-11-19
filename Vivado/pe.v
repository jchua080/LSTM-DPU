`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.11.2022 14:56:29
// Design Name: 
// Module Name: pe
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


    module pe #
    (
        parameter integer BIT_WIDTH = 8,
        parameter integer ACC_WIDTH = 32
    )
    (
        input wire clk,
        input wire resetn,
        input wire en,
        input wire [BIT_WIDTH-1 : 0] up,
        input wire [BIT_WIDTH-1 : 0] left,
        output reg [BIT_WIDTH-1 : 0] down,
        output reg [BIT_WIDTH-1 : 0] right,
        output reg [ACC_WIDTH-1 : 0] acc
    );
    
    always @(posedge clk)
        if (~resetn)
            acc <= 0;
        else if (en && up && left)
            acc <= acc + up * left;
            
    always @(negedge clk)
        if (~resetn)
            {down, right} <= 0;
        else if (en) begin
            down <= up;
            right <= left;
        end
        
    endmodule
