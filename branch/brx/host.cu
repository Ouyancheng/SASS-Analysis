#include <cuda_runtime.h>
#include <cuda.h>
#include <stdio.h>

#define CHECK(res) do {\
CUresult result = res; \
printf("checking line %d\n", __LINE__); \
if (result != CUresult::CUDA_SUCCESS) { \
    printf("line: %d, result = %d, cuda error: %s\n", __LINE__, (int)result, cudaGetErrorString(cudaGetLastError())); \
} \
} while(0)


int main() {
    CUresult status = cuInit(0);
    CHECK(status);

    CUdevice device;
    status = cuDeviceGet(&device, 0);
    CHECK(status);

    CUcontext context;
    status = cuCtxCreate(&context, 0, device);
    CHECK(status);

    CUmodule module;
    status = cuModuleLoad(&module, "brx87.cubin");
    CHECK(status);

    CUfunction kernel;
    status = cuModuleGetFunction(&kernel, module, "testbrx");
    CHECK(status);

    size_t len = 32;
    size_t size_a = len * sizeof(int64_t);

    int64_t *h_a = (int64_t*)malloc(size_a);

    for (int i = 0; i < len; ++i) {
        h_a[i] = static_cast<int64_t>((i+4) % 5);
    }

    int64_t *d_a;
    cudaMalloc((void**)&d_a, size_a);
    cudaMemcpy(d_a, h_a, size_a, cudaMemcpyHostToDevice);

    printf("malloc done, pending param construct...\n");
    
    void* args[] = {&d_a, &len};
    dim3 grid(1, 1, 1), block(32, 1, 1);

    printf("malloc done, pending kernel launch...\n");
    
    status = cuLaunchKernel(
        kernel, 
        1, 1, 1, 
        32, 1, 1, 
        0, 
        NULL, 
        args, 0);
    CHECK(status);
    status = cuCtxSynchronize();
    CHECK(status);
    status = cuModuleUnload(module);
    CHECK(status);
    status = cuCtxDestroy(context);
    CHECK(status);
    
    cudaFree(d_a);
    free(h_a);



    return 0;
}


// #include <fstream>
// #include <vector>
// // 加载Cubin文件并获取内核函数
// cudaFunction_t load_kernel(const char* cubin_path, const char* kernel_name) {
//     std::ifstream file(cubin_path, std::ios::binary | std::ios::ate);
//     std::streamsize size = file.tellg();
//     file.seekg(0, std::ios::beg);
//     std::vector<char> cubin_data(size);
//     file.read(cubin_data.data(), size);
    
//     CUmodule module;
//     CUresult result = cuModuleLoadData(&module, cubin_data.data());  // 加载Cubin到模块
//     if (result != CUresult::CUDA_SUCCESS) {
//         printf("result = %d, cuda error: %s\n", (int)result, cudaGetErrorString(cudaGetLastError()));
//     }

//     cudaFunction_t kernel;
//     result = cuModuleGetFunction(&kernel, module, kernel_name);  // 获取内核函数
//     if (result != CUresult::CUDA_SUCCESS) {
//         printf("result2 = %d, cuda error: %s\n", (int)result, cudaGetErrorString(cudaGetLastError()));
//     }
//     return kernel;
// }


    // cudaFunction_t kernel = load_kernel("brx87.cubin", "testbrx");  // 替换为实际内核名
    
    // // 准备数据和执行配置（示例）
    // int* d_data;
    // cudaMalloc(&d_data, 32 * sizeof(int64_t));
    // for (int i = 0; i < 32; ++i) {
    //     d_data[i] = i % 5;
    // }
    // void* args[] = {&d_data};
    // dim3 grid(1), block(32);
    
    // // 启动内核
    // cudaLaunchKernel(kernel, grid, block, args);
    // cudaDeviceSynchronize();
    
    // cudaFree(d_data);