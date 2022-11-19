
`timescale 1 ns / 1 ps

	module dpu_v1_0 #
	(
		// Users to add parameters here
        parameter integer BIT_WIDTH = 8,
        parameter integer ACC_WIDTH = 32,
        parameter integer BUFFER_SZ = 32,
        parameter integer INDEX_WIDTH = 6,
        parameter integer ARRAY_DIM = 32,
        parameter integer DIM_WIDTH = 5,
        parameter integer STREAM_WIDTH = 32,
        parameter integer RAM_WIDTH = 32,
        parameter integer RAM_DEPTH = 4096,
        parameter integer RAM_ADDR_WIDTH = 12,
		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_ADDR_WIDTH	= 16,
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_STRB_WIDTH = 4,
		parameter integer C_S00_AXI_RESP_WIDTH = 2,
		parameter integer C_S00_AXI_PROT_WIDTH = 3
	)
	(
		// Users to add ports here
        
		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [C_S00_AXI_PROT_WIDTH-1 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [C_S00_AXI_STRB_WIDTH-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [C_S00_AXI_RESP_WIDTH-1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [C_S00_AXI_PROT_WIDTH-1 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [C_S00_AXI_RESP_WIDTH-1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready
	);
	
	wire wen_up;
	wire wen_left;
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
    wire start_up;
    wire start_left;
    wire pushed_up;
    wire pushed_left;
    wire resume_up;
    wire resume_left;
    wire [STREAM_WIDTH-1 : 0] length_up;
    wire [STREAM_WIDTH-1 : 0] length_left;
    wire [STREAM_WIDTH-1 : 0] total_up;
    wire [STREAM_WIDTH-1 : 0] total_left;
    wire sys_en;
    wire sys_resetn;
    wire [ARRAY_DIM-1 : 0] pe_en_up;
    wire [ARRAY_DIM-1 : 0] pe_en_left;
    wire [DIM_WIDTH-2 : 0] compact_en_up;
    wire [DIM_WIDTH-2 : 0] compact_en_left;
    wire dram_wen_up;
    wire dram_wen_left;
    wire [RAM_ADDR_WIDTH-1 : 0] waddr_up;
    wire [RAM_ADDR_WIDTH-1 : 0] raddr_up;
    wire [RAM_ADDR_WIDTH-1 : 0] out_raddr_up;
    wire [RAM_ADDR_WIDTH-1 : 0] waddr_left;
    wire [RAM_ADDR_WIDTH-1 : 0] raddr_left;
    wire [RAM_ADDR_WIDTH-1 : 0] out_raddr_left;
    wire [RAM_WIDTH-1 : 0] din_up;
    wire [RAM_WIDTH-1 : 0] din_left;
    
    // Instantiation of Axi Bus Interface S00_AXI
	dpu_v1_0_S00_AXI # (
        .BIT_WIDTH(BIT_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .ARRAY_DIM(ARRAY_DIM),
        .STREAM_WIDTH(STREAM_WIDTH),
        .RAM_WIDTH(RAM_WIDTH),
        .RAM_DEPTH(RAM_DEPTH),
        .RAM_ADDR_WIDTH(RAM_ADDR_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH),
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_STRB_WIDTH(C_S00_AXI_STRB_WIDTH),
		.C_S_AXI_RESP_WIDTH(C_S00_AXI_RESP_WIDTH),
		.C_S_AXI_PROT_WIDTH(C_S00_AXI_PROT_WIDTH)
	) dpu_v1_0_S00_AXI_inst (
	    .started_up(started_up),
	    .started_left(started_left),
	    .pause_up(pause_up),
	    .pause_left(pause_left),
	    .complete(complete),
	    .acc(acc),
	    .din_up(dout_up),
	    .din_left(dout_left),
	    .start_up(start_up),
	    .start_left(start_left),
	    .resume_up(resume_up),
	    .resume_left(resume_left),
	    .length_up(length_up),
	    .length_left(length_left),
	    .total_up(total_up),
	    .total_left(total_left),
	    .sys_en(sys_en),
	    .sys_resetn(sys_resetn),
	    .pe_en_up(pe_en_up),
	    .pe_en_left(pe_en_left),
	    .dram_wen_up(dram_wen_up),
	    .dram_wen_left(dram_wen_left),
	    .waddr_up(waddr_up),
	    .raddr_up(raddr_up),
	    .waddr_left(waddr_left),
	    .raddr_left(raddr_left),
	    .dout_up(din_up),
	    .dout_left(din_left),
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready)
	);

	// Add user logic here
    dram # (
        .RAM_WIDTH(RAM_WIDTH),
        .RAM_DEPTH(RAM_DEPTH),
        .RAM_ADDR_WIDTH(RAM_ADDR_WIDTH)
    ) dram_inst_up (
        .clk(s00_axi_aclk),
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
        .clk(s00_axi_aclk),
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
        .clk(s00_axi_aclk),
        .resetn(s00_axi_aresetn & sys_resetn),
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
        .clk(s00_axi_aclk),
        .resetn(s00_axi_aresetn & sys_resetn),
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
        .clk(s00_axi_aclk),
        .resetn(s00_axi_aresetn & sys_resetn),
        .en(sys_en),
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
	// User logic ends

	endmodule
