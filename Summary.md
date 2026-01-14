# Summay: SASS Branch Instruction Behavior Analysis 

Lab note order: analysis.md -> calling.md -> braconv.md -> brx.md -> call.md 

Environment: Jetson Orin Nano 

Architecture: Ampere

SM version: sm_87 (notice that this is different from sm_86, but the difference is not significant)

Major difference between sm_87 code and sm_86 code is the initialization of barriers at the beginning of kernel launch, 
otherwise I didn't spot any noticeable difference. 

```
        /*0000*/                   ISETP.NE.U32.AND P0, PT, RZ, UR2, PT ;    /* 0x00000002ff007c0c */
                                                                             /* 0x000fda000bf05070 */
        /*0010*/               @P0 BRA 0x140 ;                               /* 0x0000012000000947 */
                                                                             /* 0x000fea0003800000 */
        /*0020*/                   BMOV.32 B0, 0xffffffff ;                  /* 0xffffffff00007956 */
                                                                             /* 0x000fe80000000000 */
        /*0030*/                   BMOV.32.CLEAR B1, B0 ;                    /* 0x0000000000017f55 */
                                                                             /* 0x000fe80000100000 */
        /*0040*/                   BMOV.32.CLEAR B2, B1 ;                    /* 0x0000000001027f55 */
                                                                             /* 0x000fe80000100000 */
        /*0050*/                   BMOV.32.CLEAR B3, B2 ;                    /* 0x0000000002037f55 */
                                                                             /* 0x000fe80000100000 */
        /*0060*/                   BMOV.32.CLEAR B4, B3 ;                    /* 0x0000000003047f55 */
                                                                             /* 0x000fe80000100000 */
        /*0070*/                   BMOV.32.CLEAR B5, B4 ;                    /* 0x0000000004057f55 */
                                                                             /* 0x000fe80000100000 */
        /*0080*/                   BMOV.32.CLEAR B6, B5 ;                    /* 0x0000000005067f55 */
                                                                             /* 0x000fe80000100000 */
        /*0090*/                   BMOV.32.CLEAR B7, B6 ;                    /* 0x0000000006077f55 */
                                                                             /* 0x000fe80000100000 */
        /*00a0*/                   BMOV.32.CLEAR B8, B7 ;                    /* 0x0000000007087f55 */
                                                                             /* 0x000fe80000100000 */
        /*00b0*/                   BMOV.32.CLEAR B9, B8 ;                    /* 0x0000000008097f55 */
                                                                             /* 0x000fe80000100000 */
        /*00c0*/                   BMOV.32.CLEAR B10, B9 ;                   /* 0x00000000090a7f55 */
                                                                             /* 0x000fe80000100000 */
        /*00d0*/                   BMOV.32.CLEAR B11, B10 ;                  /* 0x000000000a0b7f55 */
                                                                             /* 0x000fe80000100000 */
        /*00e0*/                   BMOV.32.CLEAR B12, B11 ;                  /* 0x000000000b0c7f55 */
                                                                             /* 0x000fe80000100000 */
        /*00f0*/                   BMOV.32.CLEAR B13, B12 ;                  /* 0x000000000c0d7f55 */
                                                                             /* 0x000fe80000100000 */
        /*0100*/                   BMOV.32.CLEAR B14, B13 ;                  /* 0x000000000d0e7f55 */
                                                                             /* 0x000fe80000100000 */
        /*0110*/                   BMOV.32.CLEAR B15, B14 ;                  /* 0x000000000e0f7f55 */
                                                                             /* 0x000fe80000100000 */
        /*0120*/                   BMOV.32 B15, 0x0 ;                        /* 0x000000000f007956 */
                                                                             /* 0x000fe80000000000 */
        /*0130*/                   UMOV UR2, 0x1 ;                           /* 0x0000000100027882 */
                                                                             /* 0x000fe40000000000 */
```


## Types of instructions in scope
- BRA (direct branch, relative) and its variant BRA.CONV
- BRX (indirect branch, relativity will be on detailed analysis)
- CALL.REL (relative call, direct or indirect)
- CALL.ABS (absolute call)
- RET.REL (relative return)
- RET.ABS (absolute return)

## The Behavior of "Absolute" and "Relative"

All the indirect relative jumps are actually "semi-relative", as is explained below.

### BRX Rx (indirect, semi-relative)
NOTE: the term "relative" is NOT relative to the current pc, instead, it's relative to the current kernel binary image's starting point, 
e.g., for the above code snippet, the relative standpoint is the address at the beginning of the following instruction in **actual runtime memory**: 
```
        /*0000*/                   ISETP.NE.U32.AND P0, PT, RZ, UR2, PT ;    /* 0x00000002ff007c0c */<here>
                                                                             /* 0x000fda000bf05070 */
```

### CALL.REL Rx (indirect, semi-relative)
For relative indirect calls, i.e., CALL.REL.NOINC Rx, its relative standpoint is the same as BRX. 
e.g., for the following CALL.REL.NOINC R8: 
```
        /*02d0*/                   CALL.REL.NOINC R8 0x0 ;                            /* 0xfffffd2008007344 */
                                                                                      /* 0x020fea0003c3ffff */
```
When `R8 = 0x280 = 640(Decimal)`, it will jump to address `{kernel_image_start} + 0x280 + 0x10`.

### RET.REL Rx (return, semi-relative)
Ditto.

### CALL.ABS (absolute, direct or indirect)
And absolute call just encode its absolute address *in imm or in register* -- the **actual lower 32-bit of the runtime memory address**, 
the higher 32-bit will follow the current runtime image address.
e.g., a CALL.ABS.NOINC encoded as follows will jump to target address `0x202158100`, which is `{0x0000_0002, 0x02158100}`:
```
(cuda-gdb) x/x 0x0000000202157680 
0x202157680 <_Z9atomicFooPi+640>:	0x00007943
(cuda-gdb) x/x 0x0000000202157684 
0x202157684 <_Z9atomicFooPi+644>:	0x02158100
(cuda-gdb) x/x 0x0000000202157688 
0x202157688 <_Z9atomicFooPi+648>:	0x03c00002
(cuda-gdb) x/x 0x000000020215768c 
0x20215768c <_Z9atomicFooPi+652>:	0x003fde00
```

### RET.ABS (absolute)
Ditto. 

### CALL.REL imm (direct, relative)
The relative standpoint is the current pc, e.g., 
```
        /*0270*/                   CALL.REL.NOINC 0x410 ;                             /* 0x0000019000007944 */
                                                                                      /* 0x001fea0003c00000 */
```
at runtime, this instruction resides in `0x0000000202156670`, when executing this instruction, the pc is at `0x0000000202156680`
and its encoded offset is `0x190`, this instruction jumps to `0x202156810`, which is exactly `0x202156680 + 0x190`.

### BRA (direct, relative)
The BRA instructions are relative jumps, and their relative standpoint are the current pc. This is the same as CALL.REL imm. 

### JMP/JMPX (absolute jumps, direct or indirect)
I didn't see these instructions, but supposely they encode absolute addresses at runtime, just like CALL.ABS. 

## Instruction Behavior

### BRA
```
At BRAInstrAddr: 
    BRA beautified_imm

The encoded imm is at {BRAInstrAddr + 4}, and is a 32-bit imm (the second 32-bit chunk of the BRA instruction). 

The beautified_imm is the offset relative to the starting point of SASS file...

TargetPC = BRAInstrAddr + 0x10 + (signed int32_t extend to int64_t)encoded_imm
```

### CALL.REL.NOINC beautified_imm
```
At CALLInstrAddr: 
    CALL.REL.NOINC beautified_imm

The encoded imm is at {CALLInstrAddr + 4}, and is a 32-bit imm (the second 32-bit chunk of the CALL instruction). 

The beautified_imm is the offset relative to the starting point of SASS file...

TargetPC = CALLInstrAddr + 0x10 + (signed int32_t extend to int64_t)encoded_imm
```

This instruction behaves the same as BRA... **No register is modified across this instruction except for pc**...

### BRX

The BRX instruction works as follows: 
```
At BRXInstrAddr: 
    BRX Rx beautified_imm
The encoded imm is at {BRXInstrAddr + 4}, and is a 32-bit imm (the second 32-bit chunk of the BRX instruction). 
Denote: encoded_imm = *(uint32_t*)(BRXInstrAddr+4)

beautified_imm = encoded_imm - 0x100000000
e.g., 
encoded_imm = 0xfffffbf0, 
beautified_imm = -0x410

Behavior: 
NewPC[63:0] = BRXPC[63:0] + 0x10 + Rx - (int64_t)0x0000_0001_00000000 + (uint32_t ext to int64_t)encoded_imm
```

### RET.REL.NODEC 

The RET instruction works like: 
```
RET.REL.NODEC Rx 0x0 

encoded_imm is the second 32-bit chunk of the RET instruction encoding, 

TargetPC = RETInstrPC + 0x10 + Rx + encoded_imm - 0x100000000 

e.g., 
RET.REL.NODEC R8 0x0; 
        /*0430*/                   RET.REL.NODEC R8 0x0 ;                             /* 0xfffffbc008007950 */
                                                                                      /* 0x000fea0003c3ffff */
encoded_imm = 0xfffffbc0
R8 = 0x280
RETInstrPC = 0x202156830
TargetPC jumps to 0x202156680 

And 
TargetPC = RETInstrPC  + 0x10 + Rx    + encoded_imm - 0x100000000 
         = 0x202156830 + 0x10 + 0x280 + 0xfffffbc0  - 0x100000000
         = 0x202156680

Python: 
>>> hex(0xfffffbc0-0x100000000+0x10+0x280+0x202156830)
'0x202156680'
```

### CALL.REL.NOINC Rx 
```
CALL.REL.NOINC Rx 0x0; 

encoded_imm is the second 32-bit chunk of the CALL instruction encoding, 

TargetPC = INDCALLInstrAddr + 0x10 + Rx + encoded_imm - 0x100000000 
```

### CALL.ABS.NOINC
(Guess work): Jumps to the runtime address of the specified register or immediate encoded in the instruction... No register other than pc is modified...

### RET.ABS.NODEC
(Guess work): Jumps to the runtime address of the specified register encoded in the instruction... No register other than pc is modified...


### BRA.CONV 
Same as BRA, but only jumps if the current warp is convergent!!! This behavior has proven observation!!! 
For information on where this is used, it will be mentioned afterwards. 


## Where CALL.ABS/RET.ABS/JMP/JMPX are used?
They are used in CUDA's debug mode, where kernel launching will perform dynamic relocation upon launching -- all the empty CALL.ABS instructions will be replaced by CALL.ABS with the target runtime memory addresses.

## Typical C-langauge construct how do they compile in -O0

### if-then-else 
```
@p BRA ...
```

### switch-case 
A series of if-statements, CUDA C will never generate any BRX instruction for switch statement for some reason... 

### while-loop 
```
Loop:
    p = ~test
    @p BRA Out 
    ...
    BRA Loop
Out: 
    ...
```

### PTX: barrier.cta.sync / barrier.cta.arrive 
```
    BRA.CONV Converged_BB
    CALL Convergent_procedure(i=imm)
    BRA SYNCED_BB
Converged_BB:
    BAR.SYNC/ARV Bx, imm

SYNCED_BB:
    ...
    ...
    ...

Convergent_procedure(i):
    WARPSYNC 0xffffffff
    BAR.SYNC/ARV Bx, $i
    RET
```

## NOTE 
Note: I've never see any CALL.REL/ABS without the .NOINC, and never see any RET.REL/ABS without the .NODEC, I'm unsure about how this suffix will affect the instruction behavior... 

## Caveats (unordered)
1. The generated cubin files will contain some sort of checksum mechanism -- if the file is modified cuobjdump and nvdisasm will refuse to disassemble. 
1. (unsure) ptxas will hang if the ptx file doesn't have an empty terminating line. 
1. cuda-gdb will not perform dynamic disassemble, however you modify the instruction encoding it will not update the disassembly representation. 
1. cuda-gdb works by making the next instruction (instruction pointed by pc) a trap, so x/x $pc will be a trap instruction. 
If you want to see the encoding of the instruction, make sure it's not pointed by pc. 
1. The `__constant__` identifier seems like a hint, as we can take a pointer of `__constant__` variable and modify it, using atomic instruction or regular instruction. 
1. In nvcc, passing -Xptxas -O0 can disable (at least some) optimizations conducted by ptxas, thus making more opportunities to observe the target instruction(s).
1. At least in Jetson Orin, cuda-gdb will NOT have the functionalities to inspect the barrier states, e.g., `info cuda barriers` will not work,
and printing the barrier registers will return void, this is the same for all sprs, where reading the cuda-gdb spr will all return void... 
Not sure what's happening. 

