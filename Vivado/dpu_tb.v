`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.11.2022 14:57:19
// Design Name: 
// Module Name: dpu_tb
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


    module dpu_tb;
    
    localparam integer BIT_WIDTH = 8;
    localparam integer ACC_WIDTH = 32;
    localparam integer BUFFER_SZ = 32;
    localparam integer INDEX_WIDTH = 6;
    localparam integer ARRAY_DIM = 32;
    localparam integer DIM_WIDTH = 5;
    localparam integer STREAM_WIDTH = 32;
    localparam integer RAM_WIDTH = 32;
    localparam integer RAM_DEPTH = 4096;
    localparam integer RAM_ADDR_WIDTH = 12;
    localparam integer C_S00_AXI_ADDR_WIDTH	= 16;
    localparam integer C_S00_AXI_DATA_WIDTH	= 32;
    localparam integer C_S00_AXI_STRB_WIDTH = 4;
    localparam integer C_S00_AXI_RESP_WIDTH = 2;
    localparam integer C_S00_AXI_PROT_WIDTH = 3;
    
    wire s00_axi_awready;
    wire s00_axi_wready;
    wire [C_S00_AXI_RESP_WIDTH-1 : 0] s00_axi_bresp;
    wire s00_axi_bvalid;
    wire s00_axi_arready;
    wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata;
    wire [C_S00_AXI_RESP_WIDTH-1 : 0] s00_axi_rresp;
    wire s00_axi_rvalid;
    
    reg s00_axi_aclk = 0;
    reg s00_axi_aresetn = 0;
    reg [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr;
    reg [C_S00_AXI_PROT_WIDTH-1 : 0] s00_axi_awprot;
    reg s00_axi_awvalid = 0;
    reg [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata;
    reg [C_S00_AXI_STRB_WIDTH-1 : 0] s00_axi_wstrb;
    reg s00_axi_wvalid = 0;
    reg s00_axi_bready = 0;
    reg [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr;
    reg [C_S00_AXI_PROT_WIDTH-1 : 0] s00_axi_arprot;
    reg s00_axi_arvalid = 0;
    reg s00_axi_rready = 0;
    
    integer i, j;
    
    dpu_v1_0 # (
        .BIT_WIDTH(BIT_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .BUFFER_SZ(BUFFER_SZ),
        .INDEX_WIDTH(INDEX_WIDTH),
        .ARRAY_DIM(ARRAY_DIM),
        .DIM_WIDTH(DIM_WIDTH),
        .STREAM_WIDTH(STREAM_WIDTH),
        .RAM_WIDTH(RAM_WIDTH),
        .RAM_DEPTH(RAM_DEPTH),
        .RAM_ADDR_WIDTH(RAM_ADDR_WIDTH),
        .C_S00_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH),
        .C_S00_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S00_AXI_STRB_WIDTH(C_S00_AXI_STRB_WIDTH),
        .C_S00_AXI_RESP_WIDTH(C_S00_AXI_RESP_WIDTH),
        .C_S00_AXI_PROT_WIDTH(C_S00_AXI_PROT_WIDTH)
    ) dpu_inst (
        .s00_axi_aclk(s00_axi_aclk),
		.s00_axi_aresetn(s00_axi_aresetn),
		.s00_axi_awaddr(s00_axi_awaddr),
		.s00_axi_awprot(s00_axi_awprot),
		.s00_axi_awvalid(s00_axi_awvalid),
		.s00_axi_awready(s00_axi_awready),
		.s00_axi_wdata(s00_axi_wdata),
		.s00_axi_wstrb(s00_axi_wstrb),
		.s00_axi_wvalid(s00_axi_wvalid),
		.s00_axi_wready(s00_axi_wready),
		.s00_axi_bresp(s00_axi_bresp),
		.s00_axi_bvalid(s00_axi_bvalid),
		.s00_axi_bready(s00_axi_bready),
		.s00_axi_araddr(s00_axi_araddr),
		.s00_axi_arprot(s00_axi_arprot),
		.s00_axi_arvalid(s00_axi_arvalid),
		.s00_axi_arready(s00_axi_arready),
		.s00_axi_rdata(s00_axi_rdata),
		.s00_axi_rresp(s00_axi_rresp),
		.s00_axi_rvalid(s00_axi_rvalid),
		.s00_axi_rready(s00_axi_rready)
    );
    
    always #5 s00_axi_aclk = ~s00_axi_aclk;
     
    initial begin
        #15 s00_axi_aresetn = 1;
        s00_axi_wstrb = 4'b1111;
        
        // 0-4095     rw BRAM up
        // 4096-8191  rw BRAM left
        // 8192       rw sys_resetn, sys_en
        // 8193       rw pe_en_up
        // 8194       rw pe_en_left
        // 8195       rw resume_left, resume_up, start_left, start_up
        // 8196       rw length_up
        // 8197       rw length_left
        // 8198       rw total_up
        // 8199       rw total_left
        // 8200       r  dram_wen_up
        // 8201       r  dram_wen_left
        // 8202       rw waddr_up
        // 8203       r  raddr_up
        // 8204       rw waddr_left
        // 8205       r  raddr_left
        // 8206       r  dout_up
        // 8207       r  dout_left
        // 8208       r  complete, stream_en_left, stream_en_up, pause_left, pause_up, started_left, started_up
        // 8209-9232  r  acc_reg
        
        /*
        for (i = 0; i < 2; i = i + 1) begin
            write_axi(0 + 4096 * i,  {8'd48,  8'd32,  8'd16,  8'd0});
            write_axi(4 + 4096 * i,  {8'd49,  8'd33,  8'd17,  8'd1});
            write_axi(8 + 4096 * i,  {8'd50,  8'd34,  8'd18,  8'd2});
            write_axi(12 + 4096 * i, {8'd51,  8'd35,  8'd19,  8'd3});
            write_axi(16 + 4096 * i, {8'd52,  8'd36,  8'd20,  8'd4});
            write_axi(20 + 4096 * i, {8'd53,  8'd37,  8'd21,  8'd5});
            write_axi(24 + 4096 * i, {8'd54,  8'd38,  8'd22,  8'd6});
            write_axi(28 + 4096 * i, {8'd55,  8'd39,  8'd23,  8'd7});
            write_axi(32 + 4096 * i, {8'd56,  8'd40,  8'd24,  8'd8});
            write_axi(36 + 4096 * i, {8'd57,  8'd41,  8'd25,  8'd9});
            write_axi(40 + 4096 * i, {8'd58,  8'd42,  8'd26,  8'd10});
            write_axi(44 + 4096 * i, {8'd59,  8'd43,  8'd27,  8'd11});
            write_axi(48 + 4096 * i, {8'd60,  8'd44,  8'd28,  8'd12});
            write_axi(52 + 4096 * i, {8'd61,  8'd45,  8'd29,  8'd13});
            write_axi(56 + 4096 * i, {8'd62,  8'd46,  8'd30,  8'd14});
            write_axi(60 + 4096 * i, {8'd63,  8'd47,  8'd31,  8'd15});
            
            write_axi(1 + 4096 * i,  {8'd112, 8'd96,  8'd80,  8'd64});
            write_axi(5 + 4096 * i,  {8'd113, 8'd97,  8'd81,  8'd65});
            write_axi(9 + 4096 * i,  {8'd114, 8'd98,  8'd82,  8'd66});
            write_axi(13 + 4096 * i, {8'd115, 8'd99,  8'd83,  8'd67});
            write_axi(17 + 4096 * i, {8'd116, 8'd100, 8'd84,  8'd68});
            write_axi(21 + 4096 * i, {8'd117, 8'd101, 8'd85,  8'd69});
            write_axi(25 + 4096 * i, {8'd118, 8'd102, 8'd86,  8'd70});
            write_axi(29 + 4096 * i, {8'd119, 8'd103, 8'd87,  8'd71});
            write_axi(33 + 4096 * i, {8'd120, 8'd104, 8'd88,  8'd72});
            write_axi(37 + 4096 * i, {8'd121, 8'd105, 8'd89,  8'd73});
            write_axi(41 + 4096 * i, {8'd122, 8'd106, 8'd90,  8'd74});
            write_axi(45 + 4096 * i, {8'd123, 8'd107, 8'd91,  8'd75});
            write_axi(49 + 4096 * i, {8'd124, 8'd108, 8'd92,  8'd76});
            write_axi(53 + 4096 * i, {8'd125, 8'd109, 8'd93,  8'd77});
            write_axi(57 + 4096 * i, {8'd126, 8'd110, 8'd94,  8'd78});
            write_axi(61 + 4096 * i, {8'd127, 8'd111, 8'd95,  8'd79});
            
            write_axi(2 + 4096 * i,  {8'd176, 8'd160, 8'd144, 8'd128});
            write_axi(6 + 4096 * i,  {8'd177, 8'd161, 8'd145, 8'd129});
            write_axi(10 + 4096 * i, {8'd178, 8'd162, 8'd146, 8'd130});
            write_axi(14 + 4096 * i, {8'd179, 8'd163, 8'd147, 8'd131});
            write_axi(18 + 4096 * i, {8'd180, 8'd164, 8'd148, 8'd132});
            write_axi(22 + 4096 * i, {8'd181, 8'd165, 8'd149, 8'd133});
            write_axi(26 + 4096 * i, {8'd182, 8'd166, 8'd150, 8'd134});
            write_axi(30 + 4096 * i, {8'd183, 8'd167, 8'd151, 8'd135});
            write_axi(34 + 4096 * i, {8'd184, 8'd168, 8'd152, 8'd136});
            write_axi(38 + 4096 * i, {8'd185, 8'd169, 8'd153, 8'd137});
            write_axi(42 + 4096 * i, {8'd186, 8'd170, 8'd154, 8'd138});
            write_axi(46 + 4096 * i, {8'd187, 8'd171, 8'd155, 8'd139});
            write_axi(50 + 4096 * i, {8'd188, 8'd172, 8'd156, 8'd140});
            write_axi(54 + 4096 * i, {8'd189, 8'd173, 8'd157, 8'd141});
            write_axi(58 + 4096 * i, {8'd190, 8'd174, 8'd158, 8'd142});
            write_axi(62 + 4096 * i, {8'd191, 8'd175, 8'd159, 8'd143});
            
            write_axi(3 + 4096 * i,  {8'd240, 8'd224, 8'd208, 8'd192});
            write_axi(7 + 4096 * i,  {8'd241, 8'd225, 8'd209, 8'd193});
            write_axi(11 + 4096 * i, {8'd242, 8'd226, 8'd210, 8'd194});
            write_axi(15 + 4096 * i, {8'd243, 8'd227, 8'd211, 8'd195});
            write_axi(19 + 4096 * i, {8'd244, 8'd228, 8'd212, 8'd196});
            write_axi(23 + 4096 * i, {8'd245, 8'd229, 8'd213, 8'd197});
            write_axi(27 + 4096 * i, {8'd246, 8'd230, 8'd214, 8'd198});
            write_axi(31 + 4096 * i, {8'd247, 8'd231, 8'd215, 8'd199});
            write_axi(35 + 4096 * i, {8'd248, 8'd232, 8'd216, 8'd200});
            write_axi(39 + 4096 * i, {8'd249, 8'd233, 8'd217, 8'd201});
            write_axi(43 + 4096 * i, {8'd250, 8'd234, 8'd218, 8'd202});
            write_axi(47 + 4096 * i, {8'd251, 8'd235, 8'd219, 8'd203});
            write_axi(51 + 4096 * i, {8'd252, 8'd236, 8'd220, 8'd204});
            write_axi(55 + 4096 * i, {8'd253, 8'd237, 8'd221, 8'd205});
            write_axi(59 + 4096 * i, {8'd254, 8'd238, 8'd222, 8'd206});
            write_axi(63 + 4096 * i, {8'd255, 8'd239, 8'd223, 8'd207});
        end
        
        compute(16'hFFFF, 16'hFFFF, 16, 31, 31, 16, 16);
        */
        
        /*
        write_axi(0, {8'd0, 8'd0, 8'd0, 8'd1});
        write_axi(4096, {8'd0, 8'd0, 8'd0, 8'd1});
        compute(4'b0001, 4'b0001, 1, 1, 1, 1, 1);
        
        write_axi(0, {8'd0, 8'd0, 8'd2, 8'd1});
        write_axi(4096, {8'd0, 8'd0, 8'd0, 8'd1});
        compute(4'b0011, 4'b0001, 1, 2, 1, 1, 2);
        
        write_axi(0, {8'd0, 8'd3, 8'd2, 8'd1});
        write_axi(4096, {8'd0, 8'd0, 8'd0, 8'd1});
        compute(4'b0111, 4'b0001, 1, 3, 1, 1, 3);
        
        write_axi(0, {8'd0, 8'd0, 8'd0, 8'd1});
        write_axi(1, {8'd0, 8'd0, 8'd0, 8'd2});
        write_axi(4096, {8'd0, 8'd0, 8'd0, 8'd1});
        write_axi(4097, {8'd0, 8'd0, 8'd0, 8'd2});
        compute(4'b0001, 4'b0001, 2, 2, 2, 1, 1);
        
        write_axi(0, {8'd0, 8'd0, 8'd3, 8'd1});
        write_axi(1, {8'd0, 8'd0, 8'd4, 8'd2});
        write_axi(4096, {8'd0, 8'd0, 8'd0, 8'd1});
        write_axi(4097, {8'd0, 8'd0, 8'd0, 8'd2});
        compute(4'b0011, 4'b0001, 2, 3, 2, 1, 2);
        
        write_axi(0, {8'd0, 8'd5, 8'd3, 8'd1});
        write_axi(1, {8'd0, 8'd6, 8'd4, 8'd2});
        write_axi(4096, {8'd0, 8'd0, 8'd0, 8'd1});
        write_axi(4097, {8'd0, 8'd0, 8'd0, 8'd2});
        compute(4'b0111, 4'b0001, 2, 4, 2, 1, 3);
        
        write_axi(0, {8'd0, 8'd0, 8'd0, 8'd1});
        write_axi(1, {8'd0, 8'd0, 8'd0, 8'd2});
        write_axi(2, {8'd0, 8'd0, 8'd0, 8'd3});
        write_axi(4096, {8'd0, 8'd0, 8'd0, 8'd1});
        write_axi(4097, {8'd0, 8'd0, 8'd0, 8'd2});
        write_axi(4098, {8'd0, 8'd0, 8'd0, 8'd3});
        compute(4'b0001, 4'b0001, 3, 3, 3, 1, 1);
        
        write_axi(0, {8'd0, 8'd0, 8'd4, 8'd1});
        write_axi(1, {8'd0, 8'd0, 8'd5, 8'd2});
        write_axi(2, {8'd0, 8'd0, 8'd6, 8'd3});
        write_axi(4096, {8'd0, 8'd0, 8'd0, 8'd1});
        write_axi(4097, {8'd0, 8'd0, 8'd0, 8'd2});
        write_axi(4098, {8'd0, 8'd0, 8'd0, 8'd3});
        compute(4'b0011, 4'b0001, 3, 4, 3, 1, 2);
        
        write_axi(0, {8'd0, 8'd7, 8'd4, 8'd1});
        write_axi(1, {8'd0, 8'd8, 8'd5, 8'd2});
        write_axi(2, {8'd0, 8'd9, 8'd6, 8'd3});
        write_axi(4096, {8'd0, 8'd0, 8'd0, 8'd1});
        write_axi(4097, {8'd0, 8'd0, 8'd0, 8'd2});
        write_axi(4098, {8'd0, 8'd0, 8'd0, 8'd3});
        compute(4'b0111, 4'b0001, 3, 5, 3, 1, 3);
        
        write_axi(0, {8'd0, 8'd0, 8'd0, 8'd1});
        write_axi(4096, {8'd0, 8'd0, 8'd2, 8'd1});
        compute(4'b0001, 4'b0011, 1, 1, 2, 2, 1);
        */
        
        /*
        write_axi(0, {8'd10, 8'd7, 8'd4, 8'd1});
        write_axi(1, {8'd22, 8'd19, 8'd16, 8'd13});
        write_axi(2, {8'd34, 8'd31, 8'd28, 8'd25});
        write_axi(3, {8'd46, 8'd43, 8'd40, 8'd37});
        write_axi(4, {8'd58, 8'd55, 8'd52, 8'd49});
        write_axi(5, {8'd70, 8'd67, 8'd64, 8'd61});
        write_axi(6, {8'd82, 8'd79, 8'd76, 8'd73});
        write_axi(7, {8'd0, 8'd91, 8'd88, 8'd85});
        write_axi(8, {8'd11, 8'd8, 8'd5, 8'd2});
        write_axi(9, {8'd23, 8'd20, 8'd17, 8'd14});
        write_axi(10, {8'd35, 8'd32, 8'd29, 8'd26});
        write_axi(11, {8'd47, 8'd44, 8'd41, 8'd38});
        write_axi(12, {8'd59, 8'd56, 8'd53, 8'd50});
        write_axi(13, {8'd71, 8'd68, 8'd65, 8'd62});
        write_axi(14, {8'd83, 8'd80, 8'd77, 8'd74});
        write_axi(15, {8'd0, 8'd92, 8'd89, 8'd86});
        write_axi(16, {8'd12, 8'd9, 8'd6, 8'd3});
        write_axi(17, {8'd24, 8'd21, 8'd18, 8'd15});
        write_axi(18, {8'd36, 8'd33, 8'd30, 8'd27});
        write_axi(19, {8'd48, 8'd45, 8'd42, 8'd39});
        write_axi(20, {8'd60, 8'd57, 8'd54, 8'd51});
        write_axi(21, {8'd72, 8'd69, 8'd66, 8'd63});
        write_axi(22, {8'd84, 8'd81, 8'd78, 8'd75});
        write_axi(23, {8'd0, 8'd93, 8'd90, 8'd87});
        write_axi(4096, {8'd0, 8'd0, 8'd0, 8'd1});
        write_axi(4097, {8'd0, 8'd0, 8'd0, 8'd2});
        write_axi(4098, {8'd0, 8'd0, 8'd0, 8'd3});
        compute(32'h7FFFFFFF, 4'b0001, 3, 33, 3, 1, 31);
        */
        
        write_axi(0, {8'd0, 8'd0, 8'd0, 8'd1});
        write_axi(4096, {8'd0, 8'd0, 8'd0, 8'd1});
        compute(4'b0001, 4'b0001, 1, 1, 1, 1, 1);
        
        #10 $finish;
    end
    
    task compute (
        input [ARRAY_DIM-1 : 0] pe_up_en,
        input [ARRAY_DIM-1 : 0] pe_left_en,
        input [STREAM_WIDTH-1 : 0] length,
        input [STREAM_WIDTH-1 : 0] total_up,
        input [STREAM_WIDTH-1 : 0] total_left,
        input [DIM_WIDTH : 0] left_en,
        input [DIM_WIDTH : 0] up_en
    ); begin
        write_axi(8192, 0);
        write_axi(8192, 1 << 8);
        
        write_axi(8193, pe_up_en);
        write_axi(8194, pe_left_en);
        
        write_axi(8196, length);
        write_axi(8197, length);
        write_axi(8198, total_up);
        write_axi(8199, total_left);
        write_axi(8203, 0);
        write_axi(8205, 0);
        
        write_axi(8192, (1 << 8) + 1);
        write_axi(8195, (1 << 8) + 1);
        
        read_axi(8208);
        while (~s00_axi_rdata[0] && ~s00_axi_rdata[1])
            read_axi(8208);
            
        write_axi(8195, 0);
        
        read_axi(8208);
        while (~s00_axi_rdata[4])
            read_axi(8208);
            
        write_axi(8192, 1 << 8);
        
        for (i = 0; i < left_en; i = i + 1) begin
            for (j = 0; j < up_en; j = j + 1) begin
                read_axi(8209 + ARRAY_DIM * i + j);
                $display("%x", s00_axi_rdata);
            end
        end
        $display(".");
    end
    endtask
    
    task write_axi (
        input [C_S00_AXI_ADDR_WIDTH-1 : 0] addr,
        input [C_S00_AXI_DATA_WIDTH-1 : 0] data
    ); begin
        s00_axi_awaddr = addr << 2;
        s00_axi_wdata = data;
        s00_axi_awvalid = 1;
        s00_axi_wvalid = 1;
        s00_axi_bready = 1;
        wait(s00_axi_bvalid);
        s00_axi_awvalid = 0;
        s00_axi_wvalid = 0;
        wait(~s00_axi_bvalid);
        s00_axi_bready = 0;
    end
    endtask
    
    task read_axi (
        input [C_S00_AXI_ADDR_WIDTH-1 : 0] addr
    ); begin
        s00_axi_araddr = addr << 2;
        s00_axi_arvalid = 1;
        s00_axi_rready = 1;
        wait(s00_axi_rvalid);
        s00_axi_arvalid = 0;
        wait(~s00_axi_rvalid);
        s00_axi_rready = 0;
    end
    endtask
    
    endmodule
