#include <cstdio>
#include <cstdlib>

#include <cuda_runtime.h>
#include <cuda.h>

#define XBS 256
__device__ __attribute__((noinline)) int64_t callee(int64_t a, int64_t b) {
    // if (b > 0) return callee(callee(a, b), b-1);
    return a + b;
}
__global__ void element_wise_mul(int64_t *a, int64_t *b, int64_t *c, int N) {
    // int tx = callee(threadIdx.x, callee(XBS, blockDim.x) * blockIdx.x);
    int tx = threadIdx.x + XBS * blockIdx.x;
    if (tx < N) {
        // c[tx] += 1;
        if (tx & 1) {
            c[tx] = sinf(a[tx] * b[tx] + c[tx]);
        } else {
            c[tx] = 1;
        }
        // c[tx / 2] = callee(a[tx], b[tx]);
    }
    return;
}

int main(int argc, char **argv) {
    const int N = 1024;
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

    int threadsPerBlock = XBS;
    int blocksPerGrid = (N + threadsPerBlock - 1) / threadsPerBlock;
    element_wise_mul<<<blocksPerGrid, threadsPerBlock>>>(d_a, d_b, d_c, N);

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
