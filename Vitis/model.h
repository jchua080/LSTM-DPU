#ifndef MODEL_H
#define MODEL_H

#include <time.h>
#include "activations.h"
#include "functions.h"

void load_model(FILE *output_ptr, char *path, struct model *model, uint8_t *not_float);
void update_model_params(struct model *model);
void quantize_model(struct model *model);

void evaluate(FILE *output_ptr, uint32_t *dpu, struct model *model, char *data_path, char *label_path, uint32_t batch_sz, uint8_t quantize, uint32_t representative, uint8_t run_ps);
void label_predicted(struct model *model, uint32_t *label, uint32_t *predicted, uint32_t *correct, uint8_t run_float);
void execute_model(uint32_t *dpu, struct model *model, struct matrix32 *input, uint8_t create_outputs, uint8_t first_run, uint8_t run_float, uint8_t run_ps, uint8_t update_params);

void run_embedding(struct model *model, struct matrix32 *input, uint32_t input_index, uint8_t create_outputs, uint8_t first_run, uint8_t run_float);
void run_lstm(uint32_t *dpu, struct model *model, uint32_t lstm_index, uint8_t create_outputs, uint8_t first_run, uint8_t run_float, uint8_t run_ps, uint8_t update_params);
void run_dense(uint32_t *dpu, struct model *model, uint32_t dense_index, uint8_t create_outputs, uint8_t first_run, uint8_t run_float, uint8_t run_ps, uint8_t update_params);

void init_model(struct model *model);
void free_output_data(struct model *model);
void free_model(struct model *model);

#endif
