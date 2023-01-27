#include <cuda.h>
#include <cuda_runtime.h>
#include <device_launch_parameters.h>
#include <stdio.h>
#include <stdlib.h>
#include "win-gettimeofday.h"

#define THREADS_PER_BLOCK 512

__global__ void bubbleSort(int array[], int End) 
{ 
    int swapped = 0;
    int temp;
    do 
    {
        swapped = 0;
        for (int i = 0; i < End; i++) 
        {
            if (array[i] > array[i + 1]) 
            {
                temp = array[i];
                array[i] = array[i + 1];
                array[i + 1] = temp;
                swapped = 1;
            }
        }

    } while (swapped == 1);

}

void populateRandomArray(int *x, int num_elements) 
{
    for (int i = 0; i < num_elements; i++) 
    {
        x[i] = rand() % 100 + 1;
    }
}

void bubbleSortCPU(int array[], int End) 
{ 
    int swapped = 0;
    int temp;

    do 
    {
        swapped = 0;
        for (int i = 0; i < End; i++) 
        {
            if (array[i] > array[i + 1]) 
            {
                temp = array[i];
                array[i] = array[i + 1];
                array[i + 1] = temp;
                swapped = 1;
            }
        }

    } while (swapped == 1);

}

int main(void) 
{
    const int number_of_elements = 100000; 

    int trials[number_of_elements]; 

    int *host_a;
    int *host_c;

    int *device_a;
    int *device_c;

    double cpu_time_without_allocation;
    double cpu_time_with_allocation;
    double cpu_end_time;

    double gpu_time_without_transfer;
    double gpu_time_with_transfer;
    double gpu_end_time_without_transfer;
    double gpu_end_time_with_transfer;

    for (int i = 0; i < 1; i++) 
    {
        int size = trials[i] *
                   sizeof(int); 

        int end = number_of_elements;

        host_a = (int *) malloc(size);
        host_c = (int *) malloc(size);

        cudaMalloc((void **) &device_a, size);
        cudaMalloc((void **) &device_c, size);

        populateRandomArray(host_a, number_of_elements);

        gpu_time_with_transfer = get_current_time(); 

        cudaMemcpy(device_a, host_a, size, cudaMemcpyHostToDevice);

        gpu_time_without_transfer = get_current_time(); 

        dim3 dimBlock(THREADS_PER_BLOCK, 1, 1);
        dim3 dimGrid((trials[i] + dimBlock.x - 1) / dimBlock.x, 1, 1);

        bubbleSort << < dimGrid, dimBlock >> > (device_a, end); 

        cudaError_t error = cudaGetLastError();
        if (error != cudaSuccess) 
        {
            printf("Error: %s\n", cudaGetErrorString(error));
        }

        cudaThreadSynchronize(); 

        gpu_end_time_without_transfer = get_current_time(); 

        cudaMemcpy(host_c, device_a, size, cudaMemcpyDeviceToHost);

        gpu_end_time_with_transfer = get_current_time();  

        printf("Number of elements = %d, GPU Time (Not including data transfer): %lfs\n", number_of_elements,
               (gpu_end_time_without_transfer - gpu_time_without_transfer));
        printf("Number of elements = %d, GPU Time (Including data transfer): %lfs\n", number_of_elements,
               (gpu_end_time_with_transfer - gpu_time_with_transfer));

        free(host_a);
        free(host_c);

        cudaFree(device_a);
        cudaFree(device_c);

        cudaDeviceReset();
    }
    return 0;
}