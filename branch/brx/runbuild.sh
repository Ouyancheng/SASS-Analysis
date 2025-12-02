#!/bin/bash

source_file=$1
source_file_no_extension=${source_file%.*}
source_file_extension=${source_file##*.}

if [ ${source_file_extension} = ptx ]; then

ver=$2
out_file=${source_file_no_extension}${ver}.out
cubin_file=${source_file_no_extension}${ver}.cubin
list_file=${source_file_no_extension}${ver}.list

host_file=host.cu

ptxas ${source_file} -o ${cubin_file} -O0 --gpu-name=sm_${ver}
nvcc ${host_file} -o ${out_file} -I/usr/local/cuda/include -L/usr/local/cuda/lib64 -lcudart -lcudadevrt -lcuda
cuobjdump --dump-sass ${cubin_file} > ${list_file}

fi 

