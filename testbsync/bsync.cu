#include <cstdio>
#include <cstdlib>

#include <cuda_runtime.h>
#include <cuda.h>

#define XBS 64

#define NN 32

// printf("thread.x=%d, activemask=0x%08x\n", threadIdx.x, __activemask());
// printf("thread.x=%d, activemask=0x%08x\n", threadIdx.x, __activemask());
// printf("threadidx.x = %d\n", threadIdx.x);

__device__ int mem[1024] = {0};

__device__ __noinline__ void test_branch_another(int64_t *out, uint32_t count) {
    if (threadIdx.x < NN) {
        out[threadIdx.x] = threadIdx.x;
    } else {
        mem[threadIdx.x - NN] = out[threadIdx.x - NN];
    }
    return;
}

__global__
void test_bra(int64_t *out, uint32_t count){
    __shared__ uint32_t data[XBS];
    if (threadIdx.x < 16) {
        mem[threadIdx.x] = threadIdx.y;
        mem[threadIdx.x + 16] = threadIdx.z;
        mem[threadIdx.x + 32] = threadIdx.x;
    }
    if (threadIdx.x < NN) {
        if (threadIdx.y < NN-2) 
        if (threadIdx.z < NN-3) 
        if (mem[threadIdx.y + 16] == 0) 
        if (mem[threadIdx.y + 17] == 0) 
        if (mem[threadIdx.y + 18] == 0) 
        if (mem[threadIdx.y + 19] == 0) 
        if (mem[threadIdx.y + 20] == 0) 
        if (mem[threadIdx.y + 21] == 0) 
        if (mem[threadIdx.y + 22] == 0) 
        if (mem[threadIdx.y + 23] == 0) 
        if (mem[threadIdx.y + 24] == 0) 
        if (mem[threadIdx.y + 25] == 0) 
        if (mem[threadIdx.y + 26] == 0) 
        if (mem[threadIdx.y + 27] == 0) 
        if (mem[threadIdx.y + 28] == 0) 
        if (mem[threadIdx.y + 29] == 0) 
        if (mem[threadIdx.y + 30] == 0) 
        if (mem[threadIdx.y + 31] == 0) 
        if (mem[threadIdx.y + 32] == 0) 
        if (mem[threadIdx.y + 33] == 0) 
        {
            data[threadIdx.x] = threadIdx.x;
            mem[threadIdx.x] = threadIdx.x;
            test_branch_another(out, count);
        } 

        // asm("barrier.cta.sync 0, 32;\n\t");
        data[threadIdx.x] = threadIdx.x;
        mem[threadIdx.x] = threadIdx.x;
        test_branch_another(out, count);
        
        // asm("barrier.cta.arrive 1, 32;\n\t");
    } else {
        // asm("barrier.cta.arrive 0, 32;\n\t");
        // asm("barrier.cta.sync 1, 32;\n\t");
        out[threadIdx.x - NN] = data[threadIdx.x - NN];
    }
    test_branch_another(out, count);
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
