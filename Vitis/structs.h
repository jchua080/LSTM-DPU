#ifndef STRUCTS_H
#define STRUCTS_H

#include <stdint.h>

struct matrix {
	uint32_t M;
	uint32_t N;
	uint8_t update_param;
	uint8_t alloc_column;
	uint8_t alloc_row;
	uint8_t alloc_lut;
	uint8_t *data8;
	uint32_t *column_sum;
	uint32_t *row_sum;
	uint8_t *relu_lut;
	uint8_t *sigmoid_lut;
	uint8_t *tanh_lut;
	float max;
	float min;
	float s;
	float zp;
	float *data_f;
};

struct matrix32 {
	uint32_t M;
	uint32_t N;
	uint32_t *data;
};

struct embedding {
	char *name;
	struct matrix embeddings;
};

struct lstm {
	char *name;
	char *activation;
	char *rec_activation;
	uint8_t use_bias;
	uint8_t reverse;
	uint32_t start_input;
	uint32_t end_input;
	uint32_t start_output;
	uint32_t end_output;
	struct matrix bias[4];
	struct matrix kernel[4];
	struct matrix rec_kernel[4];
};

struct dense {
	char *name;
	char *activation;
	uint8_t use_bias;
	uint32_t input_index;
	uint32_t start_output;
	uint32_t end_output;
	struct matrix bias;
	struct matrix kernel;
};

struct model {
	uint8_t has_embedding;
	uint8_t alloc_output;
	uint32_t input_dim;
	uint32_t num_name;
	uint32_t num_lstm;
	uint32_t num_dense;
	uint32_t num_output;
	char **names;
	struct embedding embedding;
	struct lstm *lstms;
	struct dense *denses;
	struct matrix *outputs;
};

#endif
