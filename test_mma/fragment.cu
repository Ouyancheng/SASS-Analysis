#include <cstdio>
#include <cstdlib>

#include <cuda_runtime.h>
#include <cuda.h>
#include <mma.h>

#include <type_traits>
#define XBS 64

__device__ __noinline__ int atomicFoo(int *a) {
    return atomicAdd(a, 1);
}


#define GEN(a) a, a+1, a+2, a+3, a+4, a+5, a+6, a+7
#define GEN2(b) GEN(b), GEN(b+8), GEN(b+16), GEN(b+24), GEN(b+32), GEN(b+40), GEN(b+48), GEN(b+56)
__constant__ int array[64] = {GEN2(0)}; // must be outside of function body,


// template <typename T, int A, int B, int C>
// struct __device_builtin__ FakeFragment {
//     T storage[A][B];
//     char test[-(std::is_class<T>::value)];
//     FakeFragment(const FakeFragment &) = delete;
//     FakeFragment(FakeFragment &&) = delete;
//     ~FakeFragment() = delete;
// };

// template<typename T, int A, int B, int C> 
// T __attribute__((always_inline)) getStorage(const FakeFragment<T, A, B, C> &ff, int a, int b, int c) {
//     return ff.storage[a][b];
// }

// template<typename T, int a, int b, int c>
// void fakeMMA(FakeFragment<T, a, b, c> &cc, const FakeFragment<T, a, b, c> &aa, const FakeFragment<T, a, b, c> &bb) {}

__global__
void test_atomic(int64_t *out, uint32_t count) {    
    // int r = atomicFoo(&(array[threadIdx.x]));
    // const void *ptr = (const void*)(&threadIdx);
    // void *pp = const_cast<void*>(ptr);
    // (*(int*)ptr) += 1024;
    // out[threadIdx.x] = (int64_t)array[threadIdx.x];

    typedef nvcuda::wmma::fragment<nvcuda::wmma::matrix_a, 16, 16, 16, __half, nvcuda::wmma::row_major> frag_a_t;
    nvcuda::wmma::fragment<nvcuda::wmma::matrix_a, 16, 16, 16, __half, nvcuda::wmma::row_major> frag_a;
    nvcuda::wmma::fragment<nvcuda::wmma::matrix_b, 16, 16, 16, __half, nvcuda::wmma::col_major> frag_b;
    nvcuda::wmma::fragment<nvcuda::wmma::accumulator, 16, 16, 16, __half, void> frag_c;
    // if (threadIdx.x == 0) {
    //     printf("sizeof fragment = %d\n", sizeof(frag_a));
    // }

    constexpr int nelem = frag_a.num_elements; // 16 
    constexpr int nstorageelem = frag_a.num_storage_elements; // 16
    constexpr int fragasize = sizeof(frag_a); // 32 (bytes)
    // frag_a_t *p_fraga = &frag_a;
    // printf("pfrag_a = %p\n", p_fraga);

    // if (threadIdx.x == 0) {
    //     for (int i = 0; i < nstorageelem; ++i) {
    //         printf("x[%d] = %f  %f\n", i, p_fraga->x[i], frag_a.x[i]);
    //     }
    // }

    nvcuda::wmma::load_matrix_sync(frag_a, (__half*)out, 0);
    nvcuda::wmma::load_matrix_sync(frag_b, (__half*)(out+nstorageelem/sizeof(int64_t)), 0);
    for (int i = 0; i < count/8; ++i) {
        frag_a.x[i] += 1.0;
    }

    __syncthreads();

    for (int i = 0; i < frag_c.num_storage_elements; ++i) {
        frag_c.x[count - 64 + i] = (__half)i;
    }

    frag_c.x[count / 32] = 1024.0;

    nvcuda::wmma::mma_sync(frag_c, frag_a, frag_b, frag_c);

    nvcuda::wmma::store_matrix_sync((__half*)out, frag_c, 1, nvcuda::wmma::layout_t::mem_row_major);

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
    printf("blocks per grid = %d\n", blocksPerGrid);
    err = cudaGetLastError();
    if (err != cudaSuccess) {
        printf("Kernel launch failed: %s\n", cudaGetErrorString(err));
    }
    test_atomic<<<blocksPerGrid, threadsPerBlock>>>(d_a, N);
    printf("threads per block = %d\n", threadsPerBlock);
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