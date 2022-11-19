#ifndef ACTIVATIONS_H
#define ACTIVATIONS_H

#include <math.h>
#include "functions.h"

void linear(struct matrix *A, struct matrix *B, uint8_t run_float);

float relu_f(float value);
void relu(struct matrix *A, struct matrix *B, uint8_t run_float);

float sigmoid_f(float value);
void sigmoid(struct matrix *A, struct matrix *B, uint8_t run_float);

void _tanh(struct matrix *A, struct matrix *B, uint8_t run_float);

void fill_luts(struct matrix *A);
void activate(char *activation, struct matrix *A, struct matrix *B, uint8_t run_float);

#endif
