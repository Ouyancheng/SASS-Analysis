## Calling Convention in Debug mode (-G -g)
NOTE: Debug mode refers to the flags -G -g passed in nvcc, it is unrelated to optimization flag. 

## Calling Convention in non-debug mode 




## Synchronization mechanism brief dip (static analysis and brief dynamic analysis)

### BRA.CONV and WARPSYNC

### BAR.SYNC and BAR.ARV

### BSSY and BSYNC 






## TODO list (experiments to conduct and lab protocol)

## Caveats (unordered)
1. The generated cubin files will contain some sort of checksum mechanism -- if the file is modified cuobjdump and nvdisasm will refuse to disassemble. 
1. (unsure) ptxas will hang if the ptx file doesn't have an empty terminating line. 
1. cuda-gdb will not perform dynamic disassemble, however you modify the instruction encoding it will not update the disassembly representation. 
1. cuda-gdb works by making the next instruction (instruction pointed by pc) a trap, so x/x $pc will be a trap instruction. 
If you want to see the encoding of the instruction, make sure it's not pointed by pc. 
1. In sm_87 (Jetson Orin), BRX instruction seems to have a bug in hardware -- it will only jump backwards based on the behavior analysis, 
and cuda c compiler (nvcc) never emits such an instruction, regardless how many case branches there are in a switch statement. 
1. The `__constant__` identifier seems like a hint, as we can take a pointer of `__constant__` variable and modify it, using atomic instruction or regular instruction. 
1. In nvcc, passing -Xptxas -O0 can disable (at least some) optimizations conducted by ptxas, thus making more opportunities to observe the target instruction(s).
1. At least in Jetson Orin, cuda-gdb will NOT have the functionalities to inspect the barrier states, e.g., `info cuda barriers` will not work,
and printing the barrier registers will return void, this is the same for all sprs, where reading the cuda-gdb spr will all return void... 
Not sure what's happening. 
