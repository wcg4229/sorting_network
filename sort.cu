/*
 * William Charles Grove
 * Bitonic sort array
 * Sorting Network Implementation
 *
 * 12/1/2016
 */

#include <stdlib.h>
#include <stdio.h>
#include <limits.h>

int generate_int() {
	return rand() / 1000000;
}

void print_values(int *values, int length) {
	int j = length / 16;
	int remainder = length - (j * 16);
	int block = 0;
	for (int i = 0; i < j; ++i) {
		printf("\nBlock %d: ", block++);
		for (int index = 0; index < 16; index++) {
			printf("%d ", values[(i * 16) + index]);
		}

	}

	if (remainder > 0) {

		printf("\nBlock %d: ", block);

		for (int i = j * 16; i < (j * 16) + remainder; i++) {
			printf("%d ", values[i]);
		}

	}

}

__global__ void sn_iteration(int *value_array, int j, int k) {
	unsigned int i, x;
	i = threadIdx.x + blockDim.x * blockIdx.x;
	x = i ^ j;

	/* The threads with the lowest ids sort the array. */
	if ((x) > i) {
		if ((i & k) == 0) {
			//Sort ascending
			if (value_array[i] > value_array[x]) {
				//swap
				float temp = value_array[i];
				value_array[i] = value_array[x];
				value_array[x] = temp;
			}
		}
		if ((i & k) != 0) {
			// Sort descending
			if (value_array[i] < value_array[x]) {
				// swap
				float temp = value_array[i];
				value_array[i] = value_array[x];
				value_array[x] = temp;
			}
		}
	}
}


//Sorting network method, activates  a kernel
void sorting_network(int *values, int block_num, int thread_num, int num_vals) {
	int *value_array;
	size_t size = num_vals * sizeof(int);

	cudaMalloc((void**) &value_array, size);
	cudaMemcpy(value_array, values, size, cudaMemcpyHostToDevice);

	/*Unlike the Voronoi diagram,
	 * this process can be modeled with
	 * a one dimensional array.
	 */
	dim3 blocks(block_num, 1);
	dim3 threads(thread_num, 1);

	int j, k;
	/* Major step */
	for (k = 2; k <= num_vals; k <<= 1) {
		/* Minor step */
		for (j = k >> 1; j > 0; j = j >> 1) {
			sn_iteration<<<blocks, threads>>>(value_array, j, k);
		}
	}
	cudaMemcpy(values, value_array, size, cudaMemcpyDeviceToHost);
	cudaFree(value_array);
}

int realloc_array(int **arr, int size) {

	int *temp;

	int fsize = size * sizeof(int);

	temp = (int*) realloc(*arr, fsize);

	if (temp == NULL) {
		printf("Error in realloc!");
		return 0;
	}

	*arr = temp;

	return 1;

}

int main(int argc, char* argv[]) {

	int *values = (int*) malloc(1 * sizeof(int));
	int num_vals = 0;

	if (argc == 1) {
		printf("There were no values passed into the function.");
	}

	if (argc == 2) {

		if ((atoi(argv[1]) == 0)) {
			//It is a file name

			FILE* file = fopen(argv[1], "r");

			if (file == NULL) {
				printf("Error opening file.\n");
				return -1;
			}

			int size = 1;

			int i = 0;
			int index = -1;

			while (!feof(file)) {
				fscanf(file, "%d", &i);

				index++;
				printf("\n[%d:%d]", index, i);
				values[index] = i;

				if (index + 1 == size) {
					size *= 2;
					if (realloc_array(&values, size) == 0) {
						return -1;
					}
				}
			}
			fclose(file);

			if (realloc_array(&values, index) == 0) {
				return -1;
			}

			num_vals = index;

		} else {
			//There is a number of values to generate

			num_vals = atoi(argv[1]);

			if (realloc_array(&values, num_vals) == 0) {
				return -1;
			}

			int i;
			for (i = 0; i < num_vals; ++i) {
				values[i] = generate_int();

			}
		}
	} else {
		//There is a list of values to read in

		for (int i = 1; i < argc; i++) {

			realloc_array(&values, i);
			values[i - 1] = atoi(argv[i]);
		}

		num_vals = argc - 1;

	}

	int padding = 0;
	int block_num = num_vals / 16;
	int remainder = num_vals % 16;

	if(block_num == 0){
		block_num = 1;
	}

	if (remainder > 0) {
		block_num++;
		padding = 16 - remainder;
		realloc_array(&values, num_vals + padding);

		for (int i = num_vals; i < num_vals + padding; i++) {
			values[i] = 50;
		}
	}

	for (int i = 0; i < num_vals + padding; i++) {
		printf("%d\n", values[i]);
	}

	printf("num_val: %d\n", num_vals);
	printf("padding: %d\n", padding);
	printf("remainder: %d\n", remainder);
	printf("block num: %d\n", block_num);
	printf("size of array: %d\n", sizeof(values)/sizeof(int));

	print_values(values, num_vals);

	sorting_network(values, block_num, block_num * 16, num_vals + padding);

	print_values(values, num_vals);
}
