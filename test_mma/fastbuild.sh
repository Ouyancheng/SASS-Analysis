#!/bin/bash


source_file=$1
source_file_no_extension=${source_file%.*}
source_file_extension=${source_file##*.}

ver=$2
nodebug_option=$3
debug_flags="-g -G"
if [ "${nodebug_option}" != "" ]; then 
debug_flags=""
echo "no debug ignored, always no debug, option=${nodebug_option} 3=$3"
fi 

debug_flags=""

cubin_file=${source_file_no_extension}${ver}.cubin
out_file=${source_file_no_extension}${ver}.out
list_file=${source_file_no_extension}${ver}.list
ptx_file=${source_file_no_extension}${ver}.ptx

# nvcc $source_file -I./include ${debug_flags} -o ${cubin_file} -cubin -gencode arch=compute_${ver},code=sm_${ver} -Xptxas -O0 
nvcc $source_file -I./include ${debug_flags} -o ${out_file} -gencode arch=compute_${ver},code=sm_${ver} 
#  -Xptxas -O0 
nvcc $source_file -I./include ${debug_flags} -o ${ptx_file} -ptx -gencode arch=compute_${ver},code=sm_${ver} 
#  -Xptxas -O0
cuobjdump --dump-sass ${out_file} > ${list_file}



