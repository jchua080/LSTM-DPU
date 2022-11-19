#include "model.h"

void load_model(FILE *output_ptr, char *path, struct model *model, uint8_t *not) {
	FILE *model_ptr;

	char *line = NULL, *token;
	size_t length;
	__ssize_t read;

	int i, j;
	uint32_t prev_output_dim, N;

	uint8_t is_input = 0, is_input_dim = 0, is_input_type = 0;
	uint8_t is_embedding = 0, is_embed_name = 0, is_embed_input_dim = 0, is_embed_output_dim = 0, is_embeddings = 0;
	uint8_t is_lstm = 0, is_lstm_name = 0, is_lstm_dir = 0, is_lstm_output_dim = 0, is_lstm_activation = 0, is_lstm_rec_activation = 0, is_lstm_use_bias = 0, is_lstm_bias = 0, is_lstm_kernel = 0, is_lstm_rec_kernel = 0;
	uint8_t is_dense = 0, is_dense_name = 0, is_dense_output_dim = 0, is_dense_activation = 0, is_dense_use_bias = 0, is_dense_bias = 0, is_dense_kernel = 0;

	printf("\nLoading %s\n", path);
	printf("---------------------------------------------------------------------\n");
	fprintf(output_ptr, "\nLoading %s\n", path);
	fprintf(output_ptr, "---------------------------------------------------------------------\n");

	if ((model_ptr = fopen(path, "r")) != NULL) {
		while ((read = getline(&line, &length, model_ptr)) != -1) {

 			if (is_input_dim)
				is_input_dim = 0;
			else if (is_input_type) {
				is_input = 0;
				is_input_type = 0;
			}

 			if (is_embed_name)
 				is_embed_name = 0;
 			else if (is_embed_input_dim)
 				is_embed_input_dim = 0;
 			else if (is_embed_output_dim)
 				is_embed_output_dim = 0;
 			else if (is_embeddings) {
 				is_embedding = 0;
 				is_embeddings = 0;
 				printf("%s (Embedding) --- Output: (None, %d, %d)\n", model->embedding.name, model->input_dim, model->embedding.embeddings.N);
 				fprintf(output_ptr, "%s (Embedding) --- Output: (None, %d, %d)\n", model->embedding.name, model->input_dim, model->embedding.embeddings.N);
 			}

 			if (is_lstm_name)
 				is_lstm_name = 0;
 			else if (is_lstm_dir)
 				is_lstm_dir = 0;
 			else if (is_lstm_output_dim)
 				is_lstm_output_dim = 0;
 			else if (is_lstm_activation)
 				is_lstm_activation = 0;
 			else if (is_lstm_rec_activation)
 				is_lstm_rec_activation = 0;
 			else if (is_lstm_use_bias)
 				is_lstm_use_bias = 0;
 			else if (is_lstm_bias)
 				is_lstm_bias = 0;
 			else if (is_lstm_kernel)
 				is_lstm_kernel = 0;
 			else if (is_lstm_rec_kernel) {
 				is_lstm = 0;
 				is_lstm_rec_kernel = 0;
 				printf("%s (LSTM) --- Output: (None, %d)\n", model->lstms[model->num_lstm - 1].name, model->lstms[model->num_lstm - 1].kernel[0].N);
 				fprintf(output_ptr, "%s (LSTM) --- Output: (None, %d)\n", model->lstms[model->num_lstm - 1].name, model->lstms[model->num_lstm - 1].kernel[0].N);
 			}

 			if (is_dense_name)
 				is_dense_name = 0;
 			else if (is_dense_output_dim)
 				is_dense_output_dim = 0;
 			else if (is_dense_activation)
 				is_dense_activation = 0;
 			else if (is_dense_use_bias)
 				is_dense_use_bias = 0;
 			else if (is_dense_bias)
 				is_dense_bias = 0;
 			else if (is_dense_kernel) {
 				is_dense = 0;
 				is_dense_kernel = 0;
 				printf("%s (Dense) --- Output: (None, %d)\n", model->denses[model->num_dense - 1].name, model->denses[model->num_dense - 1].kernel.N);
 				fprintf(output_ptr, "%s (Dense) --- Output: (None, %d)\n", model->denses[model->num_dense - 1].name, model->denses[model->num_dense - 1].kernel.N);
 			}

			while ((token = strsep(&line, " ")) != NULL) {
				if (is_input_dim == 1)
					is_input_dim = 2;
				else if (is_input_dim == 2)
					model->input_dim = prev_output_dim = atoi(token);
				else if (is_input_type)
					if (strstr(token, "float") == NULL) {
						printf("Model is not of type float.\n");
						fprintf(output_ptr, "Model is not of type float.\n");
						*not = 1;
						return;
					}

				if (is_embed_name) {
					replace_char(token, "\r\n", '\0');
					model->embedding.name = token;
					model->names[model->num_name - 1] = token;
				}
				else if (is_embed_input_dim)
					model->embedding.embeddings.M = atoi(token);
				else if (is_embed_output_dim) {
					model->embedding.embeddings.N = prev_output_dim = atoi(token);
					model->embedding.embeddings.data_f = (float*)malloc(model->embedding.embeddings.M * prev_output_dim * sizeof(float));
					model->embedding.embeddings.data8 = (uint8_t*)malloc(model->embedding.embeddings.M * prev_output_dim * sizeof(uint8_t));
				}
				else if (is_embeddings) {
					if (!j)
						replace_char(token, "[", ' ');

					model->embedding.embeddings.data_f[model->embedding.embeddings.N * i + (j++)] = atof(token);

					if (j == model->embedding.embeddings.N) {
						++i;
						j = 0;
					}
				}

				if (is_lstm_name) {
					replace_char(token, "\r\n", '\0');
					model->lstms[model->num_lstm - 1].name = token;
					model->names[model->num_name - 1] = token;
				}
				else if (is_lstm_dir)
					model->lstms[model->num_lstm - 1].reverse = strstr(token, "true") != NULL;
				else if (is_lstm_output_dim) {
					for (i = 0; i < 4; ++i) {
						model->lstms[model->num_lstm - 1].kernel[i].M = prev_output_dim;
						model->lstms[model->num_lstm - 1].kernel[i].N = atoi(token);
						model->lstms[model->num_lstm - 1].kernel[i].data_f = (float*)malloc(prev_output_dim * atoi(token) * sizeof(float));
						model->lstms[model->num_lstm - 1].kernel[i].data8 = (uint8_t*)malloc(prev_output_dim * atoi(token) * sizeof(uint8_t));
						model->lstms[model->num_lstm - 1].kernel[i].alloc_column = model->lstms[model->num_lstm - 1].kernel[i].update_param = 0;
					}

					prev_output_dim = atoi(token);

					for (i = 0; i < 4; ++i) {
						model->lstms[model->num_lstm - 1].rec_kernel[i].M = prev_output_dim;
						model->lstms[model->num_lstm - 1].rec_kernel[i].N = prev_output_dim;
						model->lstms[model->num_lstm - 1].rec_kernel[i].data_f = (float*)malloc(prev_output_dim * prev_output_dim * sizeof(float));
						model->lstms[model->num_lstm - 1].rec_kernel[i].data8 = (uint8_t*)malloc(prev_output_dim * prev_output_dim * sizeof(uint8_t));
						model->lstms[model->num_lstm - 1].rec_kernel[i].alloc_column = model->lstms[model->num_lstm - 1].rec_kernel[i].update_param = 0;
					}
				}
				else if (is_lstm_activation) {
					replace_char(token, "\r\n", '\0');
					model->lstms[model->num_lstm - 1].activation = token;
				}
				else if (is_lstm_rec_activation) {
					replace_char(token, "\r\n", '\0');
					model->lstms[model->num_lstm - 1].rec_activation = token;
				}
				else if (is_lstm_use_bias) {
					model->lstms[model->num_lstm - 1].use_bias = strstr(token, "true") != NULL;

					if (model->lstms[model->num_lstm - 1].use_bias)
						for (i = 0; i < 4; ++i) {
							model->lstms[model->num_lstm - 1].bias[i].M = 1;
							model->lstms[model->num_lstm - 1].bias[i].N = prev_output_dim;
							model->lstms[model->num_lstm - 1].bias[i].data_f = (float*)malloc(1 * prev_output_dim * sizeof(float));
							model->lstms[model->num_lstm - 1].bias[i].data8 = (uint8_t*)malloc(1 * prev_output_dim * sizeof(uint8_t));
							model->lstms[model->num_lstm - 1].bias[i].update_param = 0;
						}
				}
				else if (is_lstm_bias) {
					if (!i)
						replace_char(token, "[", ' ');

					N = model->lstms[model->num_lstm - 1].bias[0].N;
					model->lstms[model->num_lstm - 1].bias[i / N].data_f[i % N] = atof(token);
					++i;
				}
				else if (is_lstm_kernel) {
					if (!j)
						replace_char(token, "[", ' ');

					N = model->lstms[model->num_lstm - 1].kernel[0].N;
					model->lstms[model->num_lstm - 1].kernel[j / N].data_f[N * i + j % N] = atof(token);
					++j;

					if (j == N << 2) {
						++i;
						j = 0;
					}
				}
				else if (is_lstm_rec_kernel) {
					if (!j)
						replace_char(token, "[", ' ');

					N = model->lstms[model->num_lstm - 1].rec_kernel[0].N;
					model->lstms[model->num_lstm - 1].rec_kernel[j / N].data_f[N * i + j % N] = atof(token);
					++j;

					if (j == N << 2) {
						++i;
						j = 0;
					}
				}

				if (is_dense_name) {
					replace_char(token, "\r\n", '\0');
					model->denses[model->num_dense - 1].name = token;
					model->names[model->num_name - 1] = token;
				}
				else if (is_dense_output_dim) {
					model->denses[model->num_dense - 1].kernel.M = prev_output_dim;
					model->denses[model->num_dense - 1].kernel.N = atoi(token);
					model->denses[model->num_dense - 1].kernel.data_f = (float*)malloc(prev_output_dim * atoi(token) * sizeof(float));
					model->denses[model->num_dense - 1].kernel.data8 = (uint8_t*)malloc(prev_output_dim * atoi(token) * sizeof(uint8_t));
					model->denses[model->num_dense - 1].kernel.alloc_column = model->denses[model->num_dense - 1].kernel.update_param = 0;
					prev_output_dim = atoi(token);
				}
				else if (is_dense_activation) {
					replace_char(token, "\r\n", '\0');
					model->denses[model->num_dense - 1].activation = token;
				}
				else if (is_dense_use_bias) {
					model->denses[model->num_dense - 1].use_bias = strstr(token, "true") != NULL;

					if (model->denses[model->num_dense - 1].use_bias) {
						model->denses[model->num_dense - 1].bias.M = 1;
						model->denses[model->num_dense - 1].bias.N = prev_output_dim;
						model->denses[model->num_dense - 1].bias.data_f = (float*)malloc(1 * prev_output_dim * sizeof(float));
						model->denses[model->num_dense - 1].bias.data8 = (uint8_t*)malloc(1 * prev_output_dim * sizeof(uint8_t));
						model->denses[model->num_dense - 1].bias.update_param = 0;
					}
				}
				else if (is_dense_bias) {
					if (!i)
						replace_char(token, "[", ' ');

					model->denses[model->num_dense - 1].bias.data_f[i++] = atof(token);
				}
				else if (is_dense_kernel) {
					if (!j)
						replace_char(token, "[", ' ');

					N = model->denses[model->num_dense - 1].kernel.N;
					model->denses[model->num_dense - 1].kernel.data_f[N * i + (j++)] = atof(token);

					if (j == N) {
						++i;
						j = 0;
					}
				}

				if (!strcmp(token, "InputLayer"))
					is_input = 1;
				else if (is_input) {
					if (!strcmp(token, "batch_input_shape:"))
						is_input_dim = 1;
					else if (!strcmp(token, "dtype:"))
						is_input_type = 1;
				}

				if (!strcmp(token, "Embedding")) {
					model->has_embedding = 1;
					is_embedding = 1;
					is_embed_name = 1;

					if (!model->num_name)
						model->names = (char**)malloc(++(model->num_name) * sizeof(char*));
					else
						model->names = (char**)realloc(model->names, ++(model->num_name) * sizeof(char*));
				}
				else if (is_embedding) {
					if (!strcmp(token, "input_dim:"))
						is_embed_input_dim = 1;
					else if (!strcmp(token, "output_dim:"))
						is_embed_output_dim = 1;
					else if (!strcmp(token, "embeddings:")) {
						is_embeddings = 1;
						i = j = 0;
					}
				}

				if (!strcmp(token, "LSTM")) {
					is_lstm = 1;
					is_lstm_name = 1;

					if (!model->num_name)
						model->names = (char**)malloc(++(model->num_name) * sizeof(char*));
					else
						model->names = (char**)realloc(model->names, ++(model->num_name) * sizeof(char*));

					if (!model->num_lstm)
						model->lstms = (struct lstm*)malloc(++(model->num_lstm) * sizeof(struct lstm));
					else
						model->lstms = (struct lstm*)realloc(model->lstms, ++(model->num_lstm) * sizeof(struct lstm));
				}
				else if (is_lstm) {
					if (!strcmp(token, "go_backwards:"))
						is_lstm_dir = 1;
					else if (!strcmp(token, "units:"))
						is_lstm_output_dim = 1;
					else if (!strcmp(token, "activation:"))
						is_lstm_activation = 1;
					else if (!strcmp(token, "recurrent_activation:"))
						is_lstm_rec_activation = 1;
					else if (!strcmp(token, "use_bias:"))
						is_lstm_use_bias = 1;
					else if (!strcmp(token, "bias:")) {
						is_lstm_bias = 1;
						i = 0;
					}
					else if (!strcmp(token, "kernel:")) {
						is_lstm_kernel = 1;
						i = j = 0;
					}
					else if (!strcmp(token, "recurrent_kernel:")) {
						is_lstm_rec_kernel = 1;
						i = j = 0;
					}
				}

				if (!strcmp(token, "Dense")) {
					is_dense = 1;
					is_dense_name = 1;

					if (!model->num_name)
						model->names = (char**)malloc(++(model->num_name) * sizeof(char*));
					else
						model->names = (char**)realloc(model->names, ++(model->num_name) * sizeof(char*));

					if (!model->num_dense)
						model->denses = (struct dense*)malloc(++(model->num_dense) * sizeof(struct dense));
					else
						model->denses = (struct dense*)realloc(model->denses, ++(model->num_dense) * sizeof(struct dense));
				}
				else if (is_dense) {
					if (!strcmp(token, "units:"))
						is_dense_output_dim = 1;
					else if (!strcmp(token, "activation:"))
						is_dense_activation = 1;
					else if (!strcmp(token, "use_bias:"))
						is_dense_use_bias = 1;
					else if (!strcmp(token, "bias:")) {
						is_dense_bias = 1;
						i = 0;
					}
					else if (!strcmp(token, "kernel:")) {
						is_dense_kernel = 1;
						i = j = 0;
					}
				}
			}
		}

		printf("%s (Dense) --- Output: (None, %d)\n", model->denses[model->num_dense - 1].name, model->denses[model->num_dense - 1].kernel.N);
		printf("---------------------------------------------------------------------\n\n");
		fprintf(output_ptr, "%s (Dense) --- Output: (None, %d)\n", model->denses[model->num_dense - 1].name, model->denses[model->num_dense - 1].kernel.N);
		fprintf(output_ptr, "---------------------------------------------------------------------\n\n");

		FREE(line);
		fclose(model_ptr);
	}
}

void update_model_params(struct model *model) {
	int i, j;

	if (model->has_embedding)
		update_params(&model->embedding.embeddings);

	for (i = 0; i < model->num_lstm; ++i)
		for (j = 0; j < 4; ++j) {
			update_params(&model->lstms[i].kernel[j]);
			update_params(&model->lstms[i].rec_kernel[j]);

			if (model->lstms[i].use_bias)
				update_params(&model->lstms[i].bias[j]);
		}

	for (i = 0; i < model->num_dense; ++i) {
		update_params(&model->denses[i].kernel);

		if (model->denses[i].use_bias)
			update_params(&model->denses[i].bias);
	}

	for (i = 0; i < model->num_output; ++i)
		update_params(&model->outputs[i]);
}

void quantize_model(struct model *model) {
	int i, j;

	if (model->has_embedding)
		quantize_matrix(&model->embedding.embeddings);

	for (i = 0; i < model->num_lstm; ++i) {
		for (j = 0; j < 4; ++j) {
			quantize_matrix(&model->lstms[i].kernel[j]);
			quantize_matrix(&model->lstms[i].rec_kernel[j]);

			sum_column(&model->lstms[i].kernel[j]);
			sum_column(&model->lstms[i].rec_kernel[j]);

			if (model->lstms[i].use_bias)
				quantize_matrix(&model->lstms[i].bias[j]);
		}
	}

	for (i = 0; i < model->num_dense; ++i) {
		quantize_matrix(&model->denses[i].kernel);
		sum_column(&model->denses[i].kernel);

		if (model->denses[i].use_bias)
			quantize_matrix(&model->denses[i].bias);
	}
}

void evaluate(FILE *output_ptr, uint32_t *dpu, struct model *model, char *data_path, char *label_path, uint32_t batch_sz, uint8_t quantize, uint32_t representative, uint8_t run_ps) {
	FILE *data_ptr, *label_ptr;

	char *data_line = NULL, *label_line = NULL, *token;
	size_t data_length, label_length;
	__ssize_t data_read, label_read;

	double batch_time, time;
	struct timespec batch_start, start, end;

	int i, j, k;
	uint8_t first_run, create_outputs = 1;
	uint32_t *label, *predicted, correct = 0, total;

	struct matrix32 data, temp;

	for (i = 0; i < (quantize ? 2 : 1); ++i) {
		first_run = 1;

		if ((data_ptr = fopen(data_path, "r")) != NULL && (label_ptr = fopen(label_path, "r")) != NULL) {
			if (!i) {
				printf("Loading %s and %s\n\n", data_path, label_path);
				fprintf(output_ptr, "Loading %s and %s\n\n", data_path, label_path);
			}

			if (i != quantize) {
				printf("Performing representative calibration\n");
				fprintf(output_ptr, "Performing representative calibration\n");
			}
			else {
				printf("Performing evaluation\n");
				fprintf(output_ptr, "Performing evaluation\n");
			}

			clock_gettime(CLOCK_REALTIME, &batch_start);
			clock_gettime(CLOCK_REALTIME, &start);

			j = total = 0;

			data.M = batch_sz;
			data.N = model->input_dim;
			data.data = (uint32_t*)malloc(data.M * data.N * sizeof(uint32_t));

			if (i == quantize) {
				label = (uint32_t*)malloc(batch_sz * sizeof(uint32_t));
				predicted = (uint32_t*)malloc(batch_sz * sizeof(uint32_t));
			}

			while ((data_read = getline(&data_line, &data_length, data_ptr)) != -1 && (label_read = getline(&label_line, &label_length, label_ptr)) != -1) {
				++total;

				if (i == quantize)
					label[j] = atoi(label_line);

				k = 0;

				while ((token = strsep(&data_line, " ")) != NULL) {
					if (!k)
						replace_char(token, "[", ' ');

					data.data[data.N * j + k++] = atoi(token);
				}

				if (++j == batch_sz) {
					execute_model(dpu, model, &data, create_outputs, first_run, !i, run_ps, i != quantize);

					clock_gettime(CLOCK_REALTIME, &end);
					batch_time = ((double)end.tv_sec + 1e-9 * end.tv_nsec) - ((double)batch_start.tv_sec + 1e-9 * batch_start.tv_nsec);
					time = ((double)end.tv_sec + 1e-9 * end.tv_nsec) - ((double)start.tv_sec + 1e-9 * start.tv_nsec);
					clock_gettime(CLOCK_REALTIME, &batch_start);

					if (i == quantize) {
						label_predicted(model, label, predicted, &correct, !i);
						printf("Batch time: %g s (%d done) --- Performance: %g inferences/s --- Accuracy: %g%%\n", batch_time, total, (double)total / time, 100.0 * correct / total);
						fprintf(output_ptr, "Batch time: %g s (%d done) --- Performance: %g inferences/s --- Accuracy: %g%%\n", batch_time, total, (double)total / time, 100.0 * correct / total);
					}
					else {
						printf("Representative done: %d/%d --- Time left: %g s\n", total, representative, total == representative ? 0.0 : batch_time * (representative - total) / batch_sz);
						fprintf(output_ptr, "Representative done: %d/%d --- Time left: %g s\n", total, representative, total == representative ? 0.0 : batch_time * (representative - total) / batch_sz);
					}

					j = create_outputs = first_run = 0;
				}

				if (i != quantize && total == representative)
					break;
			}

			if (j) {
				temp.M = j;
				temp.N = model->input_dim;
				temp.data = (uint32_t*)malloc(temp.M * temp.N * sizeof(uint32_t));

				free_output_data(model);

				first_run = 1;

				resize32(&data, &temp);
				execute_model(dpu, model, &temp, create_outputs, first_run, !i, run_ps, i != quantize);

				clock_gettime(CLOCK_REALTIME, &end);
				batch_time = ((double)end.tv_sec + 1e-9 * end.tv_nsec) - ((double)batch_start.tv_sec + 1e-9 * batch_start.tv_nsec);
				time = ((double)end.tv_sec + 1e-9 * end.tv_nsec) - ((double)start.tv_sec + 1e-9 * start.tv_nsec);

				if (i == quantize) {
					label_predicted(model, label, predicted, &correct, !i);
					printf("Batch time: %g s (%d done) --- Performance: %g inferences/s --- Accuracy: %g%%\n", batch_time, total, (double)total / time, 100.0 * correct / total);
					fprintf(output_ptr, "Batch time: %g s (%d done) --- Performance: %g inferences/s --- Accuracy: %g%%\n", batch_time, total, (double)total / time, 100.0 * correct / total);
				}
				else {
					printf("Representative done: %d/%d --- Time left: %d s\n", total, representative, 0);
					fprintf(output_ptr, "Representative done: %d/%d --- Time left: %d s\n", total, representative, 0);
				}

				free_output_data(model);
				create_outputs = 0;

				FREE(temp.data);
			}

			printf("\n");
			fprintf(output_ptr, "\n");

			if (i == quantize) {
				printf("Total time: %g s --- Performance: %g inferences/s --- Accuracy: %g%%\n\n", time, (double)total / time, 100.0 * correct / total);
				fprintf(output_ptr, "Total time: %g s --- Performance: %g inferences/s --- Accuracy: %g%%\n\n", time, (double)total / time, 100.0 * correct / total);
			}
			else
				quantize_model(model);

			if (i == quantize) {
				FREE(label);
				FREE(predicted);
			}

			FREE(data.data);
			FREE(data_line);
			FREE(label_line);

			fclose(data_ptr);
			fclose(label_ptr);
		}
	}
}

void label_predicted(struct model *model, uint32_t *label, uint32_t *predicted, uint32_t *correct, uint8_t run_float) {
	int i, j;

	float max_f, data_f;
	uint8_t max8, data8;
	struct matrix *output;

	for (i = 0; i < model->num_dense; ++i)
		if (!strcmp(model->names[model->num_name - 1], model->denses[i].name)) {
			output = &model->outputs[model->denses[i].start_output + 1];
			break;
		}

	for (i = 0; i < output->M; ++i) {
		for (j = 0; j < output->N; ++j)
			if (run_float) {
				data_f = output->data_f[output->N * i + j];

				if (!j || data_f > max_f) {
					max_f = data_f;
					predicted[i] = j;
				}
			}
			else {
				data8 = output->data8[output->N * i + j];

				if (!j || data8 > max8) {
					max8 = data8;
					predicted[i] = j;
				}
			}

		if (label[i] == predicted[i])
			++*correct;
	}
}

void execute_model(uint32_t *dpu, struct model *model, struct matrix32 *input, uint8_t create_outputs, uint8_t first_run, uint8_t run_float, uint8_t run_ps, uint8_t fill_lut) {
	int i, j, k, start_input = 0, end_input = 0, start_output = 0, end_output = 0;

	for (i = 0; i < model->num_name; ++i) {
		if (strstr(model->names[i], "embedding")) {
			if (create_outputs) {
				model->alloc_output = 1;
				model->num_output += input->N;
				model->outputs = (struct matrix*)malloc(model->num_output * sizeof(struct matrix));
			}

			start_input = 0;
			end_input = input->N - 1;
			start_output = end_output = input->N;

			for (j = start_input; j <= end_input; ++j)
				run_embedding(model, input, j, first_run, run_float);
		}
		else if (strstr(model->names[i], "lstm")) {
			for (j = 0; j < model->num_lstm; ++j)
				if (!strcmp(model->lstms[j].name, model->names[i]))
					break;

			if (create_outputs) {
				model->num_output += (model->lstms[j].use_bias ? 25 : 21) * input->N + 2;

				if (!model->alloc_output) {
					model->alloc_output = 1;
					model->outputs = (struct matrix*)malloc(model->num_output * sizeof(struct matrix));
				}
				else
					model->outputs = (struct matrix*)realloc(model->outputs, model->num_output * sizeof(struct matrix));

				model->lstms[j].start_input = start_input;
				model->lstms[j].end_input = end_input;
				model->lstms[j].start_output = start_output;
				model->lstms[j].end_output = end_output + (model->lstms[j].use_bias ? 25 : 21) * input->N + 1;
			}

			if (model->lstms[j].use_bias)
				for (k = 0; k < 4; ++k)
					resize_bias(&model->lstms[j].bias[k], input->M, run_float);

			start_input = start_output + 20 * input->N + 2;
			end_input = end_output + 21 * input->N + 1;
			start_output = end_output = model->lstms[j].end_output + 1;

			run_lstm(dpu, model, j, first_run, run_float, run_ps, fill_lut);
		}
		else if (strstr(model->names[i], "dense")) {
			for (j = 0; j < model->num_dense; ++j)
				if (!strcmp(model->denses[j].name, model->names[i]))
					break;

			if (create_outputs) {
				model->num_output += model->denses[j].use_bias ? 3 : 2;

				if (!model->alloc_output) {
					model->alloc_output = 1;
					model->outputs = (struct matrix*)malloc(model->num_output * sizeof(struct matrix));
				}
				else
					model->outputs = (struct matrix*)realloc(model->outputs, model->num_output * sizeof(struct matrix));

				model->denses[j].input_index = end_input;
				model->denses[j].start_output = start_output;
				model->denses[j].end_output = start_output + (model->denses[j].use_bias ? 2 : 1);
			}

			if (model->denses[j].use_bias)
				resize_bias(&model->denses[j].bias, input->M, run_float);

			start_input = end_input = start_output + 1;
			start_output = end_output = model->denses[j].end_output + 1;

			run_dense(dpu, model, j, first_run, run_float, run_ps, fill_lut);
		}
	}

	if (fill_lut)
		update_model_params(model);
}

void run_embedding(struct model *model, struct matrix32 *input, uint32_t input_index, uint8_t first_run, uint8_t run_float) {
	int i, j, N;
	uint32_t data;

	if (first_run) {
		model->outputs[input_index].M = input->M;
		model->outputs[input_index].N = model->embedding.embeddings.N;
		model->outputs[input_index].data_f = (float*)malloc(input->M * model->outputs[input_index].N * sizeof(float));
		model->outputs[input_index].data8 = (uint8_t*)malloc(input->M * model->outputs[input_index].N * sizeof(uint8_t));
		model->outputs[input_index].alloc_lut = model->outputs[input_index].alloc_row = model->outputs[input_index].update_param = 0;
	}

	N = model->outputs[input_index].N;

	for (i = 0; i < input->M; ++i) {
		data = input->data[input->N * i + input_index];

		for (j = 0; j < model->outputs[input_index].N; ++j)
			if (run_float)
				model->outputs[input_index].data_f[N * i + j] = model->embedding.embeddings.data_f[N * data + j];
			else
				model->outputs[input_index].data8[N * i + j] = model->embedding.embeddings.data8[N * data + j];
	}
}

void run_lstm(uint32_t *dpu, struct model *model, uint32_t lstm_index, uint8_t first_run, uint8_t run_float, uint8_t run_ps, uint8_t fill_lut) {
	int i, j, k, M, N;
	struct lstm *lstm = &model->lstms[lstm_index];

	uint32_t timesteps, s, x[4], _h[4], x_h[4], a[5], fc, ic, c, h, x_h_b[4];

	timesteps = lstm->end_input - lstm->start_input + 1;
	s = lstm->start_input;
	x[0] = lstm->start_output;
	_h[0] = x[0] + timesteps;
	x_h[0] = _h[0] + timesteps;
	a[0] = x_h[0] + timesteps;
	x[1] = a[0] + timesteps;
	_h[1] = x[1] + timesteps;
	x_h[1] = _h[1] + timesteps;
	a[1] = x_h[1] + timesteps;
	x[2] = a[1] + timesteps;
	_h[2] = x[2] + timesteps;
	x_h[2] = _h[2] + timesteps;
	a[2] = x_h[2] + timesteps;
	x[3] = a[2] + timesteps;
	_h[3] = x[3] + timesteps;
	x_h[3] = _h[3] + timesteps;
	a[3] = x_h[3] + timesteps;
	fc = a[3] + timesteps;
	ic = fc + timesteps;
	c = ic + timesteps;
	a[4] = c + timesteps + 1;
	h = a[4] + timesteps;

	if (lstm->use_bias) {
		x_h_b[0] = h + timesteps + 1;
		x_h_b[1] = x_h_b[0] + timesteps;
		x_h_b[2] = x_h_b[1] + timesteps;
		x_h_b[3] = x_h_b[2] + timesteps;
	}

	if (first_run)
		for (i = x[0]; i <= lstm->end_output; ++i) {
			model->outputs[i].M = model->outputs[s].M;
			model->outputs[i].N = lstm->rec_kernel[0].N;
			model->outputs[i].data_f = (float*)malloc(model->outputs[i].M * model->outputs[i].N * sizeof(float));
			model->outputs[i].data8 = (uint8_t*)malloc(model->outputs[i].M * model->outputs[i].N * sizeof(uint8_t));
			model->outputs[i].alloc_lut = model->outputs[i].alloc_row = model->outputs[i].update_param = 0;
		}

	M = model->outputs[x[0]].M;
	N = model->outputs[x[0]].N;

	for (i = 0; i < M; ++i)
		for (j = 0; j < N; ++j)
			if (run_float)
				model->outputs[c].data_f[N * i + j] = model->outputs[h].data_f[N * i + j] = 0;
			else
				model->outputs[c].data8[N * i + j] = model->outputs[h].data8[N * i + j] = 0;

	for (i = lstm->reverse ? timesteps - 1 : 0, j = 0; (lstm->reverse ? i >= 0 : i < timesteps) && j < timesteps; lstm->reverse ? --i : ++i, ++j) {
		for (k = 0; k < 4; ++k) {
			multiply_matrix(dpu, &model->outputs[s + i], &lstm->kernel[k], &model->outputs[x[k] + j], run_float, run_ps);
			multiply_matrix(dpu, &model->outputs[h + j], &lstm->rec_kernel[k], &model->outputs[_h[k] + j], run_float, run_ps);
			add_matrix(&model->outputs[x[k] + j], &model->outputs[_h[k] + j], &model->outputs[x_h[k] + j], run_float);

			if (lstm->use_bias)
				add_matrix(&model->outputs[x_h[k] + j], &lstm->bias[k], &model->outputs[x_h_b[k] + j], run_float);

			if (fill_lut)
				fill_luts(&model->outputs[(lstm->use_bias ? x_h_b[k] : x_h[k]) + j]);

			activate(k == 2 ? lstm->activation : lstm->rec_activation, &model->outputs[(lstm->use_bias ? x_h_b[k] : x_h[k]) + j], &model->outputs[a[k] + j], run_float);
		}

		ele_multiply(&model->outputs[a[1] + j], &model->outputs[c + j], &model->outputs[fc + j], run_float);
		ele_multiply(&model->outputs[a[0] + j], &model->outputs[a[2] + j], &model->outputs[ic + j], run_float);
		add_matrix(&model->outputs[fc + j], &model->outputs[ic + j], &model->outputs[c + j + 1], run_float);

		if (fill_lut)
			fill_luts(&model->outputs[c + j + 1]);

		activate(lstm->activation, &model->outputs[c + j + 1], &model->outputs[a[4] + j], run_float);
		ele_multiply(&model->outputs[a[3] + j], &model->outputs[a[4] + j], &model->outputs[h + j + 1], run_float);
	}
}

void run_dense(uint32_t *dpu, struct model *model, uint32_t dense_index, uint8_t first_run, uint8_t run_float, uint8_t run_ps, uint8_t fill_lut) {
	int i;
	struct dense *dense = &model->denses[dense_index];

	if (first_run)
		for (i = dense->start_output; i <= dense->end_output; ++i) {
			model->outputs[i].M = model->outputs[dense->input_index].M;
			model->outputs[i].N = dense->kernel.N;
			model->outputs[i].data_f = (float*)malloc(model->outputs[i].M * dense->kernel.N * sizeof(float));
			model->outputs[i].data8 = (uint8_t*)malloc(model->outputs[i].M * dense->kernel.N * sizeof(uint8_t));
			model->outputs[i].alloc_lut = model->outputs[i].alloc_row = model->outputs[i].update_param = 0;
		}

	multiply_matrix(dpu, &model->outputs[dense->input_index], &dense->kernel, &model->outputs[dense->start_output], run_float, run_ps);

	if (dense->use_bias)
		add_matrix(&model->outputs[dense->start_output], &dense->bias, &model->outputs[dense->end_output], run_float);

	if (fill_lut)
		fill_luts(&model->outputs[dense->use_bias ? dense->end_output : dense->start_output]);

	activate(dense->activation, &model->outputs[dense->use_bias ? dense->end_output : dense->start_output], &model->outputs[dense->start_output + 1], run_float);
}

void init_model(struct model *model) {
	model->has_embedding = model->alloc_output = model->input_dim = model->num_name = model->num_lstm = model->num_dense = model->num_output = model->embedding.embeddings.update_param = 0;
	model->names = NULL;
	model->embedding.embeddings.data_f = NULL;
	model->embedding.embeddings.data8 = NULL;
	model->lstms = NULL;
	model->denses = NULL;
	model->outputs = NULL;
}

void free_output_data(struct model *model) {
	int i;

	for (i = 0; i < model->num_output; ++i) {
		FREE(model->outputs[i].data_f);
		FREE(model->outputs[i].data8);

		if (model->outputs[i].alloc_row)
			FREE(model->outputs[i].row_sum);
	}
}

void free_model(struct model *model) {
	int i, j;

	model->num_name = 0;
	FREE(model->names);

	model->has_embedding = 0;
	FREE(model->embedding.embeddings.data_f);
	FREE(model->embedding.embeddings.data8);

	for (i = 0; i < model->num_lstm; ++i)
		for (j = 0; j < 4; ++j) {
			FREE(model->lstms[i].kernel[j].data_f);
			FREE(model->lstms[i].kernel[j].data8);
			FREE(model->lstms[i].rec_kernel[j].data_f);
			FREE(model->lstms[i].rec_kernel[j].data8);

			if (model->lstms[i].kernel[j].alloc_column)
				FREE(model->lstms[i].kernel[j].column_sum);

			if (model->lstms[i].rec_kernel[j].alloc_column)
				FREE(model->lstms[i].rec_kernel[j].column_sum);

			if (model->lstms[i].use_bias) {
				FREE(model->lstms[i].bias[j].data_f);
				FREE(model->lstms[i].bias[j].data8);
			}
		}

	if (model->num_lstm) {
		model->num_lstm = 0;
		FREE(model->lstms);
	}

	for (i = 0; i < model->num_dense; ++i) {
		FREE(model->denses[i].kernel.data_f);
		FREE(model->denses[i].kernel.data8);

		if (model->denses[i].kernel.alloc_column)
			FREE(model->denses[i].kernel.column_sum);

		if (model->denses[i].use_bias) {
			FREE(model->denses[i].bias.data_f);
			FREE(model->denses[i].bias.data8);
		}
	}

	if (model->num_dense) {
		model->num_dense = 0;
		FREE(model->denses);
	}

	free_output_data(model);

	for (i = 0; i < model->num_output; ++i)
		if (model->outputs[i].alloc_lut) {
			FREE(model->outputs[i].relu_lut);
			FREE(model->outputs[i].sigmoid_lut);
			FREE(model->outputs[i].tanh_lut);
		}
}
