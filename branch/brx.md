# brx analysis 

NOTE: ptxas will hang if the ptx file doesn't have an empty line at the end... not sure what's happening... 

NOTE2: in CUDA C, regardless of how many cases are in the switch statement, it will NOT generate any brx instruction, 
instead, it will only generate a series of if-statements. 

See: brx_try.cu and brx_try87.ptx, brx_try.list (SASS). 

The only way I could find that could generate a brx instruction is via a ptx jump table: 
```
.version 8.5
.target sm_87
.address_size 64


.visible .entry testbrx(
    .param .u64 ctx,
    .param .u64 ctx2
)
{
    .reg .pred %p;
    .reg .u32  %op, %pc;
    .reg .u64  %r0, %r1, %maps;

    mov.u32 %pc, 0;
    ld.param.u64 %r0, [ctx2];
    ld.param.u64 %r1, [ctx];

    bra.uni BB_dispatch;

BB_add:
    add.u64 %r0, %r0, %r1;
    add.u32 %pc, %pc, 1;
    bra.uni BB_dispatch;

BB_sub:
    add.u32 %pc, %pc, 2;
    bra.uni BB_dispatch1;


BB_jmpc:
    add.u32 %pc, %pc, 3;
    bra.uni BB_dispatch;

BB_ldmap:
    add.u32 %pc, %pc, 4;
    bra.uni BB_dispatch;



BB_exit:
    ret;

targets: .branchtargets BB_add, BB_sub, BB_ldmap, BB_jmpc, BB_exit;

BB_dispatch:
    // ld.global.u32 %op, [%r1 + 0];
    mov.u32 %op, 4;
BB_dispatch1:
    brx.idx.uni %op, targets;

}
```

This generates: 
```

	code for sm_87
		Function : testbrx
	.headerflags	@"EF_CUDA_TEXMODE_UNIFIED EF_CUDA_64BIT_ADDRESS EF_CUDA_SM87 EF_CUDA_VIRTUAL_SM(EF_CUDA_SM87)"
        /*0000*/                   ISETP.NE.U32.AND P0, PT, RZ, UR2, PT ;  /* 0x00000002ff007c0c */
                                                                           /* 0x000fda000bf05070 */
        /*0010*/               @P0 BRA 0x140 ;                             /* 0x0000012000000947 */
                                                                           /* 0x000fea0003800000 */
        /*0020*/                   BMOV.32 B0, 0xffffffff ;                /* 0xffffffff00007956 */
                                                                           /* 0x000fe80000000000 */
        /*0030*/                   BMOV.32.CLEAR B1, B0 ;                  /* 0x0000000000017f55 */
                                                                           /* 0x000fe80000100000 */
        /*0040*/                   BMOV.32.CLEAR B2, B1 ;                  /* 0x0000000001027f55 */
                                                                           /* 0x000fe80000100000 */
        /*0050*/                   BMOV.32.CLEAR B3, B2 ;                  /* 0x0000000002037f55 */
                                                                           /* 0x000fe80000100000 */
        /*0060*/                   BMOV.32.CLEAR B4, B3 ;                  /* 0x0000000003047f55 */
                                                                           /* 0x000fe80000100000 */
        /*0070*/                   BMOV.32.CLEAR B5, B4 ;                  /* 0x0000000004057f55 */
                                                                           /* 0x000fe80000100000 */
        /*0080*/                   BMOV.32.CLEAR B6, B5 ;                  /* 0x0000000005067f55 */
                                                                           /* 0x000fe80000100000 */
        /*0090*/                   BMOV.32.CLEAR B7, B6 ;                  /* 0x0000000006077f55 */
                                                                           /* 0x000fe80000100000 */
        /*00a0*/                   BMOV.32.CLEAR B8, B7 ;                  /* 0x0000000007087f55 */
                                                                           /* 0x000fe80000100000 */
        /*00b0*/                   BMOV.32.CLEAR B9, B8 ;                  /* 0x0000000008097f55 */
                                                                           /* 0x000fe80000100000 */
        /*00c0*/                   BMOV.32.CLEAR B10, B9 ;                 /* 0x00000000090a7f55 */
                                                                           /* 0x000fe80000100000 */
        /*00d0*/                   BMOV.32.CLEAR B11, B10 ;                /* 0x000000000a0b7f55 */
                                                                           /* 0x000fe80000100000 */
        /*00e0*/                   BMOV.32.CLEAR B12, B11 ;                /* 0x000000000b0c7f55 */
                                                                           /* 0x000fe80000100000 */
        /*00f0*/                   BMOV.32.CLEAR B13, B12 ;                /* 0x000000000c0d7f55 */
                                                                           /* 0x000fe80000100000 */
        /*0100*/                   BMOV.32.CLEAR B14, B13 ;                /* 0x000000000d0e7f55 */
                                                                           /* 0x000fe80000100000 */
        /*0110*/                   BMOV.32.CLEAR B15, B14 ;                /* 0x000000000e0f7f55 */
                                                                           /* 0x000fe80000100000 */
        /*0120*/                   BMOV.32 B15, 0x0 ;                      /* 0x000000000f007956 */
                                                                           /* 0x000fe80000000000 */
        /*0130*/                   UMOV UR2, 0x1 ;                         /* 0x0000000100027882 */
                                                                           /* 0x000fe40000000000 */
        /*0140*/                   MOV R1, c[0x0][0x28] ;                  /* 0x00000a0000017a02 */
                                                                           /* 0x003fde0000000f00 */
        /*0150*/                   MOV R0, RZ ;                            /* 0x000000ff00007202 */
                                                                           /* 0x003fde0000000f00 */
        /*0160*/                   MOV R2, 0x8 ;                           /* 0x0000000800027802 */
                                                                           /* 0x003fde0000000f00 */
        /*0170*/                   LDC.64 R2, c[0x0][R2+0x160] ;           /* 0x0000580002027b82 */
                                                                           /* 0x00321e0000000a00 */
        /*0180*/                   MOV R7, R2 ;                            /* 0x0000000200077202 */
                                                                           /* 0x003fde0000000f00 */
        /*0190*/                   MOV R8, R3 ;                            /* 0x0000000300087202 */
                                                                           /* 0x003fde0000000f00 */
        /*01a0*/                   MOV R7, R7 ;                            /* 0x0000000700077202 */
                                                                           /* 0x003fde0000000f00 */
        /*01b0*/                   MOV R8, R8 ;                            /* 0x0000000800087202 */
                                                                           /* 0x003fde0000000f00 */
        /*01c0*/                   MOV R2, RZ ;                            /* 0x000000ff00027202 */
                                                                           /* 0x003fde0000000f00 */
        /*01d0*/                   LDC.64 R2, c[0x0][R2+0x160] ;           /* 0x0000580002027b82 */
                                                                           /* 0x00321e0000000a00 */
        /*01e0*/                   MOV R5, R2 ;                            /* 0x0000000200057202 */
                                                                           /* 0x003fde0000000f00 */
        /*01f0*/                   MOV R6, R3 ;                            /* 0x0000000300067202 */
                                                                           /* 0x003fde0000000f00 */
        /*0200*/                   MOV R5, R5 ;                            /* 0x0000000500057202 */
                                                                           /* 0x003fde0000000f00 */
        /*0210*/                   MOV R6, R6 ;                            /* 0x0000000600067202 */
                                                                           /* 0x003fde0000000f00 */
        /*0220*/                   MOV R0, R0 ;                            /* 0x0000000000007202 */
                                                                           /* 0x003fde0000000f00 */
        /*0230*/                   MOV R7, R7 ;                            /* 0x0000000700077202 */
                                                                           /* 0x003fde0000000f00 */
        /*0240*/                   MOV R8, R8 ;                            /* 0x0000000800087202 */
                                                                           /* 0x003fde0000000f00 */
        /*0250*/                   MOV R5, R5 ;                            /* 0x0000000500057202 */
                                                                           /* 0x003fde0000000f00 */
        /*0260*/                   MOV R6, R6 ;                            /* 0x0000000600067202 */
                                                                           /* 0x003fde0000000f00 */
        /*0270*/                   BRA 0x390 ;                             /* 0x0000011000007947 */
                                                                           /* 0x003fde0003800000 */
        /*0280*/                   IADD3 R2, P0, R7, R5, RZ ;              /* 0x0000000507027210 */
                                                                           /* 0x003fde0007f1e0ff */
        /*0290*/                   IADD3.X R3, R8, R6, RZ, P0, !PT ;       /* 0x0000000608037210 */
                                                                           /* 0x003fde00007fe4ff */
        /*02a0*/                   IADD3 R0, R0, 0x1, RZ ;                 /* 0x0000000100007810 */
                                                                           /* 0x003fde0007ffe0ff */
        /*02b0*/                   MOV R7, R2 ;                            /* 0x0000000200077202 */
                                                                           /* 0x003fde0000000f00 */
        /*02c0*/                   MOV R8, R3 ;                            /* 0x0000000300087202 */
                                                                           /* 0x003fde0000000f00 */
        /*02d0*/                   MOV R0, R0 ;                            /* 0x0000000000007202 */
                                                                           /* 0x003fde0000000f00 */
        /*02e0*/                   BRA 0x390 ;                             /* 0x000000a000007947 */
                                                                           /* 0x003fde0003800000 */
        /*02f0*/                   IADD3 R0, R0, 0x2, RZ ;                 /* 0x0000000200007810 */
                                                                           /* 0x003fde0007ffe0ff */
        /*0300*/                   MOV R0, R0 ;                            /* 0x0000000000007202 */
                                                                           /* 0x003fde0000000f00 */
        /*0310*/                   BRA 0x3b0 ;                             /* 0x0000009000007947 */
                                                                           /* 0x003fde0003800000 */
        /*0320*/                   IADD3 R0, R0, 0x3, RZ ;                 /* 0x0000000300007810 */
                                                                           /* 0x003fde0007ffe0ff */
        /*0330*/                   MOV R0, R0 ;                            /* 0x0000000000007202 */
                                                                           /* 0x003fde0000000f00 */
        /*0340*/                   BRA 0x390 ;                             /* 0x0000004000007947 */
                                                                           /* 0x003fde0003800000 */
        /*0350*/                   IADD3 R0, R0, 0x4, RZ ;                 /* 0x0000000400007810 */
                                                                           /* 0x003fde0007ffe0ff */
        /*0360*/                   MOV R0, R0 ;                            /* 0x0000000000007202 */
                                                                           /* 0x003fde0000000f00 */
        /*0370*/                   BRA 0x390 ;                             /* 0x0000001000007947 */
                                                                           /* 0x003fde0003800000 */
        /*0380*/                   EXIT ;                                  /* 0x000000000000794d */
                                                                           /* 0x003fde0003800000 */
        /*0390*/                   MOV R2, 0x4 ;                           /* 0x0000000400027802 */
                                                                           /* 0x003fde0000000f00 */
        /*03a0*/                   MOV R4, R2 ;                            /* 0x0000000200047202 */
                                                                           /* 0x003fde0000000f00 */
        /*03b0*/                   SHF.L.U32 R2, R4, 0x2, RZ ;             /* 0x0000000204027819 */
                                                                           /* 0x003fde00000006ff */
        /*03c0*/                   LDC R2, c[0x2][R2] ;                    /* 0x0080000002027b82 */
                                                                           /* 0x00321e0000000800 */
        /*03d0*/                   SHF.R.S32.HI R3, RZ, 0x1f, R2 ;         /* 0x0000001fff037819 */
                                                                           /* 0x003fde0000011402 */
        /*03e0*/                   MOV R2, R2 ;                            /* 0x0000000200027202 */
                                                                           /* 0x003fde0000000f00 */
        /*03f0*/                   MOV R3, R3 ;                            /* 0x0000000300037202 */
                                                                           /* 0x003fde0000000f00 */
        /*0400*/                   BRX R2 -0x410 ;                         /* 0xfffffbf002007949 */
                                                                           /* 0x003fde000383ffff */
        /*0410*/                   EXIT ;                                  /* 0x000000000000794d */
                                                                           /* 0x003fde0003800000 */
        /*0420*/                   BRA 0x420;                              /* 0xfffffff000007947 */
                                                                           /* 0x000fc0000383ffff */
        /*0430*/                   NOP;                                    /* 0x0000000000007918 */
                                                                           /* 0x000fc00000000000 */
        /*0440*/                   NOP;                                    /* 0x0000000000007918 */
                                                                           /* 0x000fc00000000000 */
        /*0450*/                   NOP;                                    /* 0x0000000000007918 */
                                                                           /* 0x000fc00000000000 */
        /*0460*/                   NOP;                                    /* 0x0000000000007918 */
                                                                           /* 0x000fc00000000000 */
        /*0470*/                   NOP;                                    /* 0x0000000000007918 */
                                                                           /* 0x000fc00000000000 */
        /*0480*/                   NOP;                                    /* 0x0000000000007918 */
                                                                           /* 0x000fc00000000000 */
        /*0490*/                   NOP;                                    /* 0x0000000000007918 */
                                                                           /* 0x000fc00000000000 */
        /*04a0*/                   NOP;                                    /* 0x0000000000007918 */
                                                                           /* 0x000fc00000000000 */
        /*04b0*/                   NOP;                                    /* 0x0000000000007918 */
                                                                           /* 0x000fc00000000000 */
        /*04c0*/                   NOP;                                    /* 0x0000000000007918 */
                                                                           /* 0x000fc00000000000 */
        /*04d0*/                   NOP;                                    /* 0x0000000000007918 */
                                                                           /* 0x000fc00000000000 */
        /*04e0*/                   NOP;                                    /* 0x0000000000007918 */
                                                                           /* 0x000fc00000000000 */
        /*04f0*/                   NOP;                                    /* 0x0000000000007918 */
                                                                           /* 0x000fc00000000000 */
		..........
```

If we look at instruction 
```
        /*0400*/                   BRX R2 -0x410 ;                         /* 0xfffffbf002007949 */
                                                                           /* 0x003fde000383ffff */
```
Notice that -0x410 in int32 two-complement representation is 0xfffffbf0, i.e., the second 32-bit chunk of the instruction. 

This may denote that BRX is actually a relative jump, for which R2 is the relative address and -0x4b0 is the relative offset... 

So, BRX Rx, imm may jump to: $pc+$Rx+imm, where $pc is the $pc pointing to the next instruction...
In this case, BRX R2, -(next instruction address) emulates an absolute jump, because the pc cancels out with the imm...

We can check this in cuda-gdb... 

by overwriting the second 32-bit chunk of the instruction, and see where it jumps... 

```
jetson@yahboom:~/workspace/experiment/branch/brx$ cuda-gdb brx87.out 
NVIDIA (R) cuda-gdb 12.6
Portions Copyright (C) 2007-2024 NVIDIA Corporation
Based on GNU gdb 13.2
Copyright (C) 2023 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
Type "show copying" and "show warranty" for details.
This CUDA-GDB was configured as "aarch64-elf-linux-gnu".
Type "show configuration" for configuration details.
For bug reporting instructions, please see:
<https://forums.developer.nvidia.com/c/developer-tools/cuda-developer-tools/cuda-gdb>.
Find the CUDA-GDB manual and other documentation resources online at:
    <https://docs.nvidia.com/cuda/cuda-gdb/index.html>.

For help, type "help".
Type "apropos word" to search for commands related to "word"...
Reading symbols from brx87.out...
(No debugging symbols found in brx87.out)
(cuda-gdb) set cuda break_on_launch application 
(cuda-gdb) run 
Starting program: /home/jetson/workspace/experiment/branch/brx/brx87.out 
[Thread debugging using libthread_db enabled]
Using host libthread_db library "/lib/aarch64-linux-gnu/libthread_db.so.1".
[New Thread 0xfffff470c840 (LWP 51571)]
[Detaching after fork from child process 51572]
checking line 16
checking line 20
[New Thread 0xfffff3e0b840 (LWP 51579)]
checking line 24
checking line 28
checking line 32
malloc done, pending param construct...
malloc done, pending kernel launch...
checking line 61
[Switching focus to CUDA kernel 0, grid 1, block (0,0,0), thread (0,0,0), device 0, sm 0, warp 0, lane 0]

CUDA thread hit application kernel entry function breakpoint, 0x0000000202156400 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) disas 
Dump of assembler code for function testbrx:
=> 0x0000000202156400 <+0>:	ISETP.NE.U32.AND P0, PT, RZ, UR2, PT 
   0x0000000202156410 <+16>:	@P0 BRA 0x140 
   0x0000000202156420 <+32>:	BMOV.32 B0, 0xffffffff 
   0x0000000202156430 <+48>:	BMOV.32.CLEAR B1, B0 
   0x0000000202156440 <+64>:	BMOV.32.CLEAR B2, B1 
   0x0000000202156450 <+80>:	BMOV.32.CLEAR B3, B2 
   0x0000000202156460 <+96>:	BMOV.32.CLEAR B4, B3 
   0x0000000202156470 <+112>:	BMOV.32.CLEAR B5, B4 
   0x0000000202156480 <+128>:	BMOV.32.CLEAR B6, B5 
   0x0000000202156490 <+144>:	BMOV.32.CLEAR B7, B6 
   0x00000002021564a0 <+160>:	BMOV.32.CLEAR B8, B7 
   0x00000002021564b0 <+176>:	BMOV.32.CLEAR B9, B8 
   0x00000002021564c0 <+192>:	BMOV.32.CLEAR B10, B9 
   0x00000002021564d0 <+208>:	BMOV.32.CLEAR B11, B10 
   0x00000002021564e0 <+224>:	BMOV.32.CLEAR B12, B11 
   0x00000002021564f0 <+240>:	BMOV.32.CLEAR B13, B12 
   0x0000000202156500 <+256>:	BMOV.32.CLEAR B14, B13 
   0x0000000202156510 <+272>:	BMOV.32.CLEAR B15, B14 
   0x0000000202156520 <+288>:	BMOV.32 B15, 0x0 
   0x0000000202156530 <+304>:	UMOV UR2, 0x1 
   0x0000000202156540 <+320>:	MOV R1, c[0x0][0x28] 
   0x0000000202156550 <+336>:	MOV R0, RZ 
   0x0000000202156560 <+352>:	MOV R2, 0x8 
   0x0000000202156570 <+368>:	LDC.64 R2, c[0x0][R2+0x160] 
   0x0000000202156580 <+384>:	MOV R7, R2 
   0x0000000202156590 <+400>:	MOV R8, R3 
   0x00000002021565a0 <+416>:	MOV R7, R7 
   0x00000002021565b0 <+432>:	MOV R8, R8 
   0x00000002021565c0 <+448>:	MOV R2, RZ 
   0x00000002021565d0 <+464>:	LDC.64 R2, c[0x0][R2+0x160] 
   0x00000002021565e0 <+480>:	MOV R5, R2 
   0x00000002021565f0 <+496>:	MOV R6, R3 
   0x0000000202156600 <+512>:	MOV R5, R5 
   0x0000000202156610 <+528>:	MOV R6, R6 
   0x0000000202156620 <+544>:	MOV R0, R0 
   0x0000000202156630 <+560>:	MOV R7, R7 
   0x0000000202156640 <+576>:	MOV R8, R8 
   0x0000000202156650 <+592>:	MOV R5, R5 
   0x0000000202156660 <+608>:	MOV R6, R6 
   0x0000000202156670 <+624>:	BRA 0x390 
   0x0000000202156680 <+640>:	IADD3 R2, P0, R7, R5, RZ 
--Type <RET> for more, q to quit, c to continue without paging--
   0x0000000202156690 <+656>:	IADD3.X R3, R8, R6, RZ, P0, !PT 
   0x00000002021566a0 <+672>:	IADD3 R0, R0, 0x1, RZ 
   0x00000002021566b0 <+688>:	MOV R7, R2 
   0x00000002021566c0 <+704>:	MOV R8, R3 
   0x00000002021566d0 <+720>:	MOV R0, R0 
   0x00000002021566e0 <+736>:	BRA 0x390 
   0x00000002021566f0 <+752>:	IADD3 R0, R0, 0x2, RZ 
   0x0000000202156700 <+768>:	MOV R0, R0 
   0x0000000202156710 <+784>:	BRA 0x3b0 
   0x0000000202156720 <+800>:	IADD3 R0, R0, 0x3, RZ 
   0x0000000202156730 <+816>:	MOV R0, R0 
   0x0000000202156740 <+832>:	BRA 0x390 
   0x0000000202156750 <+848>:	IADD3 R0, R0, 0x4, RZ 
   0x0000000202156760 <+864>:	MOV R0, R0 
   0x0000000202156770 <+880>:	BRA 0x390 
   0x0000000202156780 <+896>:	EXIT 
   0x0000000202156790 <+912>:	MOV R2, 0x4 
   0x00000002021567a0 <+928>:	MOV R4, R2 
   0x00000002021567b0 <+944>:	SHF.L.U32 R2, R4, 0x2, RZ 
   0x00000002021567c0 <+960>:	LDC R2, c[0x2][R2] 
   0x00000002021567d0 <+976>:	SHF.R.S32.HI R3, RZ, 0x1f, R2 
   0x00000002021567e0 <+992>:	MOV R2, R2 
   0x00000002021567f0 <+1008>:	MOV R3, R3 
   0x0000000202156800 <+1024>:	BRX R2 -0x410 
   0x0000000202156810 <+1040>:	EXIT 
   0x0000000202156820 <+1056>:	BRA 0x420
   0x0000000202156830 <+1072>:	NOP
   0x0000000202156840 <+1088>:	NOP
   0x0000000202156850 <+1104>:	NOP
   0x0000000202156860 <+1120>:	NOP
   0x0000000202156870 <+1136>:	NOP
   0x0000000202156880 <+1152>:	NOP
   0x0000000202156890 <+1168>:	NOP
   0x00000002021568a0 <+1184>:	NOP
   0x00000002021568b0 <+1200>:	NOP
   0x00000002021568c0 <+1216>:	NOP
   0x00000002021568d0 <+1232>:	NOP
   0x00000002021568e0 <+1248>:	NOP
   0x00000002021568f0 <+1264>:	NOP
End of assembler dump.
(cuda-gdb) 
```

Run to the BRX instruction: 
```
(cuda-gdb) si
0x0000000202156410 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156410 <testbrx+16>:	@P0 BRA 0x140 
(cuda-gdb) si
0x0000000202156540 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156540 <testbrx+320>:	MOV R1, c[0x0][0x28] 
(cuda-gdb) si     
0x0000000202156550 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156550 <testbrx+336>:	MOV R0, RZ 
(cuda-gdb) si     
0x0000000202156560 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156560 <testbrx+352>:	MOV R2, 0x8 
(cuda-gdb) si     
0x0000000202156570 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156570 <testbrx+368>:	LDC.64 R2, c[0x0][R2+0x160] 
(cuda-gdb) si     
0x0000000202156580 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156580 <testbrx+384>:	MOV R7, R2 
(cuda-gdb) si     
0x0000000202156590 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156590 <testbrx+400>:	MOV R8, R3 
(cuda-gdb) si     
0x00000002021565a0 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x2021565a0 <testbrx+416>:	MOV R7, R7 
(cuda-gdb) si     
0x00000002021565b0 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x2021565b0 <testbrx+432>:	MOV R8, R8 
(cuda-gdb) si     
0x00000002021565c0 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x2021565c0 <testbrx+448>:	MOV R2, RZ 
(cuda-gdb) si     
0x00000002021565d0 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x2021565d0 <testbrx+464>:	LDC.64 R2, c[0x0][R2+0x160] 
(cuda-gdb) si     
0x00000002021565e0 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x2021565e0 <testbrx+480>:	MOV R5, R2 
(cuda-gdb) si     
0x00000002021565f0 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x2021565f0 <testbrx+496>:	MOV R6, R3 
(cuda-gdb) si     
0x0000000202156600 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156600 <testbrx+512>:	MOV R5, R5 
(cuda-gdb) si     
0x0000000202156610 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156610 <testbrx+528>:	MOV R6, R6 
(cuda-gdb) si     
0x0000000202156620 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156620 <testbrx+544>:	MOV R0, R0 
(cuda-gdb) si     
0x0000000202156630 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156630 <testbrx+560>:	MOV R7, R7 
(cuda-gdb) si     
0x0000000202156640 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156640 <testbrx+576>:	MOV R8, R8 
(cuda-gdb) si     
0x0000000202156650 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156650 <testbrx+592>:	MOV R5, R5 
(cuda-gdb) si     
0x0000000202156660 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156660 <testbrx+608>:	MOV R6, R6 
(cuda-gdb) si     
0x0000000202156670 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156670 <testbrx+624>:	BRA 0x390 
(cuda-gdb) si     
0x0000000202156790 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156790 <testbrx+912>:	MOV R2, 0x4 
(cuda-gdb) si     
0x00000002021567a0 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x2021567a0 <testbrx+928>:	MOV R4, R2 
(cuda-gdb) si     
0x00000002021567b0 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x2021567b0 <testbrx+944>:	SHF.L.U32 R2, R4, 0x2, RZ 
(cuda-gdb) si     
0x00000002021567c0 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x2021567c0 <testbrx+960>:	LDC R2, c[0x2][R2] 
(cuda-gdb) si     
0x00000002021567d0 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x2021567d0 <testbrx+976>:	SHF.R.S32.HI R3, RZ, 0x1f, R2 
(cuda-gdb) si     
0x00000002021567e0 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x2021567e0 <testbrx+992>:	MOV R2, R2 
(cuda-gdb) si     
0x00000002021567f0 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x2021567f0 <testbrx+1008>:	MOV R3, R3 
(cuda-gdb) si     
0x0000000202156800 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156800 <testbrx+1024>:	BRX R2 -0x410 
(cuda-gdb) info register 
pc             0x202156800         0x202156800 <testbrx+1024>
errorpc        <unavailable>
R0             0x0                 0
R1             0xfffdc0            16776640
R2             0x380               896
R3             0x0                 0
R4             0x4                 4
R5             0x50e0000           84803584
R6             0x2                 2
R7             0x20                32
R8             0x0                 0
R9             0x0                 0
R10            0x0                 0
R11            0x0                 0
R12            0x0                 0
R13            0x0                 0
R14            0x0                 0
R15            0x0                 0
R16            0x0                 0
R17            0x0                 0
R18            0x0                 0
R19            0x0                 0
R20            0x0                 0
R21            0x0                 0
R22            0x0                 0
R23            0x0                 0
R24            0x0                 0
R25            0x0                 0
R26            0x0                 0
R27            0x0                 0
R28            0x0                 0
R29            0x0                 0
R30            0x0                 0
R31            0x0                 0
R32            0x0                 0
R33            0x0                 0
R34            0x0                 0
R35            0x0                 0
R36            0x0                 0
R37            0x0                 0
R38            0x0                 0
R39            0x0                 0
--Type <RET> for more, q to quit, c to continue without paging--c
R40            0x0                 0
R41            0x0                 0
R42            0x0                 0
R43            0x0                 0
R44            0x0                 0
R45            0x0                 0
R46            0x0                 0
R47            0x0                 0
R48            0x0                 0
R49            0x0                 0
R50            0x0                 0
R51            0x0                 0
R52            0x0                 0
R53            0x0                 0
R54            0x0                 0
R55            0x0                 0
R56            0x0                 0
R57            0x0                 0
R58            0x0                 0
R59            0x0                 0
R60            0x0                 0
R61            0x0                 0
R62            0x0                 0
R63            0x0                 0
R64            0x0                 0
R65            0x0                 0
R66            0x0                 0
R67            0x0                 0
R68            0x0                 0
R69            0x0                 0
R70            0x0                 0
R71            0x0                 0
R72            0x0                 0
R73            0x0                 0
R74            0x0                 0
R75            0x0                 0
R76            0x0                 0
R77            0x0                 0
R78            0x0                 0
R79            0x0                 0
R80            0x0                 0
R81            0x0                 0
R82            0x0                 0
R83            0x0                 0
R84            0x0                 0
R85            0x0                 0
R86            0x0                 0
R87            0x0                 0
R88            0x0                 0
R89            0x0                 0
R90            0x0                 0
R91            0x0                 0
R92            0x0                 0
R93            0x0                 0
R94            0x0                 0
R95            0x0                 0
R96            0x0                 0
R97            0x0                 0
R98            0x0                 0
R99            0x0                 0
R100           0x0                 0
R101           0x0                 0
R102           0x0                 0
R103           0x0                 0
R104           0x0                 0
R105           0x0                 0
R106           0x0                 0
R107           0x0                 0
R108           0x0                 0
R109           0x0                 0
R110           0x0                 0
R111           0x0                 0
R112           0x0                 0
R113           0x0                 0
R114           0x0                 0
R115           0x0                 0
R116           0x0                 0
R117           0x0                 0
R118           0x0                 0
R119           0x0                 0
R120           0x0                 0
R121           0x0                 0
R122           0x0                 0
R123           0x0                 0
R124           0x0                 0
R125           0x0                 0
R126           0x0                 0
R127           0x0                 0
R128           0x0                 0
R129           0x0                 0
R130           0x0                 0
R131           0x0                 0
R132           0x0                 0
R133           0x0                 0
R134           0x0                 0
R135           0x0                 0
R136           0x0                 0
R137           0x0                 0
R138           0x0                 0
R139           0x0                 0
R140           0x0                 0
R141           0x0                 0
R142           0x0                 0
R143           0x0                 0
R144           0x0                 0
R145           0x0                 0
R146           0x0                 0
R147           0x0                 0
R148           0x0                 0
R149           0x0                 0
R150           0x0                 0
R151           0x0                 0
R152           0x0                 0
R153           0x0                 0
R154           0x0                 0
R155           0x0                 0
R156           0x0                 0
R157           0x0                 0
R158           0x0                 0
R159           0x0                 0
R160           0x0                 0
R161           0x0                 0
R162           0x0                 0
R163           0x0                 0
R164           0x0                 0
R165           0x0                 0
R166           0x0                 0
R167           0x0                 0
R168           0x0                 0
R169           0x0                 0
R170           0x0                 0
R171           0x0                 0
R172           0x0                 0
R173           0x0                 0
R174           0x0                 0
R175           0x0                 0
R176           0x0                 0
R177           0x0                 0
R178           0x0                 0
R179           0x0                 0
R180           0x0                 0
R181           0x0                 0
R182           0x0                 0
R183           0x0                 0
R184           0x0                 0
R185           0x0                 0
R186           0x0                 0
R187           0x0                 0
R188           0x0                 0
R189           0x0                 0
R190           0x0                 0
R191           0x0                 0
R192           0x0                 0
R193           0x0                 0
R194           0x0                 0
R195           0x0                 0
R196           0x0                 0
R197           0x0                 0
R198           0x0                 0
R199           0x0                 0
R200           0x0                 0
R201           0x0                 0
R202           0x0                 0
R203           0x0                 0
R204           0x0                 0
R205           0x0                 0
R206           0x0                 0
R207           0x0                 0
R208           0x0                 0
R209           0x0                 0
R210           0x0                 0
R211           0x0                 0
R212           0x0                 0
R213           0x0                 0
R214           0x0                 0
R215           0x0                 0
R216           0x0                 0
R217           0x0                 0
R218           0x0                 0
R219           0x0                 0
R220           0x0                 0
R221           0x0                 0
R222           0x0                 0
R223           0x0                 0
R224           0x0                 0
R225           0x0                 0
R226           0x0                 0
R227           0x0                 0
R228           0x0                 0
R229           0x0                 0
R230           0x0                 0
R231           0x0                 0
R232           0x0                 0
R233           0x0                 0
R234           0x0                 0
R235           0x0                 0
R236           0x0                 0
R237           0x0                 0
R238           0x0                 0
R239           0x0                 0
R240           0x0                 0
R241           0x0                 0
R242           0x0                 0
R243           0x0                 0
R244           0x0                 0
R245           0x0                 0
R246           0x0                 0
R247           0x0                 0
R248           0x0                 0
R249           0x0                 0
R250           0x0                 0
R251           0x0                 0
R252           0x0                 0
R253           0x0                 0
R254           0x0                 0
RZ             0x0                 0
P0             0x1                 1
P1             0x0                 0
P2             0x0                 0
P3             0x0                 0
P4             0x0                 0
P5             0x0                 0
P6             0x0                 0
P7             0x1                 1
UR0            0x0                 0
UR1            0x0                 0
UR2            0x10                16
UR3            0x0                 0
UR4            0x0                 0
UR5            0x0                 0
UR6            0x0                 0
UR7            0x0                 0
UR8            0x0                 0
UR9            0x0                 0
UR10           0x0                 0
UR11           0x0                 0
UR12           0x0                 0
UR13           0x0                 0
UR14           0x0                 0
UR15           0x0                 0
UR16           0x0                 0
UR17           0x0                 0
UR18           0x0                 0
UR19           0x0                 0
UR20           0x0                 0
UR21           0x0                 0
UR22           0x0                 0
UR23           0x0                 0
UR24           0x0                 0
UR25           0x0                 0
UR26           0x0                 0
UR27           0x0                 0
UR28           0x0                 0
UR29           0x0                 0
UR30           0x0                 0
UR31           0x0                 0
UR32           0x0                 0
UR33           0x0                 0
UR34           0x0                 0
UR35           0x0                 0
UR36           0x0                 0
UR37           0x0                 0
UR38           0x0                 0
UR39           0x0                 0
UR40           0x0                 0
UR41           0x0                 0
UR42           0x0                 0
UR43           0x0                 0
UR44           0x0                 0
UR45           0x0                 0
UR46           0x0                 0
UR47           0x0                 0
UR48           0x0                 0
UR49           0x0                 0
UR50           0x0                 0
UR51           0x0                 0
UR52           0x0                 0
UR53           0x0                 0
UR54           0x0                 0
UR55           0x0                 0
UR56           0x0                 0
UR57           0x0                 0
UR58           0x0                 0
UR59           0x0                 0
UR60           0x0                 0
UR61           0x0                 0
UR62           0x0                 0
URZ            0x0                 0
UP0            0x0                 0
UP1            0x0                 0
UP2            0x0                 0
UP3            0x0                 0
UP4            0x0                 0
UP5            0x0                 0
UP6            0x0                 0
UP7            0x1                 1
CC             0x0                 0
(cuda-gdb) 
```

As we can see, R2 is 0x380, and BRX encoding is: 
```
(cuda-gdb) x/i $pc
=> 0x202156800 <testbrx+1024>:	BRX R2 -0x410 

(cuda-gdb) x/x (int*)0x202156800 
0x202156800 <testbrx+1024>:	0x02007949
(cuda-gdb) x/x (int*)0x202156804 
0x202156804 <testbrx+1028>:	0xfffffbf0
(cuda-gdb) x/x (int*)0x202156808 
0x202156808 <testbrx+1032>:	0x0383ffff
(cuda-gdb) x/x (int*)0x20215680c 
0x20215680c <testbrx+1036>:	0x003fde00
(cuda-gdb) 

```

This is consistent with the SASS dump.

And after running it, it jumps to the exit block: 
```
(cuda-gdb) p/x $pc
$2 = 0x202156800
(cuda-gdb) si     
0x0000000202156780 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156780 <testbrx+896>:	EXIT 
(cuda-gdb) 
```

So, $R2 = 0x380, BRX R2 -0x410 at 0x202156800 jumps to 0x202156780. 

Notice that R2 - 0x410 = 0x380 - 0x410 = -0x90. 
And hex(0x202156800-0x90+0x10) = '0x202156780'

Proposed behaviour is: 
```
NewPC = BRXPC + 0x10 + Rx + imm
```

Let's run again and modify the BRX instruction. 

```
jetson@yahboom:~/workspace/experiment/branch/brx$ cuda-gdb brx87.out 
NVIDIA (R) cuda-gdb 12.6
Portions Copyright (C) 2007-2024 NVIDIA Corporation
Based on GNU gdb 13.2
Copyright (C) 2023 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
Type "show copying" and "show warranty" for details.
This CUDA-GDB was configured as "aarch64-elf-linux-gnu".
Type "show configuration" for configuration details.
For bug reporting instructions, please see:
<https://forums.developer.nvidia.com/c/developer-tools/cuda-developer-tools/cuda-gdb>.
Find the CUDA-GDB manual and other documentation resources online at:
    <https://docs.nvidia.com/cuda/cuda-gdb/index.html>.

For help, type "help".
Type "apropos word" to search for commands related to "word"...
Reading symbols from brx87.out...
(No debugging symbols found in brx87.out)
(cuda-gdb) set cuda break_on_launch application 
(cuda-gdb) run 
Starting program: /home/jetson/workspace/experiment/branch/brx/brx87.out 
[Thread debugging using libthread_db enabled]
Using host libthread_db library "/lib/aarch64-linux-gnu/libthread_db.so.1".
[New Thread 0xfffff470c840 (LWP 59130)]
[Detaching after fork from child process 59131]
checking line 16
checking line 20
[New Thread 0xfffff3e0b840 (LWP 59137)]
checking line 24
checking line 28
checking line 32
malloc done, pending param construct...
malloc done, pending kernel launch...
checking line 61
[Switching focus to CUDA kernel 0, grid 1, block (0,0,0), thread (0,0,0), device 0, sm 0, warp 0, lane 0]

CUDA thread hit application kernel entry function breakpoint, 0x0000000202156400 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) disas 
Dump of assembler code for function testbrx:

=> 0x0000000202156400 <+0>:	ISETP.NE.U32.AND P0, PT, RZ, UR2, PT 
   0x0000000202156410 <+16>:	@P0 BRA 0x140 
   0x0000000202156420 <+32>:	BMOV.32 B0, 0xffffffff 
   0x0000000202156430 <+48>:	BMOV.32.CLEAR B1, B0 
   0x0000000202156440 <+64>:	BMOV.32.CLEAR B2, B1 
   0x0000000202156450 <+80>:	BMOV.32.CLEAR B3, B2 
   0x0000000202156460 <+96>:	BMOV.32.CLEAR B4, B3 
   0x0000000202156470 <+112>:	BMOV.32.CLEAR B5, B4 
   0x0000000202156480 <+128>:	BMOV.32.CLEAR B6, B5 
   0x0000000202156490 <+144>:	BMOV.32.CLEAR B7, B6 
   0x00000002021564a0 <+160>:	BMOV.32.CLEAR B8, B7 
   0x00000002021564b0 <+176>:	BMOV.32.CLEAR B9, B8 
   0x00000002021564c0 <+192>:	BMOV.32.CLEAR B10, B9 
   0x00000002021564d0 <+208>:	BMOV.32.CLEAR B11, B10 
   0x00000002021564e0 <+224>:	BMOV.32.CLEAR B12, B11 
   0x00000002021564f0 <+240>:	BMOV.32.CLEAR B13, B12 
   0x0000000202156500 <+256>:	BMOV.32.CLEAR B14, B13 
   0x0000000202156510 <+272>:	BMOV.32.CLEAR B15, B14 
   0x0000000202156520 <+288>:	BMOV.32 B15, 0x0 
   0x0000000202156530 <+304>:	UMOV UR2, 0x1 
   0x0000000202156540 <+320>:	MOV R1, c[0x0][0x28] 
   0x0000000202156550 <+336>:	MOV R0, RZ 
   0x0000000202156560 <+352>:	MOV R2, 0x8 
   0x0000000202156570 <+368>:	LDC.64 R2, c[0x0][R2+0x160] 
   0x0000000202156580 <+384>:	MOV R7, R2 
   0x0000000202156590 <+400>:	MOV R8, R3 
   0x00000002021565a0 <+416>:	MOV R7, R7 
   0x00000002021565b0 <+432>:	MOV R8, R8 
   0x00000002021565c0 <+448>:	MOV R2, RZ 
   0x00000002021565d0 <+464>:	LDC.64 R2, c[0x0][R2+0x160] 
   0x00000002021565e0 <+480>:	MOV R5, R2 
   0x00000002021565f0 <+496>:	MOV R6, R3 
   0x0000000202156600 <+512>:	MOV R5, R5 
   0x0000000202156610 <+528>:	MOV R6, R6 
   0x0000000202156620 <+544>:	MOV R0, R0 
   0x0000000202156630 <+560>:	MOV R7, R7 
   0x0000000202156640 <+576>:	MOV R8, R8 
   0x0000000202156650 <+592>:	MOV R5, R5 
   0x0000000202156660 <+608>:	MOV R6, R6 
   0x0000000202156670 <+624>:	BRA 0x390 
   0x0000000202156680 <+640>:	IADD3 R2, P0, R7, R5, RZ 
--Type <RET> for more, q to quit, c to continue without paging--
   0x0000000202156690 <+656>:	IADD3.X R3, R8, R6, RZ, P0, !PT 
   0x00000002021566a0 <+672>:	IADD3 R0, R0, 0x1, RZ 
   0x00000002021566b0 <+688>:	MOV R7, R2 
   0x00000002021566c0 <+704>:	MOV R8, R3 
   0x00000002021566d0 <+720>:	MOV R0, R0 
   0x00000002021566e0 <+736>:	BRA 0x390 
   0x00000002021566f0 <+752>:	IADD3 R0, R0, 0x2, RZ 
   0x0000000202156700 <+768>:	MOV R0, R0 
   0x0000000202156710 <+784>:	BRA 0x3b0 
   0x0000000202156720 <+800>:	IADD3 R0, R0, 0x3, RZ 
   0x0000000202156730 <+816>:	MOV R0, R0 
   0x0000000202156740 <+832>:	BRA 0x390 
   0x0000000202156750 <+848>:	IADD3 R0, R0, 0x4, RZ 
   0x0000000202156760 <+864>:	MOV R0, R0 
   0x0000000202156770 <+880>:	BRA 0x390 
   0x0000000202156780 <+896>:	EXIT 
   0x0000000202156790 <+912>:	MOV R2, 0x4 
   0x00000002021567a0 <+928>:	MOV R4, R2 
   0x00000002021567b0 <+944>:	SHF.L.U32 R2, R4, 0x2, RZ 
   0x00000002021567c0 <+960>:	LDC R2, c[0x2][R2] 
   0x00000002021567d0 <+976>:	SHF.R.S32.HI R3, RZ, 0x1f, R2 
   0x00000002021567e0 <+992>:	MOV R2, R2 
   0x00000002021567f0 <+1008>:	MOV R3, R3 
   0x0000000202156800 <+1024>:	BRX R2 -0x410 
   0x0000000202156810 <+1040>:	EXIT 
   0x0000000202156820 <+1056>:	BRA 0x420
   0x0000000202156830 <+1072>:	NOP
   0x0000000202156840 <+1088>:	NOP
   0x0000000202156850 <+1104>:	NOP
   0x0000000202156860 <+1120>:	NOP
   0x0000000202156870 <+1136>:	NOP
   0x0000000202156880 <+1152>:	NOP
   0x0000000202156890 <+1168>:	NOP
   0x00000002021568a0 <+1184>:	NOP
   0x00000002021568b0 <+1200>:	NOP
   0x00000002021568c0 <+1216>:	NOP
   0x00000002021568d0 <+1232>:	NOP
   0x00000002021568e0 <+1248>:	NOP
   0x00000002021568f0 <+1264>:	NOP
End of assembler dump.
(cuda-gdb) x/x (int*)0x202156800  
0x202156800 <testbrx+1024>:	0x02007949
(cuda-gdb) x/x (int*)0x202156804  
0x202156804 <testbrx+1028>:	0xfffffbf0
(cuda-gdb) x/x (int*)0x202156808 
0x202156808 <testbrx+1032>:	0x0383ffff
(cuda-gdb) x/x (int*)0x20215680c 
0x20215680c <testbrx+1036>:	0x003fde00
(cuda-gdb) set *(int*)0x202156804 = 0x00000000
(cuda-gdb) x/x (int*)0x202156800              
0x202156800 <testbrx+1024>:	0x02007949
(cuda-gdb) x/x (int*)0x202156804              
0x202156804 <testbrx+1028>:	0x00000000
(cuda-gdb) x/x (int*)0x202156808 
0x202156808 <testbrx+1032>:	0x0383ffff
(cuda-gdb) x/x (int*)0x20215680c 
0x20215680c <testbrx+1036>:	0x003fde00
(cuda-gdb) 
```

Try run: 
```
(cuda-gdb) si 
0x0000000202156410 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156410 <testbrx+16>:	@P0 BRA 0x140 
(cuda-gdb) si     
0x0000000202156540 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156540 <testbrx+320>:	MOV R1, c[0x0][0x28] 
(cuda-gdb) si     
0x0000000202156550 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156550 <testbrx+336>:	MOV R0, RZ 
(cuda-gdb) si     
0x0000000202156560 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156560 <testbrx+352>:	MOV R2, 0x8 
(cuda-gdb) si     
0x0000000202156570 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156570 <testbrx+368>:	LDC.64 R2, c[0x0][R2+0x160] 
(cuda-gdb) si     
0x0000000202156580 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156580 <testbrx+384>:	MOV R7, R2 
(cuda-gdb) si     
0x0000000202156590 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156590 <testbrx+400>:	MOV R8, R3 
(cuda-gdb) si     
0x00000002021565a0 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x2021565a0 <testbrx+416>:	MOV R7, R7 
(cuda-gdb) si     
0x00000002021565b0 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x2021565b0 <testbrx+432>:	MOV R8, R8 
(cuda-gdb) si     
0x00000002021565c0 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x2021565c0 <testbrx+448>:	MOV R2, RZ 
(cuda-gdb) si     
0x00000002021565d0 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x2021565d0 <testbrx+464>:	LDC.64 R2, c[0x0][R2+0x160] 
(cuda-gdb) si     
0x00000002021565e0 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x2021565e0 <testbrx+480>:	MOV R5, R2 
(cuda-gdb) si     
0x00000002021565f0 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x2021565f0 <testbrx+496>:	MOV R6, R3 
(cuda-gdb) si     
0x0000000202156600 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156600 <testbrx+512>:	MOV R5, R5 
(cuda-gdb) si     
0x0000000202156610 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156610 <testbrx+528>:	MOV R6, R6 
(cuda-gdb) si     
0x0000000202156620 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156620 <testbrx+544>:	MOV R0, R0 
(cuda-gdb) si     
0x0000000202156630 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156630 <testbrx+560>:	MOV R7, R7 
(cuda-gdb) si     
0x0000000202156640 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156640 <testbrx+576>:	MOV R8, R8 
(cuda-gdb) si     
0x0000000202156650 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156650 <testbrx+592>:	MOV R5, R5 
(cuda-gdb) si     
0x0000000202156660 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156660 <testbrx+608>:	MOV R6, R6 
(cuda-gdb) si     
0x0000000202156670 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156670 <testbrx+624>:	BRA 0x390 
(cuda-gdb) si     
0x0000000202156790 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156790 <testbrx+912>:	MOV R2, 0x4 
(cuda-gdb) si     
0x00000002021567a0 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x2021567a0 <testbrx+928>:	MOV R4, R2 
(cuda-gdb) si     
0x00000002021567b0 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x2021567b0 <testbrx+944>:	SHF.L.U32 R2, R4, 0x2, RZ 
(cuda-gdb) si     
0x00000002021567c0 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x2021567c0 <testbrx+960>:	LDC R2, c[0x2][R2] 
(cuda-gdb) si     
0x00000002021567d0 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x2021567d0 <testbrx+976>:	SHF.R.S32.HI R3, RZ, 0x1f, R2 
(cuda-gdb) si     
0x00000002021567e0 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x2021567e0 <testbrx+992>:	MOV R2, R2 
(cuda-gdb) si     
0x00000002021567f0 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x2021567f0 <testbrx+1008>:	MOV R3, R3 
(cuda-gdb) si     
0x0000000202156800 in testbrx<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156800 <testbrx+1024>:	BRX R2 -0x410 
(cuda-gdb) x/x $pc
0x202156800 <testbrx+1024>:	0x02007949
(cuda-gdb) x/x $pc+4
0x202156804 <testbrx+1028>:	0x00000000
(cuda-gdb) x/x $pc+8
0x202156808 <testbrx+1032>:	0x0383ffff
(cuda-gdb) x/x $pc+c
No symbol "c" in current context.
(cuda-gdb) x/x $pc+12
0x20215680c <testbrx+1036>:	0x003fde00
(cuda-gdb)            
```

Now we have successfully modified the instruction and pc is pointing at it. 

Inspect the registers: 
```
(cuda-gdb) info registers
pc             0x202156800         0x202156800 <testbrx+1024>
errorpc        <unavailable>
R0             0x0                 0
R1             0xfffdc0            16776640
R2             0x380               896
R3             0x0                 0
R4             0x4                 4
R5             0x50e0000           84803584
R6             0x2                 2
R7             0x20                32
R8             0x0                 0
R9             0x0                 0
R10            0x0                 0
R11            0x0                 0
R12            0x0                 0
R13            0x0                 0
R14            0x0                 0
R15            0x0                 0
R16            0x0                 0
R17            0x0                 0
R18            0x0                 0
R19            0x0                 0
R20            0x0                 0
R21            0x0                 0
R22            0x0                 0
R23            0x0                 0
R24            0x0                 0
R25            0x0                 0
R26            0x0                 0
R27            0x0                 0
R28            0x0                 0
R29            0x0                 0
R30            0x0                 0
R31            0x0                 0
R32            0x0                 0
R33            0x0                 0
R34            0x0                 0
R35            0x0                 0
R36            0x0                 0
R37            0x0                 0
R38            0x0                 0
R39            0x0                 0
--Type <RET> for more, q to quit, c to continue without paging--c
R40            0x0                 0
R41            0x0                 0
R42            0x0                 0
R43            0x0                 0
R44            0x0                 0
R45            0x0                 0
R46            0x0                 0
R47            0x0                 0
R48            0x0                 0
R49            0x0                 0
R50            0x0                 0
R51            0x0                 0
R52            0x0                 0
R53            0x0                 0
R54            0x0                 0
R55            0x0                 0
R56            0x0                 0
R57            0x0                 0
R58            0x0                 0
R59            0x0                 0
R60            0x0                 0
R61            0x0                 0
R62            0x0                 0
R63            0x0                 0
R64            0x0                 0
R65            0x0                 0
R66            0x0                 0
R67            0x0                 0
R68            0x0                 0
R69            0x0                 0
R70            0x0                 0
R71            0x0                 0
R72            0x0                 0
R73            0x0                 0
R74            0x0                 0
R75            0x0                 0
R76            0x0                 0
R77            0x0                 0
R78            0x0                 0
R79            0x0                 0
R80            0x0                 0
R81            0x0                 0
R82            0x0                 0
R83            0x0                 0
R84            0x0                 0
R85            0x0                 0
R86            0x0                 0
R87            0x0                 0
R88            0x0                 0
R89            0x0                 0
R90            0x0                 0
R91            0x0                 0
R92            0x0                 0
R93            0x0                 0
R94            0x0                 0
R95            0x0                 0
R96            0x0                 0
R97            0x0                 0
R98            0x0                 0
R99            0x0                 0
R100           0x0                 0
R101           0x0                 0
R102           0x0                 0
R103           0x0                 0
R104           0x0                 0
R105           0x0                 0
R106           0x0                 0
R107           0x0                 0
R108           0x0                 0
R109           0x0                 0
R110           0x0                 0
R111           0x0                 0
R112           0x0                 0
R113           0x0                 0
R114           0x0                 0
R115           0x0                 0
R116           0x0                 0
R117           0x0                 0
R118           0x0                 0
R119           0x0                 0
R120           0x0                 0
R121           0x0                 0
R122           0x0                 0
R123           0x0                 0
R124           0x0                 0
R125           0x0                 0
R126           0x0                 0
R127           0x0                 0
R128           0x0                 0
R129           0x0                 0
R130           0x0                 0
R131           0x0                 0
R132           0x0                 0
R133           0x0                 0
R134           0x0                 0
R135           0x0                 0
R136           0x0                 0
R137           0x0                 0
R138           0x0                 0
R139           0x0                 0
R140           0x0                 0
R141           0x0                 0
R142           0x0                 0
R143           0x0                 0
R144           0x0                 0
R145           0x0                 0
R146           0x0                 0
R147           0x0                 0
R148           0x0                 0
R149           0x0                 0
R150           0x0                 0
R151           0x0                 0
R152           0x0                 0
R153           0x0                 0
R154           0x0                 0
R155           0x0                 0
R156           0x0                 0
R157           0x0                 0
R158           0x0                 0
R159           0x0                 0
R160           0x0                 0
R161           0x0                 0
R162           0x0                 0
R163           0x0                 0
R164           0x0                 0
R165           0x0                 0
R166           0x0                 0
R167           0x0                 0
R168           0x0                 0
R169           0x0                 0
R170           0x0                 0
R171           0x0                 0
R172           0x0                 0
R173           0x0                 0
R174           0x0                 0
R175           0x0                 0
R176           0x0                 0
R177           0x0                 0
R178           0x0                 0
R179           0x0                 0
R180           0x0                 0
R181           0x0                 0
R182           0x0                 0
R183           0x0                 0
R184           0x0                 0
R185           0x0                 0
R186           0x0                 0
R187           0x0                 0
R188           0x0                 0
R189           0x0                 0
R190           0x0                 0
R191           0x0                 0
R192           0x0                 0
R193           0x0                 0
R194           0x0                 0
R195           0x0                 0
R196           0x0                 0
R197           0x0                 0
R198           0x0                 0
R199           0x0                 0
R200           0x0                 0
R201           0x0                 0
R202           0x0                 0
R203           0x0                 0
R204           0x0                 0
R205           0x0                 0
R206           0x0                 0
R207           0x0                 0
R208           0x0                 0
R209           0x0                 0
R210           0x0                 0
R211           0x0                 0
R212           0x0                 0
R213           0x0                 0
R214           0x0                 0
R215           0x0                 0
R216           0x0                 0
R217           0x0                 0
R218           0x0                 0
R219           0x0                 0
R220           0x0                 0
R221           0x0                 0
R222           0x0                 0
R223           0x0                 0
R224           0x0                 0
R225           0x0                 0
R226           0x0                 0
R227           0x0                 0
R228           0x0                 0
R229           0x0                 0
R230           0x0                 0
R231           0x0                 0
R232           0x0                 0
R233           0x0                 0
R234           0x0                 0
R235           0x0                 0
R236           0x0                 0
R237           0x0                 0
R238           0x0                 0
R239           0x0                 0
R240           0x0                 0
R241           0x0                 0
R242           0x0                 0
R243           0x0                 0
R244           0x0                 0
R245           0x0                 0
R246           0x0                 0
R247           0x0                 0
R248           0x0                 0
R249           0x0                 0
R250           0x0                 0
R251           0x0                 0
R252           0x0                 0
R253           0x0                 0
R254           0x0                 0
RZ             0x0                 0
P0             0x1                 1
P1             0x0                 0
P2             0x0                 0
P3             0x0                 0
P4             0x0                 0
P5             0x0                 0
P6             0x0                 0
P7             0x1                 1
UR0            0x0                 0
UR1            0x0                 0
UR2            0x10                16
UR3            0x0                 0
UR4            0x0                 0
UR5            0x0                 0
UR6            0x0                 0
UR7            0x0                 0
UR8            0x0                 0
UR9            0x0                 0
UR10           0x0                 0
UR11           0x0                 0
UR12           0x0                 0
UR13           0x0                 0
UR14           0x0                 0
UR15           0x0                 0
UR16           0x0                 0
UR17           0x0                 0
UR18           0x0                 0
UR19           0x0                 0
UR20           0x0                 0
UR21           0x0                 0
UR22           0x0                 0
UR23           0x0                 0
UR24           0x0                 0
UR25           0x0                 0
UR26           0x0                 0
UR27           0x0                 0
UR28           0x0                 0
UR29           0x0                 0
UR30           0x0                 0
UR31           0x0                 0
UR32           0x0                 0
UR33           0x0                 0
UR34           0x0                 0
UR35           0x0                 0
UR36           0x0                 0
UR37           0x0                 0
UR38           0x0                 0
UR39           0x0                 0
UR40           0x0                 0
UR41           0x0                 0
UR42           0x0                 0
UR43           0x0                 0
UR44           0x0                 0
UR45           0x0                 0
UR46           0x0                 0
UR47           0x0                 0
UR48           0x0                 0
UR49           0x0                 0
UR50           0x0                 0
UR51           0x0                 0
UR52           0x0                 0
UR53           0x0                 0
UR54           0x0                 0
UR55           0x0                 0
UR56           0x0                 0
UR57           0x0                 0
UR58           0x0                 0
UR59           0x0                 0
UR60           0x0                 0
UR61           0x0                 0
UR62           0x0                 0
URZ            0x0                 0
UP0            0x0                 0
UP1            0x0                 0
UP2            0x0                 0
UP3            0x0                 0
UP4            0x0                 0
UP5            0x0                 0
UP6            0x0                 0
UP7            0x1                 1
CC             0x0                 0
(cuda-gdb) 
```

R2 is 0x380, pc is 0x202156800, and BRX imm is 0x00000000 now... 

Let's si again!!! 

```
(cuda-gdb) si
0x0000000102156b90 in ??<<<(1,1,1),(32,1,1)>>> ()
(cuda-gdb) x/x $pc       
0x102156b90:	Cannot access memory at address 0x102156b90
(cuda-gdb) p/x $pc
$1 = 0x102156b90
(cuda-gdb) 
```

OKay... This is not quite expected? Let's analyse!!!

```
(cuda-gdb) info registers
pc             0x102156b90         0x102156b90
errorpc        <unavailable>
R0             0x0                 0
R1             0xfffdc0            16776640
R2             0x380               896
R3             0x0                 0
R4             0x4                 4
R5             0x50e0000           84803584
R6             0x2                 2
R7             0x20                32
R8             0x0                 0
R9             0x0                 0
R10            0x0                 0
R11            0x0                 0
R12            0x0                 0
R13            0x0                 0
R14            0x0                 0
R15            0x0                 0
R16            0x0                 0
R17            0x0                 0
R18            0x0                 0
R19            0x0                 0
R20            0x0                 0
R21            0x0                 0
R22            0x0                 0
R23            0x0                 0
R24            0x0                 0
R25            0x0                 0
R26            0x0                 0
R27            0x0                 0
R28            0x0                 0
R29            0x0                 0
R30            0x0                 0
R31            0x0                 0
R32            0x0                 0
R33            0x0                 0
R34            0x0                 0
R35            0x0                 0
R36            0x0                 0
R37            0x0                 0
R38            0x0                 0
R39            0x0                 0
--Type <RET> for more, q to quit, c to continue without paging--c
R40            0x0                 0
R41            0x0                 0
R42            0x0                 0
R43            0x0                 0
R44            0x0                 0
R45            0x0                 0
R46            0x0                 0
R47            0x0                 0
R48            0x0                 0
R49            0x0                 0
R50            0x0                 0
R51            0x0                 0
R52            0x0                 0
R53            0x0                 0
R54            0x0                 0
R55            0x0                 0
R56            0x0                 0
R57            0x0                 0
R58            0x0                 0
R59            0x0                 0
R60            0x0                 0
R61            0x0                 0
R62            0x0                 0
R63            0x0                 0
R64            0x0                 0
R65            0x0                 0
R66            0x0                 0
R67            0x0                 0
R68            0x0                 0
R69            0x0                 0
R70            0x0                 0
R71            0x0                 0
R72            0x0                 0
R73            0x0                 0
R74            0x0                 0
R75            0x0                 0
R76            0x0                 0
R77            0x0                 0
R78            0x0                 0
R79            0x0                 0
R80            0x0                 0
R81            0x0                 0
R82            0x0                 0
R83            0x0                 0
R84            0x0                 0
R85            0x0                 0
R86            0x0                 0
R87            0x0                 0
R88            0x0                 0
R89            0x0                 0
R90            0x0                 0
R91            0x0                 0
R92            0x0                 0
R93            0x0                 0
R94            0x0                 0
R95            0x0                 0
R96            0x0                 0
R97            0x0                 0
R98            0x0                 0
R99            0x0                 0
R100           0x0                 0
R101           0x0                 0
R102           0x0                 0
R103           0x0                 0
R104           0x0                 0
R105           0x0                 0
R106           0x0                 0
R107           0x0                 0
R108           0x0                 0
R109           0x0                 0
R110           0x0                 0
R111           0x0                 0
R112           0x0                 0
R113           0x0                 0
R114           0x0                 0
R115           0x0                 0
R116           0x0                 0
R117           0x0                 0
R118           0x0                 0
R119           0x0                 0
R120           0x0                 0
R121           0x0                 0
R122           0x0                 0
R123           0x0                 0
R124           0x0                 0
R125           0x0                 0
R126           0x0                 0
R127           0x0                 0
R128           0x0                 0
R129           0x0                 0
R130           0x0                 0
R131           0x0                 0
R132           0x0                 0
R133           0x0                 0
R134           0x0                 0
R135           0x0                 0
R136           0x0                 0
R137           0x0                 0
R138           0x0                 0
R139           0x0                 0
R140           0x0                 0
R141           0x0                 0
R142           0x0                 0
R143           0x0                 0
R144           0x0                 0
R145           0x0                 0
R146           0x0                 0
R147           0x0                 0
R148           0x0                 0
R149           0x0                 0
R150           0x0                 0
R151           0x0                 0
R152           0x0                 0
R153           0x0                 0
R154           0x0                 0
R155           0x0                 0
R156           0x0                 0
R157           0x0                 0
R158           0x0                 0
R159           0x0                 0
R160           0x0                 0
R161           0x0                 0
R162           0x0                 0
R163           0x0                 0
R164           0x0                 0
R165           0x0                 0
R166           0x0                 0
R167           0x0                 0
R168           0x0                 0
R169           0x0                 0
R170           0x0                 0
R171           0x0                 0
R172           0x0                 0
R173           0x0                 0
R174           0x0                 0
R175           0x0                 0
R176           0x0                 0
R177           0x0                 0
R178           0x0                 0
R179           0x0                 0
R180           0x0                 0
R181           0x0                 0
R182           0x0                 0
R183           0x0                 0
R184           0x0                 0
R185           0x0                 0
R186           0x0                 0
R187           0x0                 0
R188           0x0                 0
R189           0x0                 0
R190           0x0                 0
R191           0x0                 0
R192           0x0                 0
R193           0x0                 0
R194           0x0                 0
R195           0x0                 0
R196           0x0                 0
R197           0x0                 0
R198           0x0                 0
R199           0x0                 0
R200           0x0                 0
R201           0x0                 0
R202           0x0                 0
R203           0x0                 0
R204           0x0                 0
R205           0x0                 0
R206           0x0                 0
R207           0x0                 0
R208           0x0                 0
R209           0x0                 0
R210           0x0                 0
R211           0x0                 0
R212           0x0                 0
R213           0x0                 0
R214           0x0                 0
R215           0x0                 0
R216           0x0                 0
R217           0x0                 0
R218           0x0                 0
R219           0x0                 0
R220           0x0                 0
R221           0x0                 0
R222           0x0                 0
R223           0x0                 0
R224           0x0                 0
R225           0x0                 0
R226           0x0                 0
R227           0x0                 0
R228           0x0                 0
R229           0x0                 0
R230           0x0                 0
R231           0x0                 0
R232           0x0                 0
R233           0x0                 0
R234           0x0                 0
R235           0x0                 0
R236           0x0                 0
R237           0x0                 0
R238           0x0                 0
R239           0x0                 0
R240           0x0                 0
R241           0x0                 0
R242           0x0                 0
R243           0x0                 0
R244           0x0                 0
R245           0x0                 0
R246           0x0                 0
R247           0x0                 0
R248           0x0                 0
R249           0x0                 0
R250           0x0                 0
R251           0x0                 0
R252           0x0                 0
R253           0x0                 0
R254           0x0                 0
RZ             0x0                 0
P0             0x1                 1
P1             0x0                 0
P2             0x0                 0
P3             0x0                 0
P4             0x0                 0
P5             0x0                 0
P6             0x0                 0
P7             0x1                 1
UR0            0x0                 0
UR1            0x0                 0
UR2            0x10                16
UR3            0x0                 0
UR4            0x0                 0
UR5            0x0                 0
UR6            0x0                 0
UR7            0x0                 0
UR8            0x0                 0
UR9            0x0                 0
UR10           0x0                 0
UR11           0x0                 0
UR12           0x0                 0
UR13           0x0                 0
UR14           0x0                 0
UR15           0x0                 0
UR16           0x0                 0
UR17           0x0                 0
UR18           0x0                 0
UR19           0x0                 0
UR20           0x0                 0
UR21           0x0                 0
UR22           0x0                 0
UR23           0x0                 0
UR24           0x0                 0
UR25           0x0                 0
UR26           0x0                 0
UR27           0x0                 0
UR28           0x0                 0
UR29           0x0                 0
UR30           0x0                 0
UR31           0x0                 0
UR32           0x0                 0
UR33           0x0                 0
UR34           0x0                 0
UR35           0x0                 0
UR36           0x0                 0
UR37           0x0                 0
UR38           0x0                 0
UR39           0x0                 0
UR40           0x0                 0
UR41           0x0                 0
UR42           0x0                 0
UR43           0x0                 0
UR44           0x0                 0
UR45           0x0                 0
UR46           0x0                 0
UR47           0x0                 0
UR48           0x0                 0
UR49           0x0                 0
UR50           0x0                 0
UR51           0x0                 0
UR52           0x0                 0
UR53           0x0                 0
UR54           0x0                 0
UR55           0x0                 0
UR56           0x0                 0
UR57           0x0                 0
UR58           0x0                 0
UR59           0x0                 0
UR60           0x0                 0
UR61           0x0                 0
UR62           0x0                 0
URZ            0x0                 0
UP0            0x0                 0
UP1            0x0                 0
UP2            0x0                 0
UP3            0x0                 0
UP4            0x0                 0
UP5            0x0                 0
UP6            0x0                 0
UP7            0x1                 1
CC             0x0                 0
(cuda-gdb) 
```

notice that: hex(0x202156800-0x102156b90) = '0xfffffc70',
and hex(0x202156800-0x102156b90+0x380) = '0xfffffff0',
and hex(0x202156800-0x102156b90+0x380+0x10) = '0x100000000'

So, the proposed new behaviour is: 
```
NewPC[63:0] = BRXPC[63:0] + 0x10 + Rx - 0x100000000 + imm
```

If we substitute the previous run, where BRXPC = 0x202156800, R2 = 0x380, imm = 0xfffffbf0, 
we calculate the NewPC as follows: 
```
NewPC[63:0] = BRXPC[63:0] + 0x10 + Rx - 0x100000000 + imm
            = 0x202156800 + 0x10 + 0x380 - 0x100000000 + 0xfffffbf0
            = 0x202156780
```

And if imm = 0x00000000: 
```
NewPC[63:0] = BRXPC[63:0] + 0x10 + Rx - 0x100000000 + imm
            = 0x202156800 + 0x10 + 0x380 - 0x100000000 + 0x00000000
            = 0x102156b90
```

Works perfectly!!! 

# Conclusion 
The BRX instruction works as follows: 
```
At BRXPC: 
    BRX Rx beautified_imm
The encoded imm is at BRXPC + 4, and is a 32-bit imm (the second 32-bit chunk of the BRX instruction). 
Denote: encoded_imm = *(uint32_t*)(BRXPC+4)

beautified_imm = encoded_imm - 0x100000000
e.g., encoded_imm = 0xfffffbf0, beautified_imm = -0x410

Behavior: 
NewPC[63:0] = BRXPC[63:0] + 0x10 + Rx - 0x100000000 + encoded_imm
```

## NOTICE:
After modifying BRX to jump to 0x102156b90, without doing another si, 
if we type quit on gdb and type y, the board's display output will malfunction...
But seems like the keyboard still works fine as I can blind type sudo reboot and type password to reboot the board. 


## NOTICE2 (static analysis of ELF file): 
The BRX instruction generated loads R2 from constant memory bank 0x2, with some offset, and shifts it by 4, if we dump the ELF: 
```
jetson@yahboom:~/workspace/experiment/branch/brx$ readelf -lW brx87.cubin 

Elf file type is EXEC (Executable file)
Entry point 0x0
There are 3 program headers, starting at offset 3648

Program Headers:
  Type           Offset   VirtAddr           PhysAddr           FileSiz  MemSiz   Flg Align
  PHDR           0x000e40 0x0000000000000000 0x0000000000000000 0x0000a8 0x0000a8 R E 0x8
  LOAD           0x000468 0x0000000000000000 0x0000000000000000 0x000698 0x000698 R E 0x8
  LOAD           0x000e40 0x0000000000000000 0x0000000000000000 0x0000a8 0x0000a8 R E 0x8

 Section to Segment mapping:
  Segment Sections...
   00     
   01     .nv.constant2.testbrx .nv.constant0.testbrx .text.testbrx 
   02     
jetson@yahboom:~/workspace/experiment/branch/brx$ readelf -SW brx87.cubin 
There are 13 section headers, starting at offset 0xb00:

Section Headers:
  [Nr] Name              Type            Address          Off    Size   ES Flg Lk Inf Al
  [ 0]                   NULL            0000000000000000 000000 000000 00      0   0  0
  [ 1] .shstrtab         STRTAB          0000000000000000 000040 000105 00      0   0  1
  [ 2] .strtab           STRTAB          0000000000000000 000145 00010d 00      0   0  1
  [ 3] .symtab           SYMTAB          0000000000000000 000258 0000c0 18      2   7  8
  [ 4] .debug_frame      PROGBITS        0000000000000000 000318 000070 00      0   0  1
  [ 5] .nv.info          LOPROC+0        0000000000000000 000388 000024 00      3   0  4
  [ 6] .nv.info.testbrx  LOPROC+0        0000000000000000 0003ac 000078 00   I  3  12  4
  [ 7] .nv.callgraph     LOPROC+0x1      0000000000000000 000424 000020 08      3   0  4
  [ 8] .nv.rel.action    LOPROC+0xb      0000000000000000 000448 000010 08      0   0  8
  [ 9] .rel.debug_frame  REL             0000000000000000 000458 000010 10   I  3   4  8
  [10] .nv.constant2.testbrx PROGBITS        0000000000000000 000468 000014 00  AI  0  12  4
  [11] .nv.constant0.testbrx PROGBITS        0000000000000000 00047c 000170 00  AI  0  12  4
readelf: Warning: [12]: Unexpected value (184549383) in info field.
  [12] .text.testbrx     PROGBITS        0000000000000000 000600 000500 00  AX  3 184549383 128
Key to Flags:
  W (write), A (alloc), X (execute), M (merge), S (strings), I (info),
  L (link order), O (extra OS processing required), G (group), T (TLS),
  C (compressed), x (unknown), o (OS specific), E (exclude),
  p (processor specific)
jetson@yahboom:~/workspace/experiment/branch/brx$ 
```

We can see differentg banks of constant memory are mapped in different sections, and we focus on section .nv.constant2.testbrx, 
which is at file offset 0x000468, size 0x000014, so its range is 0x0468 - 0x047C.

If we inspect the binary brx87.cubin at that offset: 
```
0x0468: 80 02 00 00 f0 02 00 00 50 03 00 00 20 03 00 00 80 03 00 00
```
In brx87.list, if we look at the SASS code, 0x0280, 0x02f0, 0x0350, 0x0320, 0x0380 are actually the branch targets!!! 
```
        /*0270*/                   BRA 0x390 ;                             /* 0x0000011000007947 */
                                                                           /* 0x003fde0003800000 */
        /*0280*/                   IADD3 R2, P0, R7, R5, RZ ;              /* 0x0000000507027210 */
                                                                           /* 0x003fde0007f1e0ff */
        /*0290*/                   IADD3.X R3, R8, R6, RZ, P0, !PT ;       /* 0x0000000608037210 */
                                                                           /* 0x003fde00007fe4ff */
        /*02a0*/                   IADD3 R0, R0, 0x1, RZ ;                 /* 0x0000000100007810 */
                                                                           /* 0x003fde0007ffe0ff */
        /*02b0*/                   MOV R7, R2 ;                            /* 0x0000000200077202 */
                                                                           /* 0x003fde0000000f00 */
        /*02c0*/                   MOV R8, R3 ;                            /* 0x0000000300087202 */
                                                                           /* 0x003fde0000000f00 */
        /*02d0*/                   MOV R0, R0 ;                            /* 0x0000000000007202 */
                                                                           /* 0x003fde0000000f00 */
        /*02e0*/                   BRA 0x390 ;                             /* 0x000000a000007947 */
                                                                           /* 0x003fde0003800000 */
        /*02f0*/                   IADD3 R0, R0, 0x2, RZ ;                 /* 0x0000000200007810 */
                                                                           /* 0x003fde0007ffe0ff */
        /*0300*/                   MOV R0, R0 ;                            /* 0x0000000000007202 */
                                                                           /* 0x003fde0000000f00 */
        /*0310*/                   BRA 0x3b0 ;                             /* 0x0000009000007947 */
                                                                           /* 0x003fde0003800000 */
        /*0320*/                   IADD3 R0, R0, 0x3, RZ ;                 /* 0x0000000300007810 */
                                                                           /* 0x003fde0007ffe0ff */
        /*0330*/                   MOV R0, R0 ;                            /* 0x0000000000007202 */
                                                                           /* 0x003fde0000000f00 */
        /*0340*/                   BRA 0x390 ;                             /* 0x0000004000007947 */
                                                                           /* 0x003fde0003800000 */
        /*0350*/                   IADD3 R0, R0, 0x4, RZ ;                 /* 0x0000000400007810 */
                                                                           /* 0x003fde0007ffe0ff */
        /*0360*/                   MOV R0, R0 ;                            /* 0x0000000000007202 */
                                                                           /* 0x003fde0000000f00 */
        /*0370*/                   BRA 0x390 ;                             /* 0x0000001000007947 */
                                                                           /* 0x003fde0003800000 */
        /*0380*/                   EXIT ;                                  /* 0x000000000000794d */
                                                                           /* 0x003fde0003800000 */
```
```
        /*0390*/                   MOV R2, 0x4 ;                           /* 0x0000000400027802 */
                                                                           /* 0x003fde0000000f00 */
        /*03a0*/                   MOV R4, R2 ;                            /* 0x0000000200047202 */
                                                                           /* 0x003fde0000000f00 */
        /*03b0*/                   SHF.L.U32 R2, R4, 0x2, RZ ;             /* 0x0000000204027819 */
                                                                           /* 0x003fde00000006ff */
        /*03c0*/                   LDC R2, c[0x2][R2] ;                    /* 0x0080000002027b82 */
                                                                           /* 0x00321e0000000800 */
        /*03d0*/                   SHF.R.S32.HI R3, RZ, 0x1f, R2 ;         /* 0x0000001fff037819 */
                                                                           /* 0x003fde0000011402 */
        /*03e0*/                   MOV R2, R2 ;                            /* 0x0000000200027202 */
                                                                           /* 0x003fde0000000f00 */
        /*03f0*/                   MOV R3, R3 ;                            /* 0x0000000300037202 */
                                                                           /* 0x003fde0000000f00 */
        /*0400*/                   BRX R2 -0x410 ;                         /* 0xfffffbf002007949 */
                                                                           /* 0x003fde000383ffff */
```
This concludes our analysis on BRX instruction in SASS. 
Q.E.D.







