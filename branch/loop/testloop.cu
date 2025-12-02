#include <cstdio>
#include <cstdlib>

#include <cuda_runtime.h>
#include <cuda.h>

#define XBS 32

#define NN 32

// printf("thread.x=%d, activemask=0x%08x\n", threadIdx.x, __activemask());
// printf("thread.x=%d, activemask=0x%08x\n", threadIdx.x, __activemask());
// printf("threadidx.x = %d\n", threadIdx.x);

__device__ int mem[2048] = {0};

__global__
void test_bra(int64_t *out, uint32_t count){
    // __shared__ uint32_t data[XBS];
    int i = threadIdx.x;
    while (i > 0) {
        mem[threadIdx.x * XBS + i] += i;
        i--;
    }
}

int main(int argc, char **argv) {
    const int N = XBS;
    size_t size = N * sizeof(int64_t);
    size_t size_a = size;

    int64_t *h_a = (int64_t*)malloc(size_a);
    int64_t *h_b = (int64_t*)malloc(size);
    int64_t *h_c = (int64_t*)malloc(size);

    for (int i = 0; i < N; ++i) {
        h_a[i] = static_cast<int64_t>(i);
    }


    for (int i = 0; i < N; ++i) {
        h_b[i] = static_cast<int64_t>(i) * 2;
    }

    int64_t *d_a, *d_b, *d_c;

    cudaMalloc((void**)&d_a, size_a);
    cudaMalloc((void**)&d_b, size);
    cudaMalloc((void**)&d_c, size);

    cudaMemcpy(d_a, h_a, size_a, cudaMemcpyHostToDevice);
    cudaMemcpy(d_b, h_b, size, cudaMemcpyHostToDevice);
    cudaError_t err = cudaGetLastError();
    if (err != cudaSuccess) {
        printf("Kernel launch failed: %s\n", cudaGetErrorString(err));
    }

    int threadsPerBlock = XBS;
    int blocksPerGrid = (N + threadsPerBlock - 1) / threadsPerBlock;

    printf("blocks  per grid  = %d\n", blocksPerGrid);
    printf("threads per block = %d\n", threadsPerBlock);

    err = cudaGetLastError();
    if (err != cudaSuccess) {
        printf("Kernel launch failed: %s\n", cudaGetErrorString(err));
    }

    test_bra<<<blocksPerGrid, threadsPerBlock>>>(d_a, N);
    
    err = cudaGetLastError();
    if (err != cudaSuccess) {
        printf("Kernel launch failed: %s\n", cudaGetErrorString(err));
    }

    cudaMemcpy(h_c, d_c, size, cudaMemcpyDeviceToHost);

    cudaFree(d_a);
    cudaFree(d_b);
    cudaFree(d_c);

    free(h_a);
    free(h_b);
    free(h_c);
    printf("everything finished\n");

    return 0;

}
