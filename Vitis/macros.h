#ifndef MACROS_H
#define MACROS_H

#define DPU_BASEADDR 			0xA0000000
#define DPU_SIZE                0x10000

#define DRAM_UP_BASEOFF 		0
#define DRAM_UP_HIGHOFF 		4095
#define DRAM_LEFT_BASEOFF 		4096
#define DRAM_LEFT_HIGHOFF 		8191

#define SYS_CTRL_BASEOFF 		8192
#define PE_UP_EN_BASEOFF        8193
#define PE_LEFT_EN_BASEOFF      8194

#define STREAM_CTRL_BASEOFF 	8195
#define LENGTH_UP_BASEOFF       8196
#define LENGTH_LEFT_BASEOFF     8197
#define TOTAL_UP_BASEOFF 		8198
#define TOTAL_LEFT_BASEOFF 		8199

#define DRAM_WEN_UP_BASEOFF 	8200
#define DRAM_WEN_LEFT_BASEOFF 	8201
#define DRAM_WADDR_UP_BASEOFF 	8202
#define DRAM_RADDR_UP_BASEOFF 	8203
#define DRAM_WADDR_LEFT_BASEOFF 8204
#define DRAM_RADDR_LEFT_BASEOFF 8205
#define DRAM_DIN_UP_BASEOFF 	8206
#define DRAM_DIN_LEFT_BASEOFF 	8207

#define STATUS_REG_BASEOFF 		8208

#define ACC_REG_BASEOFF 		8209

#define ARRAY_DIM               32
#define DIM_WIDTH               5
#define RAM_DEPTH 				4096
#define CTRL_WIDTH              16

#define MIN(a, b)               ((a) < (b) ? (a) : (b))
#define MAX(a, b)				((a) > (b) ? (a) : (b))
#define FREE(p)                 {if (p) {free(p); p = NULL;}}

#endif
