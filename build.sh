nvcc testbranch.cu -o testbranch.cubin -cubin -gencode arch=compute_90,code=sm_90 -Xptxas -O0 

cuobjdump --dump-sass testbranch.cubin  | vim -

