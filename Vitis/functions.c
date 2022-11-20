#include "functions.h"

void multiply_ps(struct matrix *A, struct matrix *B,  struct matrix *C, uint8_t run_float) {
	int i, j, k, temp;

	if (A->M != C->M || A->N != B->M || B->N != C->N) {
		printf("multiply_ps: Incompatible dimensions.\n");
		return;
	}

	sum_row(A);

	for (i = 0; i < A->M; ++i)
		for (j = 0; j < B->N; ++j) {
			if (run_float)
				C->data_f[B->N * i + j] = 0;
			else
				temp = 0;

			for (k = 0; k < A->N; ++k)
				if (run_float)
					C->data_f[B->N * i + j] += A->data_f[A->N * i + k] * B->data_f[B->N * k + j];
				else
					temp += (int)A->data8[A->N * i + k] * (int)B->data8[B->N * k + j];

			if (!run_float)
				C->data8[B->N * i + j] = quantize(C->s, C->zp, A->s * B->s * (temp - (int)A->zp * (int)B->column_sum[j] - (int)B->zp * (int)A->row_sum[i] + (int)A->N * (int)A->zp * (int)B->zp));
		}
}

void multiply_matrix(uint32_t *dpu, struct matrix *A, struct matrix *B, struct matrix *C, uint8_t run_float, uint8_t run_ps) {
	if (run_float || run_ps)
		multiply_ps(A, B, C, run_float);
	else
		multiply_dpu(dpu, A, B, C);
}

void print_matrix(struct matrix *A, uint8_t run_float) {
	int i, j;

	for (i = 0; i < A->M; ++i) {
		for (j = 0; j < A->N; ++j)
			if (run_float)
				printf("%g ", A->data_f[A->N * i + j]);
			else
				printf("%2x ", A->data8[A->N * i + j]);


		printf("\n");
	}

	printf("\n");
}

void print_row_col(struct matrix *A, uint8_t run_float, uint32_t rows, uint32_t cols) {
	int i, j;

	for (i = 0; i < MIN(rows, A->M); ++i) {
		for (j = 0; j < MIN(cols, A->N); ++j)
			if (run_float)
				printf("%g ", A->data_f[A->N * i + j]);
			else
				printf("%2x ", A->data8[A->N * i + j]);


		printf("\n");
	}

	printf("\n");
}

void print_matrix32(struct matrix32 *A) {
	int i, j;

	for (i = 0; i < A->M; ++i) {
		for (j = 0; j < A->N; ++j)
			printf("%8x ", A->data[A->N * i + j]);

		printf("\n");
	}

	printf("\n");
}

void add_matrix(struct matrix *A, struct matrix *B, struct matrix *C, uint8_t run_float) {
	int i, j;

	if (A->M != B->M || A->N != B->N) {
		printf("add_matrix: Incompatible dimensions.\n");
		return;
	}

	for (i = 0; i < A->M; ++i)
		for (j = 0; j < A->N; ++j)
			if (run_float)
				C->data_f[A->N * i + j] = A->data_f[A->N * i + j] + B->data_f[A->N * i + j];
			else
				C->data8[A->N * i + j] = quantize(C->s, C->zp, dequantize(A->s, A->zp, A->data8[A->N * i + j]) + dequantize(B->s, B->zp, B->data8[A->N * i + j]));
}

void ele_multiply(struct matrix *A, struct matrix *B, struct matrix *C, uint8_t run_float) {
	int i, j;

	if (A->M != B->M || A->N != B->N) {
		printf("ele_multiply: Incompatible dimensions.\n");
		return;
	}

	for (i = 0; i < A->M; ++i)
		for (j = 0; j < A->N; ++j)
			if (run_float)
				C->data_f[A->N * i + j] = A->data_f[A->N * i + j] * B->data_f[A->N * i + j];
			else
				C->data8[A->N * i + j] = quantize(C->s, C->zp, dequantize(A->s, A->zp, A->data8[A->N * i + j]) * dequantize(B->s, B->zp, B->data8[A->N * i + j]));
}

void resize_bias(struct matrix *bias, uint32_t batch_sz, uint8_t run_float) {
	int i, j;

	if (bias->M != batch_sz) {
		bias->data_f = (float*)realloc(bias->data_f, batch_sz * bias->N * sizeof(float));
		bias->data8 = (uint8_t*)realloc(bias->data8, batch_sz * bias->N * sizeof(uint8_t));
	}

	for (i = 1; i < batch_sz; ++i)
		for (j = 0; j < bias->N; ++j)
			if (run_float)
				bias->data_f[bias->N * i + j] = bias->data_f[j];
			else
				bias->data8[bias->N * i + j] = bias->data8[j];

	bias->M = batch_sz;
}

void resize32(struct matrix32 *A, struct matrix32 *B) {
	int i, j;

	if ((A->M != B->M && A->N != B->N) || (A->M == B->M && A->N == B->N)) {
		printf("resize32: Incompatible dimensions.\n");
		return;
	}

	if (A->M == B->M)
		for (i = 0; i < A->M; ++i)
			for (j = 0; j < MIN(A->N, B->N); ++j)
				B->data[B->N * j + i] = A->data[A->N * j + i];
	else
		for (i = 0; i < MIN(A->M, B->M); ++i)
			for (j = 0; j < A->N; ++j)
				B->data[B->N * i + j] = A->data[A->N * i + j];

}

void replace_char(char *string, char *old, char new) {
	int i, j, length = strlen(string);

	for (i = 0; i < length; ++i)
		for (j = 0; j < strlen(old); ++j)
			if (string[i] == old[j]) {
				string[i] = new;
				break;
			}
}

void update_params(struct matrix *A) {
	int i, j;

	if (!A->update_param) {
		A->update_param = 1;
		A->max = A->min = A->data_f[0];
	}

	for (i = 0; i < A->M; ++i)
		for (j = 0; j < A->N; ++j) {
			if (A->data_f[A->N * i + j] > A->max)
				A->max = A->data_f[A->N * i + j];

			if (A->data_f[A->N * i + j] < A->min)
				A->min = A->data_f[A->N * i + j];
		}

	A->s = A->max == A->min ? 1 : (A->max - A->min) / 255;
	A->zp = A->min == 0 ? 0 : round(-A->min / A->s);
}

void sum_column(struct matrix *A) {
	int i, j;

	if (!A->alloc_column) {
		A->alloc_column = 1;
		A->column_sum = (uint32_t*)malloc(A->N * sizeof(uint32_t));
	}

	for (i = 0; i < A->N; ++i) {
		A->column_sum[i] = 0;

		for (j = 0; j < A->M; ++j)
			A->column_sum[i] += A->data8[A->N * j + i];
	}
}

void sum_row(struct matrix *A) {
	int i, j;

	if (!A->alloc_row) {
		A->alloc_row = 1;
		A->row_sum = (uint32_t*)malloc(A->M * sizeof(uint32_t));
	}

	for (i = 0; i < A->M; ++i) {
		A->row_sum[i] = 0;

		for (j = 0; j < A->N; ++j)
			A->row_sum[i] += A->data8[A->N * i + j];
	}
}

float dequantize(float s, float zp, uint8_t value) {
	return s * ((float)value - zp);
}

uint8_t clip(int value) {
	if (value < 0)
		return 0;

	if (value > 255)
		return 255;

	return value;
}

uint8_t quantize(float s, float zp, float value) {
	return clip(round(value / s + zp));
}

void quantize_matrix(struct matrix *A) {
	int i, j;

	for (i = 0; i < A->M; ++i)
		for (j = 0; j < A->N; ++j)
			A->data8[A->N * i + j] = quantize(A->s, A->zp, A->data_f[A->N * i + j]);
}

uint32_t count_lines(FILE *file_ptr) {
	int c = '\0', pc = '\n';
	uint32_t lines = 0;

	while ((c = fgetc(file_ptr)) != EOF)
	{
		if (c == '\n' && pc != '\n')
			++lines;

		pc = c;
	}

	if (pc != '\n')
		++lines;

	return lines;
}

void generate_random(uint32_t count, uint32_t max, uint32_t min, uint32_t *list) {
	int i, j;
	uint8_t reroll;

	for (i = 0; i < count; ++i)
		while (1) {
			reroll = 0;
			list[i] = min + rand() % (max - min + 1);

			for (j = 0; j < i; ++j)
				if (list[j] == list[i])
					reroll = 1;

			if (!reroll)
				break;
		}
}

uint8_t in_list(uint32_t value, uint32_t count, uint32_t *list) {
	int i;

	for (i = 0; i < count; ++i)
		if (value == list[i])
			return 1;

	return 0;
}
