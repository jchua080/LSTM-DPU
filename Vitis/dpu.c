#include "dpu.h"

void multiply_dpu(uint32_t *dpu, struct matrix *A, struct matrix *B,  struct matrix *C) {
	uint32_t pos_x, pos_y;
	uint32_t total_x = B->N >> DIM_WIDTH, rem_x = B->N - (total_x << DIM_WIDTH);
	uint32_t total_y = A->M >> DIM_WIDTH, rem_y = A->M - (total_y << DIM_WIDTH);

	uint32_t row_A, col_A, reset_A;
	uint32_t row_B, col_B, reset_B;
	uint8_t pause_up, pause_left, complete;

	uint32_t ram_pos_up, ram_pos_left, replaced_pos_up = 0;
	uint8_t replaced_up, replaced_left;

	if (A->M != C->M || A->N != B->M || B->N != C->N) {
		printf("Incompatible dimensions.\n");
		return;
	}

	int i, j;
	struct matrix32 temp;
	temp.M = C->M;
	temp.N = C->N;
	temp.data = (uint32_t*)malloc(C->M * C->N * sizeof(uint32_t));

	if (rem_x)
		++total_x;
	else
		rem_x = ARRAY_DIM;

	if (rem_y)
		++total_y;
	else
		rem_y = ARRAY_DIM;

	for (pos_y = 0; pos_y < total_y; ++pos_y) {
		replaced_left = 1;

		for (pos_x = 0; pos_x < total_x; ++pos_x) {
			replaced_up = 0;
			ram_pos_up = get_ram_pos(pos_x, total_x, rem_x, A->N, &replaced_up);

			if (replaced_up)
				replaced_pos_up = ram_pos_up;

			if (ram_pos_up >= replaced_pos_up) {
				row_B = 0;
				col_B = reset_B = ARRAY_DIM * pos_x;
				write_ram(dpu, DRAM_UP_BASEOFF + ram_pos_up, B, &row_B, &col_B, &reset_B);
			}

			if (replaced_left) {
				row_A = 0;
				col_A = reset_A = ARRAY_DIM * pos_y;
				ram_pos_left = get_ram_pos(pos_y, total_y, rem_y, A->N, NULL);
				replaced_left = 0;

				write_ram(dpu, DRAM_LEFT_BASEOFF + ram_pos_left, A, &row_A, &col_A, &reset_A);
			}

			setup_reg(dpu, pos_y == total_y - 1 ? rem_y : ARRAY_DIM, A->N, pos_x == total_x - 1 ? rem_x : ARRAY_DIM, DRAM_UP_BASEOFF + ram_pos_up, DRAM_LEFT_BASEOFF + ram_pos_left);

			enable_dpu(dpu);
			start_stream(dpu);

			pause_up = pause_left = complete = 0;

			while (1) {
				wait_status(dpu, &pause_up, &pause_left, &complete);

				if (complete)
					break;

				if (pause_up)
					write_ram(dpu, DRAM_UP_BASEOFF, B, &row_B, &col_B, &reset_B);

				if (pause_left) {
					replaced_left = 1;
					write_ram(dpu, DRAM_LEFT_BASEOFF, A, &row_A, &col_A, &reset_A);
				}

				if (pause_up & pause_left)
					resume_stream(dpu, 2);
				else if (pause_up)
					resume_stream(dpu, 1);
				else if (pause_left)
					resume_stream(dpu, 0);
			}

			disable_dpu(dpu);

			read_acc(dpu, &temp, ARRAY_DIM * pos_y, ARRAY_DIM * pos_x, pos_y == total_y - 1 ? rem_y : ARRAY_DIM, pos_x == total_x - 1 ? rem_x : ARRAY_DIM);

			reset_dpu(dpu);
		}
	}

	sum_row(A);

	for (i = 0; i < C->M; ++i)
		for (j = 0; j < C->N; ++j)
			C->data8[C->N * i + j] = quantize(C->s, C->zp, A->s * B->s * ((int)temp.data[C->N * i + j] - (int)A->zp * (int)B->column_sum[j] - (int)B->zp * (int)A->row_sum[i] + (int)A->N * (int)A->zp * (int)B->zp));

	FREE(temp.data);
}

void reset_dpu(uint32_t *dpu) {
	dpu[SYS_CTRL_BASEOFF] = 0;
	dpu[SYS_CTRL_BASEOFF] = 1 << 8;
}

void enable_dpu(uint32_t *dpu) {
	dpu[SYS_CTRL_BASEOFF] = (1 << 8) + 1;
}

void disable_dpu(uint32_t *dpu) {
	dpu[SYS_CTRL_BASEOFF] = 1 << 8;
}

void setup_reg(uint32_t *dpu, uint32_t U, uint32_t V, uint32_t W, uint32_t up_addr, uint32_t left_addr) {
	int i;
	uint32_t temp;

	for (i = 0, temp = 0; i < W; ++i)
		temp += 1 << i;
	dpu[PE_UP_EN_BASEOFF] = temp;

	for (i = 0, temp = 0; i < U; ++i)
		temp += 1 << i;
	dpu[PE_LEFT_EN_BASEOFF] = temp;

	dpu[LENGTH_UP_BASEOFF] = V;
	dpu[LENGTH_LEFT_BASEOFF] = V;

	dpu[TOTAL_UP_BASEOFF] = W + V - 1;
	dpu[TOTAL_LEFT_BASEOFF] = U + V - 1;

	dpu[DRAM_RADDR_UP_BASEOFF] = up_addr - DRAM_UP_BASEOFF;
	dpu[DRAM_RADDR_LEFT_BASEOFF] = left_addr - DRAM_LEFT_BASEOFF;
}

void start_stream(uint32_t *dpu) {
	dpu[STREAM_CTRL_BASEOFF] = (1 << 8) + 1;
	while ((dpu[STATUS_REG_BASEOFF] & 0x3) != 0x3);
	dpu[STREAM_CTRL_BASEOFF] = 0;
}

void resume_stream(uint32_t *dpu, uint8_t up_left) {
	dpu[STREAM_CTRL_BASEOFF] = (up_left % 2 == 0 ? 1 << 24 : 0) + (up_left ? 1 << 16 : 0);

	if (up_left == 2) {
		while (1)
			if (!(dpu[STATUS_REG_BASEOFF] & 0xC))
				break;
	}
	else if (up_left == 1)
		while ((dpu[STATUS_REG_BASEOFF] & 0x4) == 0x4);
	else if (!up_left)
		while ((dpu[STATUS_REG_BASEOFF] & 0x8) == 0x8);

	dpu[STREAM_CTRL_BASEOFF] = 0;
}

void wait_status(uint32_t *dpu, uint8_t *pause_up, uint8_t *pause_left, uint8_t *complete) {
	uint32_t temp;
	*pause_up = 0;
	*pause_left = 0;
	*complete = 0;

	while (1) {
		temp = dpu[STATUS_REG_BASEOFF];

		if (temp & 0x10)
			*complete = 1;

		if (temp & 0x4)
			*pause_up = 1;

		if (temp & 0x8)
			*pause_left = 1;

		if (*pause_up | *pause_left | *complete)
			break;
	}
}

void write_ram(uint32_t *dpu, uint32_t start_addr, struct matrix *A, uint32_t *i, uint32_t *j, uint32_t *reset) {
	int k = 0, l = 0, m = 0;
	uint8_t first = 1, up_left = 2;
	uint32_t temp;

	if (start_addr >= DRAM_UP_BASEOFF && start_addr <= DRAM_UP_HIGHOFF)
		up_left = 1;
	else if (start_addr >= DRAM_LEFT_BASEOFF && start_addr <= DRAM_LEFT_HIGHOFF)
		up_left = 0;

	if (up_left != 2) {
		for (; *i < (up_left ? A->M : A->N); ++(*i)) {
			for (k = first ? *j : *reset, l = 0, temp = 0; k < MIN(up_left ? A->N : A->M, *j + ARRAY_DIM); ++k, ++l) {
				first = 0;

				if ((up_left ? start_addr + m : start_addr + m - DRAM_LEFT_BASEOFF) == RAM_DEPTH) {
					*j = k;
					return;
				}

				temp += A->data8[up_left ? A->N * *i + k : A->N * k + *i] << (8 * l);

				if (l == 3) {
					l = -1;
					dpu[start_addr + (m++)] = temp;
					temp = 0;
				}
			}

			if (l > 0)
				dpu[start_addr + (m++)] = temp;
		}
	}
}

void read_acc(uint32_t *dpu, struct matrix32 *A, uint32_t row, uint32_t col, uint32_t array_rows, uint32_t array_cols) {
	int i, j;

	for (i = 0; i < MIN(array_rows, ARRAY_DIM); ++i)
		for (j = 0; j < MIN(array_cols, ARRAY_DIM); ++j)
			A->data[A->N * (row + i) + col + j] = dpu[ACC_REG_BASEOFF + ARRAY_DIM * i + j];
}

void print_ram(uint32_t *dpu, uint32_t start_addr, uint32_t end_addr) {
	int i;

	if (start_addr >= DRAM_UP_BASEOFF && start_addr <= DRAM_LEFT_HIGHOFF && end_addr >= DRAM_UP_BASEOFF && end_addr <= DRAM_LEFT_HIGHOFF)
		for (i = start_addr; i <= end_addr; ++i)
			printf("%4x - %8x\n", DRAM_UP_BASEOFF + i, dpu[DRAM_UP_BASEOFF + i]);
}

void print_reg(uint32_t *dpu) {
	int i;

	for (i = 0; i <= CTRL_WIDTH; ++i)
		printf("%4x - %8x\n", SYS_CTRL_BASEOFF + i, dpu[SYS_CTRL_BASEOFF + i]);
}

void print_acc(uint32_t *dpu, uint32_t M, uint32_t N) {
	int i, j;

	for (i = 0; i < MIN(M, ARRAY_DIM); ++i) {
		for (j = 0; j < MIN(N, ARRAY_DIM); ++j)
			printf("%8x ", dpu[ACC_REG_BASEOFF + ARRAY_DIM * i + j]);

		printf("\n");
	}
}

uint32_t get_ram_pos(uint32_t pos, uint32_t total, uint32_t rem, uint32_t V, uint8_t *replaced) {
	int i;
	uint8_t full_compact = ceil((double)ARRAY_DIM / 4);
	uint8_t compact = pos == total - 1 ? ceil((double)rem / 4) : full_compact;

	if (pos > 0) {
		if (V * (pos * full_compact + compact) <= RAM_DEPTH)
			return V * pos * full_compact;
		else {
			if (replaced != NULL)
				*replaced = 1;

			for (i = pos; i > 0; --i)
				if (V * i * full_compact <= RAM_DEPTH)
					return V * (i - 1) * full_compact;
		}
	}

	return 0;
}
