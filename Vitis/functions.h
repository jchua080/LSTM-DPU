#ifndef FUNCTIONS_H
#define FUNCTIONS_H

#include <stdlib.h>
#include <string.h>
#include "dpu.h"
#include "macros.h"
#include "structs.h"

void multiply_ps(struct matrix *A, struct matrix *B,  struct matrix *C, uint8_t run_float);
void multiply_matrix(uint32_t *dpu, struct matrix *A, struct matrix *B, struct matrix *C, uint8_t run_float, uint8_t run_ps);

void print_matrix(struct matrix *A, uint8_t run_float);
void print_row_col(struct matrix *A, uint8_t run_float, uint32_t rows, uint32_t cols);
void print_matrix32(struct matrix32 *A);

void add_matrix(struct matrix *A, struct matrix *B, struct matrix *C, uint8_t run_float);
void ele_multiply(struct matrix *A, struct matrix *B, struct matrix *C, uint8_t run_float);

void resize_bias(struct matrix *bias, uint32_t batch_sz, uint8_t run_float);
void resize32(struct matrix32 *A, struct matrix32 *B);

void replace_char(char *string, char *old, char new);

void update_params(struct matrix *A);

void sum_column(struct matrix *A);
void sum_row(struct matrix *A);

float dequantize(float s, float zp, uint8_t value);
uint8_t clip(int value);
uint8_t quantize(float s, float zp, float value);
void quantize_matrix(struct matrix *A);

uint32_t count_lines(FILE *file_ptr);
void generate_random(uint32_t count, uint32_t max, uint32_t min, uint32_t *list);
uint8_t in_list(uint32_t value, uint32_t count, uint32_t *list);

#endif
