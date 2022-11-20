#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include "model.h"

int main(int argc, char *argv[]) {
	FILE *output_ptr = fopen("output.log", "w");
	int fd;
	char *model_path, *data_path, *label_path;
	uint32_t *dpu;

	uint8_t error = 0, not_float, quantize = 1, run_ps = 0;
	uint32_t batch_sz = 64, representative = 200;
	struct model model;

	srand(time(NULL));

	if (argc == 1) {
		model_path = "lstm.model";
		data_path = "train_data.txt";
		label_path = "train_label.txt";
	}
	else if (argc == 2 && strstr(argv[1], ".model") != NULL) {
		model_path = argv[1];
		data_path = "train_data.txt";
		label_path = "train_label.txt";
	}
	else if (argc >= 4 && argc <= 8 && strstr(argv[1], ".model") != NULL) {
		model_path = argv[1];
		data_path = argv[2];
		label_path = argv[3];

		if (argc >= 5)
			batch_sz = atoi(argv[4]);

		if (argc >= 6)
			quantize = atoi(argv[5]);

		if (argc >= 7)
			representative = atoi(argv[6]);

		if (argc == 8)
			run_ps = !atoi(argv[7]);
	}
	else {
		printf("Usage: lstm_dpu_app.elf <Model_Path> <Data_Path> <Label_Path> <Batch_Size> <Quantize> <Representative> <Use_DPU>\n");
		fprintf(output_ptr, "Usage: lstm_dpu_app.elf <Model_Path> <Data_Path> <Label_Path> <Batch_Size> <Quantize> <Representative> <Use_DPU>\n");
		error = 1;
	}

	if (!error && access(model_path, F_OK)) {
		printf("%s does not exist.\n", model_path);
		fprintf(output_ptr, "%s does not exist\n", model_path);
		error = 1;
	}
	else if (!error && access(data_path, F_OK)) {
		printf("%s does not exist.\n", data_path);
		fprintf(output_ptr, "%s does not exist\n", data_path);
		error = 1;
	}
	else if (!error && access(label_path, F_OK)) {
		printf("%s does not exist.\n", label_path);
		fprintf(output_ptr, "%s does not exist\n", label_path);
		error = 1;
	}
	else if (!error && !batch_sz) {
		printf("Batch size cannot be zero\n");
		fprintf(output_ptr, "Batch size cannot be zero\n");
		error = 1;
	}
	else if (!error && quantize > 1) {
		printf("Quantize flag cannot be %d\n", quantize);
		fprintf(output_ptr, "Quantize flag cannot be %d\n", quantize);
		error = 1;
	}
	else if (!error && quantize == 1 && !representative) {
		printf("Representative cannot be zero\n");
		fprintf(output_ptr, "Representative cannot be zero\n");
		error = 1;
	}

	if (!error && (fd = open("/dev/mem", O_RDWR | O_SYNC)) != -1) {
		dpu = mmap(NULL, DPU_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, DPU_BASEADDR);
		reset_dpu(dpu);

		init_model(&model);
		load_model(output_ptr, model_path, &model, &not_float);

		if (!not_float) {
			printf("Batch size: %d --- Quantized: %s\n", batch_sz, quantize ? "True" : "False");
			fprintf(output_ptr, "Batch size: %d --- Quantized: %s\n", batch_sz, quantize ? "True" : "False");

			if (quantize) {
				printf("Representative: %d --- Use DPU: %s\n", representative, run_ps ? "False" : "True");
				fprintf(output_ptr, "Representative: %d --- Use DPU: %s\n", representative, run_ps ? "False" : "True");
			}

			printf("\n");
			fprintf(output_ptr, "\n");
			fflush(output_ptr);

			evaluate(output_ptr, dpu, &model, data_path, label_path, batch_sz, quantize, representative, run_ps);
		}

		free_model(&model);
		close(fd);
	}

	fclose(output_ptr);

	return 0;
}
