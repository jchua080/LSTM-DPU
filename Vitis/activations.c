#include "activations.h"

void linear(struct matrix *A, struct matrix *B, uint8_t run_float) {
	int i, j;

	for (i = 0; i < A->M; ++i)
		for (j = 0; j < A->N; ++j)
			if (run_float)
				B->data_f[A->N * i + j] = A->data_f[A->N * i + j];
			else
				B->data8[A->N * i + j] = A->data8[A->N * i + j];
}

float relu_f(float value) {
	return MAX(value, 0);
}

void relu(struct matrix *A, struct matrix *B, uint8_t run_float) {
	int i, j;

	for (i = 0; i < A->M; ++i)
		for (j = 0; j < A->N; ++j)
			if (run_float)
				B->data_f[A->N * i + j] = relu_f(A->data_f[A->N * i + j]);
			else
				B->data8[A->N * i + j] = A->relu_lut[A->data8[A->N * i + j]];
}

float sigmoid_f(float value) {
	return 1 / (1 + exp(-value));
}

void sigmoid(struct matrix *A, struct matrix *B, uint8_t run_float) {
	int i, j;

	for (i = 0; i < A->M; ++i)
		for (j = 0; j < A->N; ++j)
			if (run_float)
				B->data_f[A->N * i + j] = sigmoid_f(A->data_f[A->N * i + j]);
			else
				B->data8[A->N * i + j] = A->sigmoid_lut[A->data8[A->N * i + j]];
}

void _tanh(struct matrix *A, struct matrix *B, uint8_t run_float) {
	int i, j;

	for (i = 0; i < A->M; ++i)
		for (j = 0; j < A->N; ++j)
			if (run_float)
				B->data_f[A->N * i + j] = 2 * sigmoid_f(2 * A->data_f[A->N * i + j]) - 1;
			else
				B->data8[A->N * i + j] = A->tanh_lut[A->data8[A->N * i + j]];
}

void fill_luts(struct matrix *A) {
	int i;

	update_params(A);

	if (!A->alloc_lut) {
		A->alloc_lut = 1;
		A->relu_lut = (uint8_t*)malloc(256 * sizeof(uint8_t));
		A->sigmoid_lut = (uint8_t*)malloc(256 * sizeof(uint8_t));
		A->tanh_lut = (uint8_t*)malloc(256 * sizeof(uint8_t));
	}

	for (i = 0; i < 256; ++i) {
		A->relu_lut[i] = quantize(A->s, A->zp, relu_f(dequantize(A->s, A->zp, i)));
		A->sigmoid_lut[i] = quantize(A->s, A->zp, sigmoid_f(dequantize(A->s, A->zp, i)));
		A->tanh_lut[i] = quantize(A->s, A->zp, 2 * sigmoid_f(2 * dequantize(A->s, A->zp, i)) - 1);
	}
}

void activate(char *activation, struct matrix *A, struct matrix *B, uint8_t run_float) {
	if (!strcmp(activation, "relu"))
		relu(A, B, run_float);
	else if (!strcmp(activation, "sigmoid"))
		sigmoid(A, B, run_float);
	else if (!strcmp(activation, "tanh"))
		_tanh(A, B, run_float);
	else
		linear(A, B, run_float);
}
