#!/bin/bash

# filepath=/home/ubuntu/sample.txt
# filename=$(basename $filepath)
# echo ${filename%.*}

source_file=$1
source_file_no_extension=${source_file%.*}
source_file_extension=${source_file##*.}


if [ ${source_file_extension} = cu ]; then

ver=$2
nodebug_option=$3
debug_flags="-g -G"
if [ "${nodebug_option}" != "" ]; then 
debug_flags=""
echo "no debug, option=${nodebug_option} 3=$3"
fi 
# for ver in 90 86 52 
# do
cubin_file=${source_file_no_extension}${ver}.cubin
out_file=${source_file_no_extension}${ver}.out
list_file=${source_file_no_extension}${ver}.list
ptx_file=${source_file_no_extension}${ver}.ptx

nvcc $source_file -I./include ${debug_flags} -o ${cubin_file} -cubin -gencode arch=compute_${ver},code=sm_${ver} -Xptxas -O0 
nvcc $source_file -I./include ${debug_flags} -o ${out_file} -gencode arch=compute_${ver},code=sm_${ver} -Xptxas -O0 
nvcc $source_file -I./include ${debug_flags} -o ${ptx_file} -ptx -gencode arch=compute_${ver},code=sm_${ver} -Xptxas -O0
cuobjdump --dump-sass ${cubin_file} > ${list_file}

# done

elif [ ${source_file_extension} = ptx ]; then

ver=$2
out_file=${source_file_no_extension}${ver}.out
list_file=${source_file_no_extension}${ver}.list

ptxas ${source_file} -o ${out_file} -O0 --gpu-name=sm_${ver}
cuobjdump --dump-sass ${out_file} > ${list_file}

fi 

# nvcc testbranch.cu -o testbranch.cubin -cubin -gencode arch=compute_90,code=sm_90 -Xptxas -O0 

# cuobjdump --dump-sass testbranch.cubin  | vim -

# ptxas brx.ptx -o brx1.out -O0 --gpu-name=sm_90
