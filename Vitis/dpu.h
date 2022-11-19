#ifndef DPU_H
#define DPU_H

#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include "functions.h"
#include "structs.h"

void multiply_dpu(uint32_t *dpu, struct matrix *A, struct matrix *B,  struct matrix *C);

void reset_dpu(uint32_t *dpu);
void enable_dpu(uint32_t *dpu);
void disable_dpu(uint32_t *dpu);

void setup_reg(uint32_t *dpu, uint32_t U, uint32_t V, uint32_t W, uint32_t up_addr, uint32_t left_addr);

void start_stream(uint32_t *dpu);
void resume_stream(uint32_t *dpu, uint8_t up_left);

void wait_status(uint32_t *dpu, uint8_t *pause_up, uint8_t *pause_left, uint8_t *complete);

void write_ram(uint32_t *dpu, uint32_t start_addr, struct matrix *A, uint32_t *i, uint32_t *j, uint32_t *reset);
void read_acc(uint32_t *dpu, struct matrix32 *A, uint32_t row, uint32_t col, uint32_t array_rows, uint32_t array_cols);

void print_ram(uint32_t *dpu, uint32_t start_addr, uint32_t end_addr);
void print_reg(uint32_t *dpu);
void print_acc(uint32_t *dpu, uint32_t M, uint32_t N);

uint32_t get_ram_pos(uint32_t pos, uint32_t total, uint32_t rem, uint32_t V, uint8_t *replaced);

#endif
