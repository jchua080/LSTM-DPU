`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.11.2022 14:56:29
// Design Name: 
// Module Name: systolic
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


    module systolic #
    (
        parameter integer BIT_WIDTH = 8,
        parameter integer ACC_WIDTH = 32,
        parameter integer BUFFER_SZ = 32,
        parameter integer INDEX_WIDTH = 6,
        parameter integer ARRAY_DIM = 32,
        parameter integer DIM_WIDTH = 5,
        parameter integer STREAM_WIDTH = 32
    )
    (
        input wire clk,
        input wire resetn,
        input wire en,
        input wire wen_up,
        input wire wen_left,
        input wire [ARRAY_DIM-1 : 0] pe_en_up,
        input wire [ARRAY_DIM-1 : 0] pe_en_left,
        input wire [DIM_WIDTH-2 : 0] compact_en_up,
        input wire [DIM_WIDTH-2 : 0] compact_en_left,
        input wire [BUFFER_SZ*ARRAY_DIM*BIT_WIDTH-1 : 0] in_buffer_up,
        input wire [BUFFER_SZ*ARRAY_DIM*BIT_WIDTH-1 : 0] in_buffer_left,
        input wire [INDEX_WIDTH-1 : 0] buffer_index_up,
        input wire [INDEX_WIDTH-1 : 0] buffer_index_left,
        input wire [STREAM_WIDTH-1 : 0] in_total_up,
        input wire [STREAM_WIDTH-1 : 0] in_total_left,
        output reg pushed_up,
        output reg pushed_left,
        output reg complete,
        output wire [ARRAY_DIM*ARRAY_DIM*ACC_WIDTH-1 : 0] acc
    );
    
    reg [BUFFER_SZ*ARRAY_DIM*BIT_WIDTH-1 : 0] buffer_up;
    reg [BUFFER_SZ*ARRAY_DIM*BIT_WIDTH-1 : 0] buffer_left;
    reg [INDEX_WIDTH-1 : 0] index_up;
    reg [INDEX_WIDTH-1 : 0] index_left;
    reg [STREAM_WIDTH-1 : 0] counter_up;
    reg [STREAM_WIDTH-1 : 0] counter_left;
    reg [STREAM_WIDTH-1 : 0] total_up;
    reg [STREAM_WIDTH-1 : 0] total_left;
    reg idle;
    reg count_down;
    reg [DIM_WIDTH : 0] counter_end;
    wire pause;
    wire compute;
    wire [BIT_WIDTH-1 : 0] vert [1 : ARRAY_DIM][0 : ARRAY_DIM-1];
    wire [BIT_WIDTH-1 : 0] hori [0 : ARRAY_DIM-1][1 : ARRAY_DIM];
    
    assign pause = ~idle && ((!index_up && counter_up < total_up) || (!index_left && counter_left < total_left));
    assign compute = en & ~idle & ~pause;
    
    generate
        genvar i, j;
        
        for (i = 0; i < ARRAY_DIM; i = i + 1) begin
            for (j = 0; j < ARRAY_DIM; j = j + 1) begin
                pe # (
                    .BIT_WIDTH(BIT_WIDTH),
                    .ACC_WIDTH(ACC_WIDTH)
                ) pe_inst (
                    .clk(clk),
                    .resetn(resetn),
                    .en(compute & pe_en_up[j] & pe_en_left[i]),
                    .up(!i ? buffer_up[BIT_WIDTH*j +: BIT_WIDTH] : vert[i][j]),
                    .left(!j ? buffer_left[BIT_WIDTH*i +: BIT_WIDTH] : hori[i][j]),
                    .down(vert[i + 1][j]),
                    .right(hori[i][j + 1]),
                    .acc(acc[ACC_WIDTH*(ARRAY_DIM*i+j) +: ACC_WIDTH])
                );
            end
        end
    endgenerate
    
    always @(negedge clk)
        if (~resetn) begin
            {pushed_up, pushed_left, complete, index_up, index_left, counter_up, counter_left, count_down} <= 0;
            total_up <= 1;
            total_left <= 1;
            idle <= 1;
        end
        else begin
            if (~idle && ~count_down && !index_up && !index_left && (total_up > total_left ? counter_up == total_up : counter_left == total_left)) begin
                count_down <= 1;
                counter_end <= ARRAY_DIM - (((compact_en_up < compact_en_left ? compact_en_up : compact_en_left) - 1) << 2) - 1;
            end
            
            if (~pushed_up && wen_up && ~|index_up) begin
                pushed_up <= 1;
                buffer_up <= in_buffer_up;
                index_up <= buffer_index_up;
                total_up <= in_total_up;
                idle <= 0;
            end
            else if (pushed_up & ~wen_up)
                pushed_up <= 0;
                
            if (~pushed_left && wen_left && ~|index_left) begin
                pushed_left <= 1;
                buffer_left <= in_buffer_left;
                index_left <= buffer_index_left;
                total_left <= in_total_left;
                idle <= 0;
            end
            else if (pushed_left & ~wen_left)
                pushed_left <= 0;
                
            if (compute) begin
                if (count_down)
                    if (counter_end)
                        counter_end <= counter_end - 1;
                    else begin
                        complete <= 1;
                        {counter_up, counter_left, count_down} <= 0;
                        total_up <= 1;
                        total_left <= 1;
                        idle <= 1;
                    end
                    
                if (counter_up == total_up)
                    index_up <= 0;
                else if (index_up) begin
                    buffer_up <= buffer_up >> ARRAY_DIM * BIT_WIDTH;
                    index_up <= index_up - 1;
                    counter_up <= counter_up + 1;
                end
                
                if (counter_left == total_left)
                    index_left <= 0;
                else if (index_left && counter_left < total_left) begin
                    buffer_left <= buffer_left >> ARRAY_DIM * BIT_WIDTH;
                    index_left <= index_left - 1;
                    counter_left <= counter_left + 1;
                end
            end
        end
        
    endmodule
