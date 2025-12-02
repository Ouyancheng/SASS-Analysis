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

__global__
void test_brx(int64_t *out, uint32_t count){
    __shared__ uint32_t data[XBS];
    int64_t a = out[threadIdx.x];
    int64_t b = threadIdx.x + 100;
    #define CASE(x) case (x): out[b] = threadIdx.z + x; break;
    #define GENCASE(y) \
        CASE(y) \
        CASE(y+1) \
        CASE(y+2) \
        CASE(y+3) \
        CASE(y+4) \
        CASE(y+5) \
        CASE(y+6) \
        CASE(y+7) \
        CASE(y+8) \
        CASE(y+9)
    switch (a) {
        case 10:
            out[b] = threadIdx.y + 10;
            break;
        case 17:
            out[b] = threadIdx.y + 17;
            break;
        case 31:
            out[b] = threadIdx.y + 31;
            break;
        case 41:
            out[b] = threadIdx.y + 41;
            break;
        case 51:
            out[b] = threadIdx.y + 51;
            break;
        case 61:
            out[b] = threadIdx.y + 61;
            break;
        case 71:
            out[b] = threadIdx.y + 71;
            break;
        case 101:
            out[b] = threadIdx.y + 101;
            break;
        case 113:
            out[b] = threadIdx.y + 113;
            break;
        case 117:
            out[b] = threadIdx.y + 117;
            break;
        case 127:
            out[b] = threadIdx.y + 127;
            break;
        case 131:
            out[b] = threadIdx.y + 131;
            break;
        GENCASE(132)
        GENCASE(152)
        GENCASE(162)
        GENCASE(172)
        GENCASE(182)
        GENCASE(192)
    }
    return;
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

    test_brx<<<blocksPerGrid, threadsPerBlock>>>(d_a, N);
    
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
