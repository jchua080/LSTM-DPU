`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.11.2022 14:57:19
// Design Name: 
// Module Name: systolic_tb
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


    module systolic_tb;
    
    localparam integer BIT_WIDTH = 8;
    localparam integer ACC_WIDTH = 32;
    localparam integer BUFFER_SZ = 21;
    localparam integer INDEX_WIDTH = 6;
    localparam integer ARRAY_DIM = 16;
    localparam integer DIM_WIDTH = 4;
    localparam integer STREAM_WIDTH = 32;
    localparam integer RAM_WIDTH = 32;
    localparam integer RAM_DEPTH = 4;
    localparam integer RAM_ADDR_WIDTH = 2;
    
    wire wen_up;
	wire wen_left;
	wire [DIM_WIDTH-2 : 0] compact_en_up;
	wire [DIM_WIDTH-2 : 0] compact_en_left;
	wire [BUFFER_SZ*ARRAY_DIM*BIT_WIDTH-1 : 0] out_buffer_up;
	wire [BUFFER_SZ*ARRAY_DIM*BIT_WIDTH-1 : 0] out_buffer_left;
	wire [INDEX_WIDTH-1 : 0] buffer_index_up;
	wire [INDEX_WIDTH-1 : 0] buffer_index_left;
    wire started_up;
    wire started_left;
    wire pause_up;
    wire pause_left;
    wire stream_en_up;
    wire stream_en_left;
    wire complete;
    wire [ARRAY_DIM*ARRAY_DIM*RAM_WIDTH-1 : 0] acc;
    wire [RAM_WIDTH-1 : 0] dout_up;
    wire [RAM_WIDTH-1 : 0] dout_left;
    wire pushed_up;
    wire pushed_left;
    wire [RAM_ADDR_WIDTH-1 : 0] out_raddr_up;
    wire [RAM_ADDR_WIDTH-1 : 0] out_raddr_left;
    
    reg clk = 0;
    reg resetn = 0;
    reg en = 0;
    reg start_up = 0;
    reg start_left = 0;
    reg resume_up = 0;
    reg resume_left = 0;
	reg [ARRAY_DIM-1 : 0] pe_en_up;
    reg [ARRAY_DIM-1 : 0] pe_en_left;
    reg [STREAM_WIDTH-1 : 0] length_up;
    reg [STREAM_WIDTH-1 : 0] length_left;
    reg [STREAM_WIDTH-1 : 0] total_up;
    reg [STREAM_WIDTH-1 : 0] total_left;
    reg dram_wen_up = 0;
    reg dram_wen_left = 0;
    reg [RAM_ADDR_WIDTH-1 : 0] waddr_up;
    reg [RAM_ADDR_WIDTH-1 : 0] raddr_up;
    reg [RAM_ADDR_WIDTH-1 : 0] waddr_left;
    reg [RAM_ADDR_WIDTH-1 : 0] raddr_left;
    reg [RAM_WIDTH-1 : 0] din_up;
    reg [RAM_WIDTH-1 : 0] din_left;
    
    dram # (
        .RAM_WIDTH(RAM_WIDTH),
        .RAM_DEPTH(RAM_DEPTH),
        .RAM_ADDR_WIDTH(RAM_ADDR_WIDTH)
    ) dram_inst_up (
        .clk(clk),
        .wen(dram_wen_up),
        .waddr(waddr_up),
        .raddr(stream_en_up ? out_raddr_up : raddr_up),
        .din(din_up),
        .dout(dout_up)
    );
    
    dram # (
        .RAM_WIDTH(RAM_WIDTH),
        .RAM_DEPTH(RAM_DEPTH),
        .RAM_ADDR_WIDTH(RAM_ADDR_WIDTH)
    ) dram_inst_left (
        .clk(clk),
        .wen(dram_wen_left),
        .waddr(waddr_left),
        .raddr(stream_en_left ? out_raddr_left : raddr_left),
        .din(din_left),
        .dout(dout_left)
    );
    
    stream # (
        .BIT_WIDTH(BIT_WIDTH),
        .BUFFER_SZ(BUFFER_SZ),
        .INDEX_WIDTH(INDEX_WIDTH),
        .ARRAY_DIM(ARRAY_DIM),
        .DIM_WIDTH(DIM_WIDTH),
        .STREAM_WIDTH(STREAM_WIDTH),
        .RAM_WIDTH(RAM_WIDTH),
        .RAM_DEPTH(RAM_DEPTH),
        .RAM_ADDR_WIDTH(RAM_ADDR_WIDTH)
    ) stream_inst_up (
        .clk(clk),
        .resetn(resetn),
        .start(start_up),
        .pushed(pushed_up),
        .resume(resume_up),
        .pe_en(pe_en_up),
        .in_length(length_up),
        .start_raddr(raddr_up),
        .din(dout_up),
        .out_buffer(out_buffer_up),
        .wen(wen_up),
        .compact_en(compact_en_up),
        .out_buffer_index(buffer_index_up),
        .started(started_up),
        .pause(pause_up),
        .stream_en(stream_en_up),
        .out_raddr(out_raddr_up)
    );
    
    stream # (
        .BIT_WIDTH(BIT_WIDTH),
        .BUFFER_SZ(BUFFER_SZ),
        .INDEX_WIDTH(INDEX_WIDTH),
        .ARRAY_DIM(ARRAY_DIM),
        .DIM_WIDTH(DIM_WIDTH),
        .STREAM_WIDTH(STREAM_WIDTH),
        .RAM_WIDTH(RAM_WIDTH),
        .RAM_DEPTH(RAM_DEPTH),
        .RAM_ADDR_WIDTH(RAM_ADDR_WIDTH)
    ) stream_inst_left (
        .clk(clk),
        .resetn(resetn),
        .start(start_left),
        .pushed(pushed_left),
        .resume(resume_left),
        .pe_en(pe_en_left),
        .in_length(length_left),
        .start_raddr(raddr_left),
        .din(dout_left),
        .out_buffer(out_buffer_left),
        .wen(wen_left),
        .compact_en(compact_en_left),
        .out_buffer_index(buffer_index_left),
        .started(started_left),
        .pause(pause_left),
        .stream_en(stream_en_left),
        .out_raddr(out_raddr_left)
    );
    
    systolic # (
        .BIT_WIDTH(BIT_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .BUFFER_SZ(BUFFER_SZ),
        .INDEX_WIDTH(INDEX_WIDTH),
        .ARRAY_DIM(ARRAY_DIM),
        .DIM_WIDTH(DIM_WIDTH),
        .STREAM_WIDTH(STREAM_WIDTH)
    ) systolic_inst (
        .clk(clk),
        .resetn(resetn),
        .en(en),
        .wen_up(wen_up),
        .wen_left(wen_left),
        .pe_en_up(pe_en_up),
	    .pe_en_left(pe_en_left),
	    .compact_en_up(compact_en_up),
	    .compact_en_left(compact_en_left),
        .in_buffer_up(out_buffer_up),
        .in_buffer_left(out_buffer_left),
        .buffer_index_up(buffer_index_up),
        .buffer_index_left(buffer_index_left),
        .in_total_up(total_up),
        .in_total_left(total_left),
        .pushed_up(pushed_up),
        .pushed_left(pushed_left),
        .complete(complete),
        .acc(acc)
    );
    integer i;
         
    always #5 clk = ~clk;
    
    initial begin
        #15 resetn = 1;
        
        for (i = 0; i < 2; i = i + 1) begin
            write_dram(0, {8'd0, 8'd32, 8'd16, 8'd0}, i);
            write_dram(1, {8'd0, 8'd33, 8'd17, 8'd1}, i);
            write_dram(2, {8'd0, 8'd34, 8'd18, 8'd2}, i);
            write_dram(3, {8'd0, 8'd35, 8'd19, 8'd3}, i);
        end
        
        pe_en_up = 4'b0111;
        pe_en_left = 4'b0111;
        en = 1;
        
        length_up = 16;
        length_left = 16;
        total_up = 18;
        total_left = 18;
        raddr_up = 0;
        raddr_left = 0;
        start_up = 1;
        start_left = 1;
        
        wait(started_up & started_left);
        #10;
        start_up = 0;
        start_left = 0;
        
        wait(pause_up & pause_left);
        
        for (i = 0; i < 2; i = i + 1) begin
            write_dram(0, {8'd0, 8'd36, 8'd20, 8'd4}, i);
            write_dram(1, {8'd0, 8'd37, 8'd21, 8'd5}, i);
            write_dram(2, {8'd0, 8'd38, 8'd22, 8'd6}, i);
            write_dram(3, {8'd0, 8'd39, 8'd23, 8'd7}, i);
        end
        
        raddr_up = 0;
        raddr_left = 0;
        resume_up = 1;
        resume_left = 1;
        wait(~pause_up & ~pause_left);
        #10;
        resume_up = 0;
        resume_left = 0;
        
        wait(pause_up & pause_left);
        
        for (i = 0; i < 2; i = i + 1) begin
            write_dram(0, {8'd0, 8'd40, 8'd24, 8'd8}, i);
            write_dram(1, {8'd0, 8'd41, 8'd25, 8'd9}, i);
            write_dram(2, {8'd0, 8'd42, 8'd26, 8'd10}, i);
            write_dram(3, {8'd0, 8'd43, 8'd27, 8'd11}, i);
        end
        
        raddr_up = 0;
        raddr_left = 0;
        resume_up = 1;
        resume_left = 1;
        wait(~pause_up & ~pause_left);
        #10;
        resume_up = 0;
        resume_left = 0;
        
        wait(pause_up & pause_left);
        
        for (i = 0; i < 2; i = i + 1) begin
            write_dram(0, {8'd0, 8'd44, 8'd28, 8'd12}, i);
            write_dram(1, {8'd0, 8'd45, 8'd29, 8'd13}, i);
            write_dram(2, {8'd0, 8'd46, 8'd30, 8'd14}, i);
            write_dram(3, {8'd0, 8'd47, 8'd31, 8'd15}, i);
        end
        
        raddr_up = 0;
        raddr_left = 0;
        resume_up = 1;
        resume_left = 1;
        wait(~pause_up & ~pause_left);
        #10;
        resume_up = 0;
        resume_left = 0;
        
        wait(complete);
        
        $display("%x", acc);
       
        #10 $finish;
    end
    
    task write_dram (
        input [RAM_ADDR_WIDTH-1 : 0] waddr,
        input [RAM_WIDTH-1 : 0] din,
        input up_left
    ); begin
    if (up_left) begin
        dram_wen_up = 1;
        waddr_up = waddr;
        din_up = din;
        raddr_up = waddr;
        wait(din == dout_up);
        dram_wen_up = 0;
    end
    else begin
        dram_wen_left = 1;
        waddr_left = waddr;
        din_left = din;
        raddr_left = waddr;
        wait(din == dout_left);
        dram_wen_left = 0;
    end
    #10;
    end
    endtask    
    
    endmodule
