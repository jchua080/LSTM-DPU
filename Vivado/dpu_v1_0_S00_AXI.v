
`timescale 1 ns / 1 ps

	module dpu_v1_0_S00_AXI #
	(
		// Users to add parameters here
        parameter integer BIT_WIDTH = 8,
        parameter integer ACC_WIDTH = 32,
        parameter integer ARRAY_DIM = 32,
        parameter integer STREAM_WIDTH = 32,
        parameter integer RAM_WIDTH = 32,
        parameter integer RAM_DEPTH = 4096,
        parameter integer RAM_ADDR_WIDTH = 12,
		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= 16,
		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		parameter integer C_S_AXI_STRB_WIDTH = 4,
		parameter integer C_S_AXI_RESP_WIDTH = 2,
		parameter integer C_S_AXI_PROT_WIDTH = 3
	)
	(
		// Users to add ports here
        input wire started_up,
        input wire started_left,
        input wire pause_up,
        input wire pause_left,
        input wire complete,
        input wire [ARRAY_DIM*ARRAY_DIM*RAM_WIDTH-1 : 0] acc,
        input wire [RAM_WIDTH-1 : 0] din_up,
        input wire [RAM_WIDTH-1 : 0] din_left,
        output wire start_up,
        output wire start_left,
        output wire resume_up,
        output wire resume_left,
        output wire [STREAM_WIDTH-1 : 0] length_up,
        output wire [STREAM_WIDTH-1 : 0] length_left,
        output wire [STREAM_WIDTH-1 : 0] total_up,
        output wire [STREAM_WIDTH-1 : 0] total_left,
        output wire sys_en,
        output wire sys_resetn,
        output wire [ARRAY_DIM-1 : 0] pe_en_up,
        output wire [ARRAY_DIM-1 : 0] pe_en_left,
        output wire dram_wen_up,
        output wire dram_wen_left,
        output wire [RAM_ADDR_WIDTH-1 : 0] waddr_up,
        output wire [RAM_ADDR_WIDTH-1 : 0] raddr_up,
        output wire [RAM_ADDR_WIDTH-1 : 0] waddr_left,
        output wire [RAM_ADDR_WIDTH-1 : 0] raddr_left,
        output wire [RAM_WIDTH-1 : 0] dout_up,
        output wire [RAM_WIDTH-1 : 0] dout_left,
		// User ports ends
		// Do not modify the ports beyond this line

		// Global Clock Signal
		input wire  S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input wire  S_AXI_ARESETN,
		// Write address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Write channel Protection type. This signal indicates the
    		// privilege and security level of the transaction, and whether
    		// the transaction is a data access or an instruction access.
		input wire [C_S_AXI_PROT_WIDTH-1 : 0] S_AXI_AWPROT,
		// Write address valid. This signal indicates that the master signaling
    		// valid write address and control information.
		input wire  S_AXI_AWVALID,
		// Write address ready. This signal indicates that the slave is ready
    		// to accept an address and associated control signals.
		output wire  S_AXI_AWREADY,
		// Write data (issued by master, acceped by Slave) 
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte lanes hold
    		// valid data. There is one write strobe bit for each eight
    		// bits of the write data bus.    
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		// Write valid. This signal indicates that valid write
    		// data and strobes are available.
		input wire  S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
    		// can accept the write data.
		output wire  S_AXI_WREADY,
		// Write response. This signal indicates the status
    		// of the write transaction.
		output wire [C_S_AXI_RESP_WIDTH-1 : 0] S_AXI_BRESP,
		// Write response valid. This signal indicates that the channel
    		// is signaling a valid write response.
		output wire  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
    		// can accept a write response.
		input wire  S_AXI_BREADY,
		// Read address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Protection type. This signal indicates the privilege
    		// and security level of the transaction, and whether the
    		// transaction is a data access or an instruction access.
		input wire [C_S_AXI_PROT_WIDTH-1 : 0] S_AXI_ARPROT,
		// Read address valid. This signal indicates that the channel
    		// is signaling valid read address and control information.
		input wire  S_AXI_ARVALID,
		// Read address ready. This signal indicates that the slave is
    		// ready to accept an address and associated control signals.
		output wire  S_AXI_ARREADY,
		// Read data (issued by slave)
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of the
    		// read transfer.
		output wire [C_S_AXI_RESP_WIDTH-1 : 0] S_AXI_RRESP,
		// Read valid. This signal indicates that the channel is
    		// signaling the required read data.
		output wire  S_AXI_RVALID,
		// Read ready. This signal indicates that the master can
    		// accept the read data and response information.
		input wire  S_AXI_RREADY
	);

	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-3 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [C_S_AXI_RESP_WIDTH-1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-3 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [C_S_AXI_RESP_WIDTH-1 : 0] 	axi_rresp;
	reg  	axi_rvalid;

	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH >> 5) + 1;
	localparam integer OPT_MEM_ADDR_BITS = C_S_AXI_ADDR_WIDTH - ADDR_LSB - 1;
	
	localparam integer CTRL_WIDTH = 16;
	integer i, j, k;
	//----------------------------------------------
	//-- Signals for user logic register space example
	//------------------------------------------------
	wire	 slv_ren;
	wire	 slv_wen;
	reg [C_S_AXI_DATA_WIDTH-1 : 0]	 data_out;
	reg	 aw_en;
	
	reg [RAM_WIDTH-1 : 0] write_reg;
	reg [C_S_AXI_STRB_WIDTH-1 : 0] write_strb;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] ctrl_reg [0 : CTRL_WIDTH-1];
	reg [C_S_AXI_DATA_WIDTH-1 : 0] status_reg;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] acc_reg [0 : ARRAY_DIM*ARRAY_DIM-1];

	// I/O Connections assignments
	assign {sys_resetn, sys_en} = {ctrl_reg[0][8], ctrl_reg[0][0]};
	assign pe_en_up = ctrl_reg[1];
	assign pe_en_left = ctrl_reg[2];
	assign {resume_left, resume_up, start_left, start_up} = {ctrl_reg[3][24], ctrl_reg[3][16], ctrl_reg[3][8], ctrl_reg[3][0]};
    assign length_up = ctrl_reg[4][STREAM_WIDTH-1 : 0];
    assign length_left = ctrl_reg[5][STREAM_WIDTH-1 : 0];
    assign total_up = ctrl_reg[6][STREAM_WIDTH-1 : 0];
    assign total_left = ctrl_reg[7][STREAM_WIDTH-1 : 0];
    assign dram_wen_up = ctrl_reg[8][0];
    assign dram_wen_left = ctrl_reg[9][0];
    assign waddr_up = ctrl_reg[10][RAM_ADDR_WIDTH-1 : 0];
    assign raddr_up = ctrl_reg[11][RAM_ADDR_WIDTH-1 : 0];
    assign waddr_left = ctrl_reg[12][RAM_ADDR_WIDTH-1 : 0];
    assign raddr_left = ctrl_reg[13][RAM_ADDR_WIDTH-1 : 0];
    assign dout_up = ctrl_reg[14][RAM_WIDTH-1 : 0];
    assign dout_left = ctrl_reg[15][RAM_WIDTH-1 : 0];
    
	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RVALID	= axi_rvalid;
	
	assign slv_wen = axi_wready & S_AXI_WVALID & axi_awready & S_AXI_AWVALID;
	assign slv_ren = axi_arready & S_AXI_ARVALID & ~axi_rvalid;

	// Add user logic here
    always @*
        status_reg <= {complete, pause_left, pause_up, started_left, started_up};
    
    always @*
        if (~S_AXI_ARESETN | ~sys_resetn)
            for (i = 0; i < ARRAY_DIM; i = i + 1)
                for (j = 0; j < ARRAY_DIM; j = j + 1)
                    acc_reg[ARRAY_DIM*i+j] <= 0;
        else if (complete)
            for (i = 0; i < ARRAY_DIM; i = i + 1)
                for (j = 0; j < ARRAY_DIM; j = j + 1)
                    acc_reg[ARRAY_DIM*i+j] <= acc[ACC_WIDTH*(ARRAY_DIM*i+j) +: ACC_WIDTH];
    
    always @(posedge S_AXI_ACLK) begin
        if (~S_AXI_ARESETN) begin
            {axi_awaddr, axi_awready, axi_wready, axi_bresp, axi_bvalid, axi_araddr, axi_arready, axi_rresp, axi_rvalid} <= 0;
            aw_en <= 1;
            
            ctrl_reg[0] <= 1 << 8;
            
            for (k = 1; k < CTRL_WIDTH; k = k + 1)
                ctrl_reg[k] <= 0;
        end
        else begin
            // Implement axi_awready generation
            // axi_awready is asserted for one S_AXI_ACLK clock cycle when both
            // S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
            // de-asserted when reset is low.
            
            // Implement axi_awaddr latching
            // This process is used to latch the address when both 
            // S_AXI_AWVALID and S_AXI_WVALID are valid. 
            
            // Implement axi_wready generation
            // axi_wready is asserted for one S_AXI_ACLK clock cycle when both
            // S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
            // de-asserted when reset is low. 
            
            // Implement memory mapped bram and register select and write logic generation
            // The write data is accepted and written to memory mapped bram and registers when
            // axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
            // select byte enables of slave bram and registers while writing.
            // These registers are cleared when reset (active low) is applied.
            // Slave bram and register write enable is asserted when valid address and data are available
            // and the slave is ready to accept the write address and write data.
            
            // Implement write response logic generation
            // The write response and response valid signals are asserted by the slave 
            // when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
            // This marks the acceptance of address and indicates the status of 
            // write transaction.
            
            // slave is ready to accept write data when 
            // there is a valid write address and write data
            // on the write address and data bus. This design 
            // expects no outstanding transactions. 
            axi_wready <= ~axi_wready & S_AXI_WVALID & S_AXI_AWVALID & aw_en;
            
            if (~axi_awready & S_AXI_AWVALID & S_AXI_WVALID & aw_en) begin
                // Write Address latching 
                axi_awaddr <= S_AXI_AWADDR[ADDR_LSB+OPT_MEM_ADDR_BITS : ADDR_LSB];
                // slave is ready to accept write address when 
                // there is a valid write address and write data
                // on the write address and data bus. This design 
                // expects no outstanding transactions. 
                axi_awready <= 1;
                aw_en <= 0;
                write_reg <= {{8{S_AXI_WSTRB[3]}}, {8{S_AXI_WSTRB[2]}}, {8{S_AXI_WSTRB[1]}}, {8{S_AXI_WSTRB[0]}}} & S_AXI_WDATA;
                write_strb <= S_AXI_WSTRB;
                
                if (S_AXI_AWADDR[ADDR_LSB+OPT_MEM_ADDR_BITS : ADDR_LSB] < RAM_DEPTH) begin
                    ctrl_reg[8] <= 1;
                    ctrl_reg[10] <= S_AXI_AWADDR[ADDR_LSB+OPT_MEM_ADDR_BITS : ADDR_LSB];
                    ctrl_reg[14] <= {{8{S_AXI_WSTRB[3]}}, {8{S_AXI_WSTRB[2]}}, {8{S_AXI_WSTRB[1]}}, {8{S_AXI_WSTRB[0]}}} & S_AXI_WDATA;
                end
                else if (S_AXI_AWADDR[ADDR_LSB+OPT_MEM_ADDR_BITS : ADDR_LSB] >= RAM_DEPTH && S_AXI_AWADDR[ADDR_LSB+OPT_MEM_ADDR_BITS : ADDR_LSB] < (RAM_DEPTH << 1)) begin
                    ctrl_reg[9] <= 1;
                    ctrl_reg[12] <= S_AXI_AWADDR[ADDR_LSB+OPT_MEM_ADDR_BITS : ADDR_LSB] - RAM_DEPTH;
                    ctrl_reg[15] <= {{8{S_AXI_WSTRB[3]}}, {8{S_AXI_WSTRB[2]}}, {8{S_AXI_WSTRB[1]}}, {8{S_AXI_WSTRB[0]}}} & S_AXI_WDATA;
                end
            end
            else if (S_AXI_BREADY & axi_bvalid) begin
                {axi_awready, ctrl_reg[8], ctrl_reg[9]} <= 0;
                aw_en <= 1;
            end
            else
                axi_awready <= 0;
            
            if (slv_wen && axi_awaddr >= (RAM_DEPTH << 1) && axi_awaddr < (RAM_DEPTH << 1) + CTRL_WIDTH)
                // Respective byte enables are asserted as per write strobes 
                ctrl_reg[axi_awaddr-(RAM_DEPTH<<1)] <= write_reg | ({{8{~write_strb[3]}}, {8{~write_strb[2]}}, {8{~write_strb[1]}}, {8{~write_strb[0]}}} & ctrl_reg[axi_awaddr-(RAM_DEPTH<<1)]);
            
            if (axi_awready & S_AXI_AWVALID & ~axi_bvalid & axi_wready & S_AXI_WVALID) begin
                axi_bresp <= 0; // 'OKAY' response 
                // indicates a valid write response is available
                axi_bvalid <= 1;
            end
            else if (S_AXI_BREADY & axi_bvalid)
                // check if bready is asserted while bvalid is high) 
                // (there is a possibility that bready is always asserted high)  
                axi_bvalid <= 0;
            
            // Implement axi_arready generation
            // axi_arready is asserted for one S_AXI_ACLK clock cycle when
            // S_AXI_ARVALID is asserted. axi_awready is 
            // de-asserted when reset (active low) is asserted. 
            // The read address is also latched when S_AXI_ARVALID is 
            // asserted. axi_araddr is reset to zero on reset assertion.
            
            // Implement axi_arvalid generation
            // axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
            // S_AXI_ARVALID and axi_arready are asserted. The slave bram and registers 
            // data are available on the axi_rdata bus at this instance. The 
            // assertion of axi_rvalid marks the validity of read data on the 
            // bus and axi_rresp indicates the status of read transaction.axi_rvalid 
            // is deasserted on reset (active low). axi_rresp and axi_rdata are 
            // cleared to zero on reset (active low).
            
            // Implement memory mapped bram and register select and read logic generation
            // Slave bram and register read enable is asserted when valid address is available
            // and the slave is ready to accept the read address.
            
            // Output register or memory read data
            if (~axi_arready & S_AXI_ARVALID) begin
                // Read address latching
                axi_araddr  <= S_AXI_ARADDR[ADDR_LSB+OPT_MEM_ADDR_BITS : ADDR_LSB];
                // indicates that the slave has acceped the valid read address
                axi_arready <= 1;
                
                if (S_AXI_ARADDR[ADDR_LSB+OPT_MEM_ADDR_BITS : ADDR_LSB] < RAM_DEPTH)
                    ctrl_reg[11] <= S_AXI_ARADDR[ADDR_LSB+OPT_MEM_ADDR_BITS : ADDR_LSB];
                else if (S_AXI_ARADDR[ADDR_LSB+OPT_MEM_ADDR_BITS : ADDR_LSB] >= RAM_DEPTH && S_AXI_ARADDR[ADDR_LSB+OPT_MEM_ADDR_BITS : ADDR_LSB] < (RAM_DEPTH << 1))
                    ctrl_reg[13] <= S_AXI_ARADDR[ADDR_LSB+OPT_MEM_ADDR_BITS : ADDR_LSB] - RAM_DEPTH;
            end
            else
                axi_arready <= 0;
                
            // When there is a valid read address (S_AXI_ARVALID) with 
            // acceptance of read address by the slave (axi_arready), 
            // output the read dada
            if (slv_ren) begin
                axi_rresp <= 0; // 'OKAY' response
                // Valid read data is available at the read data bus
                axi_rvalid <= 1;
                
                if (axi_araddr < RAM_DEPTH)
                    axi_rdata <= din_up;
                else if (axi_araddr >= RAM_DEPTH && axi_araddr < (RAM_DEPTH << 1))
                    axi_rdata <= din_left;
                else if (axi_araddr >= (RAM_DEPTH << 1) && axi_araddr < (RAM_DEPTH << 1) + CTRL_WIDTH)
                    axi_rdata <= ctrl_reg[axi_araddr-(RAM_DEPTH<<1)];
                else if (axi_araddr == (RAM_DEPTH << 1) + CTRL_WIDTH)
                    axi_rdata <= status_reg;
                else if (axi_araddr > (RAM_DEPTH << 1) + CTRL_WIDTH && axi_araddr <= (RAM_DEPTH << 1) + CTRL_WIDTH + ARRAY_DIM * ARRAY_DIM)
                    axi_rdata <= acc_reg[axi_araddr-(RAM_DEPTH<<1)-CTRL_WIDTH-1];
                else
                    axi_rdata <= 32'hFFFFFFFF;
            end
            else if (axi_rvalid & S_AXI_RREADY)
                // Read data is accepted by the master
                axi_rvalid <= 0;
        end
    end
	// User logic ends

	endmodule
