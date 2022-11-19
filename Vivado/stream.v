`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.11.2022 14:56:29
// Design Name: 
// Module Name: stream
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


    module stream #
    (
        parameter integer BIT_WIDTH = 8,
        parameter integer BUFFER_SZ = 32,
        parameter integer INDEX_WIDTH = 6,
        parameter integer ARRAY_DIM = 32,
        parameter integer DIM_WIDTH = 5,
        parameter integer STREAM_WIDTH = 32,
        parameter integer RAM_WIDTH = 32,
        parameter integer RAM_DEPTH = 4096,
        parameter integer RAM_ADDR_WIDTH = 12
    )
    (
        input wire clk,
        input wire resetn,
        input wire start,
        input wire pushed,
        input wire resume,
        input wire [ARRAY_DIM-1 : 0] pe_en,
        input wire [STREAM_WIDTH-1 : 0] in_length,
        input wire [RAM_ADDR_WIDTH-1 : 0] start_raddr,
        input wire [RAM_WIDTH-1 : 0] din,
        output wire [BUFFER_SZ*ARRAY_DIM*BIT_WIDTH-1 : 0] out_buffer,
        output reg wen,
        output reg [DIM_WIDTH-2 : 0] compact_en,
        output reg [INDEX_WIDTH-1 : 0] out_buffer_index,
        output reg started,
        output reg pause,
        output reg stream_en,
        output reg [RAM_ADDR_WIDTH-1 : 0] out_raddr
    );
    
    reg delay;
    reg excess;
    reg [INDEX_WIDTH-1 : 0] max_excess_index;
    reg restream;
    reg streaming;
    reg [STREAM_WIDTH-1 : 0] counter;
    reg [STREAM_WIDTH-1 : 0] length;
    reg [DIM_WIDTH-1 : 0] pos;
    reg [(BUFFER_SZ<<1)*ARRAY_DIM*BIT_WIDTH-1 : 0] buffer;
    reg [INDEX_WIDTH-1 : 0] buffer_index;
    reg [INDEX_WIDTH-1 : 0] next_buffer_index;
    
    assign out_buffer = buffer[BUFFER_SZ*ARRAY_DIM*BIT_WIDTH-1 : 0];
    
    always @(posedge clk)
        if (~resetn) begin
            {wen, started, pause, stream_en, delay, excess, max_excess_index, restream, streaming, pos, buffer} <= 0;
            buffer_index <= 1;
            next_buffer_index <= 2;
        end
        else begin
            if (delay)
                delay <= 0;
            else if (started & ~start)
                started <= 0;
                
            if (~wen & ~streaming & ~started & start) begin
                started <= 1;
                stream_en <= 1;
                out_raddr <= start_raddr;
                delay <= 1;
                streaming <= 1;
                counter <= 1;
                length <= in_length;
                
                if (ARRAY_DIM == 32 && |pe_en[31 : 28])
                    compact_en <= 1;
                else if (ARRAY_DIM == 32 && |pe_en[27 : 24])
                    compact_en <= 2;
                else if (ARRAY_DIM == 32 && |pe_en[23 : 20])
                    compact_en <= 3;
                else if (ARRAY_DIM == 32 && |pe_en[19 : 16])
                    compact_en <= 4;
                else if ((ARRAY_DIM == 32 || ARRAY_DIM == 16) && |pe_en[15 : 12])
                    compact_en <= (ARRAY_DIM >> 2) - 3;
                else if ((ARRAY_DIM == 32 || ARRAY_DIM == 16) && |pe_en[11 : 8])
                    compact_en <= (ARRAY_DIM >> 2) - 2;
                else if ((ARRAY_DIM == 32 || ARRAY_DIM == 16 || ARRAY_DIM == 8) && |pe_en[7 : 4])
                    compact_en <= (ARRAY_DIM >> 2) - 1;
                else
                    compact_en <= ARRAY_DIM >> 2;
            end
            else if (excess & restream) begin
                wen <= 1;
                out_buffer_index <= max_excess_index;
                {max_excess_index, excess, restream} <= 0;
            end
            else if (streaming) begin
                if (pause) begin
                    if (resume) begin
                        pause <= 0;
                        stream_en <= 1;
                        out_raddr <= start_raddr;
                    end
                end
                else begin
                    buffer[BIT_WIDTH*(ARRAY_DIM*(buffer_index-1)+pos) +: BIT_WIDTH] <= din[BIT_WIDTH-1 : 0];
                    buffer[BIT_WIDTH*(ARRAY_DIM*buffer_index+pos+1) +: BIT_WIDTH] <= din[(BIT_WIDTH<<1)-1 : BIT_WIDTH];
                    buffer[BIT_WIDTH*(ARRAY_DIM*(buffer_index+1)+pos+2) +: BIT_WIDTH] <= din[3*BIT_WIDTH-1 : (BIT_WIDTH<<1)];
                    buffer[BIT_WIDTH*(ARRAY_DIM*(buffer_index+2)+pos+3) +: BIT_WIDTH] <= din[(BIT_WIDTH<<2)-1 : 3*BIT_WIDTH];
                    
                    if (buffer_index > BUFFER_SZ - 3) begin
                        excess <= 1;
                        
                        if (buffer_index + 3 - BUFFER_SZ > max_excess_index)
                            max_excess_index <= buffer_index + 3 - BUFFER_SZ;
                    end
                    
                    if (pos == ARRAY_DIM - (compact_en << 2) && (next_buffer_index == BUFFER_SZ + 1 || counter == length)) begin
                        out_buffer_index <= buffer_index + 3 >= BUFFER_SZ ? BUFFER_SZ : buffer_index + 3;
                        wen <= 1;
                        streaming <= 0;
                    end
                    else begin
                        if (out_raddr < RAM_DEPTH - 1)
                            out_raddr <= out_raddr + 1;
                        else begin
                            pause <= 1;
                            stream_en <= 0;
                        end
                        
                        if (pos != ARRAY_DIM - (compact_en << 2)) begin
                            pos <= pos + 4;
                            buffer_index <= buffer_index + 4;
                        end
                        else begin
                            buffer_index <= next_buffer_index;
                            counter <= counter + 1;
                            pos <= 0;
                            next_buffer_index <= next_buffer_index + 1;
                        end
                    end
                end
            end
            else if (pushed & wen) begin
                {wen, pos} <= 0;
                buffer <= buffer >> BUFFER_SZ * ARRAY_DIM * BIT_WIDTH;
                buffer_index <= 1;
                next_buffer_index <= 2;
                
                if (counter != length) begin
                    {excess, max_excess_index} <= 0;
                    streaming <= 1;
                    counter <= counter + 1;
                    
                    if (out_raddr < RAM_DEPTH - 1)
                        out_raddr <= out_raddr + 1;
                    else begin
                        pause <= 1;
                        stream_en <= 0;
                    end
                end
                else if (excess)
                    restream <= 1;
                else
                    {stream_en, buffer} <= 0;
            end
        end
        
    endmodule
