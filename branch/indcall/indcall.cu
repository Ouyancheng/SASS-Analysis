// Type your code here, or load an example.
// __global__ void square(int* array, int n) {
//     int tid = blockDim.x * blockIdx.x + threadIdx.x;
//     if (tid < n)
//         array[tid] = array[tid] * array[tid];
// }

#include <stdio.h>
struct A {
    int b;
    __device__ __noinline__ A(int b) : b(b) {}
    virtual __device__ __noinline__ void inc(int &c) {this->b += c; c *= this->b; }
    virtual __noinline__ __device__ ~A() {}
};

struct B : public A {
    using A::A;
    void __device__ __noinline__ inc(int &d) override {this->b -= d; d *= this->b; }
    virtual __device__ __noinline__ ~B() {}
};


struct C : public A {
    using A::A;
    void __device__ __noinline__ inc(int &d) override {this->b += d; d *= this->b; }
    virtual __device__ __noinline__ ~C() {}
};

__device__ __noinline__ A *getA(int a) {
    return reinterpret_cast<A*>(a);
}

// Device function for addition
__device__ int add_device(int a, int b) {
    // switch (a) {
    //     case 0:
    //     case 1:return a + b * b;
    //     case 2: return a + b * b *  b;
    //     case 3: return a + b * b * b * b;
    //     case 4: return a + b + b + b;
    //     case 5: return a + b + b * b;
    //     case 6:return a + b * b + b * b;
    //     case 7:return a + b + 1;
    //     case 8:return a + b + 1024;
    //     case 9:return a + b + 1024;
    //     case 10:return a + b + 1024;
    //     case 11:return a + b + 1026;
    //     case 12:return a + b + 1024 * 8;
    //     case 13:return a + b * b + 1024;
    //     case 15:return a + b * a + 1024;
    //     case 16:return a * a + b + 1024;
    //     case 17:return a + b + 1024;
    //     case 20:return a + b + 1024;
    //     case 1024:return a + b + 1024;

    //     default:
    //         return a + b;
    // }
    A *aa = getA(a);
    aa->inc(b);
    A *bb = getA(b);
    bb->inc(a);


    return a + b;
}



// Global kernel function
__global__ void add_kernel(int* d_in1, int* d_in2, int* d_out, int N) {
    int tid = blockIdx.x * blockDim.x + threadIdx.x;
    if (tid < N) {
        // Call the device function from within the kernel
        d_out[tid] = add_device(d_in1[tid], d_in2[tid]);
    }
}

int main() {
    int N = 10;
    int h_in1[N], h_in2[N], h_out[N];
    int *d_in1, *d_in2, *d_out;

    // Initialize host arrays
    for (int i = 0; i < N; ++i) {
        h_in1[i] = i;
        h_in2[i] = i * 2;
    }

    // Allocate device memory
    cudaMalloc((void**)&d_in1, N * sizeof(int));
    cudaMalloc((void**)&d_in2, N * sizeof(int));
    cudaMalloc((void**)&d_out, N * sizeof(int));

    // Copy data from host to device
    cudaMemcpy(d_in1, h_in1, N * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_in2, h_in2, N * sizeof(int), cudaMemcpyHostToDevice);

    // Define grid and block dimensions
    int threadsPerBlock = 256;
    int numBlocks = (N + threadsPerBlock - 1) / threadsPerBlock;

    // Launch the kernel
    add_kernel<<<numBlocks, threadsPerBlock>>>(d_in1, d_in2, d_out, N);

    // Copy results from device to host
    cudaMemcpy(h_out, d_out, N * sizeof(int), cudaMemcpyDeviceToHost);

    // Print results
    printf("Results:\n");
    for (int i = 0; i < N; ++i) {
        printf("%d + %d = %d\n", h_in1[i], h_in2[i], h_out[i]);
    }

    // Free device memory
    cudaFree(d_in1);
    cudaFree(d_in2);
    cudaFree(d_out);

    return 0;
}
