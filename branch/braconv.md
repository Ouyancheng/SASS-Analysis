# bra.conv inspection

NOTE: barrier sync count must be a multiple of warp size, aka 32: 
```
asm("barrier.cta.sync 0, 16;\n\t");
data[threadIdx.x] = threadIdx.x;
asm("barrier.cta.arrive 1, 16;\n\t");

jetson@yahboom:~/workspace/experiment/branch/braconv$ ../../runbuild.sh braconv_syncthreads.cu 87
ptxas /tmp/tmpxft_0000429c_00000000-6_braconv_syncthreads.ptx, line 45; error   : Number of threads participating in barrier must be in multiple of warp size
ptxas /tmp/tmpxft_0000429c_00000000-6_braconv_syncthreads.ptx, line 61; error   : Number of threads participating in barrier must be in multiple of warp size
ptxas /tmp/tmpxft_0000429c_00000000-6_braconv_syncthreads.ptx, line 70; error   : Number of threads participating in barrier must be in multiple of warp size
ptxas /tmp/tmpxft_0000429c_00000000-6_braconv_syncthreads.ptx, line 75; error   : Number of threads participating in barrier must be in multiple of warp size
ptxas fatal   : Ptx assembly aborted due to errors
ptxas /tmp/tmpxft_000042a6_00000000-6_braconv_syncthreads.ptx, line 45; error   : Number of threads participating in barrier must be in multiple of warp size
ptxas /tmp/tmpxft_000042a6_00000000-6_braconv_syncthreads.ptx, line 61; error   : Number of threads participating in barrier must be in multiple of warp size
ptxas /tmp/tmpxft_000042a6_00000000-6_braconv_syncthreads.ptx, line 70; error   : Number of threads participating in barrier must be in multiple of warp size
ptxas /tmp/tmpxft_000042a6_00000000-6_braconv_syncthreads.ptx, line 75; error   : Number of threads participating in barrier must be in multiple of warp size
ptxas fatal   : Ptx assembly aborted due to errors
jetson@yahboom:~/workspace/experiment/branch/braconv$ 
```

Code fixed: 
```
#define XBS 64

#define NN 32

// printf("thread.x=%d, activemask=0x%08x\n", threadIdx.x, __activemask());
// printf("thread.x=%d, activemask=0x%08x\n", threadIdx.x, __activemask());
// printf("threadidx.x = %d\n", threadIdx.x);

__device__ int mem[1024] = {0};

__global__
void test_bra(int64_t *out, uint32_t count){
    __shared__ uint32_t data[XBS];
    if (threadIdx.x < 16) {
        mem[threadIdx.x] = threadIdx.y;
        mem[threadIdx.x + 16] = threadIdx.z;
        mem[threadIdx.x + 32] = threadIdx.x;
    }
    if (threadIdx.x < NN) {
        asm("barrier.cta.sync 0, 32;\n\t");
        data[threadIdx.x] = threadIdx.x;
        asm("barrier.cta.arrive 1, 32;\n\t");
    } else {
        asm("barrier.cta.arrive 0, 32;\n\t");
        asm("barrier.cta.sync 1, 32;\n\t");
        out[threadIdx.x - NN] = data[threadIdx.x - NN];
    }
}
```

Disassembly 
```
(cuda-gdb) disas 
Dump of assembler code for function _Z8test_braPlj:
   0x0000000202156400 <+0>:	ISETP.NE.U32.AND P0, PT, RZ, UR2, PT 
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
   0x0000000202156550 <+336>:	MOV R18, c[0x0][0x118] 
   0x0000000202156560 <+352>:	MOV R19, c[0x0][0x11c] 
   0x0000000202156570 <+368>:	MOV R2, RZ 
   0x0000000202156580 <+384>:	LDC.64 R2, c[0x0][R2+0x160] 
   0x0000000202156590 <+400>:	MOV R16, R2 
   0x00000002021565a0 <+416>:	MOV R2, R3 
   0x00000002021565b0 <+432>:	MOV R16, R16 
   0x00000002021565c0 <+448>:	MOV R2, R2 
   0x00000002021565d0 <+464>:	MOV R0, 0x8 
   0x00000002021565e0 <+480>:	LDC R0, c[0x0][R0+0x160] 
   0x00000002021565f0 <+496>:	MOV R0, R0 
   0x0000000202156600 <+512>:	MOV R0, R0 
   0x0000000202156610 <+528>:	MOV R16, R16 
   0x0000000202156620 <+544>:	MOV R2, R2 
   0x0000000202156630 <+560>:	MOV R17, R0 
=> 0x0000000202156640 <+576>:	S2R R0, SR_TID.X 
   0x0000000202156650 <+592>:	MOV R0, R0 
   0x0000000202156660 <+608>:	ISETP.LT.U32.AND P0, PT, R0, 0x10, PT 
   0x0000000202156670 <+624>:	PLOP3.LUT P0, PT, P0, PT, PT, 0x8, 0x0 
   0x0000000202156680 <+640>:	BSSY B0, 0x6d0 
--Type <RET> for more, q to quit, c to continue without paging--c
   0x0000000202156690 <+656>:	@P0 BRA 0x6c0 
   0x00000002021566a0 <+672>:	BRA 0x2b0 
   0x00000002021566b0 <+688>:	S2R R6, SR_TID.Y 
   0x00000002021566c0 <+704>:	MOV R6, R6 
   0x00000002021566d0 <+720>:	S2R R0, SR_TID.X 
   0x00000002021566e0 <+736>:	MOV R0, R0 
   0x00000002021566f0 <+752>:	MOV R0, R0 
   0x0000000202156700 <+768>:	MOV R7, R0 
   0x0000000202156710 <+784>:	MOV R8, RZ 
   0x0000000202156720 <+800>:	MOV R4, 0x0 
   0x0000000202156730 <+816>:	MOV R5, 0x0 
   0x0000000202156740 <+832>:	MOV R4, R4 
   0x0000000202156750 <+848>:	MOV R5, R5 
   0x0000000202156760 <+864>:	MOV R3, R4 
   0x0000000202156770 <+880>:	MOV R0, R5 
   0x0000000202156780 <+896>:	MOV R3, R3 
   0x0000000202156790 <+912>:	MOV R0, R0 
   0x00000002021567a0 <+928>:	SHF.L.U64.HI R5, R7, 0x2, R8 
   0x00000002021567b0 <+944>:	SHF.L.U32 R4, R7, 0x2, RZ 
   0x00000002021567c0 <+960>:	IADD3 R4, P0, R3, R4, RZ 
   0x00000002021567d0 <+976>:	IADD3.X R5, R0, R5, RZ, P0, !PT 
   0x00000002021567e0 <+992>:	MOV R4, R4 
   0x00000002021567f0 <+1008>:	MOV R5, R5 
   0x0000000202156800 <+1024>:	MOV R4, R4 
   0x0000000202156810 <+1040>:	MOV R5, R5 
   0x0000000202156820 <+1056>:	R2UR UR4, R18 
   0x0000000202156830 <+1072>:	R2UR UR5, R19 
   0x0000000202156840 <+1088>:	ST.E [R4.64], R6 
   0x0000000202156850 <+1104>:	S2R R6, SR_TID.Z 
   0x0000000202156860 <+1120>:	MOV R6, R6 
   0x0000000202156870 <+1136>:	S2R R4, SR_TID.X 
   0x0000000202156880 <+1152>:	MOV R4, R4 
   0x0000000202156890 <+1168>:	IADD3 R4, R4, 0x10, RZ 
   0x00000002021568a0 <+1184>:	MOV R4, R4 
   0x00000002021568b0 <+1200>:	MOV R4, R4 
   0x00000002021568c0 <+1216>:	MOV R5, RZ 
   0x00000002021568d0 <+1232>:	SHF.L.U64.HI R5, R4, 0x2, R5 
   0x00000002021568e0 <+1248>:	SHF.L.U32 R4, R4, 0x2, RZ 
   0x00000002021568f0 <+1264>:	IADD3 R4, P0, R3, R4, RZ 
   0x0000000202156900 <+1280>:	IADD3.X R5, R0, R5, RZ, P0, !PT 
   0x0000000202156910 <+1296>:	MOV R4, R4 
   0x0000000202156920 <+1312>:	MOV R5, R5 
   0x0000000202156930 <+1328>:	MOV R4, R4 
   0x0000000202156940 <+1344>:	MOV R5, R5 
   0x0000000202156950 <+1360>:	R2UR UR4, R18 
   0x0000000202156960 <+1376>:	R2UR UR5, R19 
   0x0000000202156970 <+1392>:	ST.E [R4.64], R6 
   0x0000000202156980 <+1408>:	S2R R6, SR_TID.X 
   0x0000000202156990 <+1424>:	MOV R6, R6 
   0x00000002021569a0 <+1440>:	S2R R4, SR_TID.X 
   0x00000002021569b0 <+1456>:	MOV R4, R4 
   0x00000002021569c0 <+1472>:	IADD3 R4, R4, 0x20, RZ 
   0x00000002021569d0 <+1488>:	MOV R4, R4 
   0x00000002021569e0 <+1504>:	MOV R4, R4 
   0x00000002021569f0 <+1520>:	MOV R5, RZ 
   0x0000000202156a00 <+1536>:	SHF.L.U64.HI R5, R4, 0x2, R5 
   0x0000000202156a10 <+1552>:	SHF.L.U32 R4, R4, 0x2, RZ 
   0x0000000202156a20 <+1568>:	IADD3 R4, P0, R3, R4, RZ 
   0x0000000202156a30 <+1584>:	IADD3.X R5, R0, R5, RZ, P0, !PT 
   0x0000000202156a40 <+1600>:	MOV R4, R4 
   0x0000000202156a50 <+1616>:	MOV R5, R5 
   0x0000000202156a60 <+1632>:	MOV R4, R4 
   0x0000000202156a70 <+1648>:	MOV R5, R5 
   0x0000000202156a80 <+1664>:	R2UR UR4, R18 
   0x0000000202156a90 <+1680>:	R2UR UR5, R19 
   0x0000000202156aa0 <+1696>:	ST.E [R4.64], R6 
   0x0000000202156ab0 <+1712>:	BRA 0x6c0 
   0x0000000202156ac0 <+1728>:	BSYNC B0 
   0x0000000202156ad0 <+1744>:	S2R R0, SR_TID.X 
   0x0000000202156ae0 <+1760>:	MOV R0, R0 
   0x0000000202156af0 <+1776>:	ISETP.LT.U32.AND P0, PT, R0, 0x20, PT 
   0x0000000202156b00 <+1792>:	PLOP3.LUT P0, PT, P0, PT, PT, 0x8, 0x0 
   0x0000000202156b10 <+1808>:	@P0 BRA 0x9d0 
   0x0000000202156b20 <+1824>:	BRA 0x730 
   0x0000000202156b30 <+1840>:	BRA.CONV ~URZ, 0x790 
   0x0000000202156b40 <+1856>:	MOV R4, 0x20 
   0x0000000202156b50 <+1872>:	MOV R20, 0x0 
   0x0000000202156b60 <+1888>:	MOV R21, 0x0 
   0x0000000202156b70 <+1904>:	CALL.ABS.NOINC 0x0 
   0x0000000202156b80 <+1920>:	BRA 0x7a0 
   0x0000000202156b90 <+1936>:	BAR.SYNC 0x0, 0x20 
   0x0000000202156ba0 <+1952>:	S2R R0, SR_TID.X 
   0x0000000202156bb0 <+1968>:	MOV R0, R0 
   0x0000000202156bc0 <+1984>:	S2R R2, SR_TID.X 
   0x0000000202156bd0 <+2000>:	MOV R2, R2 
   0x0000000202156be0 <+2016>:	MOV R2, R2 
   0x0000000202156bf0 <+2032>:	MOV R6, R2 
   0x0000000202156c00 <+2048>:	MOV R7, RZ 
   0x0000000202156c10 <+2064>:	MOV R2, 0x0 
   0x0000000202156c20 <+2080>:	MOV R2, R2 
   0x0000000202156c30 <+2096>:	MOV R2, R2 
   0x0000000202156c40 <+2112>:	MOV R2, R2 
   0x0000000202156c50 <+2128>:	MOV R3, RZ 
   0x0000000202156c60 <+2144>:	MOV R4, c[0x0][0x18] 
   0x0000000202156c70 <+2160>:	MOV R5, c[0x0][0x1c] 
   0x0000000202156c80 <+2176>:	IADD3 R4, P0, R2, R4, RZ 
   0x0000000202156c90 <+2192>:	IADD3.X R5, R3, R5, RZ, P0, !PT 
   0x0000000202156ca0 <+2208>:	SHF.L.U64.HI R3, R6, 0x2, R7 
   0x0000000202156cb0 <+2224>:	SHF.L.U32 R2, R6, 0x2, RZ 
   0x0000000202156cc0 <+2240>:	IADD3 R2, P0, R4, R2, RZ 
   0x0000000202156cd0 <+2256>:	IADD3.X R3, R5, R3, RZ, P0, !PT 
   0x0000000202156ce0 <+2272>:	MOV R2, R2 
   0x0000000202156cf0 <+2288>:	MOV R3, R3 
   0x0000000202156d00 <+2304>:	MOV R2, R2 
   0x0000000202156d10 <+2320>:	MOV R3, R3 
   0x0000000202156d20 <+2336>:	R2UR UR4, R18 
   0x0000000202156d30 <+2352>:	R2UR UR5, R19 
   0x0000000202156d40 <+2368>:	ST.E [R2.64], R0 
   0x0000000202156d50 <+2384>:	BRA.CONV ~URZ, 0x9b0 
   0x0000000202156d60 <+2400>:	MOV R4, 0x20 
   0x0000000202156d70 <+2416>:	MOV R20, 0x0 
   0x0000000202156d80 <+2432>:	MOV R21, 0x0 
   0x0000000202156d90 <+2448>:	CALL.ABS.NOINC 0x0 
   0x0000000202156da0 <+2464>:	BRA 0x9c0 
   0x0000000202156db0 <+2480>:	BAR.ARV 0x1, 0x20 
   0x0000000202156dc0 <+2496>:	BRA 0xda0 
   0x0000000202156dd0 <+2512>:	BRA.CONV ~URZ, 0xa30 
   0x0000000202156de0 <+2528>:	MOV R4, 0x20 
   0x0000000202156df0 <+2544>:	MOV R20, 0x0 
   0x0000000202156e00 <+2560>:	MOV R21, 0x0 
   0x0000000202156e10 <+2576>:	CALL.ABS.NOINC 0x0 
   0x0000000202156e20 <+2592>:	BRA 0xa40 
   0x0000000202156e30 <+2608>:	BAR.ARV 0x0, 0x20 
   0x0000000202156e40 <+2624>:	BRA.CONV ~URZ, 0xaa0 
   0x0000000202156e50 <+2640>:	MOV R4, 0x20 
   0x0000000202156e60 <+2656>:	MOV R20, 0x0 
   0x0000000202156e70 <+2672>:	MOV R21, 0x0 
   0x0000000202156e80 <+2688>:	CALL.ABS.NOINC 0x0 
   0x0000000202156e90 <+2704>:	BRA 0xab0 
   0x0000000202156ea0 <+2720>:	BAR.SYNC 0x1, 0x20 
   0x0000000202156eb0 <+2736>:	S2R R0, SR_TID.X 
   0x0000000202156ec0 <+2752>:	MOV R0, R0 
   0x0000000202156ed0 <+2768>:	IADD3 R0, R0, -0x20, RZ 
   0x0000000202156ee0 <+2784>:	MOV R0, R0 
   0x0000000202156ef0 <+2800>:	MOV R6, R0 
   0x0000000202156f00 <+2816>:	MOV R7, RZ 
   0x0000000202156f10 <+2832>:	MOV R0, 0x0 
   0x0000000202156f20 <+2848>:	MOV R0, R0 
   0x0000000202156f30 <+2864>:	MOV R0, R0 
   0x0000000202156f40 <+2880>:	MOV R4, R0 
   0x0000000202156f50 <+2896>:	MOV R5, RZ 
   0x0000000202156f60 <+2912>:	MOV R0, c[0x0][0x18] 
   0x0000000202156f70 <+2928>:	MOV R3, c[0x0][0x1c] 
   0x0000000202156f80 <+2944>:	IADD3 R0, P0, R4, R0, RZ 
   0x0000000202156f90 <+2960>:	IADD3.X R3, R5, R3, RZ, P0, !PT 
   0x0000000202156fa0 <+2976>:	SHF.L.U64.HI R5, R6, 0x2, R7 
   0x0000000202156fb0 <+2992>:	SHF.L.U32 R4, R6, 0x2, RZ 
   0x0000000202156fc0 <+3008>:	IADD3 R4, P0, R0, R4, RZ 
   0x0000000202156fd0 <+3024>:	IADD3.X R5, R3, R5, RZ, P0, !PT 
   0x0000000202156fe0 <+3040>:	MOV R4, R4 
   0x0000000202156ff0 <+3056>:	MOV R5, R5 
   0x0000000202157000 <+3072>:	MOV R4, R4 
   0x0000000202157010 <+3088>:	MOV R5, R5 
   0x0000000202157020 <+3104>:	R2UR UR4, R18 
   0x0000000202157030 <+3120>:	R2UR UR5, R19 
   0x0000000202157040 <+3136>:	LD.E R4, [R4.64] 
   0x0000000202157050 <+3152>:	MOV R4, R4 
   0x0000000202157060 <+3168>:	MOV R4, R4 
   0x0000000202157070 <+3184>:	MOV R5, RZ 
   0x0000000202157080 <+3200>:	S2R R0, SR_TID.X 
   0x0000000202157090 <+3216>:	MOV R0, R0 
   0x00000002021570a0 <+3232>:	IADD3 R0, R0, -0x20, RZ 
   0x00000002021570b0 <+3248>:	MOV R0, R0 
   0x00000002021570c0 <+3264>:	MOV R0, R0 
   0x00000002021570d0 <+3280>:	MOV R3, RZ 
   0x00000002021570e0 <+3296>:	SHF.L.U64.HI R3, R0, 0x3, R3 
   0x00000002021570f0 <+3312>:	SHF.L.U32 R0, R0, 0x3, RZ 
   0x0000000202157100 <+3328>:	IADD3 R16, P0, R16, R0, RZ 
   0x0000000202157110 <+3344>:	IADD3.X R3, R2, R3, RZ, P0, !PT 
   0x0000000202157120 <+3360>:	MOV R2, R16 
   0x0000000202157130 <+3376>:	MOV R3, R3 
   0x0000000202157140 <+3392>:	MOV R2, R2 
   0x0000000202157150 <+3408>:	MOV R3, R3 
   0x0000000202157160 <+3424>:	R2UR UR4, R18 
   0x0000000202157170 <+3440>:	R2UR UR5, R19 
   0x0000000202157180 <+3456>:	ST.E.64 [R2.64], R4 
   0x0000000202157190 <+3472>:	BRA 0xda0 
   0x00000002021571a0 <+3488>:	MEMBAR.SC.VC 
   0x00000002021571b0 <+3504>:	ERRBAR 
   0x00000002021571c0 <+3520>:	EXIT 
   0x00000002021571d0 <+3536>:	MEMBAR.SC.VC 
   0x00000002021571e0 <+3552>:	ERRBAR 
   0x00000002021571f0 <+3568>:	EXIT 
   0x0000000202157200 <+3584>:	BRA 0xe00
   0x0000000202157210 <+3600>:	NOP
   0x0000000202157220 <+3616>:	NOP
   0x0000000202157230 <+3632>:	NOP
   0x0000000202157240 <+3648>:	NOP
   0x0000000202157250 <+3664>:	NOP
   0x0000000202157260 <+3680>:	NOP
   0x0000000202157270 <+3696>:	NOP
   0x0000000202157280 <+3712>:	NOP
   0x0000000202157290 <+3728>:	NOP
   0x00000002021572a0 <+3744>:	NOP
   0x00000002021572b0 <+3760>:	NOP
   0x00000002021572c0 <+3776>:	NOP
   0x00000002021572d0 <+3792>:	NOP
   0x00000002021572e0 <+3808>:	NOP
   0x00000002021572f0 <+3824>:	NOP
End of assembler dump.
(cuda-gdb) 
```

Registers:
```
(cuda-gdb) info register 
pc             0x202156640         0x202156640 <test_bra(long*, unsigned int)+576>
errorpc        <unavailable>
R0             0x40                64
R1             0xfffdc0            16776640
R2             0x2                 2
R3             0x2                 2
R4             0x0                 0
R5             0x0                 0
R6             0x0                 0
R7             0x0                 0
R8             0x0                 0
R9             0x0                 0
R10            0x0                 0
R11            0x0                 0
R12            0x0                 0
R13            0x0                 0
R14            0x0                 0
R15            0x0                 0
R16            0x50e0000           84803584
R17            0x40                64
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
P0             0x0                 0
P1             0x0                 0
P2             0x0                 0
P3             0x0                 0
P4             0x0                 0
P5             0x0                 0
P6             0x0                 0
P7             0x1                 1
UR0            0x0                 0
UR1            0x0                 0
UR2            0x1                 1
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

Before setting barriers
```
(cuda-gdb) x/i $pc
=> 0x202156680 <_Z8test_braPlj+640>:	BSSY B0, 0x6d0 
(cuda-gdb) print $B0
$1 = void
```

And B0 is set as: 
```
   0x0000000202156420 <+32>:	BMOV.32 B0, 0xffffffff 
```

For some reason, `info cuda barriers` doesn't work in local `cuda-gdb`, but I think we can inspect the pc of each lane and each warp then... 

Before the `if (tid < 16)` branch: 
```
(cuda-gdb) x/i $pc            
=> 0x202156690 <_Z8test_braPlj+656>:	@P0 BRA 0x6c0 
(cuda-gdb) info cuda warps 
  Wp Active Lanes Mask Divergent Lanes Mask          Active PC Kernel BlockIdx First Active ThreadIdx 
Device 0 SM 0
*  0        0xffffffff           0x00000000 0x0000000202156690      0  (0,0,0)                (0,0,0) 
   1        0xffffffff           0x00000000 0x0000000202156640      0  (0,0,0)               (32,0,0) 
(cuda-gdb) info cuda contexts 
             Context Dev  State 
* 0x0000aaaaaabe1960   0 active 
(cuda-gdb) info cuda lanes 
  Ln  State         PC         ThreadIdx Exception 
Device 0 SM 0 Warp 0
*  0 active 0x0000000202156690   (0,0,0)    None   
   1 active 0x0000000202156690   (1,0,0)    None   
   2 active 0x0000000202156690   (2,0,0)    None   
   3 active 0x0000000202156690   (3,0,0)    None   
   4 active 0x0000000202156690   (4,0,0)    None   
   5 active 0x0000000202156690   (5,0,0)    None   
   6 active 0x0000000202156690   (6,0,0)    None   
   7 active 0x0000000202156690   (7,0,0)    None   
   8 active 0x0000000202156690   (8,0,0)    None   
   9 active 0x0000000202156690   (9,0,0)    None   
  10 active 0x0000000202156690  (10,0,0)    None   
  11 active 0x0000000202156690  (11,0,0)    None   
  12 active 0x0000000202156690  (12,0,0)    None   
  13 active 0x0000000202156690  (13,0,0)    None   
  14 active 0x0000000202156690  (14,0,0)    None   
  15 active 0x0000000202156690  (15,0,0)    None   
  16 active 0x0000000202156690  (16,0,0)    None   
  17 active 0x0000000202156690  (17,0,0)    None   
  18 active 0x0000000202156690  (18,0,0)    None   
  19 active 0x0000000202156690  (19,0,0)    None   
  20 active 0x0000000202156690  (20,0,0)    None   
  21 active 0x0000000202156690  (21,0,0)    None   
  22 active 0x0000000202156690  (22,0,0)    None   
  23 active 0x0000000202156690  (23,0,0)    None   
  24 active 0x0000000202156690  (24,0,0)    None   
  25 active 0x0000000202156690  (25,0,0)    None   
  26 active 0x0000000202156690  (26,0,0)    None   
  27 active 0x0000000202156690  (27,0,0)    None   
  28 active 0x0000000202156690  (28,0,0)    None   
  29 active 0x0000000202156690  (29,0,0)    None   
  30 active 0x0000000202156690  (30,0,0)    None   
  31 active 0x0000000202156690  (31,0,0)    None   
(cuda-gdb)  
```

The branch target to 0x6c0 is at 
```
        /*0240*/                   S2R R0, SR_TID.X ;                        /* 0x0000000000007919 */
                                                                             /* 0x00321e0000002100 */
        /*0250*/                   MOV R0, R0 ;                              /* 0x0000000000007202 */
                                                                             /* 0x003fde0000000f00 */
        /*0260*/                   ISETP.LT.U32.AND P0, PT, R0, 0x10, PT ;   /* 0x000000100000780c */
                                                                             /* 0x003fde0003f01070 */
        /*0270*/                   PLOP3.LUT P0, PT, P0, PT, PT, 0x8, 0x0 ;  /* 0x000000000000781c */
                                                                             /* 0x003fde000070e170 */
        /*0280*/                   BSSY B0, 0x6d0 ;                          /* 0x0000044000007945 */
                                                                             /* 0x003fde0003800000 */
        /*0290*/               @P0 BRA 0x6c0 ;                               /* 0x0000042000000947 */
                                                                             /* 0x003fde0003800000 */

         ... ... 

        /*06a0*/                   ST.E [R4.64], R6 ;                        /* 0x0000000604007985 */
                                                                             /* 0x0033de000c101904 */
        /*06b0*/                   BRA 0x6c0 ;                               /* 0x0000000000007947 */
                                                                             /* 0x003fde0003800000 */
        /*06c0*/                   BSYNC B0 ;                                /* 0x0000000000007941 */
                                                                             /* 0x003fde0003800000 */
        /*06d0*/                   S2R R0, SR_TID.X ;                        /* 0x0000000000007919 */
                                                                             /* 0x00321e0000002100 */
```
As we can see, the BSSY instruction sets a barrier and specifies where the BSYNC (synchronization point) is. 

After executing the conditional branch: 
```
(cuda-gdb) si 
0x00000002021566a0	20	    if (threadIdx.x < 16) {
(cuda-gdb) x/i $pc         
=> 0x2021566a0 <_Z8test_braPlj+672>:	BRA 0x2b0 

(cuda-gdb) info cuda lanes 
  Ln   State           PC         ThreadIdx Exception 
Device 0 SM 0 Warp 0
*  0   active  0x00000002021566a0   (0,0,0)    None   
   1   active  0x00000002021566a0   (1,0,0)    None   
   2   active  0x00000002021566a0   (2,0,0)    None   
   3   active  0x00000002021566a0   (3,0,0)    None   
   4   active  0x00000002021566a0   (4,0,0)    None   
   5   active  0x00000002021566a0   (5,0,0)    None   
   6   active  0x00000002021566a0   (6,0,0)    None   
   7   active  0x00000002021566a0   (7,0,0)    None   
   8   active  0x00000002021566a0   (8,0,0)    None   
   9   active  0x00000002021566a0   (9,0,0)    None   
  10   active  0x00000002021566a0  (10,0,0)    None   
  11   active  0x00000002021566a0  (11,0,0)    None   
  12   active  0x00000002021566a0  (12,0,0)    None   
  13   active  0x00000002021566a0  (13,0,0)    None   
  14   active  0x00000002021566a0  (14,0,0)    None   
  15   active  0x00000002021566a0  (15,0,0)    None   
  16 divergent 0x0000000202156ac0  (16,0,0)    None   
  17 divergent 0x0000000202156ac0  (17,0,0)    None   
  18 divergent 0x0000000202156ac0  (18,0,0)    None   
  19 divergent 0x0000000202156ac0  (19,0,0)    None   
  20 divergent 0x0000000202156ac0  (20,0,0)    None   
  21 divergent 0x0000000202156ac0  (21,0,0)    None   
  22 divergent 0x0000000202156ac0  (22,0,0)    None   
  23 divergent 0x0000000202156ac0  (23,0,0)    None   
  24 divergent 0x0000000202156ac0  (24,0,0)    None   
  25 divergent 0x0000000202156ac0  (25,0,0)    None   
  26 divergent 0x0000000202156ac0  (26,0,0)    None   
  27 divergent 0x0000000202156ac0  (27,0,0)    None   
  28 divergent 0x0000000202156ac0  (28,0,0)    None   
  29 divergent 0x0000000202156ac0  (29,0,0)    None   
  30 divergent 0x0000000202156ac0  (30,0,0)    None   
  31 divergent 0x0000000202156ac0  (31,0,0)    None  
(cuda-gdb) info cuda warps 
  Wp Active Lanes Mask Divergent Lanes Mask          Active PC Kernel BlockIdx First Active ThreadIdx 
Device 0 SM 0
*  0        0x0000ffff           0xffff0000 0x00000002021566a0      0  (0,0,0)                (0,0,0) 
   1        0xffffffff           0x00000000 0x0000000202156640      0  (0,0,0)               (32,0,0) 
(cuda-gdb) cuda device sm warp lane block thread 
block (0,0,0), thread (0,0,0), device 0, sm 0, warp 0, lane 0
(cuda-gdb) cuda device 0 sm 0 warp 0 lane 16     
[Switching focus to CUDA kernel 0, grid 1, block (0,0,0), thread (16,0,0), device 0, sm 0, warp 0, lane 16]
0x0000000202156ac0	23	        mem[threadIdx.x + 32] = threadIdx.x;
(cuda-gdb) x/i $pc
=> 0x202156ac0 <_Z8test_braPlj+1728>:	BSYNC B0 
(cuda-gdb) set cuda step_divergent_lanes off 
```
Command ` set cuda step_divergent_lanes off ` instructs cuda-gdb to switch focus when the current focused lane is divergent,
and some other lane is continueing execution when you do `stepi`.

Now: 
```
(cuda-gdb) cuda device 0 sm 0 warp 0 lane 16 
CUDA focus unchanged.
(cuda-gdb) cuda device sm warp lane block thread 
block (0,0,0), thread (16,0,0), device 0, sm 0, warp 0, lane 16
(cuda-gdb) si 
[Switching focus to CUDA kernel 0, grid 1, block (0,0,0), thread (15,0,0), device 0, sm 0, warp 0, lane 15]
21	        mem[threadIdx.x] = threadIdx.y;
(cuda-gdb) info cuda lanes 
  Ln   State           PC         ThreadIdx Exception 
Device 0 SM 0 Warp 0
   0   active  0x00000002021566b0   (0,0,0)    None   
   1   active  0x00000002021566b0   (1,0,0)    None   
   2   active  0x00000002021566b0   (2,0,0)    None   
   3   active  0x00000002021566b0   (3,0,0)    None   
   4   active  0x00000002021566b0   (4,0,0)    None   
   5   active  0x00000002021566b0   (5,0,0)    None   
   6   active  0x00000002021566b0   (6,0,0)    None   
   7   active  0x00000002021566b0   (7,0,0)    None   
   8   active  0x00000002021566b0   (8,0,0)    None   
   9   active  0x00000002021566b0   (9,0,0)    None   
  10   active  0x00000002021566b0  (10,0,0)    None   
  11   active  0x00000002021566b0  (11,0,0)    None   
  12   active  0x00000002021566b0  (12,0,0)    None   
  13   active  0x00000002021566b0  (13,0,0)    None   
  14   active  0x00000002021566b0  (14,0,0)    None   
* 15   active  0x00000002021566b0  (15,0,0)    None   
  16 divergent 0x0000000202156ac0  (16,0,0)    None   
  17 divergent 0x0000000202156ac0  (17,0,0)    None   
  18 divergent 0x0000000202156ac0  (18,0,0)    None   
  19 divergent 0x0000000202156ac0  (19,0,0)    None   
  20 divergent 0x0000000202156ac0  (20,0,0)    None   
  21 divergent 0x0000000202156ac0  (21,0,0)    None   
  22 divergent 0x0000000202156ac0  (22,0,0)    None   
  23 divergent 0x0000000202156ac0  (23,0,0)    None   
  24 divergent 0x0000000202156ac0  (24,0,0)    None   
  25 divergent 0x0000000202156ac0  (25,0,0)    None   
  26 divergent 0x0000000202156ac0  (26,0,0)    None   
  27 divergent 0x0000000202156ac0  (27,0,0)    None   
  28 divergent 0x0000000202156ac0  (28,0,0)    None   
  29 divergent 0x0000000202156ac0  (29,0,0)    None   
  30 divergent 0x0000000202156ac0  (30,0,0)    None   
  31 divergent 0x0000000202156ac0  (31,0,0)    None   
(cuda-gdb) info cuda warps 
  Wp Active Lanes Mask Divergent Lanes Mask          Active PC Kernel BlockIdx First Active ThreadIdx 
Device 0 SM 0
   0        0x0000ffff           0xffff0000 0x00000002021566b0      0  (0,0,0)                (0,0,0) 
   1        0xffffffff           0x00000000 0x0000000202156640      0  (0,0,0)               (32,0,0) 
(cuda-gdb) 

```

This means thread 16-31 is waiting for thread 0-15... 

Switching back to thread 0 and stepi until the final branch instruction: 
```
(cuda-gdb) x/i $pc
=> 0x202156ab0 <_Z8test_braPlj+1712>:	BRA 0x6c0 
(cuda-gdb) info cuda lanes 
  Ln   State           PC         ThreadIdx Exception 
Device 0 SM 0 Warp 0
*  0   active  0x0000000202156ab0   (0,0,0)    None   
   1   active  0x0000000202156ab0   (1,0,0)    None   
   2   active  0x0000000202156ab0   (2,0,0)    None   
   3   active  0x0000000202156ab0   (3,0,0)    None   
   4   active  0x0000000202156ab0   (4,0,0)    None   
   5   active  0x0000000202156ab0   (5,0,0)    None   
   6   active  0x0000000202156ab0   (6,0,0)    None   
   7   active  0x0000000202156ab0   (7,0,0)    None   
   8   active  0x0000000202156ab0   (8,0,0)    None   
   9   active  0x0000000202156ab0   (9,0,0)    None   
  10   active  0x0000000202156ab0  (10,0,0)    None   
  11   active  0x0000000202156ab0  (11,0,0)    None   
  12   active  0x0000000202156ab0  (12,0,0)    None   
  13   active  0x0000000202156ab0  (13,0,0)    None   
  14   active  0x0000000202156ab0  (14,0,0)    None   
  15   active  0x0000000202156ab0  (15,0,0)    None   
  16 divergent 0x0000000202156ac0  (16,0,0)    None   
  17 divergent 0x0000000202156ac0  (17,0,0)    None   
  18 divergent 0x0000000202156ac0  (18,0,0)    None   
  19 divergent 0x0000000202156ac0  (19,0,0)    None   
  20 divergent 0x0000000202156ac0  (20,0,0)    None   
  21 divergent 0x0000000202156ac0  (21,0,0)    None   
  22 divergent 0x0000000202156ac0  (22,0,0)    None   
  23 divergent 0x0000000202156ac0  (23,0,0)    None   
  24 divergent 0x0000000202156ac0  (24,0,0)    None   
  25 divergent 0x0000000202156ac0  (25,0,0)    None   
  26 divergent 0x0000000202156ac0  (26,0,0)    None   
  27 divergent 0x0000000202156ac0  (27,0,0)    None   
  28 divergent 0x0000000202156ac0  (28,0,0)    None   
  29 divergent 0x0000000202156ac0  (29,0,0)    None   
  30 divergent 0x0000000202156ac0  (30,0,0)    None   
  31 divergent 0x0000000202156ac0  (31,0,0)    None   
(cuda-gdb) info cuda warps 
  Wp Active Lanes Mask Divergent Lanes Mask          Active PC Kernel BlockIdx First Active ThreadIdx 
Device 0 SM 0
*  0        0x0000ffff           0xffff0000 0x0000000202156ab0      0  (0,0,0)                (0,0,0) 
   1        0xffffffff           0x00000000 0x0000000202156640      0  (0,0,0)               (32,0,0) 
(cuda-gdb) disas 
Dump of assembler code for function _Z8test_braPlj:
   0x0000000202156400 <+0>:	ISETP.NE.U32.AND P0, PT, RZ, UR2, PT 
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
   0x0000000202156550 <+336>:	MOV R18, c[0x0][0x118] 
   0x0000000202156560 <+352>:	MOV R19, c[0x0][0x11c] 
   0x0000000202156570 <+368>:	MOV R2, RZ 
   0x0000000202156580 <+384>:	LDC.64 R2, c[0x0][R2+0x160] 
   0x0000000202156590 <+400>:	MOV R16, R2 
   0x00000002021565a0 <+416>:	MOV R2, R3 
   0x00000002021565b0 <+432>:	MOV R16, R16 
   0x00000002021565c0 <+448>:	MOV R2, R2 
   0x00000002021565d0 <+464>:	MOV R0, 0x8 
   0x00000002021565e0 <+480>:	LDC R0, c[0x0][R0+0x160] 
   0x00000002021565f0 <+496>:	MOV R0, R0 
   0x0000000202156600 <+512>:	MOV R0, R0 
   0x0000000202156610 <+528>:	MOV R16, R16 
   0x0000000202156620 <+544>:	MOV R2, R2 
   0x0000000202156630 <+560>:	MOV R17, R0 
   0x0000000202156640 <+576>:	S2R R0, SR_TID.X 
   0x0000000202156650 <+592>:	MOV R0, R0 
   0x0000000202156660 <+608>:	ISETP.LT.U32.AND P0, PT, R0, 0x10, PT 
   0x0000000202156670 <+624>:	PLOP3.LUT P0, PT, P0, PT, PT, 0x8, 0x0 
   0x0000000202156680 <+640>:	BSSY B0, 0x6d0 
--Type <RET> for more, q to quit, c to continue without paging--
   0x0000000202156690 <+656>:	@P0 BRA 0x6c0 
   0x00000002021566a0 <+672>:	BRA 0x2b0 
   0x00000002021566b0 <+688>:	S2R R6, SR_TID.Y 
   0x00000002021566c0 <+704>:	MOV R6, R6 
   0x00000002021566d0 <+720>:	S2R R0, SR_TID.X 
   0x00000002021566e0 <+736>:	MOV R0, R0 
   0x00000002021566f0 <+752>:	MOV R0, R0 
   0x0000000202156700 <+768>:	MOV R7, R0 
   0x0000000202156710 <+784>:	MOV R8, RZ 
   0x0000000202156720 <+800>:	MOV R4, 0x0 
   0x0000000202156730 <+816>:	MOV R5, 0x0 
   0x0000000202156740 <+832>:	MOV R4, R4 
   0x0000000202156750 <+848>:	MOV R5, R5 
   0x0000000202156760 <+864>:	MOV R3, R4 
   0x0000000202156770 <+880>:	MOV R0, R5 
   0x0000000202156780 <+896>:	MOV R3, R3 
   0x0000000202156790 <+912>:	MOV R0, R0 
   0x00000002021567a0 <+928>:	SHF.L.U64.HI R5, R7, 0x2, R8 
   0x00000002021567b0 <+944>:	SHF.L.U32 R4, R7, 0x2, RZ 
   0x00000002021567c0 <+960>:	IADD3 R4, P0, R3, R4, RZ 
   0x00000002021567d0 <+976>:	IADD3.X R5, R0, R5, RZ, P0, !PT 
   0x00000002021567e0 <+992>:	MOV R4, R4 
   0x00000002021567f0 <+1008>:	MOV R5, R5 
   0x0000000202156800 <+1024>:	MOV R4, R4 
   0x0000000202156810 <+1040>:	MOV R5, R5 
   0x0000000202156820 <+1056>:	R2UR UR4, R18 
   0x0000000202156830 <+1072>:	R2UR UR5, R19 
   0x0000000202156840 <+1088>:	ST.E [R4.64], R6 
   0x0000000202156850 <+1104>:	S2R R6, SR_TID.Z 
   0x0000000202156860 <+1120>:	MOV R6, R6 
   0x0000000202156870 <+1136>:	S2R R4, SR_TID.X 
   0x0000000202156880 <+1152>:	MOV R4, R4 
   0x0000000202156890 <+1168>:	IADD3 R4, R4, 0x10, RZ 
   0x00000002021568a0 <+1184>:	MOV R4, R4 
   0x00000002021568b0 <+1200>:	MOV R4, R4 
   0x00000002021568c0 <+1216>:	MOV R5, RZ 
   0x00000002021568d0 <+1232>:	SHF.L.U64.HI R5, R4, 0x2, R5 
   0x00000002021568e0 <+1248>:	SHF.L.U32 R4, R4, 0x2, RZ 
   0x00000002021568f0 <+1264>:	IADD3 R4, P0, R3, R4, RZ 
   0x0000000202156900 <+1280>:	IADD3.X R5, R0, R5, RZ, P0, !PT 
   0x0000000202156910 <+1296>:	MOV R4, R4 
   0x0000000202156920 <+1312>:	MOV R5, R5 
--Type <RET> for more, q to quit, c to continue without paging--c
   0x0000000202156930 <+1328>:	MOV R4, R4 
   0x0000000202156940 <+1344>:	MOV R5, R5 
   0x0000000202156950 <+1360>:	R2UR UR4, R18 
   0x0000000202156960 <+1376>:	R2UR UR5, R19 
   0x0000000202156970 <+1392>:	ST.E [R4.64], R6 
   0x0000000202156980 <+1408>:	S2R R6, SR_TID.X 
   0x0000000202156990 <+1424>:	MOV R6, R6 
   0x00000002021569a0 <+1440>:	S2R R4, SR_TID.X 
   0x00000002021569b0 <+1456>:	MOV R4, R4 
   0x00000002021569c0 <+1472>:	IADD3 R4, R4, 0x20, RZ 
   0x00000002021569d0 <+1488>:	MOV R4, R4 
   0x00000002021569e0 <+1504>:	MOV R4, R4 
   0x00000002021569f0 <+1520>:	MOV R5, RZ 
   0x0000000202156a00 <+1536>:	SHF.L.U64.HI R5, R4, 0x2, R5 
   0x0000000202156a10 <+1552>:	SHF.L.U32 R4, R4, 0x2, RZ 
   0x0000000202156a20 <+1568>:	IADD3 R4, P0, R3, R4, RZ 
   0x0000000202156a30 <+1584>:	IADD3.X R5, R0, R5, RZ, P0, !PT 
   0x0000000202156a40 <+1600>:	MOV R4, R4 
   0x0000000202156a50 <+1616>:	MOV R5, R5 
   0x0000000202156a60 <+1632>:	MOV R4, R4 
   0x0000000202156a70 <+1648>:	MOV R5, R5 
   0x0000000202156a80 <+1664>:	R2UR UR4, R18 
   0x0000000202156a90 <+1680>:	R2UR UR5, R19 
   0x0000000202156aa0 <+1696>:	ST.E [R4.64], R6 
=> 0x0000000202156ab0 <+1712>:	BRA 0x6c0 
   0x0000000202156ac0 <+1728>:	BSYNC B0 
   0x0000000202156ad0 <+1744>:	S2R R0, SR_TID.X 
   0x0000000202156ae0 <+1760>:	MOV R0, R0 
   0x0000000202156af0 <+1776>:	ISETP.LT.U32.AND P0, PT, R0, 0x20, PT 
   0x0000000202156b00 <+1792>:	PLOP3.LUT P0, PT, P0, PT, PT, 0x8, 0x0 
   0x0000000202156b10 <+1808>:	@P0 BRA 0x9d0 
   0x0000000202156b20 <+1824>:	BRA 0x730 
   0x0000000202156b30 <+1840>:	BRA.CONV ~URZ, 0x790 
   0x0000000202156b40 <+1856>:	MOV R4, 0x20 
   0x0000000202156b50 <+1872>:	MOV R20, 0x0 
   0x0000000202156b60 <+1888>:	MOV R21, 0x0 
   0x0000000202156b70 <+1904>:	CALL.ABS.NOINC 0x0 
   0x0000000202156b80 <+1920>:	BRA 0x7a0 
   0x0000000202156b90 <+1936>:	BAR.SYNC 0x0, 0x20 
   0x0000000202156ba0 <+1952>:	S2R R0, SR_TID.X 
   0x0000000202156bb0 <+1968>:	MOV R0, R0 
   0x0000000202156bc0 <+1984>:	S2R R2, SR_TID.X 
   0x0000000202156bd0 <+2000>:	MOV R2, R2 
   0x0000000202156be0 <+2016>:	MOV R2, R2 
   0x0000000202156bf0 <+2032>:	MOV R6, R2 
   0x0000000202156c00 <+2048>:	MOV R7, RZ 
   0x0000000202156c10 <+2064>:	MOV R2, 0x0 
   0x0000000202156c20 <+2080>:	MOV R2, R2 
   0x0000000202156c30 <+2096>:	MOV R2, R2 
   0x0000000202156c40 <+2112>:	MOV R2, R2 
   0x0000000202156c50 <+2128>:	MOV R3, RZ 
   0x0000000202156c60 <+2144>:	MOV R4, c[0x0][0x18] 
   0x0000000202156c70 <+2160>:	MOV R5, c[0x0][0x1c] 
   0x0000000202156c80 <+2176>:	IADD3 R4, P0, R2, R4, RZ 
   0x0000000202156c90 <+2192>:	IADD3.X R5, R3, R5, RZ, P0, !PT 
   0x0000000202156ca0 <+2208>:	SHF.L.U64.HI R3, R6, 0x2, R7 
   0x0000000202156cb0 <+2224>:	SHF.L.U32 R2, R6, 0x2, RZ 
   0x0000000202156cc0 <+2240>:	IADD3 R2, P0, R4, R2, RZ 
   0x0000000202156cd0 <+2256>:	IADD3.X R3, R5, R3, RZ, P0, !PT 
   0x0000000202156ce0 <+2272>:	MOV R2, R2 
   0x0000000202156cf0 <+2288>:	MOV R3, R3 
   0x0000000202156d00 <+2304>:	MOV R2, R2 
   0x0000000202156d10 <+2320>:	MOV R3, R3 
   0x0000000202156d20 <+2336>:	R2UR UR4, R18 
   0x0000000202156d30 <+2352>:	R2UR UR5, R19 
   0x0000000202156d40 <+2368>:	ST.E [R2.64], R0 
   0x0000000202156d50 <+2384>:	BRA.CONV ~URZ, 0x9b0 
   0x0000000202156d60 <+2400>:	MOV R4, 0x20 
   0x0000000202156d70 <+2416>:	MOV R20, 0x0 
   0x0000000202156d80 <+2432>:	MOV R21, 0x0 
   0x0000000202156d90 <+2448>:	CALL.ABS.NOINC 0x0 
   0x0000000202156da0 <+2464>:	BRA 0x9c0 
   0x0000000202156db0 <+2480>:	BAR.ARV 0x1, 0x20 
   0x0000000202156dc0 <+2496>:	BRA 0xda0 
   0x0000000202156dd0 <+2512>:	BRA.CONV ~URZ, 0xa30 
   0x0000000202156de0 <+2528>:	MOV R4, 0x20 
   0x0000000202156df0 <+2544>:	MOV R20, 0x0 
   0x0000000202156e00 <+2560>:	MOV R21, 0x0 
   0x0000000202156e10 <+2576>:	CALL.ABS.NOINC 0x0 
   0x0000000202156e20 <+2592>:	BRA 0xa40 
   0x0000000202156e30 <+2608>:	BAR.ARV 0x0, 0x20 
   0x0000000202156e40 <+2624>:	BRA.CONV ~URZ, 0xaa0 
   0x0000000202156e50 <+2640>:	MOV R4, 0x20 
   0x0000000202156e60 <+2656>:	MOV R20, 0x0 
   0x0000000202156e70 <+2672>:	MOV R21, 0x0 
   0x0000000202156e80 <+2688>:	CALL.ABS.NOINC 0x0 
   0x0000000202156e90 <+2704>:	BRA 0xab0 
   0x0000000202156ea0 <+2720>:	BAR.SYNC 0x1, 0x20 
   0x0000000202156eb0 <+2736>:	S2R R0, SR_TID.X 
   0x0000000202156ec0 <+2752>:	MOV R0, R0 
   0x0000000202156ed0 <+2768>:	IADD3 R0, R0, -0x20, RZ 
   0x0000000202156ee0 <+2784>:	MOV R0, R0 
   0x0000000202156ef0 <+2800>:	MOV R6, R0 
   0x0000000202156f00 <+2816>:	MOV R7, RZ 
   0x0000000202156f10 <+2832>:	MOV R0, 0x0 
   0x0000000202156f20 <+2848>:	MOV R0, R0 
   0x0000000202156f30 <+2864>:	MOV R0, R0 
   0x0000000202156f40 <+2880>:	MOV R4, R0 
   0x0000000202156f50 <+2896>:	MOV R5, RZ 
   0x0000000202156f60 <+2912>:	MOV R0, c[0x0][0x18] 
   0x0000000202156f70 <+2928>:	MOV R3, c[0x0][0x1c] 
   0x0000000202156f80 <+2944>:	IADD3 R0, P0, R4, R0, RZ 
   0x0000000202156f90 <+2960>:	IADD3.X R3, R5, R3, RZ, P0, !PT 
   0x0000000202156fa0 <+2976>:	SHF.L.U64.HI R5, R6, 0x2, R7 
   0x0000000202156fb0 <+2992>:	SHF.L.U32 R4, R6, 0x2, RZ 
   0x0000000202156fc0 <+3008>:	IADD3 R4, P0, R0, R4, RZ 
   0x0000000202156fd0 <+3024>:	IADD3.X R5, R3, R5, RZ, P0, !PT 
   0x0000000202156fe0 <+3040>:	MOV R4, R4 
   0x0000000202156ff0 <+3056>:	MOV R5, R5 
   0x0000000202157000 <+3072>:	MOV R4, R4 
   0x0000000202157010 <+3088>:	MOV R5, R5 
   0x0000000202157020 <+3104>:	R2UR UR4, R18 
   0x0000000202157030 <+3120>:	R2UR UR5, R19 
   0x0000000202157040 <+3136>:	LD.E R4, [R4.64] 
   0x0000000202157050 <+3152>:	MOV R4, R4 
   0x0000000202157060 <+3168>:	MOV R4, R4 
   0x0000000202157070 <+3184>:	MOV R5, RZ 
   0x0000000202157080 <+3200>:	S2R R0, SR_TID.X 
   0x0000000202157090 <+3216>:	MOV R0, R0 
   0x00000002021570a0 <+3232>:	IADD3 R0, R0, -0x20, RZ 
   0x00000002021570b0 <+3248>:	MOV R0, R0 
   0x00000002021570c0 <+3264>:	MOV R0, R0 
   0x00000002021570d0 <+3280>:	MOV R3, RZ 
   0x00000002021570e0 <+3296>:	SHF.L.U64.HI R3, R0, 0x3, R3 
   0x00000002021570f0 <+3312>:	SHF.L.U32 R0, R0, 0x3, RZ 
   0x0000000202157100 <+3328>:	IADD3 R16, P0, R16, R0, RZ 
   0x0000000202157110 <+3344>:	IADD3.X R3, R2, R3, RZ, P0, !PT 
   0x0000000202157120 <+3360>:	MOV R2, R16 
   0x0000000202157130 <+3376>:	MOV R3, R3 
   0x0000000202157140 <+3392>:	MOV R2, R2 
   0x0000000202157150 <+3408>:	MOV R3, R3 
   0x0000000202157160 <+3424>:	R2UR UR4, R18 
   0x0000000202157170 <+3440>:	R2UR UR5, R19 
   0x0000000202157180 <+3456>:	ST.E.64 [R2.64], R4 
   0x0000000202157190 <+3472>:	BRA 0xda0 
   0x00000002021571a0 <+3488>:	MEMBAR.SC.VC 
   0x00000002021571b0 <+3504>:	ERRBAR 
   0x00000002021571c0 <+3520>:	EXIT 
   0x00000002021571d0 <+3536>:	MEMBAR.SC.VC 
   0x00000002021571e0 <+3552>:	ERRBAR 
   0x00000002021571f0 <+3568>:	EXIT 
   0x0000000202157200 <+3584>:	BRA 0xe00
   0x0000000202157210 <+3600>:	NOP
   0x0000000202157220 <+3616>:	NOP
   0x0000000202157230 <+3632>:	NOP
   0x0000000202157240 <+3648>:	NOP
   0x0000000202157250 <+3664>:	NOP
   0x0000000202157260 <+3680>:	NOP
   0x0000000202157270 <+3696>:	NOP
   0x0000000202157280 <+3712>:	NOP
   0x0000000202157290 <+3728>:	NOP
   0x00000002021572a0 <+3744>:	NOP
   0x00000002021572b0 <+3760>:	NOP
   0x00000002021572c0 <+3776>:	NOP
   0x00000002021572d0 <+3792>:	NOP
   0x00000002021572e0 <+3808>:	NOP
   0x00000002021572f0 <+3824>:	NOP
End of assembler dump.
(cuda-gdb) 
```


After executing the final instruction of the if-block, all threads are at the same PC now: 


```
(cuda-gdb) cuda device 0 sm 0 warp 0 lane 16 
[Switching focus to CUDA kernel 0, grid 1, block (0,0,0), thread (16,0,0), device 0, sm 0, warp 0, lane 16]
0x0000000202156ac0	23	        mem[threadIdx.x + 32] = threadIdx.x;
(cuda-gdb) si 
[Switching focus to CUDA kernel 0, grid 1, block (0,0,0), thread (15,0,0), device 0, sm 0, warp 0, lane 15]
0x0000000202156ac0	23	        mem[threadIdx.x + 32] = threadIdx.x;
(cuda-gdb) info cuda barriers 
Unrecognized option: 'barriers'.
(cuda-gdb) print $B0
$3 = void
(cuda-gdb) info cuda lanes 
  Ln   State           PC         ThreadIdx Exception 
Device 0 SM 0 Warp 0
   0   active  0x0000000202156ac0   (0,0,0)    None   
   1   active  0x0000000202156ac0   (1,0,0)    None   
   2   active  0x0000000202156ac0   (2,0,0)    None   
   3   active  0x0000000202156ac0   (3,0,0)    None   
   4   active  0x0000000202156ac0   (4,0,0)    None   
   5   active  0x0000000202156ac0   (5,0,0)    None   
   6   active  0x0000000202156ac0   (6,0,0)    None   
   7   active  0x0000000202156ac0   (7,0,0)    None   
   8   active  0x0000000202156ac0   (8,0,0)    None   
   9   active  0x0000000202156ac0   (9,0,0)    None   
  10   active  0x0000000202156ac0  (10,0,0)    None   
  11   active  0x0000000202156ac0  (11,0,0)    None   
  12   active  0x0000000202156ac0  (12,0,0)    None   
  13   active  0x0000000202156ac0  (13,0,0)    None   
  14   active  0x0000000202156ac0  (14,0,0)    None   
* 15   active  0x0000000202156ac0  (15,0,0)    None   
  16 divergent 0x0000000202156ac0  (16,0,0)    None   
  17 divergent 0x0000000202156ac0  (17,0,0)    None   
  18 divergent 0x0000000202156ac0  (18,0,0)    None   
  19 divergent 0x0000000202156ac0  (19,0,0)    None   
  20 divergent 0x0000000202156ac0  (20,0,0)    None   
  21 divergent 0x0000000202156ac0  (21,0,0)    None   
  22 divergent 0x0000000202156ac0  (22,0,0)    None   
  23 divergent 0x0000000202156ac0  (23,0,0)    None   
  24 divergent 0x0000000202156ac0  (24,0,0)    None   
  25 divergent 0x0000000202156ac0  (25,0,0)    None   
  26 divergent 0x0000000202156ac0  (26,0,0)    None   
  27 divergent 0x0000000202156ac0  (27,0,0)    None   
  28 divergent 0x0000000202156ac0  (28,0,0)    None   
  29 divergent 0x0000000202156ac0  (29,0,0)    None   
  30 divergent 0x0000000202156ac0  (30,0,0)    None   
  31 divergent 0x0000000202156ac0  (31,0,0)    None   
(cuda-gdb) 
```

si again: 
```
(cuda-gdb) cuda device 0 sm 0 warp 0 lane 16 
[Switching focus to CUDA kernel 0, grid 1, block (0,0,0), thread (16,0,0), device 0, sm 0, warp 0, lane 16]
0x0000000202156ac0	23	        mem[threadIdx.x + 32] = threadIdx.x;
(cuda-gdb) si                                
0x0000000202156ac0	23	        mem[threadIdx.x + 32] = threadIdx.x;
(cuda-gdb) info cuda lanes                   
  Ln  State         PC         ThreadIdx Exception 
Device 0 SM 0 Warp 0
   0 active 0x0000000202156ac0   (0,0,0)    None   
   1 active 0x0000000202156ac0   (1,0,0)    None   
   2 active 0x0000000202156ac0   (2,0,0)    None   
   3 active 0x0000000202156ac0   (3,0,0)    None   
   4 active 0x0000000202156ac0   (4,0,0)    None   
   5 active 0x0000000202156ac0   (5,0,0)    None   
   6 active 0x0000000202156ac0   (6,0,0)    None   
   7 active 0x0000000202156ac0   (7,0,0)    None   
   8 active 0x0000000202156ac0   (8,0,0)    None   
   9 active 0x0000000202156ac0   (9,0,0)    None   
  10 active 0x0000000202156ac0  (10,0,0)    None   
  11 active 0x0000000202156ac0  (11,0,0)    None   
  12 active 0x0000000202156ac0  (12,0,0)    None   
  13 active 0x0000000202156ac0  (13,0,0)    None   
  14 active 0x0000000202156ac0  (14,0,0)    None   
  15 active 0x0000000202156ac0  (15,0,0)    None   
* 16 active 0x0000000202156ac0  (16,0,0)    None   
  17 active 0x0000000202156ac0  (17,0,0)    None   
  18 active 0x0000000202156ac0  (18,0,0)    None   
  19 active 0x0000000202156ac0  (19,0,0)    None   
  20 active 0x0000000202156ac0  (20,0,0)    None   
  21 active 0x0000000202156ac0  (21,0,0)    None   
  22 active 0x0000000202156ac0  (22,0,0)    None   
  23 active 0x0000000202156ac0  (23,0,0)    None   
  24 active 0x0000000202156ac0  (24,0,0)    None   
  25 active 0x0000000202156ac0  (25,0,0)    None   
  26 active 0x0000000202156ac0  (26,0,0)    None   
  27 active 0x0000000202156ac0  (27,0,0)    None   
  28 active 0x0000000202156ac0  (28,0,0)    None   
  29 active 0x0000000202156ac0  (29,0,0)    None   
  30 active 0x0000000202156ac0  (30,0,0)    None   
  31 active 0x0000000202156ac0  (31,0,0)    None   
(cuda-gdb) 
```

## Conclusion 1 
`BSYNC` has regrouping effect.



Continue to the next conditional branch: 
```
(cuda-gdb) si
25	    if (threadIdx.x < NN) {
(cuda-gdb) si
0x0000000202156ae0	25	    if (threadIdx.x < NN) {
(cuda-gdb) si
0x0000000202156af0	25	    if (threadIdx.x < NN) {
(cuda-gdb) x/i $pc
=> 0x202156af0 <_Z8test_braPlj+1776>:	ISETP.LT.U32.AND P0, PT, R0, 0x20, PT 
(cuda-gdb) si
0x0000000202156b00	25	    if (threadIdx.x < NN) {
(cuda-gdb) x/i $pc
=> 0x202156b00 <_Z8test_braPlj+1792>:	PLOP3.LUT P0, PT, P0, PT, PT, 0x8, 0x0 
(cuda-gdb) si
0x0000000202156b10	25	    if (threadIdx.x < NN) {
(cuda-gdb) x/i $pc
=> 0x202156b10 <_Z8test_braPlj+1808>:	@P0 BRA 0x9d0 
(cuda-gdb) info cuda warps 
  Wp Active Lanes Mask Divergent Lanes Mask          Active PC Kernel BlockIdx First Active ThreadIdx 
Device 0 SM 0
   0        0xffffffff           0x00000000 0x0000000202156b10      0  (0,0,0)                (0,0,0) 
   1        0xffffffff           0x00000000 0x0000000202156640      0  (0,0,0)               (32,0,0) 
(cuda-gdb) 
```

As we can see, warp1 hasn't run yet, as it's PC is still at the starting PC. 

Now: we switch to warp 1 and try to si from it, let's see what happens: 
```
(cuda-gdb) si                                
0x0000000202156b20	25	    if (threadIdx.x < NN) {
(cuda-gdb) info cuda warps 
  Wp Active Lanes Mask Divergent Lanes Mask          Active PC Kernel BlockIdx First Active ThreadIdx 
Device 0 SM 0
   0        0xffffffff           0x00000000 0x0000000202156b20      0  (0,0,0)                (0,0,0) 
   1        0xffffffff           0x00000000 0x0000000202156640      0  (0,0,0)               (32,0,0) 
(cuda-gdb) si
26	        asm("barrier.cta.sync 0, 32;\n\t");
(cuda-gdb) x/i $pc         
=> 0x202156b30 <_Z8test_braPlj+1840>:	BRA.CONV ~URZ, 0x790 
(cuda-gdb) info cuda warps 
  Wp Active Lanes Mask Divergent Lanes Mask          Active PC Kernel BlockIdx First Active ThreadIdx 
Device 0 SM 0
   0        0xffffffff           0x00000000 0x0000000202156b30      0  (0,0,0)                (0,0,0) 
   1        0xffffffff           0x00000000 0x0000000202156640      0  (0,0,0)               (32,0,0) 
(cuda-gdb) cuda device 0 sm 0 warp 1 lane 0
[Switching focus to CUDA kernel 0, grid 1, block (0,0,0), thread (32,0,0), device 0, sm 0, warp 1, lane 0]
20	    if (threadIdx.x < 16) {
(cuda-gdb) disas  
Dump of assembler code for function _Z8test_braPlj:
   0x0000000202156400 <+0>:	ISETP.NE.U32.AND P0, PT, RZ, UR2, PT 
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
   0x0000000202156550 <+336>:	MOV R18, c[0x0][0x118] 
   0x0000000202156560 <+352>:	MOV R19, c[0x0][0x11c] 
   0x0000000202156570 <+368>:	MOV R2, RZ 
   0x0000000202156580 <+384>:	LDC.64 R2, c[0x0][R2+0x160] 
   0x0000000202156590 <+400>:	MOV R16, R2 
   0x00000002021565a0 <+416>:	MOV R2, R3 
   0x00000002021565b0 <+432>:	MOV R16, R16 
   0x00000002021565c0 <+448>:	MOV R2, R2 
   0x00000002021565d0 <+464>:	MOV R0, 0x8 
   0x00000002021565e0 <+480>:	LDC R0, c[0x0][R0+0x160] 
   0x00000002021565f0 <+496>:	MOV R0, R0 
   0x0000000202156600 <+512>:	MOV R0, R0 
   0x0000000202156610 <+528>:	MOV R16, R16 
   0x0000000202156620 <+544>:	MOV R2, R2 
   0x0000000202156630 <+560>:	MOV R17, R0 
=> 0x0000000202156640 <+576>:	S2R R0, SR_TID.X 
   0x0000000202156650 <+592>:	MOV R0, R0 
   0x0000000202156660 <+608>:	ISETP.LT.U32.AND P0, PT, R0, 0x10, PT 
   0x0000000202156670 <+624>:	PLOP3.LUT P0, PT, P0, PT, PT, 0x8, 0x0 
   0x0000000202156680 <+640>:	BSSY B0, 0x6d0 
--Type <RET> for more, q to quit, c to continue without paging--

```

si a bit: 
```
(cuda-gdb) si
0x0000000202156650	20	    if (threadIdx.x < 16) {
(cuda-gdb) info cuda warps 
  Wp Active Lanes Mask Divergent Lanes Mask          Active PC Kernel BlockIdx First Active ThreadIdx 
Device 0 SM 0
   0        0xffffffff           0x00000000 0x0000000202156b30      0  (0,0,0)                (0,0,0) 
*  1        0xffffffff           0x00000000 0x0000000202156650      0  (0,0,0)               (32,0,0) 
(cuda-gdb) si 10
0x0000000202156b00	25	    if (threadIdx.x < NN) {
(cuda-gdb) info cuda warps 
  Wp Active Lanes Mask Divergent Lanes Mask          Active PC Kernel BlockIdx First Active ThreadIdx 
Device 0 SM 0
   0        0xffffffff           0x00000000 0x0000000202156b30      0  (0,0,0)                (0,0,0) 
*  1        0xffffffff           0x00000000 0x0000000202156b00      0  (0,0,0)               (32,0,0) 


(cuda-gdb) si 
0x0000000202156b10	25	    if (threadIdx.x < NN) {
(cuda-gdb) info cuda warps 
  Wp Active Lanes Mask Divergent Lanes Mask          Active PC Kernel BlockIdx First Active ThreadIdx 
Device 0 SM 0
   0        0xffffffff           0x00000000 0x0000000202156b30      0  (0,0,0)                (0,0,0) 
*  1        0xffffffff           0x00000000 0x0000000202156b10      0  (0,0,0)               (32,0,0) 
(cuda-gdb) x/i $pc
=> 0x202156b10 <_Z8test_braPlj+1808>:	@P0 BRA 0x9d0 
(cuda-gdb) disas 
Dump of assembler code for function _Z8test_braPlj:
   0x0000000202156400 <+0>:	ISETP.NE.U32.AND P0, PT, RZ, UR2, PT 
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
   0x0000000202156550 <+336>:	MOV R18, c[0x0][0x118] 
   0x0000000202156560 <+352>:	MOV R19, c[0x0][0x11c] 
   0x0000000202156570 <+368>:	MOV R2, RZ 
   0x0000000202156580 <+384>:	LDC.64 R2, c[0x0][R2+0x160] 
   0x0000000202156590 <+400>:	MOV R16, R2 
   0x00000002021565a0 <+416>:	MOV R2, R3 
   0x00000002021565b0 <+432>:	MOV R16, R16 
   0x00000002021565c0 <+448>:	MOV R2, R2 
   0x00000002021565d0 <+464>:	MOV R0, 0x8 
   0x00000002021565e0 <+480>:	LDC R0, c[0x0][R0+0x160] 
   0x00000002021565f0 <+496>:	MOV R0, R0 
   0x0000000202156600 <+512>:	MOV R0, R0 
   0x0000000202156610 <+528>:	MOV R16, R16 
   0x0000000202156620 <+544>:	MOV R2, R2 
   0x0000000202156630 <+560>:	MOV R17, R0 
   0x0000000202156640 <+576>:	S2R R0, SR_TID.X 
   0x0000000202156650 <+592>:	MOV R0, R0 
   0x0000000202156660 <+608>:	ISETP.LT.U32.AND P0, PT, R0, 0x10, PT 
   0x0000000202156670 <+624>:	PLOP3.LUT P0, PT, P0, PT, PT, 0x8, 0x0 
   0x0000000202156680 <+640>:	BSSY B0, 0x6d0 
--Type <RET> for more, q to quit, c to continue without paging--c
   0x0000000202156690 <+656>:	@P0 BRA 0x6c0 
   0x00000002021566a0 <+672>:	BRA 0x2b0 
   0x00000002021566b0 <+688>:	S2R R6, SR_TID.Y 
   0x00000002021566c0 <+704>:	MOV R6, R6 
   0x00000002021566d0 <+720>:	S2R R0, SR_TID.X 
   0x00000002021566e0 <+736>:	MOV R0, R0 
   0x00000002021566f0 <+752>:	MOV R0, R0 
   0x0000000202156700 <+768>:	MOV R7, R0 
   0x0000000202156710 <+784>:	MOV R8, RZ 
   0x0000000202156720 <+800>:	MOV R4, 0x0 
   0x0000000202156730 <+816>:	MOV R5, 0x0 
   0x0000000202156740 <+832>:	MOV R4, R4 
   0x0000000202156750 <+848>:	MOV R5, R5 
   0x0000000202156760 <+864>:	MOV R3, R4 
   0x0000000202156770 <+880>:	MOV R0, R5 
   0x0000000202156780 <+896>:	MOV R3, R3 
   0x0000000202156790 <+912>:	MOV R0, R0 
   0x00000002021567a0 <+928>:	SHF.L.U64.HI R5, R7, 0x2, R8 
   0x00000002021567b0 <+944>:	SHF.L.U32 R4, R7, 0x2, RZ 
   0x00000002021567c0 <+960>:	IADD3 R4, P0, R3, R4, RZ 
   0x00000002021567d0 <+976>:	IADD3.X R5, R0, R5, RZ, P0, !PT 
   0x00000002021567e0 <+992>:	MOV R4, R4 
   0x00000002021567f0 <+1008>:	MOV R5, R5 
   0x0000000202156800 <+1024>:	MOV R4, R4 
   0x0000000202156810 <+1040>:	MOV R5, R5 
   0x0000000202156820 <+1056>:	R2UR UR4, R18 
   0x0000000202156830 <+1072>:	R2UR UR5, R19 
   0x0000000202156840 <+1088>:	ST.E [R4.64], R6 
   0x0000000202156850 <+1104>:	S2R R6, SR_TID.Z 
   0x0000000202156860 <+1120>:	MOV R6, R6 
   0x0000000202156870 <+1136>:	S2R R4, SR_TID.X 
   0x0000000202156880 <+1152>:	MOV R4, R4 
   0x0000000202156890 <+1168>:	IADD3 R4, R4, 0x10, RZ 
   0x00000002021568a0 <+1184>:	MOV R4, R4 
   0x00000002021568b0 <+1200>:	MOV R4, R4 
   0x00000002021568c0 <+1216>:	MOV R5, RZ 
   0x00000002021568d0 <+1232>:	SHF.L.U64.HI R5, R4, 0x2, R5 
   0x00000002021568e0 <+1248>:	SHF.L.U32 R4, R4, 0x2, RZ 
   0x00000002021568f0 <+1264>:	IADD3 R4, P0, R3, R4, RZ 
   0x0000000202156900 <+1280>:	IADD3.X R5, R0, R5, RZ, P0, !PT 
   0x0000000202156910 <+1296>:	MOV R4, R4 
   0x0000000202156920 <+1312>:	MOV R5, R5 
   0x0000000202156930 <+1328>:	MOV R4, R4 
   0x0000000202156940 <+1344>:	MOV R5, R5 
   0x0000000202156950 <+1360>:	R2UR UR4, R18 
   0x0000000202156960 <+1376>:	R2UR UR5, R19 
   0x0000000202156970 <+1392>:	ST.E [R4.64], R6 
   0x0000000202156980 <+1408>:	S2R R6, SR_TID.X 
   0x0000000202156990 <+1424>:	MOV R6, R6 
   0x00000002021569a0 <+1440>:	S2R R4, SR_TID.X 
   0x00000002021569b0 <+1456>:	MOV R4, R4 
   0x00000002021569c0 <+1472>:	IADD3 R4, R4, 0x20, RZ 
   0x00000002021569d0 <+1488>:	MOV R4, R4 
   0x00000002021569e0 <+1504>:	MOV R4, R4 
   0x00000002021569f0 <+1520>:	MOV R5, RZ 
   0x0000000202156a00 <+1536>:	SHF.L.U64.HI R5, R4, 0x2, R5 
   0x0000000202156a10 <+1552>:	SHF.L.U32 R4, R4, 0x2, RZ 
   0x0000000202156a20 <+1568>:	IADD3 R4, P0, R3, R4, RZ 
   0x0000000202156a30 <+1584>:	IADD3.X R5, R0, R5, RZ, P0, !PT 
   0x0000000202156a40 <+1600>:	MOV R4, R4 
   0x0000000202156a50 <+1616>:	MOV R5, R5 
   0x0000000202156a60 <+1632>:	MOV R4, R4 
   0x0000000202156a70 <+1648>:	MOV R5, R5 
   0x0000000202156a80 <+1664>:	R2UR UR4, R18 
   0x0000000202156a90 <+1680>:	R2UR UR5, R19 
   0x0000000202156aa0 <+1696>:	ST.E [R4.64], R6 
   0x0000000202156ab0 <+1712>:	BRA 0x6c0 
   0x0000000202156ac0 <+1728>:	BSYNC B0 
   0x0000000202156ad0 <+1744>:	S2R R0, SR_TID.X 
   0x0000000202156ae0 <+1760>:	MOV R0, R0 
   0x0000000202156af0 <+1776>:	ISETP.LT.U32.AND P0, PT, R0, 0x20, PT 
   0x0000000202156b00 <+1792>:	PLOP3.LUT P0, PT, P0, PT, PT, 0x8, 0x0 
=> 0x0000000202156b10 <+1808>:	@P0 BRA 0x9d0 
   0x0000000202156b20 <+1824>:	BRA 0x730 
   0x0000000202156b30 <+1840>:	BRA.CONV ~URZ, 0x790 
   0x0000000202156b40 <+1856>:	MOV R4, 0x20 
   0x0000000202156b50 <+1872>:	MOV R20, 0x0 
   0x0000000202156b60 <+1888>:	MOV R21, 0x0 
   0x0000000202156b70 <+1904>:	CALL.ABS.NOINC 0x0 
   0x0000000202156b80 <+1920>:	BRA 0x7a0 
   0x0000000202156b90 <+1936>:	BAR.SYNC 0x0, 0x20 
   0x0000000202156ba0 <+1952>:	S2R R0, SR_TID.X 
   0x0000000202156bb0 <+1968>:	MOV R0, R0 
   0x0000000202156bc0 <+1984>:	S2R R2, SR_TID.X 
   0x0000000202156bd0 <+2000>:	MOV R2, R2 
   0x0000000202156be0 <+2016>:	MOV R2, R2 
   0x0000000202156bf0 <+2032>:	MOV R6, R2 
   0x0000000202156c00 <+2048>:	MOV R7, RZ 
   0x0000000202156c10 <+2064>:	MOV R2, 0x0 
   0x0000000202156c20 <+2080>:	MOV R2, R2 
   0x0000000202156c30 <+2096>:	MOV R2, R2 
   0x0000000202156c40 <+2112>:	MOV R2, R2 
   0x0000000202156c50 <+2128>:	MOV R3, RZ 
   0x0000000202156c60 <+2144>:	MOV R4, c[0x0][0x18] 
   0x0000000202156c70 <+2160>:	MOV R5, c[0x0][0x1c] 
   0x0000000202156c80 <+2176>:	IADD3 R4, P0, R2, R4, RZ 
   0x0000000202156c90 <+2192>:	IADD3.X R5, R3, R5, RZ, P0, !PT 
   0x0000000202156ca0 <+2208>:	SHF.L.U64.HI R3, R6, 0x2, R7 
   0x0000000202156cb0 <+2224>:	SHF.L.U32 R2, R6, 0x2, RZ 
   0x0000000202156cc0 <+2240>:	IADD3 R2, P0, R4, R2, RZ 
   0x0000000202156cd0 <+2256>:	IADD3.X R3, R5, R3, RZ, P0, !PT 
   0x0000000202156ce0 <+2272>:	MOV R2, R2 
   0x0000000202156cf0 <+2288>:	MOV R3, R3 
   0x0000000202156d00 <+2304>:	MOV R2, R2 
   0x0000000202156d10 <+2320>:	MOV R3, R3 
   0x0000000202156d20 <+2336>:	R2UR UR4, R18 
   0x0000000202156d30 <+2352>:	R2UR UR5, R19 
   0x0000000202156d40 <+2368>:	ST.E [R2.64], R0 
   0x0000000202156d50 <+2384>:	BRA.CONV ~URZ, 0x9b0 
   0x0000000202156d60 <+2400>:	MOV R4, 0x20 
   0x0000000202156d70 <+2416>:	MOV R20, 0x0 
   0x0000000202156d80 <+2432>:	MOV R21, 0x0 
   0x0000000202156d90 <+2448>:	CALL.ABS.NOINC 0x0 
   0x0000000202156da0 <+2464>:	BRA 0x9c0 
   0x0000000202156db0 <+2480>:	BAR.ARV 0x1, 0x20 
   0x0000000202156dc0 <+2496>:	BRA 0xda0 
   0x0000000202156dd0 <+2512>:	BRA.CONV ~URZ, 0xa30 
   0x0000000202156de0 <+2528>:	MOV R4, 0x20 
   0x0000000202156df0 <+2544>:	MOV R20, 0x0 
   0x0000000202156e00 <+2560>:	MOV R21, 0x0 
   0x0000000202156e10 <+2576>:	CALL.ABS.NOINC 0x0 
   0x0000000202156e20 <+2592>:	BRA 0xa40 
   0x0000000202156e30 <+2608>:	BAR.ARV 0x0, 0x20 
   0x0000000202156e40 <+2624>:	BRA.CONV ~URZ, 0xaa0 
   0x0000000202156e50 <+2640>:	MOV R4, 0x20 
   0x0000000202156e60 <+2656>:	MOV R20, 0x0 
   0x0000000202156e70 <+2672>:	MOV R21, 0x0 
   0x0000000202156e80 <+2688>:	CALL.ABS.NOINC 0x0 
   0x0000000202156e90 <+2704>:	BRA 0xab0 
   0x0000000202156ea0 <+2720>:	BAR.SYNC 0x1, 0x20 
   0x0000000202156eb0 <+2736>:	S2R R0, SR_TID.X 
   0x0000000202156ec0 <+2752>:	MOV R0, R0 
   0x0000000202156ed0 <+2768>:	IADD3 R0, R0, -0x20, RZ 
   0x0000000202156ee0 <+2784>:	MOV R0, R0 
   0x0000000202156ef0 <+2800>:	MOV R6, R0 
   0x0000000202156f00 <+2816>:	MOV R7, RZ 
   0x0000000202156f10 <+2832>:	MOV R0, 0x0 
   0x0000000202156f20 <+2848>:	MOV R0, R0 
   0x0000000202156f30 <+2864>:	MOV R0, R0 
   0x0000000202156f40 <+2880>:	MOV R4, R0 
   0x0000000202156f50 <+2896>:	MOV R5, RZ 
   0x0000000202156f60 <+2912>:	MOV R0, c[0x0][0x18] 
   0x0000000202156f70 <+2928>:	MOV R3, c[0x0][0x1c] 
   0x0000000202156f80 <+2944>:	IADD3 R0, P0, R4, R0, RZ 
   0x0000000202156f90 <+2960>:	IADD3.X R3, R5, R3, RZ, P0, !PT 
   0x0000000202156fa0 <+2976>:	SHF.L.U64.HI R5, R6, 0x2, R7 
   0x0000000202156fb0 <+2992>:	SHF.L.U32 R4, R6, 0x2, RZ 
   0x0000000202156fc0 <+3008>:	IADD3 R4, P0, R0, R4, RZ 
   0x0000000202156fd0 <+3024>:	IADD3.X R5, R3, R5, RZ, P0, !PT 
   0x0000000202156fe0 <+3040>:	MOV R4, R4 
   0x0000000202156ff0 <+3056>:	MOV R5, R5 
   0x0000000202157000 <+3072>:	MOV R4, R4 
   0x0000000202157010 <+3088>:	MOV R5, R5 
   0x0000000202157020 <+3104>:	R2UR UR4, R18 
   0x0000000202157030 <+3120>:	R2UR UR5, R19 
   0x0000000202157040 <+3136>:	LD.E R4, [R4.64] 
   0x0000000202157050 <+3152>:	MOV R4, R4 
   0x0000000202157060 <+3168>:	MOV R4, R4 
   0x0000000202157070 <+3184>:	MOV R5, RZ 
   0x0000000202157080 <+3200>:	S2R R0, SR_TID.X 
   0x0000000202157090 <+3216>:	MOV R0, R0 
   0x00000002021570a0 <+3232>:	IADD3 R0, R0, -0x20, RZ 
   0x00000002021570b0 <+3248>:	MOV R0, R0 
   0x00000002021570c0 <+3264>:	MOV R0, R0 
   0x00000002021570d0 <+3280>:	MOV R3, RZ 
   0x00000002021570e0 <+3296>:	SHF.L.U64.HI R3, R0, 0x3, R3 
   0x00000002021570f0 <+3312>:	SHF.L.U32 R0, R0, 0x3, RZ 
   0x0000000202157100 <+3328>:	IADD3 R16, P0, R16, R0, RZ 
   0x0000000202157110 <+3344>:	IADD3.X R3, R2, R3, RZ, P0, !PT 
   0x0000000202157120 <+3360>:	MOV R2, R16 
   0x0000000202157130 <+3376>:	MOV R3, R3 
   0x0000000202157140 <+3392>:	MOV R2, R2 
   0x0000000202157150 <+3408>:	MOV R3, R3 
   0x0000000202157160 <+3424>:	R2UR UR4, R18 
   0x0000000202157170 <+3440>:	R2UR UR5, R19 
   0x0000000202157180 <+3456>:	ST.E.64 [R2.64], R4 
   0x0000000202157190 <+3472>:	BRA 0xda0 
   0x00000002021571a0 <+3488>:	MEMBAR.SC.VC 
   0x00000002021571b0 <+3504>:	ERRBAR 
   0x00000002021571c0 <+3520>:	EXIT 
   0x00000002021571d0 <+3536>:	MEMBAR.SC.VC 
   0x00000002021571e0 <+3552>:	ERRBAR 
   0x00000002021571f0 <+3568>:	EXIT 
   0x0000000202157200 <+3584>:	BRA 0xe00
   0x0000000202157210 <+3600>:	NOP
   0x0000000202157220 <+3616>:	NOP
   0x0000000202157230 <+3632>:	NOP
   0x0000000202157240 <+3648>:	NOP
   0x0000000202157250 <+3664>:	NOP
   0x0000000202157260 <+3680>:	NOP
   0x0000000202157270 <+3696>:	NOP
   0x0000000202157280 <+3712>:	NOP
   0x0000000202157290 <+3728>:	NOP
   0x00000002021572a0 <+3744>:	NOP
   0x00000002021572b0 <+3760>:	NOP
   0x00000002021572c0 <+3776>:	NOP
   0x00000002021572d0 <+3792>:	NOP
   0x00000002021572e0 <+3808>:	NOP
   0x00000002021572f0 <+3824>:	NOP
End of assembler dump.
(cuda-gdb) 
```

```
(cuda-gdb) si
30	        asm("barrier.cta.arrive 0, 32;\n\t");
(cuda-gdb) x/i $pc
=> 0x202156dd0 <_Z8test_braPlj+2512>:	BRA.CONV ~URZ, 0xa30 
(cuda-gdb) info cuda warps 
  Wp Active Lanes Mask Divergent Lanes Mask          Active PC Kernel BlockIdx First Active ThreadIdx 
Device 0 SM 0
   0        0xffffffff           0x00000000 0x0000000202156b30      0  (0,0,0)                (0,0,0) 
*  1        0xffffffff           0x00000000 0x0000000202156dd0      0  (0,0,0)               (32,0,0) 
(cuda-gdb) disas 
Dump of assembler code for function _Z8test_braPlj:
   0x0000000202156400 <+0>:	ISETP.NE.U32.AND P0, PT, RZ, UR2, PT 
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
   0x0000000202156550 <+336>:	MOV R18, c[0x0][0x118] 
   0x0000000202156560 <+352>:	MOV R19, c[0x0][0x11c] 
   0x0000000202156570 <+368>:	MOV R2, RZ 
   0x0000000202156580 <+384>:	LDC.64 R2, c[0x0][R2+0x160] 
   0x0000000202156590 <+400>:	MOV R16, R2 
   0x00000002021565a0 <+416>:	MOV R2, R3 
   0x00000002021565b0 <+432>:	MOV R16, R16 
   0x00000002021565c0 <+448>:	MOV R2, R2 
   0x00000002021565d0 <+464>:	MOV R0, 0x8 
   0x00000002021565e0 <+480>:	LDC R0, c[0x0][R0+0x160] 
   0x00000002021565f0 <+496>:	MOV R0, R0 
   0x0000000202156600 <+512>:	MOV R0, R0 
   0x0000000202156610 <+528>:	MOV R16, R16 
   0x0000000202156620 <+544>:	MOV R2, R2 
   0x0000000202156630 <+560>:	MOV R17, R0 
   0x0000000202156640 <+576>:	S2R R0, SR_TID.X 
   0x0000000202156650 <+592>:	MOV R0, R0 
   0x0000000202156660 <+608>:	ISETP.LT.U32.AND P0, PT, R0, 0x10, PT 
   0x0000000202156670 <+624>:	PLOP3.LUT P0, PT, P0, PT, PT, 0x8, 0x0 
   0x0000000202156680 <+640>:	BSSY B0, 0x6d0 
--Type <RET> for more, q to quit, c to continue without paging--c
   0x0000000202156690 <+656>:	@P0 BRA 0x6c0 
   0x00000002021566a0 <+672>:	BRA 0x2b0 
   0x00000002021566b0 <+688>:	S2R R6, SR_TID.Y 
   0x00000002021566c0 <+704>:	MOV R6, R6 
   0x00000002021566d0 <+720>:	S2R R0, SR_TID.X 
   0x00000002021566e0 <+736>:	MOV R0, R0 
   0x00000002021566f0 <+752>:	MOV R0, R0 
   0x0000000202156700 <+768>:	MOV R7, R0 
   0x0000000202156710 <+784>:	MOV R8, RZ 
   0x0000000202156720 <+800>:	MOV R4, 0x0 
   0x0000000202156730 <+816>:	MOV R5, 0x0 
   0x0000000202156740 <+832>:	MOV R4, R4 
   0x0000000202156750 <+848>:	MOV R5, R5 
   0x0000000202156760 <+864>:	MOV R3, R4 
   0x0000000202156770 <+880>:	MOV R0, R5 
   0x0000000202156780 <+896>:	MOV R3, R3 
   0x0000000202156790 <+912>:	MOV R0, R0 
   0x00000002021567a0 <+928>:	SHF.L.U64.HI R5, R7, 0x2, R8 
   0x00000002021567b0 <+944>:	SHF.L.U32 R4, R7, 0x2, RZ 
   0x00000002021567c0 <+960>:	IADD3 R4, P0, R3, R4, RZ 
   0x00000002021567d0 <+976>:	IADD3.X R5, R0, R5, RZ, P0, !PT 
   0x00000002021567e0 <+992>:	MOV R4, R4 
   0x00000002021567f0 <+1008>:	MOV R5, R5 
   0x0000000202156800 <+1024>:	MOV R4, R4 
   0x0000000202156810 <+1040>:	MOV R5, R5 
   0x0000000202156820 <+1056>:	R2UR UR4, R18 
   0x0000000202156830 <+1072>:	R2UR UR5, R19 
   0x0000000202156840 <+1088>:	ST.E [R4.64], R6 
   0x0000000202156850 <+1104>:	S2R R6, SR_TID.Z 
   0x0000000202156860 <+1120>:	MOV R6, R6 
   0x0000000202156870 <+1136>:	S2R R4, SR_TID.X 
   0x0000000202156880 <+1152>:	MOV R4, R4 
   0x0000000202156890 <+1168>:	IADD3 R4, R4, 0x10, RZ 
   0x00000002021568a0 <+1184>:	MOV R4, R4 
   0x00000002021568b0 <+1200>:	MOV R4, R4 
   0x00000002021568c0 <+1216>:	MOV R5, RZ 
   0x00000002021568d0 <+1232>:	SHF.L.U64.HI R5, R4, 0x2, R5 
   0x00000002021568e0 <+1248>:	SHF.L.U32 R4, R4, 0x2, RZ 
   0x00000002021568f0 <+1264>:	IADD3 R4, P0, R3, R4, RZ 
   0x0000000202156900 <+1280>:	IADD3.X R5, R0, R5, RZ, P0, !PT 
   0x0000000202156910 <+1296>:	MOV R4, R4 
   0x0000000202156920 <+1312>:	MOV R5, R5 
   0x0000000202156930 <+1328>:	MOV R4, R4 
   0x0000000202156940 <+1344>:	MOV R5, R5 
   0x0000000202156950 <+1360>:	R2UR UR4, R18 
   0x0000000202156960 <+1376>:	R2UR UR5, R19 
   0x0000000202156970 <+1392>:	ST.E [R4.64], R6 
   0x0000000202156980 <+1408>:	S2R R6, SR_TID.X 
   0x0000000202156990 <+1424>:	MOV R6, R6 
   0x00000002021569a0 <+1440>:	S2R R4, SR_TID.X 
   0x00000002021569b0 <+1456>:	MOV R4, R4 
   0x00000002021569c0 <+1472>:	IADD3 R4, R4, 0x20, RZ 
   0x00000002021569d0 <+1488>:	MOV R4, R4 
   0x00000002021569e0 <+1504>:	MOV R4, R4 
   0x00000002021569f0 <+1520>:	MOV R5, RZ 
   0x0000000202156a00 <+1536>:	SHF.L.U64.HI R5, R4, 0x2, R5 
   0x0000000202156a10 <+1552>:	SHF.L.U32 R4, R4, 0x2, RZ 
   0x0000000202156a20 <+1568>:	IADD3 R4, P0, R3, R4, RZ 
   0x0000000202156a30 <+1584>:	IADD3.X R5, R0, R5, RZ, P0, !PT 
   0x0000000202156a40 <+1600>:	MOV R4, R4 
   0x0000000202156a50 <+1616>:	MOV R5, R5 
   0x0000000202156a60 <+1632>:	MOV R4, R4 
   0x0000000202156a70 <+1648>:	MOV R5, R5 
   0x0000000202156a80 <+1664>:	R2UR UR4, R18 
   0x0000000202156a90 <+1680>:	R2UR UR5, R19 
   0x0000000202156aa0 <+1696>:	ST.E [R4.64], R6 
   0x0000000202156ab0 <+1712>:	BRA 0x6c0 
   0x0000000202156ac0 <+1728>:	BSYNC B0 
   0x0000000202156ad0 <+1744>:	S2R R0, SR_TID.X 
   0x0000000202156ae0 <+1760>:	MOV R0, R0 
   0x0000000202156af0 <+1776>:	ISETP.LT.U32.AND P0, PT, R0, 0x20, PT 
   0x0000000202156b00 <+1792>:	PLOP3.LUT P0, PT, P0, PT, PT, 0x8, 0x0 
   0x0000000202156b10 <+1808>:	@P0 BRA 0x9d0 
   0x0000000202156b20 <+1824>:	BRA 0x730 
   0x0000000202156b30 <+1840>:	BRA.CONV ~URZ, 0x790 
   0x0000000202156b40 <+1856>:	MOV R4, 0x20 
   0x0000000202156b50 <+1872>:	MOV R20, 0x0 
   0x0000000202156b60 <+1888>:	MOV R21, 0x0 
   0x0000000202156b70 <+1904>:	CALL.ABS.NOINC 0x0 
   0x0000000202156b80 <+1920>:	BRA 0x7a0 
   0x0000000202156b90 <+1936>:	BAR.SYNC 0x0, 0x20 
   0x0000000202156ba0 <+1952>:	S2R R0, SR_TID.X 
   0x0000000202156bb0 <+1968>:	MOV R0, R0 
   0x0000000202156bc0 <+1984>:	S2R R2, SR_TID.X 
   0x0000000202156bd0 <+2000>:	MOV R2, R2 
   0x0000000202156be0 <+2016>:	MOV R2, R2 
   0x0000000202156bf0 <+2032>:	MOV R6, R2 
   0x0000000202156c00 <+2048>:	MOV R7, RZ 
   0x0000000202156c10 <+2064>:	MOV R2, 0x0 
   0x0000000202156c20 <+2080>:	MOV R2, R2 
   0x0000000202156c30 <+2096>:	MOV R2, R2 
   0x0000000202156c40 <+2112>:	MOV R2, R2 
   0x0000000202156c50 <+2128>:	MOV R3, RZ 
   0x0000000202156c60 <+2144>:	MOV R4, c[0x0][0x18] 
   0x0000000202156c70 <+2160>:	MOV R5, c[0x0][0x1c] 
   0x0000000202156c80 <+2176>:	IADD3 R4, P0, R2, R4, RZ 
   0x0000000202156c90 <+2192>:	IADD3.X R5, R3, R5, RZ, P0, !PT 
   0x0000000202156ca0 <+2208>:	SHF.L.U64.HI R3, R6, 0x2, R7 
   0x0000000202156cb0 <+2224>:	SHF.L.U32 R2, R6, 0x2, RZ 
   0x0000000202156cc0 <+2240>:	IADD3 R2, P0, R4, R2, RZ 
   0x0000000202156cd0 <+2256>:	IADD3.X R3, R5, R3, RZ, P0, !PT 
   0x0000000202156ce0 <+2272>:	MOV R2, R2 
   0x0000000202156cf0 <+2288>:	MOV R3, R3 
   0x0000000202156d00 <+2304>:	MOV R2, R2 
   0x0000000202156d10 <+2320>:	MOV R3, R3 
   0x0000000202156d20 <+2336>:	R2UR UR4, R18 
   0x0000000202156d30 <+2352>:	R2UR UR5, R19 
   0x0000000202156d40 <+2368>:	ST.E [R2.64], R0 
   0x0000000202156d50 <+2384>:	BRA.CONV ~URZ, 0x9b0 
   0x0000000202156d60 <+2400>:	MOV R4, 0x20 
   0x0000000202156d70 <+2416>:	MOV R20, 0x0 
   0x0000000202156d80 <+2432>:	MOV R21, 0x0 
   0x0000000202156d90 <+2448>:	CALL.ABS.NOINC 0x0 
   0x0000000202156da0 <+2464>:	BRA 0x9c0 
   0x0000000202156db0 <+2480>:	BAR.ARV 0x1, 0x20 
   0x0000000202156dc0 <+2496>:	BRA 0xda0 
=> 0x0000000202156dd0 <+2512>:	BRA.CONV ~URZ, 0xa30 
   0x0000000202156de0 <+2528>:	MOV R4, 0x20 
   0x0000000202156df0 <+2544>:	MOV R20, 0x0 
   0x0000000202156e00 <+2560>:	MOV R21, 0x0 
   0x0000000202156e10 <+2576>:	CALL.ABS.NOINC 0x0 
   0x0000000202156e20 <+2592>:	BRA 0xa40 
   0x0000000202156e30 <+2608>:	BAR.ARV 0x0, 0x20 
   0x0000000202156e40 <+2624>:	BRA.CONV ~URZ, 0xaa0 
   0x0000000202156e50 <+2640>:	MOV R4, 0x20 
   0x0000000202156e60 <+2656>:	MOV R20, 0x0 
   0x0000000202156e70 <+2672>:	MOV R21, 0x0 
   0x0000000202156e80 <+2688>:	CALL.ABS.NOINC 0x0 
   0x0000000202156e90 <+2704>:	BRA 0xab0 
   0x0000000202156ea0 <+2720>:	BAR.SYNC 0x1, 0x20 
   0x0000000202156eb0 <+2736>:	S2R R0, SR_TID.X 
   0x0000000202156ec0 <+2752>:	MOV R0, R0 
   0x0000000202156ed0 <+2768>:	IADD3 R0, R0, -0x20, RZ 
   0x0000000202156ee0 <+2784>:	MOV R0, R0 
   0x0000000202156ef0 <+2800>:	MOV R6, R0 
   0x0000000202156f00 <+2816>:	MOV R7, RZ 
   0x0000000202156f10 <+2832>:	MOV R0, 0x0 
   0x0000000202156f20 <+2848>:	MOV R0, R0 
   0x0000000202156f30 <+2864>:	MOV R0, R0 
   0x0000000202156f40 <+2880>:	MOV R4, R0 
   0x0000000202156f50 <+2896>:	MOV R5, RZ 
   0x0000000202156f60 <+2912>:	MOV R0, c[0x0][0x18] 
   0x0000000202156f70 <+2928>:	MOV R3, c[0x0][0x1c] 
   0x0000000202156f80 <+2944>:	IADD3 R0, P0, R4, R0, RZ 
   0x0000000202156f90 <+2960>:	IADD3.X R3, R5, R3, RZ, P0, !PT 
   0x0000000202156fa0 <+2976>:	SHF.L.U64.HI R5, R6, 0x2, R7 
   0x0000000202156fb0 <+2992>:	SHF.L.U32 R4, R6, 0x2, RZ 
   0x0000000202156fc0 <+3008>:	IADD3 R4, P0, R0, R4, RZ 
   0x0000000202156fd0 <+3024>:	IADD3.X R5, R3, R5, RZ, P0, !PT 
   0x0000000202156fe0 <+3040>:	MOV R4, R4 
   0x0000000202156ff0 <+3056>:	MOV R5, R5 
   0x0000000202157000 <+3072>:	MOV R4, R4 
   0x0000000202157010 <+3088>:	MOV R5, R5 
   0x0000000202157020 <+3104>:	R2UR UR4, R18 
   0x0000000202157030 <+3120>:	R2UR UR5, R19 
   0x0000000202157040 <+3136>:	LD.E R4, [R4.64] 
   0x0000000202157050 <+3152>:	MOV R4, R4 
   0x0000000202157060 <+3168>:	MOV R4, R4 
   0x0000000202157070 <+3184>:	MOV R5, RZ 
   0x0000000202157080 <+3200>:	S2R R0, SR_TID.X 
   0x0000000202157090 <+3216>:	MOV R0, R0 
   0x00000002021570a0 <+3232>:	IADD3 R0, R0, -0x20, RZ 
   0x00000002021570b0 <+3248>:	MOV R0, R0 
   0x00000002021570c0 <+3264>:	MOV R0, R0 
   0x00000002021570d0 <+3280>:	MOV R3, RZ 
   0x00000002021570e0 <+3296>:	SHF.L.U64.HI R3, R0, 0x3, R3 
   0x00000002021570f0 <+3312>:	SHF.L.U32 R0, R0, 0x3, RZ 
   0x0000000202157100 <+3328>:	IADD3 R16, P0, R16, R0, RZ 
   0x0000000202157110 <+3344>:	IADD3.X R3, R2, R3, RZ, P0, !PT 
   0x0000000202157120 <+3360>:	MOV R2, R16 
   0x0000000202157130 <+3376>:	MOV R3, R3 
   0x0000000202157140 <+3392>:	MOV R2, R2 
   0x0000000202157150 <+3408>:	MOV R3, R3 
   0x0000000202157160 <+3424>:	R2UR UR4, R18 
   0x0000000202157170 <+3440>:	R2UR UR5, R19 
   0x0000000202157180 <+3456>:	ST.E.64 [R2.64], R4 
   0x0000000202157190 <+3472>:	BRA 0xda0 
   0x00000002021571a0 <+3488>:	MEMBAR.SC.VC 
   0x00000002021571b0 <+3504>:	ERRBAR 
   0x00000002021571c0 <+3520>:	EXIT 
   0x00000002021571d0 <+3536>:	MEMBAR.SC.VC 
   0x00000002021571e0 <+3552>:	ERRBAR 
   0x00000002021571f0 <+3568>:	EXIT 
   0x0000000202157200 <+3584>:	BRA 0xe00
   0x0000000202157210 <+3600>:	NOP
   0x0000000202157220 <+3616>:	NOP
   0x0000000202157230 <+3632>:	NOP
   0x0000000202157240 <+3648>:	NOP
   0x0000000202157250 <+3664>:	NOP
   0x0000000202157260 <+3680>:	NOP
   0x0000000202157270 <+3696>:	NOP
   0x0000000202157280 <+3712>:	NOP
   0x0000000202157290 <+3728>:	NOP
   0x00000002021572a0 <+3744>:	NOP
   0x00000002021572b0 <+3760>:	NOP
   0x00000002021572c0 <+3776>:	NOP
   0x00000002021572d0 <+3792>:	NOP
   0x00000002021572e0 <+3808>:	NOP
   0x00000002021572f0 <+3824>:	NOP
End of assembler dump.
(cuda-gdb) 
```

```
(cuda-gdb) info cuda lanes 
  Ln  State         PC         ThreadIdx Exception 
Device 0 SM 0 Warp 1
*  0 active 0x0000000202156dd0  (32,0,0)    None   
   1 active 0x0000000202156dd0  (33,0,0)    None   
   2 active 0x0000000202156dd0  (34,0,0)    None   
   3 active 0x0000000202156dd0  (35,0,0)    None   
   4 active 0x0000000202156dd0  (36,0,0)    None   
   5 active 0x0000000202156dd0  (37,0,0)    None   
   6 active 0x0000000202156dd0  (38,0,0)    None   
   7 active 0x0000000202156dd0  (39,0,0)    None   
   8 active 0x0000000202156dd0  (40,0,0)    None   
   9 active 0x0000000202156dd0  (41,0,0)    None   
  10 active 0x0000000202156dd0  (42,0,0)    None   
  11 active 0x0000000202156dd0  (43,0,0)    None   
  12 active 0x0000000202156dd0  (44,0,0)    None   
  13 active 0x0000000202156dd0  (45,0,0)    None   
  14 active 0x0000000202156dd0  (46,0,0)    None   
  15 active 0x0000000202156dd0  (47,0,0)    None   
  16 active 0x0000000202156dd0  (48,0,0)    None   
  17 active 0x0000000202156dd0  (49,0,0)    None   
  18 active 0x0000000202156dd0  (50,0,0)    None   
  19 active 0x0000000202156dd0  (51,0,0)    None   
  20 active 0x0000000202156dd0  (52,0,0)    None   
  21 active 0x0000000202156dd0  (53,0,0)    None   
  22 active 0x0000000202156dd0  (54,0,0)    None   
  23 active 0x0000000202156dd0  (55,0,0)    None   
  24 active 0x0000000202156dd0  (56,0,0)    None   
  25 active 0x0000000202156dd0  (57,0,0)    None   
  26 active 0x0000000202156dd0  (58,0,0)    None   
  27 active 0x0000000202156dd0  (59,0,0)    None   
  28 active 0x0000000202156dd0  (60,0,0)    None   
  29 active 0x0000000202156dd0  (61,0,0)    None   
  30 active 0x0000000202156dd0  (62,0,0)    None   
  31 active 0x0000000202156dd0  (63,0,0)    None   
(cuda-gdb) info cuda warps 
  Wp Active Lanes Mask Divergent Lanes Mask          Active PC Kernel BlockIdx First Active ThreadIdx 
Device 0 SM 0
   0        0xffffffff           0x00000000 0x0000000202156b30      0  (0,0,0)                (0,0,0) 
*  1        0xffffffff           0x00000000 0x0000000202156dd0      0  (0,0,0)               (32,0,0) 
(cuda-gdb) x/i $pc
=> 0x202156dd0 <_Z8test_braPlj+2512>:	BRA.CONV ~URZ, 0xa30 
(cuda-gdb) si
0x0000000202156e30	30	        asm("barrier.cta.arrive 0, 32;\n\t");
(cuda-gdb) x/i $pc
=> 0x202156e30 <_Z8test_braPlj+2608>:	BAR.ARV 0x0, 0x20 
(cuda-gdb) 

```


Switch back to warp0 for the sync barrier: 
```
(cuda-gdb) cuda device 0 sm 0 warp 0 lane 0
[Switching focus to CUDA kernel 0, grid 1, block (0,0,0), thread (0,0,0), device 0, sm 0, warp 0, lane 0]
26	        asm("barrier.cta.sync 0, 32;\n\t");
(cuda-gdb) x/i $pc
=> 0x202156b30 <_Z8test_braPlj+1840>:	BRA.CONV ~URZ, 0x790 
(cuda-gdb) si
0x0000000202156b90	26	        asm("barrier.cta.sync 0, 32;\n\t");
(cuda-gdb) x/i $pc
=> 0x202156b90 <_Z8test_braPlj+1936>:	BAR.SYNC 0x0, 0x20 
(cuda-gdb)        
```

si again: 
```
(cuda-gdb) si     
27	        data[threadIdx.x] = threadIdx.x;
(cuda-gdb) x/i $pc
=> 0x202156ba0 <_Z8test_braPlj+1952>:	S2R R0, SR_TID.X 
(cuda-gdb) info cuda warps 
  Wp Active Lanes Mask Divergent Lanes Mask          Active PC Kernel BlockIdx First Active ThreadIdx 
Device 0 SM 0
*  0        0xffffffff           0x00000000 0x0000000202156ba0      0  (0,0,0)                (0,0,0) 
   1        0xffffffff           0x00000000 0x0000000202156e30      0  (0,0,0)               (32,0,0) 
(cuda-gdb) 


```

Seems like in single stepping mode, warp barriers are not respected -- as we can see here, BAR.SYNC 0x0, 0x20 is ignored, 
despite the warp1 hasn't executed BAR.ARV 0x0, 0x20. 

We si to the next barrier instruction: 
```
(cuda-gdb) si
0x0000000202156d40	27	        data[threadIdx.x] = threadIdx.x;
(cuda-gdb) x/i $pc
=> 0x202156d40 <_Z8test_braPlj+2368>:	ST.E [R2.64], R0 
(cuda-gdb) si
28	        asm("barrier.cta.arrive 1, 32;\n\t");
(cuda-gdb) x/i $pc
=> 0x202156d50 <_Z8test_braPlj+2384>:	BRA.CONV ~URZ, 0x9b0 


(cuda-gdb) si
0x0000000202156db0	28	        asm("barrier.cta.arrive 1, 32;\n\t");
(cuda-gdb) x/i $pc
=> 0x202156db0 <_Z8test_braPlj+2480>:	BAR.ARV 0x1, 0x20 
(cuda-gdb) cuda device 0 sm 0 warp 1 lane 0
[Switching focus to CUDA kernel 0, grid 1, block (0,0,0), thread (32,0,0), device 0, sm 0, warp 1, lane 0]
0x0000000202156e30	30	        asm("barrier.cta.arrive 0, 32;\n\t");
(cuda-gdb) info cuda warps 
  Wp Active Lanes Mask Divergent Lanes Mask          Active PC Kernel BlockIdx First Active ThreadIdx 
Device 0 SM 0
   0        0xffffffff           0x00000000 0x0000000202156db0      0  (0,0,0)                (0,0,0) 
*  1        0xffffffff           0x00000000 0x0000000202156e30      0  (0,0,0)               (32,0,0) 
(cuda-gdb) 
```

NExt: 
```
(cuda-gdb) si
31	        asm("barrier.cta.sync 1, 32;\n\t");
(cuda-gdb) x/i $pc
=> 0x202156e40 <_Z8test_braPlj+2624>:	BRA.CONV ~URZ, 0xaa0 
(cuda-gdb) disas 
Dump of assembler code for function _Z8test_braPlj:
   0x0000000202156400 <+0>:	ISETP.NE.U32.AND P0, PT, RZ, UR2, PT 
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
   0x0000000202156550 <+336>:	MOV R18, c[0x0][0x118] 
   0x0000000202156560 <+352>:	MOV R19, c[0x0][0x11c] 
   0x0000000202156570 <+368>:	MOV R2, RZ 
   0x0000000202156580 <+384>:	LDC.64 R2, c[0x0][R2+0x160] 
   0x0000000202156590 <+400>:	MOV R16, R2 
   0x00000002021565a0 <+416>:	MOV R2, R3 
   0x00000002021565b0 <+432>:	MOV R16, R16 
   0x00000002021565c0 <+448>:	MOV R2, R2 
   0x00000002021565d0 <+464>:	MOV R0, 0x8 
   0x00000002021565e0 <+480>:	LDC R0, c[0x0][R0+0x160] 
   0x00000002021565f0 <+496>:	MOV R0, R0 
   0x0000000202156600 <+512>:	MOV R0, R0 
   0x0000000202156610 <+528>:	MOV R16, R16 
   0x0000000202156620 <+544>:	MOV R2, R2 
   0x0000000202156630 <+560>:	MOV R17, R0 
   0x0000000202156640 <+576>:	S2R R0, SR_TID.X 
   0x0000000202156650 <+592>:	MOV R0, R0 
   0x0000000202156660 <+608>:	ISETP.LT.U32.AND P0, PT, R0, 0x10, PT 
   0x0000000202156670 <+624>:	PLOP3.LUT P0, PT, P0, PT, PT, 0x8, 0x0 
   0x0000000202156680 <+640>:	BSSY B0, 0x6d0 
--Type <RET> for more, q to quit, c to continue without paging--c
   0x0000000202156690 <+656>:	@P0 BRA 0x6c0 
   0x00000002021566a0 <+672>:	BRA 0x2b0 
   0x00000002021566b0 <+688>:	S2R R6, SR_TID.Y 
   0x00000002021566c0 <+704>:	MOV R6, R6 
   0x00000002021566d0 <+720>:	S2R R0, SR_TID.X 
   0x00000002021566e0 <+736>:	MOV R0, R0 
   0x00000002021566f0 <+752>:	MOV R0, R0 
   0x0000000202156700 <+768>:	MOV R7, R0 
   0x0000000202156710 <+784>:	MOV R8, RZ 
   0x0000000202156720 <+800>:	MOV R4, 0x0 
   0x0000000202156730 <+816>:	MOV R5, 0x0 
   0x0000000202156740 <+832>:	MOV R4, R4 
   0x0000000202156750 <+848>:	MOV R5, R5 
   0x0000000202156760 <+864>:	MOV R3, R4 
   0x0000000202156770 <+880>:	MOV R0, R5 
   0x0000000202156780 <+896>:	MOV R3, R3 
   0x0000000202156790 <+912>:	MOV R0, R0 
   0x00000002021567a0 <+928>:	SHF.L.U64.HI R5, R7, 0x2, R8 
   0x00000002021567b0 <+944>:	SHF.L.U32 R4, R7, 0x2, RZ 
   0x00000002021567c0 <+960>:	IADD3 R4, P0, R3, R4, RZ 
   0x00000002021567d0 <+976>:	IADD3.X R5, R0, R5, RZ, P0, !PT 
   0x00000002021567e0 <+992>:	MOV R4, R4 
   0x00000002021567f0 <+1008>:	MOV R5, R5 
   0x0000000202156800 <+1024>:	MOV R4, R4 
   0x0000000202156810 <+1040>:	MOV R5, R5 
   0x0000000202156820 <+1056>:	R2UR UR4, R18 
   0x0000000202156830 <+1072>:	R2UR UR5, R19 
   0x0000000202156840 <+1088>:	ST.E [R4.64], R6 
   0x0000000202156850 <+1104>:	S2R R6, SR_TID.Z 
   0x0000000202156860 <+1120>:	MOV R6, R6 
   0x0000000202156870 <+1136>:	S2R R4, SR_TID.X 
   0x0000000202156880 <+1152>:	MOV R4, R4 
   0x0000000202156890 <+1168>:	IADD3 R4, R4, 0x10, RZ 
   0x00000002021568a0 <+1184>:	MOV R4, R4 
   0x00000002021568b0 <+1200>:	MOV R4, R4 
   0x00000002021568c0 <+1216>:	MOV R5, RZ 
   0x00000002021568d0 <+1232>:	SHF.L.U64.HI R5, R4, 0x2, R5 
   0x00000002021568e0 <+1248>:	SHF.L.U32 R4, R4, 0x2, RZ 
   0x00000002021568f0 <+1264>:	IADD3 R4, P0, R3, R4, RZ 
   0x0000000202156900 <+1280>:	IADD3.X R5, R0, R5, RZ, P0, !PT 
   0x0000000202156910 <+1296>:	MOV R4, R4 
   0x0000000202156920 <+1312>:	MOV R5, R5 
   0x0000000202156930 <+1328>:	MOV R4, R4 
   0x0000000202156940 <+1344>:	MOV R5, R5 
   0x0000000202156950 <+1360>:	R2UR UR4, R18 
   0x0000000202156960 <+1376>:	R2UR UR5, R19 
   0x0000000202156970 <+1392>:	ST.E [R4.64], R6 
   0x0000000202156980 <+1408>:	S2R R6, SR_TID.X 
   0x0000000202156990 <+1424>:	MOV R6, R6 
   0x00000002021569a0 <+1440>:	S2R R4, SR_TID.X 
   0x00000002021569b0 <+1456>:	MOV R4, R4 
   0x00000002021569c0 <+1472>:	IADD3 R4, R4, 0x20, RZ 
   0x00000002021569d0 <+1488>:	MOV R4, R4 
   0x00000002021569e0 <+1504>:	MOV R4, R4 
   0x00000002021569f0 <+1520>:	MOV R5, RZ 
   0x0000000202156a00 <+1536>:	SHF.L.U64.HI R5, R4, 0x2, R5 
   0x0000000202156a10 <+1552>:	SHF.L.U32 R4, R4, 0x2, RZ 
   0x0000000202156a20 <+1568>:	IADD3 R4, P0, R3, R4, RZ 
   0x0000000202156a30 <+1584>:	IADD3.X R5, R0, R5, RZ, P0, !PT 
   0x0000000202156a40 <+1600>:	MOV R4, R4 
   0x0000000202156a50 <+1616>:	MOV R5, R5 
   0x0000000202156a60 <+1632>:	MOV R4, R4 
   0x0000000202156a70 <+1648>:	MOV R5, R5 
   0x0000000202156a80 <+1664>:	R2UR UR4, R18 
   0x0000000202156a90 <+1680>:	R2UR UR5, R19 
   0x0000000202156aa0 <+1696>:	ST.E [R4.64], R6 
   0x0000000202156ab0 <+1712>:	BRA 0x6c0 
   0x0000000202156ac0 <+1728>:	BSYNC B0 
   0x0000000202156ad0 <+1744>:	S2R R0, SR_TID.X 
   0x0000000202156ae0 <+1760>:	MOV R0, R0 
   0x0000000202156af0 <+1776>:	ISETP.LT.U32.AND P0, PT, R0, 0x20, PT 
   0x0000000202156b00 <+1792>:	PLOP3.LUT P0, PT, P0, PT, PT, 0x8, 0x0 
   0x0000000202156b10 <+1808>:	@P0 BRA 0x9d0 
   0x0000000202156b20 <+1824>:	BRA 0x730 
   0x0000000202156b30 <+1840>:	BRA.CONV ~URZ, 0x790 
   0x0000000202156b40 <+1856>:	MOV R4, 0x20 
   0x0000000202156b50 <+1872>:	MOV R20, 0x0 
   0x0000000202156b60 <+1888>:	MOV R21, 0x0 
   0x0000000202156b70 <+1904>:	CALL.ABS.NOINC 0x0 
   0x0000000202156b80 <+1920>:	BRA 0x7a0 
   0x0000000202156b90 <+1936>:	BAR.SYNC 0x0, 0x20 
   0x0000000202156ba0 <+1952>:	S2R R0, SR_TID.X 
   0x0000000202156bb0 <+1968>:	MOV R0, R0 
   0x0000000202156bc0 <+1984>:	S2R R2, SR_TID.X 
   0x0000000202156bd0 <+2000>:	MOV R2, R2 
   0x0000000202156be0 <+2016>:	MOV R2, R2 
   0x0000000202156bf0 <+2032>:	MOV R6, R2 
   0x0000000202156c00 <+2048>:	MOV R7, RZ 
   0x0000000202156c10 <+2064>:	MOV R2, 0x0 
   0x0000000202156c20 <+2080>:	MOV R2, R2 
   0x0000000202156c30 <+2096>:	MOV R2, R2 
   0x0000000202156c40 <+2112>:	MOV R2, R2 
   0x0000000202156c50 <+2128>:	MOV R3, RZ 
   0x0000000202156c60 <+2144>:	MOV R4, c[0x0][0x18] 
   0x0000000202156c70 <+2160>:	MOV R5, c[0x0][0x1c] 
   0x0000000202156c80 <+2176>:	IADD3 R4, P0, R2, R4, RZ 
   0x0000000202156c90 <+2192>:	IADD3.X R5, R3, R5, RZ, P0, !PT 
   0x0000000202156ca0 <+2208>:	SHF.L.U64.HI R3, R6, 0x2, R7 
   0x0000000202156cb0 <+2224>:	SHF.L.U32 R2, R6, 0x2, RZ 
   0x0000000202156cc0 <+2240>:	IADD3 R2, P0, R4, R2, RZ 
   0x0000000202156cd0 <+2256>:	IADD3.X R3, R5, R3, RZ, P0, !PT 
   0x0000000202156ce0 <+2272>:	MOV R2, R2 
   0x0000000202156cf0 <+2288>:	MOV R3, R3 
   0x0000000202156d00 <+2304>:	MOV R2, R2 
   0x0000000202156d10 <+2320>:	MOV R3, R3 
   0x0000000202156d20 <+2336>:	R2UR UR4, R18 
   0x0000000202156d30 <+2352>:	R2UR UR5, R19 
   0x0000000202156d40 <+2368>:	ST.E [R2.64], R0 
   0x0000000202156d50 <+2384>:	BRA.CONV ~URZ, 0x9b0 
   0x0000000202156d60 <+2400>:	MOV R4, 0x20 
   0x0000000202156d70 <+2416>:	MOV R20, 0x0 
   0x0000000202156d80 <+2432>:	MOV R21, 0x0 
   0x0000000202156d90 <+2448>:	CALL.ABS.NOINC 0x0 
   0x0000000202156da0 <+2464>:	BRA 0x9c0 
   0x0000000202156db0 <+2480>:	BAR.ARV 0x1, 0x20 
   0x0000000202156dc0 <+2496>:	BRA 0xda0 
   0x0000000202156dd0 <+2512>:	BRA.CONV ~URZ, 0xa30 
   0x0000000202156de0 <+2528>:	MOV R4, 0x20 
   0x0000000202156df0 <+2544>:	MOV R20, 0x0 
   0x0000000202156e00 <+2560>:	MOV R21, 0x0 
   0x0000000202156e10 <+2576>:	CALL.ABS.NOINC 0x0 
   0x0000000202156e20 <+2592>:	BRA 0xa40 
   0x0000000202156e30 <+2608>:	BAR.ARV 0x0, 0x20 
=> 0x0000000202156e40 <+2624>:	BRA.CONV ~URZ, 0xaa0 
   0x0000000202156e50 <+2640>:	MOV R4, 0x20 
   0x0000000202156e60 <+2656>:	MOV R20, 0x0 
   0x0000000202156e70 <+2672>:	MOV R21, 0x0 
   0x0000000202156e80 <+2688>:	CALL.ABS.NOINC 0x0 
   0x0000000202156e90 <+2704>:	BRA 0xab0 
   0x0000000202156ea0 <+2720>:	BAR.SYNC 0x1, 0x20 
   0x0000000202156eb0 <+2736>:	S2R R0, SR_TID.X 
   0x0000000202156ec0 <+2752>:	MOV R0, R0 
   0x0000000202156ed0 <+2768>:	IADD3 R0, R0, -0x20, RZ 
   0x0000000202156ee0 <+2784>:	MOV R0, R0 
   0x0000000202156ef0 <+2800>:	MOV R6, R0 
   0x0000000202156f00 <+2816>:	MOV R7, RZ 
   0x0000000202156f10 <+2832>:	MOV R0, 0x0 
   0x0000000202156f20 <+2848>:	MOV R0, R0 
   0x0000000202156f30 <+2864>:	MOV R0, R0 
   0x0000000202156f40 <+2880>:	MOV R4, R0 
   0x0000000202156f50 <+2896>:	MOV R5, RZ 
   0x0000000202156f60 <+2912>:	MOV R0, c[0x0][0x18] 
   0x0000000202156f70 <+2928>:	MOV R3, c[0x0][0x1c] 
   0x0000000202156f80 <+2944>:	IADD3 R0, P0, R4, R0, RZ 
   0x0000000202156f90 <+2960>:	IADD3.X R3, R5, R3, RZ, P0, !PT 
   0x0000000202156fa0 <+2976>:	SHF.L.U64.HI R5, R6, 0x2, R7 
   0x0000000202156fb0 <+2992>:	SHF.L.U32 R4, R6, 0x2, RZ 
   0x0000000202156fc0 <+3008>:	IADD3 R4, P0, R0, R4, RZ 
   0x0000000202156fd0 <+3024>:	IADD3.X R5, R3, R5, RZ, P0, !PT 
   0x0000000202156fe0 <+3040>:	MOV R4, R4 
   0x0000000202156ff0 <+3056>:	MOV R5, R5 
   0x0000000202157000 <+3072>:	MOV R4, R4 
   0x0000000202157010 <+3088>:	MOV R5, R5 
   0x0000000202157020 <+3104>:	R2UR UR4, R18 
   0x0000000202157030 <+3120>:	R2UR UR5, R19 
   0x0000000202157040 <+3136>:	LD.E R4, [R4.64] 
   0x0000000202157050 <+3152>:	MOV R4, R4 
   0x0000000202157060 <+3168>:	MOV R4, R4 
   0x0000000202157070 <+3184>:	MOV R5, RZ 
   0x0000000202157080 <+3200>:	S2R R0, SR_TID.X 
   0x0000000202157090 <+3216>:	MOV R0, R0 
   0x00000002021570a0 <+3232>:	IADD3 R0, R0, -0x20, RZ 
   0x00000002021570b0 <+3248>:	MOV R0, R0 
   0x00000002021570c0 <+3264>:	MOV R0, R0 
   0x00000002021570d0 <+3280>:	MOV R3, RZ 
   0x00000002021570e0 <+3296>:	SHF.L.U64.HI R3, R0, 0x3, R3 
   0x00000002021570f0 <+3312>:	SHF.L.U32 R0, R0, 0x3, RZ 
   0x0000000202157100 <+3328>:	IADD3 R16, P0, R16, R0, RZ 
   0x0000000202157110 <+3344>:	IADD3.X R3, R2, R3, RZ, P0, !PT 
   0x0000000202157120 <+3360>:	MOV R2, R16 
   0x0000000202157130 <+3376>:	MOV R3, R3 
   0x0000000202157140 <+3392>:	MOV R2, R2 
   0x0000000202157150 <+3408>:	MOV R3, R3 
   0x0000000202157160 <+3424>:	R2UR UR4, R18 
   0x0000000202157170 <+3440>:	R2UR UR5, R19 
   0x0000000202157180 <+3456>:	ST.E.64 [R2.64], R4 
   0x0000000202157190 <+3472>:	BRA 0xda0 
   0x00000002021571a0 <+3488>:	MEMBAR.SC.VC 
   0x00000002021571b0 <+3504>:	ERRBAR 
   0x00000002021571c0 <+3520>:	EXIT 
   0x00000002021571d0 <+3536>:	MEMBAR.SC.VC 
   0x00000002021571e0 <+3552>:	ERRBAR 
   0x00000002021571f0 <+3568>:	EXIT 
   0x0000000202157200 <+3584>:	BRA 0xe00
   0x0000000202157210 <+3600>:	NOP
   0x0000000202157220 <+3616>:	NOP
   0x0000000202157230 <+3632>:	NOP
   0x0000000202157240 <+3648>:	NOP
   0x0000000202157250 <+3664>:	NOP
   0x0000000202157260 <+3680>:	NOP
   0x0000000202157270 <+3696>:	NOP
   0x0000000202157280 <+3712>:	NOP
   0x0000000202157290 <+3728>:	NOP
   0x00000002021572a0 <+3744>:	NOP
   0x00000002021572b0 <+3760>:	NOP
   0x00000002021572c0 <+3776>:	NOP
   0x00000002021572d0 <+3792>:	NOP
   0x00000002021572e0 <+3808>:	NOP
   0x00000002021572f0 <+3824>:	NOP
End of assembler dump.
(cuda-gdb) 
```

The following further proves that the inter warp barrier is not respected? 
```
(cuda-gdb) info cuda warps 
  Wp Active Lanes Mask Divergent Lanes Mask          Active PC Kernel BlockIdx First Active ThreadIdx 
Device 0 SM 0
   0        0xffffffff           0x00000000 0x0000000202156db0      0  (0,0,0)                (0,0,0) 
*  1        0xffffffff           0x00000000 0x0000000202156e40      0  (0,0,0)               (32,0,0) 
(cuda-gdb) si
0x0000000202156ea0	31	        asm("barrier.cta.sync 1, 32;\n\t");
(cuda-gdb) x/i $pc         
=> 0x202156ea0 <_Z8test_braPlj+2720>:	BAR.SYNC 0x1, 0x20 
(cuda-gdb) si
32	        out[threadIdx.x - NN] = data[threadIdx.x - NN];
(cuda-gdb) info cuda warps 
  Wp Active Lanes Mask Divergent Lanes Mask          Active PC Kernel BlockIdx First Active ThreadIdx 
Device 0 SM 0
   0        0xffffffff           0x00000000 0x0000000202156db0      0  (0,0,0)                (0,0,0) 
*  1        0xffffffff           0x00000000 0x0000000202156eb0      0  (0,0,0)               (32,0,0) 
(cuda-gdb) x/i $pc
=> 0x202156eb0 <_Z8test_braPlj+2736>:	S2R R0, SR_TID.X 
(cuda-gdb) 
```


We try to si warp 1 to the end: 
```
(cuda-gdb) x/i $pc
=> 0x2021570a0 <_Z8test_braPlj+3232>:	IADD3 R0, R0, -0x20, RZ 
(cuda-gdb) disas 
Dump of assembler code for function _Z8test_braPlj:
   0x0000000202156400 <+0>:	ISETP.NE.U32.AND P0, PT, RZ, UR2, PT 
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
   0x0000000202156550 <+336>:	MOV R18, c[0x0][0x118] 
   0x0000000202156560 <+352>:	MOV R19, c[0x0][0x11c] 
   0x0000000202156570 <+368>:	MOV R2, RZ 
   0x0000000202156580 <+384>:	LDC.64 R2, c[0x0][R2+0x160] 
   0x0000000202156590 <+400>:	MOV R16, R2 
   0x00000002021565a0 <+416>:	MOV R2, R3 
   0x00000002021565b0 <+432>:	MOV R16, R16 
   0x00000002021565c0 <+448>:	MOV R2, R2 
   0x00000002021565d0 <+464>:	MOV R0, 0x8 
   0x00000002021565e0 <+480>:	LDC R0, c[0x0][R0+0x160] 
   0x00000002021565f0 <+496>:	MOV R0, R0 
   0x0000000202156600 <+512>:	MOV R0, R0 
   0x0000000202156610 <+528>:	MOV R16, R16 
   0x0000000202156620 <+544>:	MOV R2, R2 
   0x0000000202156630 <+560>:	MOV R17, R0 
   0x0000000202156640 <+576>:	S2R R0, SR_TID.X 
   0x0000000202156650 <+592>:	MOV R0, R0 
   0x0000000202156660 <+608>:	ISETP.LT.U32.AND P0, PT, R0, 0x10, PT 
   0x0000000202156670 <+624>:	PLOP3.LUT P0, PT, P0, PT, PT, 0x8, 0x0 
   0x0000000202156680 <+640>:	BSSY B0, 0x6d0 
--Type <RET> for more, q to quit, c to continue without paging--c
   0x0000000202156690 <+656>:	@P0 BRA 0x6c0 
   0x00000002021566a0 <+672>:	BRA 0x2b0 
   0x00000002021566b0 <+688>:	S2R R6, SR_TID.Y 
   0x00000002021566c0 <+704>:	MOV R6, R6 
   0x00000002021566d0 <+720>:	S2R R0, SR_TID.X 
   0x00000002021566e0 <+736>:	MOV R0, R0 
   0x00000002021566f0 <+752>:	MOV R0, R0 
   0x0000000202156700 <+768>:	MOV R7, R0 
   0x0000000202156710 <+784>:	MOV R8, RZ 
   0x0000000202156720 <+800>:	MOV R4, 0x0 
   0x0000000202156730 <+816>:	MOV R5, 0x0 
   0x0000000202156740 <+832>:	MOV R4, R4 
   0x0000000202156750 <+848>:	MOV R5, R5 
   0x0000000202156760 <+864>:	MOV R3, R4 
   0x0000000202156770 <+880>:	MOV R0, R5 
   0x0000000202156780 <+896>:	MOV R3, R3 
   0x0000000202156790 <+912>:	MOV R0, R0 
   0x00000002021567a0 <+928>:	SHF.L.U64.HI R5, R7, 0x2, R8 
   0x00000002021567b0 <+944>:	SHF.L.U32 R4, R7, 0x2, RZ 
   0x00000002021567c0 <+960>:	IADD3 R4, P0, R3, R4, RZ 
   0x00000002021567d0 <+976>:	IADD3.X R5, R0, R5, RZ, P0, !PT 
   0x00000002021567e0 <+992>:	MOV R4, R4 
   0x00000002021567f0 <+1008>:	MOV R5, R5 
   0x0000000202156800 <+1024>:	MOV R4, R4 
   0x0000000202156810 <+1040>:	MOV R5, R5 
   0x0000000202156820 <+1056>:	R2UR UR4, R18 
   0x0000000202156830 <+1072>:	R2UR UR5, R19 
   0x0000000202156840 <+1088>:	ST.E [R4.64], R6 
   0x0000000202156850 <+1104>:	S2R R6, SR_TID.Z 
   0x0000000202156860 <+1120>:	MOV R6, R6 
   0x0000000202156870 <+1136>:	S2R R4, SR_TID.X 
   0x0000000202156880 <+1152>:	MOV R4, R4 
   0x0000000202156890 <+1168>:	IADD3 R4, R4, 0x10, RZ 
   0x00000002021568a0 <+1184>:	MOV R4, R4 
   0x00000002021568b0 <+1200>:	MOV R4, R4 
   0x00000002021568c0 <+1216>:	MOV R5, RZ 
   0x00000002021568d0 <+1232>:	SHF.L.U64.HI R5, R4, 0x2, R5 
   0x00000002021568e0 <+1248>:	SHF.L.U32 R4, R4, 0x2, RZ 
   0x00000002021568f0 <+1264>:	IADD3 R4, P0, R3, R4, RZ 
   0x0000000202156900 <+1280>:	IADD3.X R5, R0, R5, RZ, P0, !PT 
   0x0000000202156910 <+1296>:	MOV R4, R4 
   0x0000000202156920 <+1312>:	MOV R5, R5 
   0x0000000202156930 <+1328>:	MOV R4, R4 
   0x0000000202156940 <+1344>:	MOV R5, R5 
   0x0000000202156950 <+1360>:	R2UR UR4, R18 
   0x0000000202156960 <+1376>:	R2UR UR5, R19 
   0x0000000202156970 <+1392>:	ST.E [R4.64], R6 
   0x0000000202156980 <+1408>:	S2R R6, SR_TID.X 
   0x0000000202156990 <+1424>:	MOV R6, R6 
   0x00000002021569a0 <+1440>:	S2R R4, SR_TID.X 
   0x00000002021569b0 <+1456>:	MOV R4, R4 
   0x00000002021569c0 <+1472>:	IADD3 R4, R4, 0x20, RZ 
   0x00000002021569d0 <+1488>:	MOV R4, R4 
   0x00000002021569e0 <+1504>:	MOV R4, R4 
   0x00000002021569f0 <+1520>:	MOV R5, RZ 
   0x0000000202156a00 <+1536>:	SHF.L.U64.HI R5, R4, 0x2, R5 
   0x0000000202156a10 <+1552>:	SHF.L.U32 R4, R4, 0x2, RZ 
   0x0000000202156a20 <+1568>:	IADD3 R4, P0, R3, R4, RZ 
   0x0000000202156a30 <+1584>:	IADD3.X R5, R0, R5, RZ, P0, !PT 
   0x0000000202156a40 <+1600>:	MOV R4, R4 
   0x0000000202156a50 <+1616>:	MOV R5, R5 
   0x0000000202156a60 <+1632>:	MOV R4, R4 
   0x0000000202156a70 <+1648>:	MOV R5, R5 
   0x0000000202156a80 <+1664>:	R2UR UR4, R18 
   0x0000000202156a90 <+1680>:	R2UR UR5, R19 
   0x0000000202156aa0 <+1696>:	ST.E [R4.64], R6 
   0x0000000202156ab0 <+1712>:	BRA 0x6c0 
   0x0000000202156ac0 <+1728>:	BSYNC B0 
   0x0000000202156ad0 <+1744>:	S2R R0, SR_TID.X 
   0x0000000202156ae0 <+1760>:	MOV R0, R0 
   0x0000000202156af0 <+1776>:	ISETP.LT.U32.AND P0, PT, R0, 0x20, PT 
   0x0000000202156b00 <+1792>:	PLOP3.LUT P0, PT, P0, PT, PT, 0x8, 0x0 
   0x0000000202156b10 <+1808>:	@P0 BRA 0x9d0 
   0x0000000202156b20 <+1824>:	BRA 0x730 
   0x0000000202156b30 <+1840>:	BRA.CONV ~URZ, 0x790 
   0x0000000202156b40 <+1856>:	MOV R4, 0x20 
   0x0000000202156b50 <+1872>:	MOV R20, 0x0 
   0x0000000202156b60 <+1888>:	MOV R21, 0x0 
   0x0000000202156b70 <+1904>:	CALL.ABS.NOINC 0x0 
   0x0000000202156b80 <+1920>:	BRA 0x7a0 
   0x0000000202156b90 <+1936>:	BAR.SYNC 0x0, 0x20 
   0x0000000202156ba0 <+1952>:	S2R R0, SR_TID.X 
   0x0000000202156bb0 <+1968>:	MOV R0, R0 
   0x0000000202156bc0 <+1984>:	S2R R2, SR_TID.X 
   0x0000000202156bd0 <+2000>:	MOV R2, R2 
   0x0000000202156be0 <+2016>:	MOV R2, R2 
   0x0000000202156bf0 <+2032>:	MOV R6, R2 
   0x0000000202156c00 <+2048>:	MOV R7, RZ 
   0x0000000202156c10 <+2064>:	MOV R2, 0x0 
   0x0000000202156c20 <+2080>:	MOV R2, R2 
   0x0000000202156c30 <+2096>:	MOV R2, R2 
   0x0000000202156c40 <+2112>:	MOV R2, R2 
   0x0000000202156c50 <+2128>:	MOV R3, RZ 
   0x0000000202156c60 <+2144>:	MOV R4, c[0x0][0x18] 
   0x0000000202156c70 <+2160>:	MOV R5, c[0x0][0x1c] 
   0x0000000202156c80 <+2176>:	IADD3 R4, P0, R2, R4, RZ 
   0x0000000202156c90 <+2192>:	IADD3.X R5, R3, R5, RZ, P0, !PT 
   0x0000000202156ca0 <+2208>:	SHF.L.U64.HI R3, R6, 0x2, R7 
   0x0000000202156cb0 <+2224>:	SHF.L.U32 R2, R6, 0x2, RZ 
   0x0000000202156cc0 <+2240>:	IADD3 R2, P0, R4, R2, RZ 
   0x0000000202156cd0 <+2256>:	IADD3.X R3, R5, R3, RZ, P0, !PT 
   0x0000000202156ce0 <+2272>:	MOV R2, R2 
   0x0000000202156cf0 <+2288>:	MOV R3, R3 
   0x0000000202156d00 <+2304>:	MOV R2, R2 
   0x0000000202156d10 <+2320>:	MOV R3, R3 
   0x0000000202156d20 <+2336>:	R2UR UR4, R18 
   0x0000000202156d30 <+2352>:	R2UR UR5, R19 
   0x0000000202156d40 <+2368>:	ST.E [R2.64], R0 
   0x0000000202156d50 <+2384>:	BRA.CONV ~URZ, 0x9b0 
   0x0000000202156d60 <+2400>:	MOV R4, 0x20 
   0x0000000202156d70 <+2416>:	MOV R20, 0x0 
   0x0000000202156d80 <+2432>:	MOV R21, 0x0 
   0x0000000202156d90 <+2448>:	CALL.ABS.NOINC 0x0 
   0x0000000202156da0 <+2464>:	BRA 0x9c0 
   0x0000000202156db0 <+2480>:	BAR.ARV 0x1, 0x20 
   0x0000000202156dc0 <+2496>:	BRA 0xda0 
   0x0000000202156dd0 <+2512>:	BRA.CONV ~URZ, 0xa30 
   0x0000000202156de0 <+2528>:	MOV R4, 0x20 
   0x0000000202156df0 <+2544>:	MOV R20, 0x0 
   0x0000000202156e00 <+2560>:	MOV R21, 0x0 
   0x0000000202156e10 <+2576>:	CALL.ABS.NOINC 0x0 
   0x0000000202156e20 <+2592>:	BRA 0xa40 
   0x0000000202156e30 <+2608>:	BAR.ARV 0x0, 0x20 
   0x0000000202156e40 <+2624>:	BRA.CONV ~URZ, 0xaa0 
   0x0000000202156e50 <+2640>:	MOV R4, 0x20 
   0x0000000202156e60 <+2656>:	MOV R20, 0x0 
   0x0000000202156e70 <+2672>:	MOV R21, 0x0 
   0x0000000202156e80 <+2688>:	CALL.ABS.NOINC 0x0 
   0x0000000202156e90 <+2704>:	BRA 0xab0 
   0x0000000202156ea0 <+2720>:	BAR.SYNC 0x1, 0x20 
   0x0000000202156eb0 <+2736>:	S2R R0, SR_TID.X 
   0x0000000202156ec0 <+2752>:	MOV R0, R0 
   0x0000000202156ed0 <+2768>:	IADD3 R0, R0, -0x20, RZ 
   0x0000000202156ee0 <+2784>:	MOV R0, R0 
   0x0000000202156ef0 <+2800>:	MOV R6, R0 
   0x0000000202156f00 <+2816>:	MOV R7, RZ 
   0x0000000202156f10 <+2832>:	MOV R0, 0x0 
   0x0000000202156f20 <+2848>:	MOV R0, R0 
   0x0000000202156f30 <+2864>:	MOV R0, R0 
   0x0000000202156f40 <+2880>:	MOV R4, R0 
   0x0000000202156f50 <+2896>:	MOV R5, RZ 
   0x0000000202156f60 <+2912>:	MOV R0, c[0x0][0x18] 
   0x0000000202156f70 <+2928>:	MOV R3, c[0x0][0x1c] 
   0x0000000202156f80 <+2944>:	IADD3 R0, P0, R4, R0, RZ 
   0x0000000202156f90 <+2960>:	IADD3.X R3, R5, R3, RZ, P0, !PT 
   0x0000000202156fa0 <+2976>:	SHF.L.U64.HI R5, R6, 0x2, R7 
   0x0000000202156fb0 <+2992>:	SHF.L.U32 R4, R6, 0x2, RZ 
   0x0000000202156fc0 <+3008>:	IADD3 R4, P0, R0, R4, RZ 
   0x0000000202156fd0 <+3024>:	IADD3.X R5, R3, R5, RZ, P0, !PT 
   0x0000000202156fe0 <+3040>:	MOV R4, R4 
   0x0000000202156ff0 <+3056>:	MOV R5, R5 
   0x0000000202157000 <+3072>:	MOV R4, R4 
   0x0000000202157010 <+3088>:	MOV R5, R5 
   0x0000000202157020 <+3104>:	R2UR UR4, R18 
   0x0000000202157030 <+3120>:	R2UR UR5, R19 
   0x0000000202157040 <+3136>:	LD.E R4, [R4.64] 
   0x0000000202157050 <+3152>:	MOV R4, R4 
   0x0000000202157060 <+3168>:	MOV R4, R4 
   0x0000000202157070 <+3184>:	MOV R5, RZ 
   0x0000000202157080 <+3200>:	S2R R0, SR_TID.X 
   0x0000000202157090 <+3216>:	MOV R0, R0 
=> 0x00000002021570a0 <+3232>:	IADD3 R0, R0, -0x20, RZ 
   0x00000002021570b0 <+3248>:	MOV R0, R0 
   0x00000002021570c0 <+3264>:	MOV R0, R0 
   0x00000002021570d0 <+3280>:	MOV R3, RZ 
   0x00000002021570e0 <+3296>:	SHF.L.U64.HI R3, R0, 0x3, R3 
   0x00000002021570f0 <+3312>:	SHF.L.U32 R0, R0, 0x3, RZ 
   0x0000000202157100 <+3328>:	IADD3 R16, P0, R16, R0, RZ 
   0x0000000202157110 <+3344>:	IADD3.X R3, R2, R3, RZ, P0, !PT 
   0x0000000202157120 <+3360>:	MOV R2, R16 
   0x0000000202157130 <+3376>:	MOV R3, R3 
   0x0000000202157140 <+3392>:	MOV R2, R2 
   0x0000000202157150 <+3408>:	MOV R3, R3 
   0x0000000202157160 <+3424>:	R2UR UR4, R18 
   0x0000000202157170 <+3440>:	R2UR UR5, R19 
   0x0000000202157180 <+3456>:	ST.E.64 [R2.64], R4 
   0x0000000202157190 <+3472>:	BRA 0xda0 
   0x00000002021571a0 <+3488>:	MEMBAR.SC.VC 
   0x00000002021571b0 <+3504>:	ERRBAR 
   0x00000002021571c0 <+3520>:	EXIT 
   0x00000002021571d0 <+3536>:	MEMBAR.SC.VC 
   0x00000002021571e0 <+3552>:	ERRBAR 
   0x00000002021571f0 <+3568>:	EXIT 
   0x0000000202157200 <+3584>:	BRA 0xe00
   0x0000000202157210 <+3600>:	NOP
   0x0000000202157220 <+3616>:	NOP
   0x0000000202157230 <+3632>:	NOP
   0x0000000202157240 <+3648>:	NOP
   0x0000000202157250 <+3664>:	NOP
   0x0000000202157260 <+3680>:	NOP
   0x0000000202157270 <+3696>:	NOP
   0x0000000202157280 <+3712>:	NOP
   0x0000000202157290 <+3728>:	NOP
   0x00000002021572a0 <+3744>:	NOP
   0x00000002021572b0 <+3760>:	NOP
   0x00000002021572c0 <+3776>:	NOP
   0x00000002021572d0 <+3792>:	NOP
   0x00000002021572e0 <+3808>:	NOP
   0x00000002021572f0 <+3824>:	NOP
End of assembler dump.
(cuda-gdb) si 5
0x00000002021570f0	32	        out[threadIdx.x - NN] = data[threadIdx.x - NN];
(cuda-gdb) x/i $pc
=> 0x2021570f0 <_Z8test_braPlj+3312>:	SHF.L.U32 R0, R0, 0x3, RZ 
(cuda-gdb) si  
0x0000000202157100	32	        out[threadIdx.x - NN] = data[threadIdx.x - NN];
(cuda-gdb) si 5 
0x0000000202157150	32	        out[threadIdx.x - NN] = data[threadIdx.x - NN];
(cuda-gdb) x/i $pc
=> 0x202157150 <_Z8test_braPlj+3408>:	MOV R3, R3 
(cuda-gdb) si
0x0000000202157160	32	        out[threadIdx.x - NN] = data[threadIdx.x - NN];
(cuda-gdb) x/i $pc
=> 0x202157160 <_Z8test_braPlj+3424>:	R2UR UR4, R18 
(cuda-gdb) si 
0x0000000202157170	32	        out[threadIdx.x - NN] = data[threadIdx.x - NN];
(cuda-gdb) x/i $pc
=> 0x202157170 <_Z8test_braPlj+3440>:	R2UR UR5, R19 
(cuda-gdb) si 
0x0000000202157180	32	        out[threadIdx.x - NN] = data[threadIdx.x - NN];
(cuda-gdb) x/i $pc 
=> 0x202157180 <_Z8test_braPlj+3456>:	ST.E.64 [R2.64], R4 
(cuda-gdb) si
0x0000000202157190	32	        out[threadIdx.x - NN] = data[threadIdx.x - NN];
(cuda-gdb) x/i $pc
=> 0x202157190 <_Z8test_braPlj+3472>:	BRA 0xda0 
(cuda-gdb) si
34	}
(cuda-gdb) x/i $pc
=> 0x2021571a0 <_Z8test_braPlj+3488>:	MEMBAR.SC.VC 
(cuda-gdb) info cuda warps 
  Wp Active Lanes Mask Divergent Lanes Mask          Active PC Kernel BlockIdx First Active ThreadIdx 
Device 0 SM 0
   0        0xffffffff           0x00000000 0x0000000202156db0      0  (0,0,0)                (0,0,0) 
*  1        0xffffffff           0x00000000 0x00000002021571a0      0  (0,0,0)               (32,0,0) 
(cuda-gdb) 
```

And see what's happening in the epilogue: 
```
(cuda-gdb) si 
0x00000002021571b0	34	}
(cuda-gdb) x/i $pc         
=> 0x2021571b0 <_Z8test_braPlj+3504>:	ERRBAR 
(cuda-gdb) info cuda warps 
  Wp Active Lanes Mask Divergent Lanes Mask          Active PC Kernel BlockIdx First Active ThreadIdx 
Device 0 SM 0
   0        0xffffffff           0x00000000 0x0000000202156db0      0  (0,0,0)                (0,0,0) 
*  1        0xffffffff           0x00000000 0x00000002021571b0      0  (0,0,0)               (32,0,0) 
(cuda-gdb) info register 
pc             0x2021571b0         0x2021571b0 <test_bra(long*, unsigned int)+3504>
errorpc        <unavailable>
R0             0x0                 0
R1             0xfffdc0            16776640
R2             0x50e0000           84803584
R3             0x2                 2
R4             0x0                 0
R5             0x0                 0
R6             0x0                 0
R7             0x0                 0
R8             0x0                 0
R9             0x0                 0
R10            0x0                 0
R11            0x0                 0
R12            0x0                 0
R13            0x0                 0
R14            0x0                 0
R15            0x0                 0
R16            0x50e0000           84803584
R17            0x40                64
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
P0             0x0                 0
P1             0x0                 0
P2             0x0                 0
P3             0x0                 0
P4             0x0                 0
P5             0x0                 0
P6             0x0                 0
P7             0x1                 1
UR0            0x0                 0
UR1            0x0                 0
UR2            0x1                 1
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
(cuda-gdb) info cuda warps 
  Wp Active Lanes Mask Divergent Lanes Mask          Active PC Kernel BlockIdx First Active ThreadIdx 
Device 0 SM 0
   0        0xffffffff           0x00000000 0x0000000202156db0      0  (0,0,0)                (0,0,0) 
*  1        0xffffffff           0x00000000 0x00000002021571b0      0  (0,0,0)               (32,0,0) 
(cuda-gdb) si              
0x00000002021571c0	34	}
(cuda-gdb) info register   
pc             0x2021571c0         0x2021571c0 <test_bra(long*, unsigned int)+3520>
errorpc        <unavailable>
R0             0x0                 0
R1             0xfffdc0            16776640
R2             0x50e0000           84803584
R3             0x2                 2
R4             0x0                 0
R5             0x0                 0
R6             0x0                 0
R7             0x0                 0
R8             0x0                 0
R9             0x0                 0
R10            0x0                 0
R11            0x0                 0
R12            0x0                 0
R13            0x0                 0
R14            0x0                 0
R15            0x0                 0
R16            0x50e0000           84803584
R17            0x40                64
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
P0             0x0                 0
P1             0x0                 0
P2             0x0                 0
P3             0x0                 0
P4             0x0                 0
P5             0x0                 0
P6             0x0                 0
P7             0x1                 1
UR0            0x0                 0
UR1            0x0                 0
UR2            0x1                 1
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
(cuda-gdb) info cuda warps 
  Wp Active Lanes Mask Divergent Lanes Mask          Active PC Kernel BlockIdx First Active ThreadIdx 
Device 0 SM 0
   0        0xffffffff           0x00000000 0x0000000202156db0      0  (0,0,0)                (0,0,0) 
*  1        0xffffffff           0x00000000 0x00000002021571c0      0  (0,0,0)               (32,0,0) 
(cuda-gdb)                 
```

Now it will automatically jump back the warp0: 
```
(cuda-gdb) info cuda warps 
  Wp Active Lanes Mask Divergent Lanes Mask          Active PC Kernel BlockIdx First Active ThreadIdx 
Device 0 SM 0
   0        0xffffffff           0x00000000 0x0000000202156db0      0  (0,0,0)                (0,0,0) 
*  1        0xffffffff           0x00000000 0x00000002021571c0      0  (0,0,0)               (32,0,0) 
(cuda-gdb) si              
[Switching focus to CUDA kernel 0, grid 1, block (0,0,0), thread (0,0,0), device 0, sm 0, warp 0, lane 0]
0x0000000202156db0	28	        asm("barrier.cta.arrive 1, 32;\n\t");
(cuda-gdb) info cuda warps 
  Wp Active Lanes Mask Divergent Lanes Mask          Active PC Kernel BlockIdx First Active ThreadIdx 
Device 0 SM 0
*  0        0xffffffff           0x00000000 0x0000000202156db0      0  (0,0,0)                (0,0,0) 
(cuda-gdb) x/i $pc
=> 0x202156db0 <_Z8test_braPlj+2480>:	BAR.ARV 0x1, 0x20 
(cuda-gdb) si
0x0000000202156dc0	28	        asm("barrier.cta.arrive 1, 32;\n\t");
(cuda-gdb) x/i $pc
=> 0x202156dc0 <_Z8test_braPlj+2496>:	BRA 0xda0 
(cuda-gdb) si     
34	}
(cuda-gdb) disas 
Dump of assembler code for function _Z8test_braPlj:
   0x0000000202156400 <+0>:	ISETP.NE.U32.AND P0, PT, RZ, UR2, PT 
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
   0x0000000202156550 <+336>:	MOV R18, c[0x0][0x118] 
   0x0000000202156560 <+352>:	MOV R19, c[0x0][0x11c] 
   0x0000000202156570 <+368>:	MOV R2, RZ 
   0x0000000202156580 <+384>:	LDC.64 R2, c[0x0][R2+0x160] 
   0x0000000202156590 <+400>:	MOV R16, R2 
   0x00000002021565a0 <+416>:	MOV R2, R3 
   0x00000002021565b0 <+432>:	MOV R16, R16 
   0x00000002021565c0 <+448>:	MOV R2, R2 
   0x00000002021565d0 <+464>:	MOV R0, 0x8 
   0x00000002021565e0 <+480>:	LDC R0, c[0x0][R0+0x160] 
   0x00000002021565f0 <+496>:	MOV R0, R0 
   0x0000000202156600 <+512>:	MOV R0, R0 
   0x0000000202156610 <+528>:	MOV R16, R16 
   0x0000000202156620 <+544>:	MOV R2, R2 
   0x0000000202156630 <+560>:	MOV R17, R0 
   0x0000000202156640 <+576>:	S2R R0, SR_TID.X 
   0x0000000202156650 <+592>:	MOV R0, R0 
   0x0000000202156660 <+608>:	ISETP.LT.U32.AND P0, PT, R0, 0x10, PT 
   0x0000000202156670 <+624>:	PLOP3.LUT P0, PT, P0, PT, PT, 0x8, 0x0 
   0x0000000202156680 <+640>:	BSSY B0, 0x6d0 
--Type <RET> for more, q to quit, c to continue without paging--c
   0x0000000202156690 <+656>:	@P0 BRA 0x6c0 
   0x00000002021566a0 <+672>:	BRA 0x2b0 
   0x00000002021566b0 <+688>:	S2R R6, SR_TID.Y 
   0x00000002021566c0 <+704>:	MOV R6, R6 
   0x00000002021566d0 <+720>:	S2R R0, SR_TID.X 
   0x00000002021566e0 <+736>:	MOV R0, R0 
   0x00000002021566f0 <+752>:	MOV R0, R0 
   0x0000000202156700 <+768>:	MOV R7, R0 
   0x0000000202156710 <+784>:	MOV R8, RZ 
   0x0000000202156720 <+800>:	MOV R4, 0x0 
   0x0000000202156730 <+816>:	MOV R5, 0x0 
   0x0000000202156740 <+832>:	MOV R4, R4 
   0x0000000202156750 <+848>:	MOV R5, R5 
   0x0000000202156760 <+864>:	MOV R3, R4 
   0x0000000202156770 <+880>:	MOV R0, R5 
   0x0000000202156780 <+896>:	MOV R3, R3 
   0x0000000202156790 <+912>:	MOV R0, R0 
   0x00000002021567a0 <+928>:	SHF.L.U64.HI R5, R7, 0x2, R8 
   0x00000002021567b0 <+944>:	SHF.L.U32 R4, R7, 0x2, RZ 
   0x00000002021567c0 <+960>:	IADD3 R4, P0, R3, R4, RZ 
   0x00000002021567d0 <+976>:	IADD3.X R5, R0, R5, RZ, P0, !PT 
   0x00000002021567e0 <+992>:	MOV R4, R4 
   0x00000002021567f0 <+1008>:	MOV R5, R5 
   0x0000000202156800 <+1024>:	MOV R4, R4 
   0x0000000202156810 <+1040>:	MOV R5, R5 
   0x0000000202156820 <+1056>:	R2UR UR4, R18 
   0x0000000202156830 <+1072>:	R2UR UR5, R19 
   0x0000000202156840 <+1088>:	ST.E [R4.64], R6 
   0x0000000202156850 <+1104>:	S2R R6, SR_TID.Z 
   0x0000000202156860 <+1120>:	MOV R6, R6 
   0x0000000202156870 <+1136>:	S2R R4, SR_TID.X 
   0x0000000202156880 <+1152>:	MOV R4, R4 
   0x0000000202156890 <+1168>:	IADD3 R4, R4, 0x10, RZ 
   0x00000002021568a0 <+1184>:	MOV R4, R4 
   0x00000002021568b0 <+1200>:	MOV R4, R4 
   0x00000002021568c0 <+1216>:	MOV R5, RZ 
   0x00000002021568d0 <+1232>:	SHF.L.U64.HI R5, R4, 0x2, R5 
   0x00000002021568e0 <+1248>:	SHF.L.U32 R4, R4, 0x2, RZ 
   0x00000002021568f0 <+1264>:	IADD3 R4, P0, R3, R4, RZ 
   0x0000000202156900 <+1280>:	IADD3.X R5, R0, R5, RZ, P0, !PT 
   0x0000000202156910 <+1296>:	MOV R4, R4 
   0x0000000202156920 <+1312>:	MOV R5, R5 
   0x0000000202156930 <+1328>:	MOV R4, R4 
   0x0000000202156940 <+1344>:	MOV R5, R5 
   0x0000000202156950 <+1360>:	R2UR UR4, R18 
   0x0000000202156960 <+1376>:	R2UR UR5, R19 
   0x0000000202156970 <+1392>:	ST.E [R4.64], R6 
   0x0000000202156980 <+1408>:	S2R R6, SR_TID.X 
   0x0000000202156990 <+1424>:	MOV R6, R6 
   0x00000002021569a0 <+1440>:	S2R R4, SR_TID.X 
   0x00000002021569b0 <+1456>:	MOV R4, R4 
   0x00000002021569c0 <+1472>:	IADD3 R4, R4, 0x20, RZ 
   0x00000002021569d0 <+1488>:	MOV R4, R4 
   0x00000002021569e0 <+1504>:	MOV R4, R4 
   0x00000002021569f0 <+1520>:	MOV R5, RZ 
   0x0000000202156a00 <+1536>:	SHF.L.U64.HI R5, R4, 0x2, R5 
   0x0000000202156a10 <+1552>:	SHF.L.U32 R4, R4, 0x2, RZ 
   0x0000000202156a20 <+1568>:	IADD3 R4, P0, R3, R4, RZ 
   0x0000000202156a30 <+1584>:	IADD3.X R5, R0, R5, RZ, P0, !PT 
   0x0000000202156a40 <+1600>:	MOV R4, R4 
   0x0000000202156a50 <+1616>:	MOV R5, R5 
   0x0000000202156a60 <+1632>:	MOV R4, R4 
   0x0000000202156a70 <+1648>:	MOV R5, R5 
   0x0000000202156a80 <+1664>:	R2UR UR4, R18 
   0x0000000202156a90 <+1680>:	R2UR UR5, R19 
   0x0000000202156aa0 <+1696>:	ST.E [R4.64], R6 
   0x0000000202156ab0 <+1712>:	BRA 0x6c0 
   0x0000000202156ac0 <+1728>:	BSYNC B0 
   0x0000000202156ad0 <+1744>:	S2R R0, SR_TID.X 
   0x0000000202156ae0 <+1760>:	MOV R0, R0 
   0x0000000202156af0 <+1776>:	ISETP.LT.U32.AND P0, PT, R0, 0x20, PT 
   0x0000000202156b00 <+1792>:	PLOP3.LUT P0, PT, P0, PT, PT, 0x8, 0x0 
   0x0000000202156b10 <+1808>:	@P0 BRA 0x9d0 
   0x0000000202156b20 <+1824>:	BRA 0x730 
   0x0000000202156b30 <+1840>:	BRA.CONV ~URZ, 0x790 
   0x0000000202156b40 <+1856>:	MOV R4, 0x20 
   0x0000000202156b50 <+1872>:	MOV R20, 0x0 
   0x0000000202156b60 <+1888>:	MOV R21, 0x0 
   0x0000000202156b70 <+1904>:	CALL.ABS.NOINC 0x0 
   0x0000000202156b80 <+1920>:	BRA 0x7a0 
   0x0000000202156b90 <+1936>:	BAR.SYNC 0x0, 0x20 
   0x0000000202156ba0 <+1952>:	S2R R0, SR_TID.X 
   0x0000000202156bb0 <+1968>:	MOV R0, R0 
   0x0000000202156bc0 <+1984>:	S2R R2, SR_TID.X 
   0x0000000202156bd0 <+2000>:	MOV R2, R2 
   0x0000000202156be0 <+2016>:	MOV R2, R2 
   0x0000000202156bf0 <+2032>:	MOV R6, R2 
   0x0000000202156c00 <+2048>:	MOV R7, RZ 
   0x0000000202156c10 <+2064>:	MOV R2, 0x0 
   0x0000000202156c20 <+2080>:	MOV R2, R2 
   0x0000000202156c30 <+2096>:	MOV R2, R2 
   0x0000000202156c40 <+2112>:	MOV R2, R2 
   0x0000000202156c50 <+2128>:	MOV R3, RZ 
   0x0000000202156c60 <+2144>:	MOV R4, c[0x0][0x18] 
   0x0000000202156c70 <+2160>:	MOV R5, c[0x0][0x1c] 
   0x0000000202156c80 <+2176>:	IADD3 R4, P0, R2, R4, RZ 
   0x0000000202156c90 <+2192>:	IADD3.X R5, R3, R5, RZ, P0, !PT 
   0x0000000202156ca0 <+2208>:	SHF.L.U64.HI R3, R6, 0x2, R7 
   0x0000000202156cb0 <+2224>:	SHF.L.U32 R2, R6, 0x2, RZ 
   0x0000000202156cc0 <+2240>:	IADD3 R2, P0, R4, R2, RZ 
   0x0000000202156cd0 <+2256>:	IADD3.X R3, R5, R3, RZ, P0, !PT 
   0x0000000202156ce0 <+2272>:	MOV R2, R2 
   0x0000000202156cf0 <+2288>:	MOV R3, R3 
   0x0000000202156d00 <+2304>:	MOV R2, R2 
   0x0000000202156d10 <+2320>:	MOV R3, R3 
   0x0000000202156d20 <+2336>:	R2UR UR4, R18 
   0x0000000202156d30 <+2352>:	R2UR UR5, R19 
   0x0000000202156d40 <+2368>:	ST.E [R2.64], R0 
   0x0000000202156d50 <+2384>:	BRA.CONV ~URZ, 0x9b0 
   0x0000000202156d60 <+2400>:	MOV R4, 0x20 
   0x0000000202156d70 <+2416>:	MOV R20, 0x0 
   0x0000000202156d80 <+2432>:	MOV R21, 0x0 
   0x0000000202156d90 <+2448>:	CALL.ABS.NOINC 0x0 
   0x0000000202156da0 <+2464>:	BRA 0x9c0 
   0x0000000202156db0 <+2480>:	BAR.ARV 0x1, 0x20 
   0x0000000202156dc0 <+2496>:	BRA 0xda0 
   0x0000000202156dd0 <+2512>:	BRA.CONV ~URZ, 0xa30 
   0x0000000202156de0 <+2528>:	MOV R4, 0x20 
   0x0000000202156df0 <+2544>:	MOV R20, 0x0 
   0x0000000202156e00 <+2560>:	MOV R21, 0x0 
   0x0000000202156e10 <+2576>:	CALL.ABS.NOINC 0x0 
   0x0000000202156e20 <+2592>:	BRA 0xa40 
   0x0000000202156e30 <+2608>:	BAR.ARV 0x0, 0x20 
   0x0000000202156e40 <+2624>:	BRA.CONV ~URZ, 0xaa0 
   0x0000000202156e50 <+2640>:	MOV R4, 0x20 
   0x0000000202156e60 <+2656>:	MOV R20, 0x0 
   0x0000000202156e70 <+2672>:	MOV R21, 0x0 
   0x0000000202156e80 <+2688>:	CALL.ABS.NOINC 0x0 
   0x0000000202156e90 <+2704>:	BRA 0xab0 
   0x0000000202156ea0 <+2720>:	BAR.SYNC 0x1, 0x20 
   0x0000000202156eb0 <+2736>:	S2R R0, SR_TID.X 
   0x0000000202156ec0 <+2752>:	MOV R0, R0 
   0x0000000202156ed0 <+2768>:	IADD3 R0, R0, -0x20, RZ 
   0x0000000202156ee0 <+2784>:	MOV R0, R0 
   0x0000000202156ef0 <+2800>:	MOV R6, R0 
   0x0000000202156f00 <+2816>:	MOV R7, RZ 
   0x0000000202156f10 <+2832>:	MOV R0, 0x0 
   0x0000000202156f20 <+2848>:	MOV R0, R0 
   0x0000000202156f30 <+2864>:	MOV R0, R0 
   0x0000000202156f40 <+2880>:	MOV R4, R0 
   0x0000000202156f50 <+2896>:	MOV R5, RZ 
   0x0000000202156f60 <+2912>:	MOV R0, c[0x0][0x18] 
   0x0000000202156f70 <+2928>:	MOV R3, c[0x0][0x1c] 
   0x0000000202156f80 <+2944>:	IADD3 R0, P0, R4, R0, RZ 
   0x0000000202156f90 <+2960>:	IADD3.X R3, R5, R3, RZ, P0, !PT 
   0x0000000202156fa0 <+2976>:	SHF.L.U64.HI R5, R6, 0x2, R7 
   0x0000000202156fb0 <+2992>:	SHF.L.U32 R4, R6, 0x2, RZ 
   0x0000000202156fc0 <+3008>:	IADD3 R4, P0, R0, R4, RZ 
   0x0000000202156fd0 <+3024>:	IADD3.X R5, R3, R5, RZ, P0, !PT 
   0x0000000202156fe0 <+3040>:	MOV R4, R4 
   0x0000000202156ff0 <+3056>:	MOV R5, R5 
   0x0000000202157000 <+3072>:	MOV R4, R4 
   0x0000000202157010 <+3088>:	MOV R5, R5 
   0x0000000202157020 <+3104>:	R2UR UR4, R18 
   0x0000000202157030 <+3120>:	R2UR UR5, R19 
   0x0000000202157040 <+3136>:	LD.E R4, [R4.64] 
   0x0000000202157050 <+3152>:	MOV R4, R4 
   0x0000000202157060 <+3168>:	MOV R4, R4 
   0x0000000202157070 <+3184>:	MOV R5, RZ 
   0x0000000202157080 <+3200>:	S2R R0, SR_TID.X 
   0x0000000202157090 <+3216>:	MOV R0, R0 
   0x00000002021570a0 <+3232>:	IADD3 R0, R0, -0x20, RZ 
   0x00000002021570b0 <+3248>:	MOV R0, R0 
   0x00000002021570c0 <+3264>:	MOV R0, R0 
   0x00000002021570d0 <+3280>:	MOV R3, RZ 
   0x00000002021570e0 <+3296>:	SHF.L.U64.HI R3, R0, 0x3, R3 
   0x00000002021570f0 <+3312>:	SHF.L.U32 R0, R0, 0x3, RZ 
   0x0000000202157100 <+3328>:	IADD3 R16, P0, R16, R0, RZ 
   0x0000000202157110 <+3344>:	IADD3.X R3, R2, R3, RZ, P0, !PT 
   0x0000000202157120 <+3360>:	MOV R2, R16 
   0x0000000202157130 <+3376>:	MOV R3, R3 
   0x0000000202157140 <+3392>:	MOV R2, R2 
   0x0000000202157150 <+3408>:	MOV R3, R3 
   0x0000000202157160 <+3424>:	R2UR UR4, R18 
   0x0000000202157170 <+3440>:	R2UR UR5, R19 
   0x0000000202157180 <+3456>:	ST.E.64 [R2.64], R4 
   0x0000000202157190 <+3472>:	BRA 0xda0 
=> 0x00000002021571a0 <+3488>:	MEMBAR.SC.VC 
   0x00000002021571b0 <+3504>:	ERRBAR 
   0x00000002021571c0 <+3520>:	EXIT 
   0x00000002021571d0 <+3536>:	MEMBAR.SC.VC 
   0x00000002021571e0 <+3552>:	ERRBAR 
   0x00000002021571f0 <+3568>:	EXIT 
   0x0000000202157200 <+3584>:	BRA 0xe00
   0x0000000202157210 <+3600>:	NOP
   0x0000000202157220 <+3616>:	NOP
   0x0000000202157230 <+3632>:	NOP
   0x0000000202157240 <+3648>:	NOP
   0x0000000202157250 <+3664>:	NOP
   0x0000000202157260 <+3680>:	NOP
   0x0000000202157270 <+3696>:	NOP
   0x0000000202157280 <+3712>:	NOP
   0x0000000202157290 <+3728>:	NOP
   0x00000002021572a0 <+3744>:	NOP
   0x00000002021572b0 <+3760>:	NOP
   0x00000002021572c0 <+3776>:	NOP
   0x00000002021572d0 <+3792>:	NOP
   0x00000002021572e0 <+3808>:	NOP
   0x00000002021572f0 <+3824>:	NOP
End of assembler dump.
(cuda-gdb) si
0x00000002021571b0	34	}
(cuda-gdb) si
0x00000002021571c0	34	}
(cuda-gdb) disas 
Dump of assembler code for function _Z8test_braPlj:
   0x0000000202156400 <+0>:	ISETP.NE.U32.AND P0, PT, RZ, UR2, PT 
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
   0x0000000202156550 <+336>:	MOV R18, c[0x0][0x118] 
   0x0000000202156560 <+352>:	MOV R19, c[0x0][0x11c] 
   0x0000000202156570 <+368>:	MOV R2, RZ 
   0x0000000202156580 <+384>:	LDC.64 R2, c[0x0][R2+0x160] 
   0x0000000202156590 <+400>:	MOV R16, R2 
   0x00000002021565a0 <+416>:	MOV R2, R3 
   0x00000002021565b0 <+432>:	MOV R16, R16 
   0x00000002021565c0 <+448>:	MOV R2, R2 
   0x00000002021565d0 <+464>:	MOV R0, 0x8 
   0x00000002021565e0 <+480>:	LDC R0, c[0x0][R0+0x160] 
   0x00000002021565f0 <+496>:	MOV R0, R0 
   0x0000000202156600 <+512>:	MOV R0, R0 
   0x0000000202156610 <+528>:	MOV R16, R16 
   0x0000000202156620 <+544>:	MOV R2, R2 
   0x0000000202156630 <+560>:	MOV R17, R0 
   0x0000000202156640 <+576>:	S2R R0, SR_TID.X 
   0x0000000202156650 <+592>:	MOV R0, R0 
   0x0000000202156660 <+608>:	ISETP.LT.U32.AND P0, PT, R0, 0x10, PT 
   0x0000000202156670 <+624>:	PLOP3.LUT P0, PT, P0, PT, PT, 0x8, 0x0 
   0x0000000202156680 <+640>:	BSSY B0, 0x6d0 
--Type <RET> for more, q to quit, c to continue without paging--q
Quit
(cuda-gdb) x/i $pc
=> 0x2021571c0 <_Z8test_braPlj+3520>:	EXIT 
(cuda-gdb) disas 
Dump of assembler code for function _Z8test_braPlj:
   0x0000000202156400 <+0>:	ISETP.NE.U32.AND P0, PT, RZ, UR2, PT 
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
   0x0000000202156550 <+336>:	MOV R18, c[0x0][0x118] 
   0x0000000202156560 <+352>:	MOV R19, c[0x0][0x11c] 
   0x0000000202156570 <+368>:	MOV R2, RZ 
   0x0000000202156580 <+384>:	LDC.64 R2, c[0x0][R2+0x160] 
   0x0000000202156590 <+400>:	MOV R16, R2 
   0x00000002021565a0 <+416>:	MOV R2, R3 
   0x00000002021565b0 <+432>:	MOV R16, R16 
   0x00000002021565c0 <+448>:	MOV R2, R2 
   0x00000002021565d0 <+464>:	MOV R0, 0x8 
   0x00000002021565e0 <+480>:	LDC R0, c[0x0][R0+0x160] 
   0x00000002021565f0 <+496>:	MOV R0, R0 
   0x0000000202156600 <+512>:	MOV R0, R0 
   0x0000000202156610 <+528>:	MOV R16, R16 
   0x0000000202156620 <+544>:	MOV R2, R2 
   0x0000000202156630 <+560>:	MOV R17, R0 
   0x0000000202156640 <+576>:	S2R R0, SR_TID.X 
   0x0000000202156650 <+592>:	MOV R0, R0 
   0x0000000202156660 <+608>:	ISETP.LT.U32.AND P0, PT, R0, 0x10, PT 
   0x0000000202156670 <+624>:	PLOP3.LUT P0, PT, P0, PT, PT, 0x8, 0x0 
   0x0000000202156680 <+640>:	BSSY B0, 0x6d0 
--Type <RET> for more, q to quit, c to continue without paging--c
   0x0000000202156690 <+656>:	@P0 BRA 0x6c0 
   0x00000002021566a0 <+672>:	BRA 0x2b0 
   0x00000002021566b0 <+688>:	S2R R6, SR_TID.Y 
   0x00000002021566c0 <+704>:	MOV R6, R6 
   0x00000002021566d0 <+720>:	S2R R0, SR_TID.X 
   0x00000002021566e0 <+736>:	MOV R0, R0 
   0x00000002021566f0 <+752>:	MOV R0, R0 
   0x0000000202156700 <+768>:	MOV R7, R0 
   0x0000000202156710 <+784>:	MOV R8, RZ 
   0x0000000202156720 <+800>:	MOV R4, 0x0 
   0x0000000202156730 <+816>:	MOV R5, 0x0 
   0x0000000202156740 <+832>:	MOV R4, R4 
   0x0000000202156750 <+848>:	MOV R5, R5 
   0x0000000202156760 <+864>:	MOV R3, R4 
   0x0000000202156770 <+880>:	MOV R0, R5 
   0x0000000202156780 <+896>:	MOV R3, R3 
   0x0000000202156790 <+912>:	MOV R0, R0 
   0x00000002021567a0 <+928>:	SHF.L.U64.HI R5, R7, 0x2, R8 
   0x00000002021567b0 <+944>:	SHF.L.U32 R4, R7, 0x2, RZ 
   0x00000002021567c0 <+960>:	IADD3 R4, P0, R3, R4, RZ 
   0x00000002021567d0 <+976>:	IADD3.X R5, R0, R5, RZ, P0, !PT 
   0x00000002021567e0 <+992>:	MOV R4, R4 
   0x00000002021567f0 <+1008>:	MOV R5, R5 
   0x0000000202156800 <+1024>:	MOV R4, R4 
   0x0000000202156810 <+1040>:	MOV R5, R5 
   0x0000000202156820 <+1056>:	R2UR UR4, R18 
   0x0000000202156830 <+1072>:	R2UR UR5, R19 
   0x0000000202156840 <+1088>:	ST.E [R4.64], R6 
   0x0000000202156850 <+1104>:	S2R R6, SR_TID.Z 
   0x0000000202156860 <+1120>:	MOV R6, R6 
   0x0000000202156870 <+1136>:	S2R R4, SR_TID.X 
   0x0000000202156880 <+1152>:	MOV R4, R4 
   0x0000000202156890 <+1168>:	IADD3 R4, R4, 0x10, RZ 
   0x00000002021568a0 <+1184>:	MOV R4, R4 
   0x00000002021568b0 <+1200>:	MOV R4, R4 
   0x00000002021568c0 <+1216>:	MOV R5, RZ 
   0x00000002021568d0 <+1232>:	SHF.L.U64.HI R5, R4, 0x2, R5 
   0x00000002021568e0 <+1248>:	SHF.L.U32 R4, R4, 0x2, RZ 
   0x00000002021568f0 <+1264>:	IADD3 R4, P0, R3, R4, RZ 
   0x0000000202156900 <+1280>:	IADD3.X R5, R0, R5, RZ, P0, !PT 
   0x0000000202156910 <+1296>:	MOV R4, R4 
   0x0000000202156920 <+1312>:	MOV R5, R5 
   0x0000000202156930 <+1328>:	MOV R4, R4 
   0x0000000202156940 <+1344>:	MOV R5, R5 
   0x0000000202156950 <+1360>:	R2UR UR4, R18 
   0x0000000202156960 <+1376>:	R2UR UR5, R19 
   0x0000000202156970 <+1392>:	ST.E [R4.64], R6 
   0x0000000202156980 <+1408>:	S2R R6, SR_TID.X 
   0x0000000202156990 <+1424>:	MOV R6, R6 
   0x00000002021569a0 <+1440>:	S2R R4, SR_TID.X 
   0x00000002021569b0 <+1456>:	MOV R4, R4 
   0x00000002021569c0 <+1472>:	IADD3 R4, R4, 0x20, RZ 
   0x00000002021569d0 <+1488>:	MOV R4, R4 
   0x00000002021569e0 <+1504>:	MOV R4, R4 
   0x00000002021569f0 <+1520>:	MOV R5, RZ 
   0x0000000202156a00 <+1536>:	SHF.L.U64.HI R5, R4, 0x2, R5 
   0x0000000202156a10 <+1552>:	SHF.L.U32 R4, R4, 0x2, RZ 
   0x0000000202156a20 <+1568>:	IADD3 R4, P0, R3, R4, RZ 
   0x0000000202156a30 <+1584>:	IADD3.X R5, R0, R5, RZ, P0, !PT 
   0x0000000202156a40 <+1600>:	MOV R4, R4 
   0x0000000202156a50 <+1616>:	MOV R5, R5 
   0x0000000202156a60 <+1632>:	MOV R4, R4 
   0x0000000202156a70 <+1648>:	MOV R5, R5 
   0x0000000202156a80 <+1664>:	R2UR UR4, R18 
   0x0000000202156a90 <+1680>:	R2UR UR5, R19 
   0x0000000202156aa0 <+1696>:	ST.E [R4.64], R6 
   0x0000000202156ab0 <+1712>:	BRA 0x6c0 
   0x0000000202156ac0 <+1728>:	BSYNC B0 
   0x0000000202156ad0 <+1744>:	S2R R0, SR_TID.X 
   0x0000000202156ae0 <+1760>:	MOV R0, R0 
   0x0000000202156af0 <+1776>:	ISETP.LT.U32.AND P0, PT, R0, 0x20, PT 
   0x0000000202156b00 <+1792>:	PLOP3.LUT P0, PT, P0, PT, PT, 0x8, 0x0 
   0x0000000202156b10 <+1808>:	@P0 BRA 0x9d0 
   0x0000000202156b20 <+1824>:	BRA 0x730 
   0x0000000202156b30 <+1840>:	BRA.CONV ~URZ, 0x790 
   0x0000000202156b40 <+1856>:	MOV R4, 0x20 
   0x0000000202156b50 <+1872>:	MOV R20, 0x0 
   0x0000000202156b60 <+1888>:	MOV R21, 0x0 
   0x0000000202156b70 <+1904>:	CALL.ABS.NOINC 0x0 
   0x0000000202156b80 <+1920>:	BRA 0x7a0 
   0x0000000202156b90 <+1936>:	BAR.SYNC 0x0, 0x20 
   0x0000000202156ba0 <+1952>:	S2R R0, SR_TID.X 
   0x0000000202156bb0 <+1968>:	MOV R0, R0 
   0x0000000202156bc0 <+1984>:	S2R R2, SR_TID.X 
   0x0000000202156bd0 <+2000>:	MOV R2, R2 
   0x0000000202156be0 <+2016>:	MOV R2, R2 
   0x0000000202156bf0 <+2032>:	MOV R6, R2 
   0x0000000202156c00 <+2048>:	MOV R7, RZ 
   0x0000000202156c10 <+2064>:	MOV R2, 0x0 
   0x0000000202156c20 <+2080>:	MOV R2, R2 
   0x0000000202156c30 <+2096>:	MOV R2, R2 
   0x0000000202156c40 <+2112>:	MOV R2, R2 
   0x0000000202156c50 <+2128>:	MOV R3, RZ 
   0x0000000202156c60 <+2144>:	MOV R4, c[0x0][0x18] 
   0x0000000202156c70 <+2160>:	MOV R5, c[0x0][0x1c] 
   0x0000000202156c80 <+2176>:	IADD3 R4, P0, R2, R4, RZ 
   0x0000000202156c90 <+2192>:	IADD3.X R5, R3, R5, RZ, P0, !PT 
   0x0000000202156ca0 <+2208>:	SHF.L.U64.HI R3, R6, 0x2, R7 
   0x0000000202156cb0 <+2224>:	SHF.L.U32 R2, R6, 0x2, RZ 
   0x0000000202156cc0 <+2240>:	IADD3 R2, P0, R4, R2, RZ 
   0x0000000202156cd0 <+2256>:	IADD3.X R3, R5, R3, RZ, P0, !PT 
   0x0000000202156ce0 <+2272>:	MOV R2, R2 
   0x0000000202156cf0 <+2288>:	MOV R3, R3 
   0x0000000202156d00 <+2304>:	MOV R2, R2 
   0x0000000202156d10 <+2320>:	MOV R3, R3 
   0x0000000202156d20 <+2336>:	R2UR UR4, R18 
   0x0000000202156d30 <+2352>:	R2UR UR5, R19 
   0x0000000202156d40 <+2368>:	ST.E [R2.64], R0 
   0x0000000202156d50 <+2384>:	BRA.CONV ~URZ, 0x9b0 
   0x0000000202156d60 <+2400>:	MOV R4, 0x20 
   0x0000000202156d70 <+2416>:	MOV R20, 0x0 
   0x0000000202156d80 <+2432>:	MOV R21, 0x0 
   0x0000000202156d90 <+2448>:	CALL.ABS.NOINC 0x0 
   0x0000000202156da0 <+2464>:	BRA 0x9c0 
   0x0000000202156db0 <+2480>:	BAR.ARV 0x1, 0x20 
   0x0000000202156dc0 <+2496>:	BRA 0xda0 
   0x0000000202156dd0 <+2512>:	BRA.CONV ~URZ, 0xa30 
   0x0000000202156de0 <+2528>:	MOV R4, 0x20 
   0x0000000202156df0 <+2544>:	MOV R20, 0x0 
   0x0000000202156e00 <+2560>:	MOV R21, 0x0 
   0x0000000202156e10 <+2576>:	CALL.ABS.NOINC 0x0 
   0x0000000202156e20 <+2592>:	BRA 0xa40 
   0x0000000202156e30 <+2608>:	BAR.ARV 0x0, 0x20 
   0x0000000202156e40 <+2624>:	BRA.CONV ~URZ, 0xaa0 
   0x0000000202156e50 <+2640>:	MOV R4, 0x20 
   0x0000000202156e60 <+2656>:	MOV R20, 0x0 
   0x0000000202156e70 <+2672>:	MOV R21, 0x0 
   0x0000000202156e80 <+2688>:	CALL.ABS.NOINC 0x0 
   0x0000000202156e90 <+2704>:	BRA 0xab0 
   0x0000000202156ea0 <+2720>:	BAR.SYNC 0x1, 0x20 
   0x0000000202156eb0 <+2736>:	S2R R0, SR_TID.X 
   0x0000000202156ec0 <+2752>:	MOV R0, R0 
   0x0000000202156ed0 <+2768>:	IADD3 R0, R0, -0x20, RZ 
   0x0000000202156ee0 <+2784>:	MOV R0, R0 
   0x0000000202156ef0 <+2800>:	MOV R6, R0 
   0x0000000202156f00 <+2816>:	MOV R7, RZ 
   0x0000000202156f10 <+2832>:	MOV R0, 0x0 
   0x0000000202156f20 <+2848>:	MOV R0, R0 
   0x0000000202156f30 <+2864>:	MOV R0, R0 
   0x0000000202156f40 <+2880>:	MOV R4, R0 
   0x0000000202156f50 <+2896>:	MOV R5, RZ 
   0x0000000202156f60 <+2912>:	MOV R0, c[0x0][0x18] 
   0x0000000202156f70 <+2928>:	MOV R3, c[0x0][0x1c] 
   0x0000000202156f80 <+2944>:	IADD3 R0, P0, R4, R0, RZ 
   0x0000000202156f90 <+2960>:	IADD3.X R3, R5, R3, RZ, P0, !PT 
   0x0000000202156fa0 <+2976>:	SHF.L.U64.HI R5, R6, 0x2, R7 
   0x0000000202156fb0 <+2992>:	SHF.L.U32 R4, R6, 0x2, RZ 
   0x0000000202156fc0 <+3008>:	IADD3 R4, P0, R0, R4, RZ 
   0x0000000202156fd0 <+3024>:	IADD3.X R5, R3, R5, RZ, P0, !PT 
   0x0000000202156fe0 <+3040>:	MOV R4, R4 
   0x0000000202156ff0 <+3056>:	MOV R5, R5 
   0x0000000202157000 <+3072>:	MOV R4, R4 
   0x0000000202157010 <+3088>:	MOV R5, R5 
   0x0000000202157020 <+3104>:	R2UR UR4, R18 
   0x0000000202157030 <+3120>:	R2UR UR5, R19 
   0x0000000202157040 <+3136>:	LD.E R4, [R4.64] 
   0x0000000202157050 <+3152>:	MOV R4, R4 
   0x0000000202157060 <+3168>:	MOV R4, R4 
   0x0000000202157070 <+3184>:	MOV R5, RZ 
   0x0000000202157080 <+3200>:	S2R R0, SR_TID.X 
   0x0000000202157090 <+3216>:	MOV R0, R0 
   0x00000002021570a0 <+3232>:	IADD3 R0, R0, -0x20, RZ 
   0x00000002021570b0 <+3248>:	MOV R0, R0 
   0x00000002021570c0 <+3264>:	MOV R0, R0 
   0x00000002021570d0 <+3280>:	MOV R3, RZ 
   0x00000002021570e0 <+3296>:	SHF.L.U64.HI R3, R0, 0x3, R3 
   0x00000002021570f0 <+3312>:	SHF.L.U32 R0, R0, 0x3, RZ 
   0x0000000202157100 <+3328>:	IADD3 R16, P0, R16, R0, RZ 
   0x0000000202157110 <+3344>:	IADD3.X R3, R2, R3, RZ, P0, !PT 
   0x0000000202157120 <+3360>:	MOV R2, R16 
   0x0000000202157130 <+3376>:	MOV R3, R3 
   0x0000000202157140 <+3392>:	MOV R2, R2 
   0x0000000202157150 <+3408>:	MOV R3, R3 
   0x0000000202157160 <+3424>:	R2UR UR4, R18 
   0x0000000202157170 <+3440>:	R2UR UR5, R19 
   0x0000000202157180 <+3456>:	ST.E.64 [R2.64], R4 
   0x0000000202157190 <+3472>:	BRA 0xda0 
   0x00000002021571a0 <+3488>:	MEMBAR.SC.VC 
   0x00000002021571b0 <+3504>:	ERRBAR 
=> 0x00000002021571c0 <+3520>:	EXIT 
   0x00000002021571d0 <+3536>:	MEMBAR.SC.VC 
   0x00000002021571e0 <+3552>:	ERRBAR 
   0x00000002021571f0 <+3568>:	EXIT 
   0x0000000202157200 <+3584>:	BRA 0xe00
   0x0000000202157210 <+3600>:	NOP
   0x0000000202157220 <+3616>:	NOP
   0x0000000202157230 <+3632>:	NOP
   0x0000000202157240 <+3648>:	NOP
   0x0000000202157250 <+3664>:	NOP
   0x0000000202157260 <+3680>:	NOP
   0x0000000202157270 <+3696>:	NOP
   0x0000000202157280 <+3712>:	NOP
   0x0000000202157290 <+3728>:	NOP
   0x00000002021572a0 <+3744>:	NOP
   0x00000002021572b0 <+3760>:	NOP
   0x00000002021572c0 <+3776>:	NOP
   0x00000002021572d0 <+3792>:	NOP
   0x00000002021572e0 <+3808>:	NOP
   0x00000002021572f0 <+3824>:	NOP
End of assembler dump.
(cuda-gdb) so 
source command requires file name of file to source.
(cuda-gdb) si 
[Switching to Thread 0xfffff7ff2840 (LWP 81571)]
0x0000fffff7ec1b4c in ioctl () from /lib/aarch64-linux-gnu/libc.so.6
(cuda-gdb) 
```

And terminate. 

## Conclusion 2 
In single stepping mode, warp-level barrier is not respected... 





# Now try to use cuda-gdb to kill the BSYNC... 

```
jetson@yahboom:~/workspace/experiment/branch/braconv$ cuda-gdb ./braconv_syncthreads87.out 
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
Reading symbols from ./braconv_syncthreads87.out...
(cuda-gdb) break test_bra(long*, unsigned int) 
Breakpoint 1 at 0x9f28: file /home/jetson/workspace/experiment/branch/braconv/braconv_syncthreads.cu, line 18.
(cuda-gdb) run 
Starting program: /home/jetson/workspace/experiment/branch/braconv/braconv_syncthreads87.out 
[Thread debugging using libthread_db enabled]
Using host libthread_db library "/lib/aarch64-linux-gnu/libthread_db.so.1".
[New Thread 0xfffff47dc840 (LWP 140371)]
[Detaching after fork from child process 140372]
[New Thread 0xfffff3edb840 (LWP 140378)]
blocks  per grid  = 1
threads per block = 64
[Switching focus to CUDA kernel 0, grid 1, block (0,0,0), thread (0,0,0), device 0, sm 0, warp 0, lane 0]

CUDA thread hit Breakpoint 1.1, test_bra<<<(1,1,1),(64,1,1)>>> (out=0x2050e0000, count=64) at braconv_syncthreads.cu:20
20	    if (threadIdx.x < 16) {
(cuda-gdb) disas 
Dump of assembler code for function _Z8test_braPlj:
   0x0000000202156400 <+0>:	ISETP.NE.U32.AND P0, PT, RZ, UR2, PT 
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
   0x0000000202156550 <+336>:	MOV R18, c[0x0][0x118] 
   0x0000000202156560 <+352>:	MOV R19, c[0x0][0x11c] 
   0x0000000202156570 <+368>:	MOV R2, RZ 
   0x0000000202156580 <+384>:	LDC.64 R2, c[0x0][R2+0x160] 
   0x0000000202156590 <+400>:	MOV R16, R2 
   0x00000002021565a0 <+416>:	MOV R2, R3 
   0x00000002021565b0 <+432>:	MOV R16, R16 
   0x00000002021565c0 <+448>:	MOV R2, R2 
   0x00000002021565d0 <+464>:	MOV R0, 0x8 
   0x00000002021565e0 <+480>:	LDC R0, c[0x0][R0+0x160] 
   0x00000002021565f0 <+496>:	MOV R0, R0 
   0x0000000202156600 <+512>:	MOV R0, R0 
   0x0000000202156610 <+528>:	MOV R16, R16 
   0x0000000202156620 <+544>:	MOV R2, R2 
   0x0000000202156630 <+560>:	MOV R17, R0 
=> 0x0000000202156640 <+576>:	S2R R0, SR_TID.X 
   0x0000000202156650 <+592>:	MOV R0, R0 
   0x0000000202156660 <+608>:	ISETP.LT.U32.AND P0, PT, R0, 0x10, PT 
   0x0000000202156670 <+624>:	PLOP3.LUT P0, PT, P0, PT, PT, 0x8, 0x0 
   0x0000000202156680 <+640>:	BSSY B0, 0x6d0 
   0x0000000202156690 <+656>:	@P0 BRA 0x6c0 
   0x00000002021566a0 <+672>:	BRA 0x2b0 
   0x00000002021566b0 <+688>:	S2R R6, SR_TID.Y 
   0x00000002021566c0 <+704>:	MOV R6, R6 
   0x00000002021566d0 <+720>:	S2R R0, SR_TID.X 
   0x00000002021566e0 <+736>:	MOV R0, R0 
   0x00000002021566f0 <+752>:	MOV R0, R0 
   0x0000000202156700 <+768>:	MOV R7, R0 
   0x0000000202156710 <+784>:	MOV R8, RZ 
   0x0000000202156720 <+800>:	MOV R4, 0x0 
   0x0000000202156730 <+816>:	MOV R5, 0x0 
   0x0000000202156740 <+832>:	MOV R4, R4 
   0x0000000202156750 <+848>:	MOV R5, R5 
   0x0000000202156760 <+864>:	MOV R3, R4 
   0x0000000202156770 <+880>:	MOV R0, R5 
   0x0000000202156780 <+896>:	MOV R3, R3 
   0x0000000202156790 <+912>:	MOV R0, R0 
   0x00000002021567a0 <+928>:	SHF.L.U64.HI R5, R7, 0x2, R8 
   0x00000002021567b0 <+944>:	SHF.L.U32 R4, R7, 0x2, RZ 
   0x00000002021567c0 <+960>:	IADD3 R4, P0, R3, R4, RZ 
   0x00000002021567d0 <+976>:	IADD3.X R5, R0, R5, RZ, P0, !PT 
   0x00000002021567e0 <+992>:	MOV R4, R4 
   0x00000002021567f0 <+1008>:	MOV R5, R5 
   0x0000000202156800 <+1024>:	MOV R4, R4 
   0x0000000202156810 <+1040>:	MOV R5, R5 
   0x0000000202156820 <+1056>:	R2UR UR4, R18 
   0x0000000202156830 <+1072>:	R2UR UR5, R19 
   0x0000000202156840 <+1088>:	ST.E [R4.64], R6 
   0x0000000202156850 <+1104>:	S2R R6, SR_TID.Z 
   0x0000000202156860 <+1120>:	MOV R6, R6 
   0x0000000202156870 <+1136>:	S2R R4, SR_TID.X 
   0x0000000202156880 <+1152>:	MOV R4, R4 
   0x0000000202156890 <+1168>:	IADD3 R4, R4, 0x10, RZ 
   0x00000002021568a0 <+1184>:	MOV R4, R4 
   0x00000002021568b0 <+1200>:	MOV R4, R4 
   0x00000002021568c0 <+1216>:	MOV R5, RZ 
   0x00000002021568d0 <+1232>:	SHF.L.U64.HI R5, R4, 0x2, R5 
   0x00000002021568e0 <+1248>:	SHF.L.U32 R4, R4, 0x2, RZ 
   0x00000002021568f0 <+1264>:	IADD3 R4, P0, R3, R4, RZ 
   0x0000000202156900 <+1280>:	IADD3.X R5, R0, R5, RZ, P0, !PT 
   0x0000000202156910 <+1296>:	MOV R4, R4 
   0x0000000202156920 <+1312>:	MOV R5, R5 
   0x0000000202156930 <+1328>:	MOV R4, R4 
   0x0000000202156940 <+1344>:	MOV R5, R5 
   0x0000000202156950 <+1360>:	R2UR UR4, R18 
   0x0000000202156960 <+1376>:	R2UR UR5, R19 
   0x0000000202156970 <+1392>:	ST.E [R4.64], R6 
   0x0000000202156980 <+1408>:	S2R R6, SR_TID.X 
--Type <RET> for more, q to quit, c to continue without paging--c
   0x0000000202156990 <+1424>:	MOV R6, R6 
   0x00000002021569a0 <+1440>:	S2R R4, SR_TID.X 
   0x00000002021569b0 <+1456>:	MOV R4, R4 
   0x00000002021569c0 <+1472>:	IADD3 R4, R4, 0x20, RZ 
   0x00000002021569d0 <+1488>:	MOV R4, R4 
   0x00000002021569e0 <+1504>:	MOV R4, R4 
   0x00000002021569f0 <+1520>:	MOV R5, RZ 
   0x0000000202156a00 <+1536>:	SHF.L.U64.HI R5, R4, 0x2, R5 
   0x0000000202156a10 <+1552>:	SHF.L.U32 R4, R4, 0x2, RZ 
   0x0000000202156a20 <+1568>:	IADD3 R4, P0, R3, R4, RZ 
   0x0000000202156a30 <+1584>:	IADD3.X R5, R0, R5, RZ, P0, !PT 
   0x0000000202156a40 <+1600>:	MOV R4, R4 
   0x0000000202156a50 <+1616>:	MOV R5, R5 
   0x0000000202156a60 <+1632>:	MOV R4, R4 
   0x0000000202156a70 <+1648>:	MOV R5, R5 
   0x0000000202156a80 <+1664>:	R2UR UR4, R18 
   0x0000000202156a90 <+1680>:	R2UR UR5, R19 
   0x0000000202156aa0 <+1696>:	ST.E [R4.64], R6 
   0x0000000202156ab0 <+1712>:	BRA 0x6c0 
   0x0000000202156ac0 <+1728>:	BSYNC B0 
   0x0000000202156ad0 <+1744>:	S2R R0, SR_TID.X 
   0x0000000202156ae0 <+1760>:	MOV R0, R0 
   0x0000000202156af0 <+1776>:	ISETP.LT.U32.AND P0, PT, R0, 0x20, PT 
   0x0000000202156b00 <+1792>:	PLOP3.LUT P0, PT, P0, PT, PT, 0x8, 0x0 
   0x0000000202156b10 <+1808>:	@P0 BRA 0x9d0 
   0x0000000202156b20 <+1824>:	BRA 0x730 
   0x0000000202156b30 <+1840>:	BRA.CONV ~URZ, 0x790 
   0x0000000202156b40 <+1856>:	MOV R4, 0x20 
   0x0000000202156b50 <+1872>:	MOV R20, 0x0 
   0x0000000202156b60 <+1888>:	MOV R21, 0x0 
   0x0000000202156b70 <+1904>:	CALL.ABS.NOINC 0x0 
   0x0000000202156b80 <+1920>:	BRA 0x7a0 
   0x0000000202156b90 <+1936>:	BAR.SYNC 0x0, 0x20 
   0x0000000202156ba0 <+1952>:	S2R R0, SR_TID.X 
   0x0000000202156bb0 <+1968>:	MOV R0, R0 
   0x0000000202156bc0 <+1984>:	S2R R2, SR_TID.X 
   0x0000000202156bd0 <+2000>:	MOV R2, R2 
   0x0000000202156be0 <+2016>:	MOV R2, R2 
   0x0000000202156bf0 <+2032>:	MOV R6, R2 
   0x0000000202156c00 <+2048>:	MOV R7, RZ 
   0x0000000202156c10 <+2064>:	MOV R2, 0x0 
   0x0000000202156c20 <+2080>:	MOV R2, R2 
   0x0000000202156c30 <+2096>:	MOV R2, R2 
   0x0000000202156c40 <+2112>:	MOV R2, R2 
   0x0000000202156c50 <+2128>:	MOV R3, RZ 
   0x0000000202156c60 <+2144>:	MOV R4, c[0x0][0x18] 
   0x0000000202156c70 <+2160>:	MOV R5, c[0x0][0x1c] 
   0x0000000202156c80 <+2176>:	IADD3 R4, P0, R2, R4, RZ 
   0x0000000202156c90 <+2192>:	IADD3.X R5, R3, R5, RZ, P0, !PT 
   0x0000000202156ca0 <+2208>:	SHF.L.U64.HI R3, R6, 0x2, R7 
   0x0000000202156cb0 <+2224>:	SHF.L.U32 R2, R6, 0x2, RZ 
   0x0000000202156cc0 <+2240>:	IADD3 R2, P0, R4, R2, RZ 
   0x0000000202156cd0 <+2256>:	IADD3.X R3, R5, R3, RZ, P0, !PT 
   0x0000000202156ce0 <+2272>:	MOV R2, R2 
   0x0000000202156cf0 <+2288>:	MOV R3, R3 
   0x0000000202156d00 <+2304>:	MOV R2, R2 
   0x0000000202156d10 <+2320>:	MOV R3, R3 
   0x0000000202156d20 <+2336>:	R2UR UR4, R18 
   0x0000000202156d30 <+2352>:	R2UR UR5, R19 
   0x0000000202156d40 <+2368>:	ST.E [R2.64], R0 
   0x0000000202156d50 <+2384>:	BRA.CONV ~URZ, 0x9b0 
   0x0000000202156d60 <+2400>:	MOV R4, 0x20 
   0x0000000202156d70 <+2416>:	MOV R20, 0x0 
   0x0000000202156d80 <+2432>:	MOV R21, 0x0 
   0x0000000202156d90 <+2448>:	CALL.ABS.NOINC 0x0 
   0x0000000202156da0 <+2464>:	BRA 0x9c0 
   0x0000000202156db0 <+2480>:	BAR.ARV 0x1, 0x20 
   0x0000000202156dc0 <+2496>:	BRA 0xda0 
   0x0000000202156dd0 <+2512>:	BRA.CONV ~URZ, 0xa30 
   0x0000000202156de0 <+2528>:	MOV R4, 0x20 
   0x0000000202156df0 <+2544>:	MOV R20, 0x0 
   0x0000000202156e00 <+2560>:	MOV R21, 0x0 
   0x0000000202156e10 <+2576>:	CALL.ABS.NOINC 0x0 
   0x0000000202156e20 <+2592>:	BRA 0xa40 
   0x0000000202156e30 <+2608>:	BAR.ARV 0x0, 0x20 
   0x0000000202156e40 <+2624>:	BRA.CONV ~URZ, 0xaa0 
   0x0000000202156e50 <+2640>:	MOV R4, 0x20 
   0x0000000202156e60 <+2656>:	MOV R20, 0x0 
   0x0000000202156e70 <+2672>:	MOV R21, 0x0 
   0x0000000202156e80 <+2688>:	CALL.ABS.NOINC 0x0 
   0x0000000202156e90 <+2704>:	BRA 0xab0 
   0x0000000202156ea0 <+2720>:	BAR.SYNC 0x1, 0x20 
   0x0000000202156eb0 <+2736>:	S2R R0, SR_TID.X 
   0x0000000202156ec0 <+2752>:	MOV R0, R0 
   0x0000000202156ed0 <+2768>:	IADD3 R0, R0, -0x20, RZ 
   0x0000000202156ee0 <+2784>:	MOV R0, R0 
   0x0000000202156ef0 <+2800>:	MOV R6, R0 
   0x0000000202156f00 <+2816>:	MOV R7, RZ 
   0x0000000202156f10 <+2832>:	MOV R0, 0x0 
   0x0000000202156f20 <+2848>:	MOV R0, R0 
   0x0000000202156f30 <+2864>:	MOV R0, R0 
   0x0000000202156f40 <+2880>:	MOV R4, R0 
   0x0000000202156f50 <+2896>:	MOV R5, RZ 
   0x0000000202156f60 <+2912>:	MOV R0, c[0x0][0x18] 
   0x0000000202156f70 <+2928>:	MOV R3, c[0x0][0x1c] 
   0x0000000202156f80 <+2944>:	IADD3 R0, P0, R4, R0, RZ 
   0x0000000202156f90 <+2960>:	IADD3.X R3, R5, R3, RZ, P0, !PT 
   0x0000000202156fa0 <+2976>:	SHF.L.U64.HI R5, R6, 0x2, R7 
   0x0000000202156fb0 <+2992>:	SHF.L.U32 R4, R6, 0x2, RZ 
   0x0000000202156fc0 <+3008>:	IADD3 R4, P0, R0, R4, RZ 
   0x0000000202156fd0 <+3024>:	IADD3.X R5, R3, R5, RZ, P0, !PT 
   0x0000000202156fe0 <+3040>:	MOV R4, R4 
   0x0000000202156ff0 <+3056>:	MOV R5, R5 
   0x0000000202157000 <+3072>:	MOV R4, R4 
   0x0000000202157010 <+3088>:	MOV R5, R5 
   0x0000000202157020 <+3104>:	R2UR UR4, R18 
   0x0000000202157030 <+3120>:	R2UR UR5, R19 
   0x0000000202157040 <+3136>:	LD.E R4, [R4.64] 
   0x0000000202157050 <+3152>:	MOV R4, R4 
   0x0000000202157060 <+3168>:	MOV R4, R4 
   0x0000000202157070 <+3184>:	MOV R5, RZ 
   0x0000000202157080 <+3200>:	S2R R0, SR_TID.X 
   0x0000000202157090 <+3216>:	MOV R0, R0 
   0x00000002021570a0 <+3232>:	IADD3 R0, R0, -0x20, RZ 
   0x00000002021570b0 <+3248>:	MOV R0, R0 
   0x00000002021570c0 <+3264>:	MOV R0, R0 
   0x00000002021570d0 <+3280>:	MOV R3, RZ 
   0x00000002021570e0 <+3296>:	SHF.L.U64.HI R3, R0, 0x3, R3 
   0x00000002021570f0 <+3312>:	SHF.L.U32 R0, R0, 0x3, RZ 
   0x0000000202157100 <+3328>:	IADD3 R16, P0, R16, R0, RZ 
   0x0000000202157110 <+3344>:	IADD3.X R3, R2, R3, RZ, P0, !PT 
   0x0000000202157120 <+3360>:	MOV R2, R16 
   0x0000000202157130 <+3376>:	MOV R3, R3 
   0x0000000202157140 <+3392>:	MOV R2, R2 
   0x0000000202157150 <+3408>:	MOV R3, R3 
   0x0000000202157160 <+3424>:	R2UR UR4, R18 
   0x0000000202157170 <+3440>:	R2UR UR5, R19 
   0x0000000202157180 <+3456>:	ST.E.64 [R2.64], R4 
   0x0000000202157190 <+3472>:	BRA 0xda0 
   0x00000002021571a0 <+3488>:	MEMBAR.SC.VC 
   0x00000002021571b0 <+3504>:	ERRBAR 
   0x00000002021571c0 <+3520>:	EXIT 
   0x00000002021571d0 <+3536>:	MEMBAR.SC.VC 
   0x00000002021571e0 <+3552>:	ERRBAR 
   0x00000002021571f0 <+3568>:	EXIT 
   0x0000000202157200 <+3584>:	BRA 0xe00
   0x0000000202157210 <+3600>:	NOP
   0x0000000202157220 <+3616>:	NOP
   0x0000000202157230 <+3632>:	NOP
   0x0000000202157240 <+3648>:	NOP
   0x0000000202157250 <+3664>:	NOP
   0x0000000202157260 <+3680>:	NOP
   0x0000000202157270 <+3696>:	NOP
   0x0000000202157280 <+3712>:	NOP
   0x0000000202157290 <+3728>:	NOP
   0x00000002021572a0 <+3744>:	NOP
   0x00000002021572b0 <+3760>:	NOP
   0x00000002021572c0 <+3776>:	NOP
   0x00000002021572d0 <+3792>:	NOP
   0x00000002021572e0 <+3808>:	NOP
   0x00000002021572f0 <+3824>:	NOP
End of assembler dump.
(cuda-gdb) 
```

We modify the BSYNC at    0x0000000202156ac0 <+1728>:	BSYNC B0 
to a NOP:
```
(cuda-gdb) set *((char*)0x0000000202156ac0) = 0x18
(cuda-gdb) set *((char*)0x0000000202156ac1) = 0x79
(cuda-gdb) set *((char*)0x0000000202156ac2) = 0x00
(cuda-gdb) set *((char*)0x0000000202156ac3) = 0x00
(cuda-gdb) set *((char*)0x0000000202156ac4) = 0x00
(cuda-gdb) set *((char*)0x0000000202156ac5) = 0x00
(cuda-gdb) set *((char*)0x0000000202156ac6) = 0x00
(cuda-gdb) set *((char*)0x0000000202156ac7) = 0x00
(cuda-gdb) set *((char*)0x0000000202156ac8) = 0x00
(cuda-gdb) set *((char*)0x0000000202156ac9) = 0x00
(cuda-gdb) set *((char*)0x0000000202156aca) = 0x00
(cuda-gdb) set *((char*)0x0000000202156acb) = 0x00
(cuda-gdb) set *((char*)0x0000000202156acc) = 0x00
(cuda-gdb) set *((char*)0x0000000202156acd) = 0xc0
(cuda-gdb) set *((char*)0x0000000202156ace) = 0x0f 
(cuda-gdb) set *((char*)0x0000000202156acf) = 0x00
(cuda-gdb) 
```

Notice that the disasm result is cached, so don't take it as granted: 
```
(cuda-gdb) x/i 0x0000000202156ac0 
   0x202156ac0 <_Z8test_braPlj+1728>:	BSYNC B0 
(cuda-gdb) x/x 0x0000000202156ac0 
0x202156ac0 <_Z8test_braPlj+1728>:	0x00007918
(cuda-gdb) x/x 0x0000000202156ac8 
0x202156ac8 <_Z8test_braPlj+1736>:	0x00000000
(cuda-gdb) x/x 0x0000000202156ac4 
0x202156ac4 <_Z8test_braPlj+1732>:	0x00000000
(cuda-gdb) x/x 0x0000000202156ac8 
0x202156ac8 <_Z8test_braPlj+1736>:	0x00000000
(cuda-gdb) x/x 0x0000000202156acc 
0x202156acc <_Z8test_braPlj+1740>:	0x000fc000
(cuda-gdb) 
```

If we compare this to the NOP at    0x0000000202157210 <+3600>:	NOP
```
(cuda-gdb) x/x 0x0000000202157210
0x202157210 <_Z8test_braPlj+3600>:	0x00007918
(cuda-gdb) x/x 0x0000000202157214
0x202157214 <_Z8test_braPlj+3604>:	0x00000000
(cuda-gdb) x/x 0x0000000202157218
0x202157218 <_Z8test_braPlj+3608>:	0x00000000
(cuda-gdb) x/x 0x000000020215721c
0x20215721c <_Z8test_braPlj+3612>:	0x000fc000
(cuda-gdb) 
```

Perfect! 

Let's GOOOOO!!! 

```
(cuda-gdb) disas 
Dump of assembler code for function _Z8test_braPlj:
   0x0000000202156400 <+0>:	ISETP.NE.U32.AND P0, PT, RZ, UR2, PT 
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
   0x0000000202156550 <+336>:	MOV R18, c[0x0][0x118] 
   0x0000000202156560 <+352>:	MOV R19, c[0x0][0x11c] 
   0x0000000202156570 <+368>:	MOV R2, RZ 
   0x0000000202156580 <+384>:	LDC.64 R2, c[0x0][R2+0x160] 
   0x0000000202156590 <+400>:	MOV R16, R2 
   0x00000002021565a0 <+416>:	MOV R2, R3 
   0x00000002021565b0 <+432>:	MOV R16, R16 
   0x00000002021565c0 <+448>:	MOV R2, R2 
   0x00000002021565d0 <+464>:	MOV R0, 0x8 
   0x00000002021565e0 <+480>:	LDC R0, c[0x0][R0+0x160] 
   0x00000002021565f0 <+496>:	MOV R0, R0 
   0x0000000202156600 <+512>:	MOV R0, R0 
   0x0000000202156610 <+528>:	MOV R16, R16 
   0x0000000202156620 <+544>:	MOV R2, R2 
   0x0000000202156630 <+560>:	MOV R17, R0 
=> 0x0000000202156640 <+576>:	S2R R0, SR_TID.X 
   0x0000000202156650 <+592>:	MOV R0, R0 
   0x0000000202156660 <+608>:	ISETP.LT.U32.AND P0, PT, R0, 0x10, PT 
   0x0000000202156670 <+624>:	PLOP3.LUT P0, PT, P0, PT, PT, 0x8, 0x0 
   0x0000000202156680 <+640>:	BSSY B0, 0x6d0 
   0x0000000202156690 <+656>:	@P0 BRA 0x6c0 
   0x00000002021566a0 <+672>:	BRA 0x2b0 
   0x00000002021566b0 <+688>:	S2R R6, SR_TID.Y 
   0x00000002021566c0 <+704>:	MOV R6, R6 
   0x00000002021566d0 <+720>:	S2R R0, SR_TID.X 
   0x00000002021566e0 <+736>:	MOV R0, R0 
   0x00000002021566f0 <+752>:	MOV R0, R0 
   0x0000000202156700 <+768>:	MOV R7, R0 
   0x0000000202156710 <+784>:	MOV R8, RZ 
   0x0000000202156720 <+800>:	MOV R4, 0x0 
   0x0000000202156730 <+816>:	MOV R5, 0x0 
   0x0000000202156740 <+832>:	MOV R4, R4 
   0x0000000202156750 <+848>:	MOV R5, R5 
   0x0000000202156760 <+864>:	MOV R3, R4 
   0x0000000202156770 <+880>:	MOV R0, R5 
   0x0000000202156780 <+896>:	MOV R3, R3 
   0x0000000202156790 <+912>:	MOV R0, R0 
   0x00000002021567a0 <+928>:	SHF.L.U64.HI R5, R7, 0x2, R8 
   0x00000002021567b0 <+944>:	SHF.L.U32 R4, R7, 0x2, RZ 
   0x00000002021567c0 <+960>:	IADD3 R4, P0, R3, R4, RZ 
   0x00000002021567d0 <+976>:	IADD3.X R5, R0, R5, RZ, P0, !PT 
   0x00000002021567e0 <+992>:	MOV R4, R4 
   0x00000002021567f0 <+1008>:	MOV R5, R5 
   0x0000000202156800 <+1024>:	MOV R4, R4 
   0x0000000202156810 <+1040>:	MOV R5, R5 
   0x0000000202156820 <+1056>:	R2UR UR4, R18 
   0x0000000202156830 <+1072>:	R2UR UR5, R19 
   0x0000000202156840 <+1088>:	ST.E [R4.64], R6 
   0x0000000202156850 <+1104>:	S2R R6, SR_TID.Z 
   0x0000000202156860 <+1120>:	MOV R6, R6 
   0x0000000202156870 <+1136>:	S2R R4, SR_TID.X 
   0x0000000202156880 <+1152>:	MOV R4, R4 
   0x0000000202156890 <+1168>:	IADD3 R4, R4, 0x10, RZ 
   0x00000002021568a0 <+1184>:	MOV R4, R4 
   0x00000002021568b0 <+1200>:	MOV R4, R4 
   0x00000002021568c0 <+1216>:	MOV R5, RZ 
   0x00000002021568d0 <+1232>:	SHF.L.U64.HI R5, R4, 0x2, R5 
   0x00000002021568e0 <+1248>:	SHF.L.U32 R4, R4, 0x2, RZ 
   0x00000002021568f0 <+1264>:	IADD3 R4, P0, R3, R4, RZ 
   0x0000000202156900 <+1280>:	IADD3.X R5, R0, R5, RZ, P0, !PT 
   0x0000000202156910 <+1296>:	MOV R4, R4 
   0x0000000202156920 <+1312>:	MOV R5, R5 
   0x0000000202156930 <+1328>:	MOV R4, R4 
   0x0000000202156940 <+1344>:	MOV R5, R5 
   0x0000000202156950 <+1360>:	R2UR UR4, R18 
   0x0000000202156960 <+1376>:	R2UR UR5, R19 
   0x0000000202156970 <+1392>:	ST.E [R4.64], R6 
   0x0000000202156980 <+1408>:	S2R R6, SR_TID.X 
--Type <RET> for more, q to quit, c to continue without paging--c
   0x0000000202156990 <+1424>:	MOV R6, R6 
   0x00000002021569a0 <+1440>:	S2R R4, SR_TID.X 
   0x00000002021569b0 <+1456>:	MOV R4, R4 
   0x00000002021569c0 <+1472>:	IADD3 R4, R4, 0x20, RZ 
   0x00000002021569d0 <+1488>:	MOV R4, R4 
   0x00000002021569e0 <+1504>:	MOV R4, R4 
   0x00000002021569f0 <+1520>:	MOV R5, RZ 
   0x0000000202156a00 <+1536>:	SHF.L.U64.HI R5, R4, 0x2, R5 
   0x0000000202156a10 <+1552>:	SHF.L.U32 R4, R4, 0x2, RZ 
   0x0000000202156a20 <+1568>:	IADD3 R4, P0, R3, R4, RZ 
   0x0000000202156a30 <+1584>:	IADD3.X R5, R0, R5, RZ, P0, !PT 
   0x0000000202156a40 <+1600>:	MOV R4, R4 
   0x0000000202156a50 <+1616>:	MOV R5, R5 
   0x0000000202156a60 <+1632>:	MOV R4, R4 
   0x0000000202156a70 <+1648>:	MOV R5, R5 
   0x0000000202156a80 <+1664>:	R2UR UR4, R18 
   0x0000000202156a90 <+1680>:	R2UR UR5, R19 
   0x0000000202156aa0 <+1696>:	ST.E [R4.64], R6 
   0x0000000202156ab0 <+1712>:	BRA 0x6c0 
   0x0000000202156ac0 <+1728>:	BSYNC B0 
   0x0000000202156ad0 <+1744>:	S2R R0, SR_TID.X 
   0x0000000202156ae0 <+1760>:	MOV R0, R0 
   0x0000000202156af0 <+1776>:	ISETP.LT.U32.AND P0, PT, R0, 0x20, PT 
   0x0000000202156b00 <+1792>:	PLOP3.LUT P0, PT, P0, PT, PT, 0x8, 0x0 
   0x0000000202156b10 <+1808>:	@P0 BRA 0x9d0 
   0x0000000202156b20 <+1824>:	BRA 0x730 
   0x0000000202156b30 <+1840>:	BRA.CONV ~URZ, 0x790 
   0x0000000202156b40 <+1856>:	MOV R4, 0x20 
   0x0000000202156b50 <+1872>:	MOV R20, 0x0 
   0x0000000202156b60 <+1888>:	MOV R21, 0x0 
   0x0000000202156b70 <+1904>:	CALL.ABS.NOINC 0x0 
   0x0000000202156b80 <+1920>:	BRA 0x7a0 
   0x0000000202156b90 <+1936>:	BAR.SYNC 0x0, 0x20 
   0x0000000202156ba0 <+1952>:	S2R R0, SR_TID.X 
   0x0000000202156bb0 <+1968>:	MOV R0, R0 
   0x0000000202156bc0 <+1984>:	S2R R2, SR_TID.X 
   0x0000000202156bd0 <+2000>:	MOV R2, R2 
   0x0000000202156be0 <+2016>:	MOV R2, R2 
   0x0000000202156bf0 <+2032>:	MOV R6, R2 
   0x0000000202156c00 <+2048>:	MOV R7, RZ 
   0x0000000202156c10 <+2064>:	MOV R2, 0x0 
   0x0000000202156c20 <+2080>:	MOV R2, R2 
   0x0000000202156c30 <+2096>:	MOV R2, R2 
   0x0000000202156c40 <+2112>:	MOV R2, R2 
   0x0000000202156c50 <+2128>:	MOV R3, RZ 
   0x0000000202156c60 <+2144>:	MOV R4, c[0x0][0x18] 
   0x0000000202156c70 <+2160>:	MOV R5, c[0x0][0x1c] 
   0x0000000202156c80 <+2176>:	IADD3 R4, P0, R2, R4, RZ 
   0x0000000202156c90 <+2192>:	IADD3.X R5, R3, R5, RZ, P0, !PT 
   0x0000000202156ca0 <+2208>:	SHF.L.U64.HI R3, R6, 0x2, R7 
   0x0000000202156cb0 <+2224>:	SHF.L.U32 R2, R6, 0x2, RZ 
   0x0000000202156cc0 <+2240>:	IADD3 R2, P0, R4, R2, RZ 
   0x0000000202156cd0 <+2256>:	IADD3.X R3, R5, R3, RZ, P0, !PT 
   0x0000000202156ce0 <+2272>:	MOV R2, R2 
   0x0000000202156cf0 <+2288>:	MOV R3, R3 
   0x0000000202156d00 <+2304>:	MOV R2, R2 
   0x0000000202156d10 <+2320>:	MOV R3, R3 
   0x0000000202156d20 <+2336>:	R2UR UR4, R18 
   0x0000000202156d30 <+2352>:	R2UR UR5, R19 
   0x0000000202156d40 <+2368>:	ST.E [R2.64], R0 
   0x0000000202156d50 <+2384>:	BRA.CONV ~URZ, 0x9b0 
   0x0000000202156d60 <+2400>:	MOV R4, 0x20 
   0x0000000202156d70 <+2416>:	MOV R20, 0x0 
   0x0000000202156d80 <+2432>:	MOV R21, 0x0 
   0x0000000202156d90 <+2448>:	CALL.ABS.NOINC 0x0 
   0x0000000202156da0 <+2464>:	BRA 0x9c0 
   0x0000000202156db0 <+2480>:	BAR.ARV 0x1, 0x20 
   0x0000000202156dc0 <+2496>:	BRA 0xda0 
   0x0000000202156dd0 <+2512>:	BRA.CONV ~URZ, 0xa30 
   0x0000000202156de0 <+2528>:	MOV R4, 0x20 
   0x0000000202156df0 <+2544>:	MOV R20, 0x0 
   0x0000000202156e00 <+2560>:	MOV R21, 0x0 
   0x0000000202156e10 <+2576>:	CALL.ABS.NOINC 0x0 
   0x0000000202156e20 <+2592>:	BRA 0xa40 
   0x0000000202156e30 <+2608>:	BAR.ARV 0x0, 0x20 
   0x0000000202156e40 <+2624>:	BRA.CONV ~URZ, 0xaa0 
   0x0000000202156e50 <+2640>:	MOV R4, 0x20 
   0x0000000202156e60 <+2656>:	MOV R20, 0x0 
   0x0000000202156e70 <+2672>:	MOV R21, 0x0 
   0x0000000202156e80 <+2688>:	CALL.ABS.NOINC 0x0 
   0x0000000202156e90 <+2704>:	BRA 0xab0 
   0x0000000202156ea0 <+2720>:	BAR.SYNC 0x1, 0x20 
   0x0000000202156eb0 <+2736>:	S2R R0, SR_TID.X 
   0x0000000202156ec0 <+2752>:	MOV R0, R0 
   0x0000000202156ed0 <+2768>:	IADD3 R0, R0, -0x20, RZ 
   0x0000000202156ee0 <+2784>:	MOV R0, R0 
   0x0000000202156ef0 <+2800>:	MOV R6, R0 
   0x0000000202156f00 <+2816>:	MOV R7, RZ 
   0x0000000202156f10 <+2832>:	MOV R0, 0x0 
   0x0000000202156f20 <+2848>:	MOV R0, R0 
   0x0000000202156f30 <+2864>:	MOV R0, R0 
   0x0000000202156f40 <+2880>:	MOV R4, R0 
   0x0000000202156f50 <+2896>:	MOV R5, RZ 
   0x0000000202156f60 <+2912>:	MOV R0, c[0x0][0x18] 
   0x0000000202156f70 <+2928>:	MOV R3, c[0x0][0x1c] 
   0x0000000202156f80 <+2944>:	IADD3 R0, P0, R4, R0, RZ 
   0x0000000202156f90 <+2960>:	IADD3.X R3, R5, R3, RZ, P0, !PT 
   0x0000000202156fa0 <+2976>:	SHF.L.U64.HI R5, R6, 0x2, R7 
   0x0000000202156fb0 <+2992>:	SHF.L.U32 R4, R6, 0x2, RZ 
   0x0000000202156fc0 <+3008>:	IADD3 R4, P0, R0, R4, RZ 
   0x0000000202156fd0 <+3024>:	IADD3.X R5, R3, R5, RZ, P0, !PT 
   0x0000000202156fe0 <+3040>:	MOV R4, R4 
   0x0000000202156ff0 <+3056>:	MOV R5, R5 
   0x0000000202157000 <+3072>:	MOV R4, R4 
   0x0000000202157010 <+3088>:	MOV R5, R5 
   0x0000000202157020 <+3104>:	R2UR UR4, R18 
   0x0000000202157030 <+3120>:	R2UR UR5, R19 
   0x0000000202157040 <+3136>:	LD.E R4, [R4.64] 
   0x0000000202157050 <+3152>:	MOV R4, R4 
   0x0000000202157060 <+3168>:	MOV R4, R4 
   0x0000000202157070 <+3184>:	MOV R5, RZ 
   0x0000000202157080 <+3200>:	S2R R0, SR_TID.X 
   0x0000000202157090 <+3216>:	MOV R0, R0 
   0x00000002021570a0 <+3232>:	IADD3 R0, R0, -0x20, RZ 
   0x00000002021570b0 <+3248>:	MOV R0, R0 
   0x00000002021570c0 <+3264>:	MOV R0, R0 
   0x00000002021570d0 <+3280>:	MOV R3, RZ 
   0x00000002021570e0 <+3296>:	SHF.L.U64.HI R3, R0, 0x3, R3 
   0x00000002021570f0 <+3312>:	SHF.L.U32 R0, R0, 0x3, RZ 
   0x0000000202157100 <+3328>:	IADD3 R16, P0, R16, R0, RZ 
   0x0000000202157110 <+3344>:	IADD3.X R3, R2, R3, RZ, P0, !PT 
   0x0000000202157120 <+3360>:	MOV R2, R16 
   0x0000000202157130 <+3376>:	MOV R3, R3 
   0x0000000202157140 <+3392>:	MOV R2, R2 
   0x0000000202157150 <+3408>:	MOV R3, R3 
   0x0000000202157160 <+3424>:	R2UR UR4, R18 
   0x0000000202157170 <+3440>:	R2UR UR5, R19 
   0x0000000202157180 <+3456>:	ST.E.64 [R2.64], R4 
   0x0000000202157190 <+3472>:	BRA 0xda0 
   0x00000002021571a0 <+3488>:	MEMBAR.SC.VC 
   0x00000002021571b0 <+3504>:	ERRBAR 
   0x00000002021571c0 <+3520>:	EXIT 
   0x00000002021571d0 <+3536>:	MEMBAR.SC.VC 
   0x00000002021571e0 <+3552>:	ERRBAR 
   0x00000002021571f0 <+3568>:	EXIT 
   0x0000000202157200 <+3584>:	BRA 0xe00
   0x0000000202157210 <+3600>:	NOP
   0x0000000202157220 <+3616>:	NOP
   0x0000000202157230 <+3632>:	NOP
   0x0000000202157240 <+3648>:	NOP
   0x0000000202157250 <+3664>:	NOP
   0x0000000202157260 <+3680>:	NOP
   0x0000000202157270 <+3696>:	NOP
   0x0000000202157280 <+3712>:	NOP
   0x0000000202157290 <+3728>:	NOP
   0x00000002021572a0 <+3744>:	NOP
   0x00000002021572b0 <+3760>:	NOP
   0x00000002021572c0 <+3776>:	NOP
   0x00000002021572d0 <+3792>:	NOP
   0x00000002021572e0 <+3808>:	NOP
   0x00000002021572f0 <+3824>:	NOP
End of assembler dump.
(cuda-gdb) 
```

Now in divergence: 
```
(cuda-gdb) info cuda warps 
  Wp Active Lanes Mask Divergent Lanes Mask          Active PC Kernel BlockIdx First Active ThreadIdx 
Device 0 SM 0
*  0        0xffffffff           0x00000000 0x0000000202156640      0  (0,0,0)                (0,0,0) 
   1        0xffffffff           0x00000000 0x0000000202156640      0  (0,0,0)               (32,0,0) 
(cuda-gdb) info cuda lanes 
  Ln  State         PC         ThreadIdx Exception 
Device 0 SM 0 Warp 0
*  0 active 0x0000000202156640   (0,0,0)    None   
   1 active 0x0000000202156640   (1,0,0)    None   
   2 active 0x0000000202156640   (2,0,0)    None   
   3 active 0x0000000202156640   (3,0,0)    None   
   4 active 0x0000000202156640   (4,0,0)    None   
   5 active 0x0000000202156640   (5,0,0)    None   
   6 active 0x0000000202156640   (6,0,0)    None   
   7 active 0x0000000202156640   (7,0,0)    None   
   8 active 0x0000000202156640   (8,0,0)    None   
   9 active 0x0000000202156640   (9,0,0)    None   
  10 active 0x0000000202156640  (10,0,0)    None   
  11 active 0x0000000202156640  (11,0,0)    None   
  12 active 0x0000000202156640  (12,0,0)    None   
  13 active 0x0000000202156640  (13,0,0)    None   
  14 active 0x0000000202156640  (14,0,0)    None   
  15 active 0x0000000202156640  (15,0,0)    None   
  16 active 0x0000000202156640  (16,0,0)    None   
  17 active 0x0000000202156640  (17,0,0)    None   
  18 active 0x0000000202156640  (18,0,0)    None   
  19 active 0x0000000202156640  (19,0,0)    None   
  20 active 0x0000000202156640  (20,0,0)    None   
  21 active 0x0000000202156640  (21,0,0)    None   
  22 active 0x0000000202156640  (22,0,0)    None   
  23 active 0x0000000202156640  (23,0,0)    None   
  24 active 0x0000000202156640  (24,0,0)    None   
  25 active 0x0000000202156640  (25,0,0)    None   
  26 active 0x0000000202156640  (26,0,0)    None   
  27 active 0x0000000202156640  (27,0,0)    None   
  28 active 0x0000000202156640  (28,0,0)    None   
  29 active 0x0000000202156640  (29,0,0)    None   
  30 active 0x0000000202156640  (30,0,0)    None   
  31 active 0x0000000202156640  (31,0,0)    None   
(cuda-gdb) si                    
0x0000000202156650	20	    if (threadIdx.x < 16) {
(cuda-gdb) si
0x0000000202156660	20	    if (threadIdx.x < 16) {
(cuda-gdb) x/i $pc
=> 0x202156660 <_Z8test_braPlj+608>:	ISETP.LT.U32.AND P0, PT, R0, 0x10, PT 
(cuda-gdb) si
0x0000000202156670	20	    if (threadIdx.x < 16) {
(cuda-gdb) si
0x0000000202156680	20	    if (threadIdx.x < 16) {
(cuda-gdb) x/i $pc
=> 0x202156680 <_Z8test_braPlj+640>:	BSSY B0, 0x6d0 
(cuda-gdb) si 
0x0000000202156690	20	    if (threadIdx.x < 16) {
(cuda-gdb) x/i $pc
=> 0x202156690 <_Z8test_braPlj+656>:	@P0 BRA 0x6c0 
(cuda-gdb) info cuda lanes 
  Ln  State         PC         ThreadIdx Exception 
Device 0 SM 0 Warp 0
*  0 active 0x0000000202156690   (0,0,0)    None   
   1 active 0x0000000202156690   (1,0,0)    None   
   2 active 0x0000000202156690   (2,0,0)    None   
   3 active 0x0000000202156690   (3,0,0)    None   
   4 active 0x0000000202156690   (4,0,0)    None   
   5 active 0x0000000202156690   (5,0,0)    None   
   6 active 0x0000000202156690   (6,0,0)    None   
   7 active 0x0000000202156690   (7,0,0)    None   
   8 active 0x0000000202156690   (8,0,0)    None   
   9 active 0x0000000202156690   (9,0,0)    None   
  10 active 0x0000000202156690  (10,0,0)    None   
  11 active 0x0000000202156690  (11,0,0)    None   
  12 active 0x0000000202156690  (12,0,0)    None   
  13 active 0x0000000202156690  (13,0,0)    None   
  14 active 0x0000000202156690  (14,0,0)    None   
  15 active 0x0000000202156690  (15,0,0)    None   
  16 active 0x0000000202156690  (16,0,0)    None   
  17 active 0x0000000202156690  (17,0,0)    None   
  18 active 0x0000000202156690  (18,0,0)    None   
  19 active 0x0000000202156690  (19,0,0)    None   
  20 active 0x0000000202156690  (20,0,0)    None   
  21 active 0x0000000202156690  (21,0,0)    None   
  22 active 0x0000000202156690  (22,0,0)    None   
  23 active 0x0000000202156690  (23,0,0)    None   
  24 active 0x0000000202156690  (24,0,0)    None   
  25 active 0x0000000202156690  (25,0,0)    None   
  26 active 0x0000000202156690  (26,0,0)    None   
  27 active 0x0000000202156690  (27,0,0)    None   
  28 active 0x0000000202156690  (28,0,0)    None   
  29 active 0x0000000202156690  (29,0,0)    None   
  30 active 0x0000000202156690  (30,0,0)    None   
  31 active 0x0000000202156690  (31,0,0)    None   
(cuda-gdb) si
0x00000002021566a0	20	    if (threadIdx.x < 16) {
(cuda-gdb) info cuda lanes 
  Ln   State           PC         ThreadIdx Exception 
Device 0 SM 0 Warp 0
*  0   active  0x00000002021566a0   (0,0,0)    None   
   1   active  0x00000002021566a0   (1,0,0)    None   
   2   active  0x00000002021566a0   (2,0,0)    None   
   3   active  0x00000002021566a0   (3,0,0)    None   
   4   active  0x00000002021566a0   (4,0,0)    None   
   5   active  0x00000002021566a0   (5,0,0)    None   
   6   active  0x00000002021566a0   (6,0,0)    None   
   7   active  0x00000002021566a0   (7,0,0)    None   
   8   active  0x00000002021566a0   (8,0,0)    None   
   9   active  0x00000002021566a0   (9,0,0)    None   
  10   active  0x00000002021566a0  (10,0,0)    None   
  11   active  0x00000002021566a0  (11,0,0)    None   
  12   active  0x00000002021566a0  (12,0,0)    None   
  13   active  0x00000002021566a0  (13,0,0)    None   
  14   active  0x00000002021566a0  (14,0,0)    None   
  15   active  0x00000002021566a0  (15,0,0)    None   
  16 divergent 0x0000000202156ac0  (16,0,0)    None   
  17 divergent 0x0000000202156ac0  (17,0,0)    None   
  18 divergent 0x0000000202156ac0  (18,0,0)    None   
  19 divergent 0x0000000202156ac0  (19,0,0)    None   
  20 divergent 0x0000000202156ac0  (20,0,0)    None   
  21 divergent 0x0000000202156ac0  (21,0,0)    None   
  22 divergent 0x0000000202156ac0  (22,0,0)    None   
  23 divergent 0x0000000202156ac0  (23,0,0)    None   
  24 divergent 0x0000000202156ac0  (24,0,0)    None   
  25 divergent 0x0000000202156ac0  (25,0,0)    None   
  26 divergent 0x0000000202156ac0  (26,0,0)    None   
  27 divergent 0x0000000202156ac0  (27,0,0)    None   
  28 divergent 0x0000000202156ac0  (28,0,0)    None   
  29 divergent 0x0000000202156ac0  (29,0,0)    None   
  30 divergent 0x0000000202156ac0  (30,0,0)    None   
  31 divergent 0x0000000202156ac0  (31,0,0)    None   
(cuda-gdb) 
```

Now we switch to thread 16 and see what happens... 

```
(cuda-gdb) x/i $pc
=> 0x2021566a0 <_Z8test_braPlj+672>:	BRA 0x2b0 
(cuda-gdb) cuda device sm warp lane block thread  
block (0,0,0), thread (0,0,0), device 0, sm 0, warp 0, lane 0
(cuda-gdb) cuda device 0 sm 0 warp 0 lane 16      
[Switching focus to CUDA kernel 0, grid 1, block (0,0,0), thread (16,0,0), device 0, sm 0, warp 0, lane 16]
0x0000000202156ac0	23	        mem[threadIdx.x + 32] = threadIdx.x;
(cuda-gdb) x/i $pc
=> 0x202156ac0 <_Z8test_braPlj+1728>:	BSYNC B0 
(cuda-gdb) si 
[Current focus set to CUDA kernel 0, grid 1, block (0,0,0), thread (16,0,0), device 0, sm 0, warp 0, lane 16]
warning: Current CUDA focus is no longer active. Stepping divergent CUDA threads until current CUDA focus is active again.

/// it hangs......
```

Try to do a Ctrl-C on it: 
```
(cuda-gdb) si 
[Current focus set to CUDA kernel 0, grid 1, block (0,0,0), thread (16,0,0), device 0, sm 0, warp 0, lane 16]
warning: Current CUDA focus is no longer active. Stepping divergent CUDA threads until current CUDA focus is active again.


^C
Thread 1 "braconv_syncthr" received signal SIGINT, Interrupt.
0x0000000202156ac0 in test_bra<<<(1,1,1),(64,1,1)>>> (out=0x2050e0000, count=64) at braconv_syncthreads.cu:23
23	        mem[threadIdx.x + 32] = threadIdx.x;
(cuda-gdb) x/i $pc
=> 0x202156ac0 <_Z8test_braPlj+1728>:	BSYNC B0 
(cuda-gdb) info cuda warps 
  Wp Active Lanes Mask Divergent Lanes Mask          Active PC Kernel BlockIdx First Active ThreadIdx 
Device 0 SM 0
   0        0x0000ffff           0xffff0000 0x0000000202156ad0      0  (0,0,0)                (0,0,0) 
   1        0xffffffff           0x00000000 0x0000000202156640      0  (0,0,0)               (32,0,0) 
(cuda-gdb) info cuda lanes 
  Ln   State           PC         ThreadIdx Exception 
Device 0 SM 0 Warp 0
   0   active  0x0000000202156ad0   (0,0,0)    None   
   1   active  0x0000000202156ad0   (1,0,0)    None   
   2   active  0x0000000202156ad0   (2,0,0)    None   
   3   active  0x0000000202156ad0   (3,0,0)    None   
   4   active  0x0000000202156ad0   (4,0,0)    None   
   5   active  0x0000000202156ad0   (5,0,0)    None   
   6   active  0x0000000202156ad0   (6,0,0)    None   
   7   active  0x0000000202156ad0   (7,0,0)    None   
   8   active  0x0000000202156ad0   (8,0,0)    None   
   9   active  0x0000000202156ad0   (9,0,0)    None   
  10   active  0x0000000202156ad0  (10,0,0)    None   
  11   active  0x0000000202156ad0  (11,0,0)    None   
  12   active  0x0000000202156ad0  (12,0,0)    None   
  13   active  0x0000000202156ad0  (13,0,0)    None   
  14   active  0x0000000202156ad0  (14,0,0)    None   
  15   active  0x0000000202156ad0  (15,0,0)    None   
* 16 divergent 0x0000000202156ac0  (16,0,0)    None   
  17 divergent 0x0000000202156ac0  (17,0,0)    None   
  18 divergent 0x0000000202156ac0  (18,0,0)    None   
  19 divergent 0x0000000202156ac0  (19,0,0)    None   
  20 divergent 0x0000000202156ac0  (20,0,0)    None   
  21 divergent 0x0000000202156ac0  (21,0,0)    None   
  22 divergent 0x0000000202156ac0  (22,0,0)    None   
  23 divergent 0x0000000202156ac0  (23,0,0)    None   
  24 divergent 0x0000000202156ac0  (24,0,0)    None   
  25 divergent 0x0000000202156ac0  (25,0,0)    None   
  26 divergent 0x0000000202156ac0  (26,0,0)    None   
  27 divergent 0x0000000202156ac0  (27,0,0)    None   
  28 divergent 0x0000000202156ac0  (28,0,0)    None   
  29 divergent 0x0000000202156ac0  (29,0,0)    None   
  30 divergent 0x0000000202156ac0  (30,0,0)    None   
  31 divergent 0x0000000202156ac0  (31,0,0)    None   
(cuda-gdb) 
```

Try to si again, and it still hangs.......
```
* 16 divergent 0x0000000202156ac0  (16,0,0)    None   
  17 divergent 0x0000000202156ac0  (17,0,0)    None   
  18 divergent 0x0000000202156ac0  (18,0,0)    None   
  19 divergent 0x0000000202156ac0  (19,0,0)    None   
  20 divergent 0x0000000202156ac0  (20,0,0)    None   
  21 divergent 0x0000000202156ac0  (21,0,0)    None   
  22 divergent 0x0000000202156ac0  (22,0,0)    None   
  23 divergent 0x0000000202156ac0  (23,0,0)    None   
  24 divergent 0x0000000202156ac0  (24,0,0)    None   
  25 divergent 0x0000000202156ac0  (25,0,0)    None   
  26 divergent 0x0000000202156ac0  (26,0,0)    None   
  27 divergent 0x0000000202156ac0  (27,0,0)    None   
  28 divergent 0x0000000202156ac0  (28,0,0)    None   
  29 divergent 0x0000000202156ac0  (29,0,0)    None   
  30 divergent 0x0000000202156ac0  (30,0,0)    None   
  31 divergent 0x0000000202156ac0  (31,0,0)    None   
(cuda-gdb) si 
[Current focus set to CUDA kernel 0, grid 1, block (0,0,0), thread (16,0,0), device 0, sm 0, warp 0, lane 16]
warning: Current CUDA focus is no longer active. Stepping divergent CUDA threads until current CUDA focus is active again.
^C
Thread 1 "braconv_syncthr" received signal SIGINT, Interrupt.
0x0000000202156ac0 in test_bra<<<(1,1,1),(64,1,1)>>> (out=0x2050e0000, count=64) at braconv_syncthreads.cu:23
23	        mem[threadIdx.x + 32] = threadIdx.x;
(cuda-gdb) info cuda lanes 
  Ln   State           PC         ThreadIdx Exception 
Device 0 SM 0 Warp 0
   0   active  0x0000000202156ad0   (0,0,0)    None   
   1   active  0x0000000202156ad0   (1,0,0)    None   
   2   active  0x0000000202156ad0   (2,0,0)    None   
   3   active  0x0000000202156ad0   (3,0,0)    None   
   4   active  0x0000000202156ad0   (4,0,0)    None   
   5   active  0x0000000202156ad0   (5,0,0)    None   
   6   active  0x0000000202156ad0   (6,0,0)    None   
   7   active  0x0000000202156ad0   (7,0,0)    None   
   8   active  0x0000000202156ad0   (8,0,0)    None   
   9   active  0x0000000202156ad0   (9,0,0)    None   
  10   active  0x0000000202156ad0  (10,0,0)    None   
  11   active  0x0000000202156ad0  (11,0,0)    None   
  12   active  0x0000000202156ad0  (12,0,0)    None   
  13   active  0x0000000202156ad0  (13,0,0)    None   
  14   active  0x0000000202156ad0  (14,0,0)    None   
  15   active  0x0000000202156ad0  (15,0,0)    None   
* 16 divergent 0x0000000202156ac0  (16,0,0)    None   
  17 divergent 0x0000000202156ac0  (17,0,0)    None   
  18 divergent 0x0000000202156ac0  (18,0,0)    None   
  19 divergent 0x0000000202156ac0  (19,0,0)    None   
  20 divergent 0x0000000202156ac0  (20,0,0)    None   
  21 divergent 0x0000000202156ac0  (21,0,0)    None   
  22 divergent 0x0000000202156ac0  (22,0,0)    None   
  23 divergent 0x0000000202156ac0  (23,0,0)    None   
  24 divergent 0x0000000202156ac0  (24,0,0)    None   
  25 divergent 0x0000000202156ac0  (25,0,0)    None   
  26 divergent 0x0000000202156ac0  (26,0,0)    None   
  27 divergent 0x0000000202156ac0  (27,0,0)    None   
  28 divergent 0x0000000202156ac0  (28,0,0)    None   
  29 divergent 0x0000000202156ac0  (29,0,0)    None   
  30 divergent 0x0000000202156ac0  (30,0,0)    None   
  31 divergent 0x0000000202156ac0  (31,0,0)    None   
(cuda-gdb) 
```

Switch back to lane0, and everything works as normal: 
```
(cuda-gdb) cuda device 0 sm 0 warp 0 lane 0       
[Switching focus to CUDA kernel 0, grid 1, block (0,0,0), thread (0,0,0), device 0, sm 0, warp 0, lane 0]
25	    if (threadIdx.x < NN) {
(cuda-gdb) x/i $pc
=> 0x202156ad0 <_Z8test_braPlj+1744>:	S2R R0, SR_TID.X 
(cuda-gdb) si 
0x0000000202156ae0	25	    if (threadIdx.x < NN) {
(cuda-gdb) x/i $pc
=> 0x202156ae0 <_Z8test_braPlj+1760>:	MOV R0, R0 
(cuda-gdb) 
```

And if we switch back to lane16, it can now si as normal!!! 
```
(cuda-gdb) si 
0x0000000202156af0	25	    if (threadIdx.x < NN) {
(cuda-gdb) x/i $pc
=> 0x202156af0 <_Z8test_braPlj+1776>:	ISETP.LT.U32.AND P0, PT, R0, 0x20, PT 
(cuda-gdb) si     
0x0000000202156b00	25	    if (threadIdx.x < NN) {
(cuda-gdb) x/i $pc
=> 0x202156b00 <_Z8test_braPlj+1792>:	PLOP3.LUT P0, PT, P0, PT, PT, 0x8, 0x0 
(cuda-gdb) info cuda warps 
  Wp Active Lanes Mask Divergent Lanes Mask          Active PC Kernel BlockIdx First Active ThreadIdx 
Device 0 SM 0
*  0        0x0000ffff           0xffff0000 0x0000000202156b00      0  (0,0,0)                (0,0,0) 
   1        0xffffffff           0x00000000 0x0000000202156640      0  (0,0,0)               (32,0,0) 
(cuda-gdb) info cuda lanes 
  Ln   State           PC         ThreadIdx Exception 
Device 0 SM 0 Warp 0
*  0   active  0x0000000202156b00   (0,0,0)    None   
   1   active  0x0000000202156b00   (1,0,0)    None   
   2   active  0x0000000202156b00   (2,0,0)    None   
   3   active  0x0000000202156b00   (3,0,0)    None   
   4   active  0x0000000202156b00   (4,0,0)    None   
   5   active  0x0000000202156b00   (5,0,0)    None   
   6   active  0x0000000202156b00   (6,0,0)    None   
   7   active  0x0000000202156b00   (7,0,0)    None   
   8   active  0x0000000202156b00   (8,0,0)    None   
   9   active  0x0000000202156b00   (9,0,0)    None   
  10   active  0x0000000202156b00  (10,0,0)    None   
  11   active  0x0000000202156b00  (11,0,0)    None   
  12   active  0x0000000202156b00  (12,0,0)    None   
  13   active  0x0000000202156b00  (13,0,0)    None   
  14   active  0x0000000202156b00  (14,0,0)    None   
  15   active  0x0000000202156b00  (15,0,0)    None   
  16 divergent 0x0000000202156ac0  (16,0,0)    None   
  17 divergent 0x0000000202156ac0  (17,0,0)    None   
  18 divergent 0x0000000202156ac0  (18,0,0)    None   
  19 divergent 0x0000000202156ac0  (19,0,0)    None   
  20 divergent 0x0000000202156ac0  (20,0,0)    None   
  21 divergent 0x0000000202156ac0  (21,0,0)    None   
  22 divergent 0x0000000202156ac0  (22,0,0)    None   
  23 divergent 0x0000000202156ac0  (23,0,0)    None   
  24 divergent 0x0000000202156ac0  (24,0,0)    None   
  25 divergent 0x0000000202156ac0  (25,0,0)    None   
  26 divergent 0x0000000202156ac0  (26,0,0)    None   
  27 divergent 0x0000000202156ac0  (27,0,0)    None   
  28 divergent 0x0000000202156ac0  (28,0,0)    None   
  29 divergent 0x0000000202156ac0  (29,0,0)    None   
  30 divergent 0x0000000202156ac0  (30,0,0)    None   
  31 divergent 0x0000000202156ac0  (31,0,0)    None   
(cuda-gdb) cuda device 0 sm 0 warp 0 lane 16
[Switching focus to CUDA kernel 0, grid 1, block (0,0,0), thread (16,0,0), device 0, sm 0, warp 0, lane 16]
0x0000000202156ac0	23	        mem[threadIdx.x + 32] = threadIdx.x;
(cuda-gdb) si 
25	    if (threadIdx.x < NN) {
(cuda-gdb) info cuda lanes                  
  Ln   State           PC         ThreadIdx Exception 
Device 0 SM 0 Warp 0
   0 divergent 0x0000000202159e60   (0,0,0)    None   
   1 divergent 0x0000000202159e60   (1,0,0)    None   
   2 divergent 0x0000000202159e60   (2,0,0)    None   
   3 divergent 0x0000000202159e60   (3,0,0)    None   
   4 divergent 0x0000000202159e60   (4,0,0)    None   
   5 divergent 0x0000000202159e60   (5,0,0)    None   
   6 divergent 0x0000000202159e60   (6,0,0)    None   
   7 divergent 0x0000000202159e60   (7,0,0)    None   
   8 divergent 0x0000000202159e60   (8,0,0)    None   
   9 divergent 0x0000000202159e60   (9,0,0)    None   
  10 divergent 0x0000000202159e60  (10,0,0)    None   
  11 divergent 0x0000000202159e60  (11,0,0)    None   
  12 divergent 0x0000000202159e60  (12,0,0)    None   
  13 divergent 0x0000000202159e60  (13,0,0)    None   
  14 divergent 0x0000000202159e60  (14,0,0)    None   
  15 divergent 0x0000000202159e60  (15,0,0)    None   
* 16   active  0x0000000202156ad0  (16,0,0)    None   
  17   active  0x0000000202156ad0  (17,0,0)    None   
  18   active  0x0000000202156ad0  (18,0,0)    None   
  19   active  0x0000000202156ad0  (19,0,0)    None   
  20   active  0x0000000202156ad0  (20,0,0)    None   
  21   active  0x0000000202156ad0  (21,0,0)    None   
  22   active  0x0000000202156ad0  (22,0,0)    None   
  23   active  0x0000000202156ad0  (23,0,0)    None   
  24   active  0x0000000202156ad0  (24,0,0)    None   
  25   active  0x0000000202156ad0  (25,0,0)    None   
  26   active  0x0000000202156ad0  (26,0,0)    None   
  27   active  0x0000000202156ad0  (27,0,0)    None   
  28   active  0x0000000202156ad0  (28,0,0)    None   
  29   active  0x0000000202156ad0  (29,0,0)    None   
  30   active  0x0000000202156ad0  (30,0,0)    None   
  31   active  0x0000000202156ad0  (31,0,0)    None   
(cuda-gdb) 
```

Wait a minute!!! 
LOOK AT THE LANE INFO ABOVE!!!
Thread 0 to 15 are now DIVERGENT!!!!!!

```
(cuda-gdb) cuda device 0 sm 0 warp 0 lane 0 
[Switching focus to CUDA kernel 0, grid 1, block (0,0,0), thread (0,0,0), device 0, sm 0, warp 0, lane 0]
0x0000000202159e60 in __cuda_sm70_barrier_sync_0_count ()
(cuda-gdb) 
(cuda-gdb) cuda device 0 sm 0 warp 0 lane 0 
[Switching focus to CUDA kernel 0, grid 1, block (0,0,0), thread (0,0,0), device 0, sm 0, warp 0, lane 0]
0x0000000202159e60 in __cuda_sm70_barrier_sync_0_count ()
(cuda-gdb) bt
#0  0x0000000202159e60 in __cuda_sm70_barrier_sync_0_count ()
#1  0x0000000202156b80 in test_bra<<<(1,1,1),(64,1,1)>>> (out=0x2050e0000, count=64) at braconv_syncthreads.cu:26
(cuda-gdb) 
```

However: if we step back to lane16 and try one si, all lanes will jump to the same place:
```
(cuda-gdb) info cuda lanes                 
  Ln   State           PC         ThreadIdx Exception 
Device 0 SM 0 Warp 0
*  0 divergent 0x0000000202159e60   (0,0,0)    None   
   1 divergent 0x0000000202159e60   (1,0,0)    None   
   2 divergent 0x0000000202159e60   (2,0,0)    None   
   3 divergent 0x0000000202159e60   (3,0,0)    None   
   4 divergent 0x0000000202159e60   (4,0,0)    None   
   5 divergent 0x0000000202159e60   (5,0,0)    None   
   6 divergent 0x0000000202159e60   (6,0,0)    None   
   7 divergent 0x0000000202159e60   (7,0,0)    None   
   8 divergent 0x0000000202159e60   (8,0,0)    None   
   9 divergent 0x0000000202159e60   (9,0,0)    None   
  10 divergent 0x0000000202159e60  (10,0,0)    None   
  11 divergent 0x0000000202159e60  (11,0,0)    None   
  12 divergent 0x0000000202159e60  (12,0,0)    None   
  13 divergent 0x0000000202159e60  (13,0,0)    None   
  14 divergent 0x0000000202159e60  (14,0,0)    None   
  15 divergent 0x0000000202159e60  (15,0,0)    None   
  16   active  0x0000000202156ad0  (16,0,0)    None   
  17   active  0x0000000202156ad0  (17,0,0)    None   
  18   active  0x0000000202156ad0  (18,0,0)    None   
  19   active  0x0000000202156ad0  (19,0,0)    None   
  20   active  0x0000000202156ad0  (20,0,0)    None   
  21   active  0x0000000202156ad0  (21,0,0)    None   
  22   active  0x0000000202156ad0  (22,0,0)    None   
  23   active  0x0000000202156ad0  (23,0,0)    None   
  24   active  0x0000000202156ad0  (24,0,0)    None   
  25   active  0x0000000202156ad0  (25,0,0)    None   
  26   active  0x0000000202156ad0  (26,0,0)    None   
  27   active  0x0000000202156ad0  (27,0,0)    None   
  28   active  0x0000000202156ad0  (28,0,0)    None   
  29   active  0x0000000202156ad0  (29,0,0)    None   
  30   active  0x0000000202156ad0  (30,0,0)    None   
  31   active  0x0000000202156ad0  (31,0,0)    None   
(cuda-gdb) cuda device 0 sm 0 warp 0 lane 16
[Switching focus to CUDA kernel 0, grid 1, block (0,0,0), thread (16,0,0), device 0, sm 0, warp 0, lane 16]
25	    if (threadIdx.x < NN) {
(cuda-gdb) x/i $pc
=> 0x202156ad0 <_Z8test_braPlj+1744>:	S2R R0, SR_TID.X 
(cuda-gdb) si 
0x0000000202159e70 in __cuda_sm70_barrier_sync_0_count ()
(cuda-gdb) info cuda lanes                  
  Ln  State         PC         ThreadIdx Exception 
Device 0 SM 0 Warp 0
   0 active 0x0000000202159e70   (0,0,0)    None   
   1 active 0x0000000202159e70   (1,0,0)    None   
   2 active 0x0000000202159e70   (2,0,0)    None   
   3 active 0x0000000202159e70   (3,0,0)    None   
   4 active 0x0000000202159e70   (4,0,0)    None   
   5 active 0x0000000202159e70   (5,0,0)    None   
   6 active 0x0000000202159e70   (6,0,0)    None   
   7 active 0x0000000202159e70   (7,0,0)    None   
   8 active 0x0000000202159e70   (8,0,0)    None   
   9 active 0x0000000202159e70   (9,0,0)    None   
  10 active 0x0000000202159e70  (10,0,0)    None   
  11 active 0x0000000202159e70  (11,0,0)    None   
  12 active 0x0000000202159e70  (12,0,0)    None   
  13 active 0x0000000202159e70  (13,0,0)    None   
  14 active 0x0000000202159e70  (14,0,0)    None   
  15 active 0x0000000202159e70  (15,0,0)    None   
* 16 active 0x0000000202159e70  (16,0,0)    None   
  17 active 0x0000000202159e70  (17,0,0)    None   
  18 active 0x0000000202159e70  (18,0,0)    None   
  19 active 0x0000000202159e70  (19,0,0)    None   
  20 active 0x0000000202159e70  (20,0,0)    None   
  21 active 0x0000000202159e70  (21,0,0)    None   
  22 active 0x0000000202159e70  (22,0,0)    None   
  23 active 0x0000000202159e70  (23,0,0)    None   
  24 active 0x0000000202159e70  (24,0,0)    None   
  25 active 0x0000000202159e70  (25,0,0)    None   
  26 active 0x0000000202159e70  (26,0,0)    None   
  27 active 0x0000000202159e70  (27,0,0)    None   
  28 active 0x0000000202159e70  (28,0,0)    None   
  29 active 0x0000000202159e70  (29,0,0)    None   
  30 active 0x0000000202159e70  (30,0,0)    None   
  31 active 0x0000000202159e70  (31,0,0)    None   
(cuda-gdb) disas 
Dump of assembler code for function __cuda_sm70_barrier_sync_0_count:
   0x0000000202159d00 <+0>:	ISETP.NE.U32.AND P0, PT, RZ, UR2, PT 
   0x0000000202159d10 <+16>:	@P0 BRA 0x140 
   0x0000000202159d20 <+32>:	BMOV.32 B0, 0xffffffff 
   0x0000000202159d30 <+48>:	BMOV.32.CLEAR B1, B0 
   0x0000000202159d40 <+64>:	BMOV.32.CLEAR B2, B1 
   0x0000000202159d50 <+80>:	BMOV.32.CLEAR B3, B2 
   0x0000000202159d60 <+96>:	BMOV.32.CLEAR B4, B3 
   0x0000000202159d70 <+112>:	BMOV.32.CLEAR B5, B4 
   0x0000000202159d80 <+128>:	BMOV.32.CLEAR B6, B5 
   0x0000000202159d90 <+144>:	BMOV.32.CLEAR B7, B6 
   0x0000000202159da0 <+160>:	BMOV.32.CLEAR B8, B7 
   0x0000000202159db0 <+176>:	BMOV.32.CLEAR B9, B8 
   0x0000000202159dc0 <+192>:	BMOV.32.CLEAR B10, B9 
   0x0000000202159dd0 <+208>:	BMOV.32.CLEAR B11, B10 
   0x0000000202159de0 <+224>:	BMOV.32.CLEAR B12, B11 
   0x0000000202159df0 <+240>:	BMOV.32.CLEAR B13, B12 
   0x0000000202159e00 <+256>:	BMOV.32.CLEAR B14, B13 
   0x0000000202159e10 <+272>:	BMOV.32.CLEAR B15, B14 
   0x0000000202159e20 <+288>:	BMOV.32 B15, 0x0 
   0x0000000202159e30 <+304>:	UMOV UR2, 0x1 
   0x0000000202159e40 <+320>:	MOV R4, R4 
   0x0000000202159e50 <+336>:	MOV R4, R4 
   0x0000000202159e60 <+352>:	WARPSYNC 0xffffffff 
=> 0x0000000202159e70 <+368>:	BAR.SYNC 0x0, R4 
   0x0000000202159e80 <+384>:	MOV R4, RZ 
   0x0000000202159e90 <+400>:	MOV R4, R4 
   0x0000000202159ea0 <+416>:	RET.ABS.NODEC R20 0x0 
   0x0000000202159eb0 <+432>:	BRA 0x1b0
   0x0000000202159ec0 <+448>:	NOP
   0x0000000202159ed0 <+464>:	NOP
   0x0000000202159ee0 <+480>:	NOP
   0x0000000202159ef0 <+496>:	NOP
   0x0000000202159f00 <+512>:	NOP
   0x0000000202159f10 <+528>:	NOP
   0x0000000202159f20 <+544>:	NOP
   0x0000000202159f30 <+560>:	NOP
   0x0000000202159f40 <+576>:	NOP
   0x0000000202159f50 <+592>:	NOP
   0x0000000202159f60 <+608>:	NOP
   0x0000000202159f70 <+624>:	NOP
End of assembler dump.
(cuda-gdb) 
```

Now it jumps into the synchronization function: 
```
(cuda-gdb) cuda device 0 sm 0 warp 0 lane 0 
[Switching focus to CUDA kernel 0, grid 1, block (0,0,0), thread (0,0,0), device 0, sm 0, warp 0, lane 0]
0x0000000202159e70 in __cuda_sm70_barrier_sync_0_count ()
(cuda-gdb) bt 
#0  0x0000000202159e70 in __cuda_sm70_barrier_sync_0_count ()
#1  0x0000000202156b80 in test_bra<<<(1,1,1),(64,1,1)>>> (out=0x2050e0000, count=64) at braconv_syncthreads.cu:26
(cuda-gdb) frame 1
#1  0x0000000202156b80 in test_bra<<<(1,1,1),(64,1,1)>>> (out=0x2050e0000, count=64) at braconv_syncthreads.cu:26
26	        asm("barrier.cta.sync 0, 32;\n\t");
(cuda-gdb) disas 
Dump of assembler code for function _Z8test_braPlj:
   0x0000000202156400 <+0>:	ISETP.NE.U32.AND P0, PT, RZ, UR2, PT 
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
   0x0000000202156550 <+336>:	MOV R18, c[0x0][0x118] 
   0x0000000202156560 <+352>:	MOV R19, c[0x0][0x11c] 
   0x0000000202156570 <+368>:	MOV R2, RZ 
   0x0000000202156580 <+384>:	LDC.64 R2, c[0x0][R2+0x160] 
   0x0000000202156590 <+400>:	MOV R16, R2 
   0x00000002021565a0 <+416>:	MOV R2, R3 
   0x00000002021565b0 <+432>:	MOV R16, R16 
   0x00000002021565c0 <+448>:	MOV R2, R2 
   0x00000002021565d0 <+464>:	MOV R0, 0x8 
   0x00000002021565e0 <+480>:	LDC R0, c[0x0][R0+0x160] 
   0x00000002021565f0 <+496>:	MOV R0, R0 
   0x0000000202156600 <+512>:	MOV R0, R0 
   0x0000000202156610 <+528>:	MOV R16, R16 
   0x0000000202156620 <+544>:	MOV R2, R2 
   0x0000000202156630 <+560>:	MOV R17, R0 
   0x0000000202156640 <+576>:	S2R R0, SR_TID.X 
   0x0000000202156650 <+592>:	MOV R0, R0 
   0x0000000202156660 <+608>:	ISETP.LT.U32.AND P0, PT, R0, 0x10, PT 
   0x0000000202156670 <+624>:	PLOP3.LUT P0, PT, P0, PT, PT, 0x8, 0x0 
   0x0000000202156680 <+640>:	BSSY B0, 0x6d0 
   0x0000000202156690 <+656>:	@P0 BRA 0x6c0 
   0x00000002021566a0 <+672>:	BRA 0x2b0 
   0x00000002021566b0 <+688>:	S2R R6, SR_TID.Y 
   0x00000002021566c0 <+704>:	MOV R6, R6 
   0x00000002021566d0 <+720>:	S2R R0, SR_TID.X 
   0x00000002021566e0 <+736>:	MOV R0, R0 
   0x00000002021566f0 <+752>:	MOV R0, R0 
   0x0000000202156700 <+768>:	MOV R7, R0 
   0x0000000202156710 <+784>:	MOV R8, RZ 
   0x0000000202156720 <+800>:	MOV R4, 0x0 
   0x0000000202156730 <+816>:	MOV R5, 0x0 
   0x0000000202156740 <+832>:	MOV R4, R4 
   0x0000000202156750 <+848>:	MOV R5, R5 
   0x0000000202156760 <+864>:	MOV R3, R4 
   0x0000000202156770 <+880>:	MOV R0, R5 
   0x0000000202156780 <+896>:	MOV R3, R3 
   0x0000000202156790 <+912>:	MOV R0, R0 
   0x00000002021567a0 <+928>:	SHF.L.U64.HI R5, R7, 0x2, R8 
   0x00000002021567b0 <+944>:	SHF.L.U32 R4, R7, 0x2, RZ 
   0x00000002021567c0 <+960>:	IADD3 R4, P0, R3, R4, RZ 
   0x00000002021567d0 <+976>:	IADD3.X R5, R0, R5, RZ, P0, !PT 
   0x00000002021567e0 <+992>:	MOV R4, R4 
   0x00000002021567f0 <+1008>:	MOV R5, R5 
   0x0000000202156800 <+1024>:	MOV R4, R4 
   0x0000000202156810 <+1040>:	MOV R5, R5 
   0x0000000202156820 <+1056>:	R2UR UR4, R18 
   0x0000000202156830 <+1072>:	R2UR UR5, R19 
   0x0000000202156840 <+1088>:	ST.E [R4.64], R6 
   0x0000000202156850 <+1104>:	S2R R6, SR_TID.Z 
   0x0000000202156860 <+1120>:	MOV R6, R6 
   0x0000000202156870 <+1136>:	S2R R4, SR_TID.X 
   0x0000000202156880 <+1152>:	MOV R4, R4 
   0x0000000202156890 <+1168>:	IADD3 R4, R4, 0x10, RZ 
   0x00000002021568a0 <+1184>:	MOV R4, R4 
   0x00000002021568b0 <+1200>:	MOV R4, R4 
   0x00000002021568c0 <+1216>:	MOV R5, RZ 
   0x00000002021568d0 <+1232>:	SHF.L.U64.HI R5, R4, 0x2, R5 
   0x00000002021568e0 <+1248>:	SHF.L.U32 R4, R4, 0x2, RZ 
   0x00000002021568f0 <+1264>:	IADD3 R4, P0, R3, R4, RZ 
   0x0000000202156900 <+1280>:	IADD3.X R5, R0, R5, RZ, P0, !PT 
   0x0000000202156910 <+1296>:	MOV R4, R4 
   0x0000000202156920 <+1312>:	MOV R5, R5 
   0x0000000202156930 <+1328>:	MOV R4, R4 
   0x0000000202156940 <+1344>:	MOV R5, R5 
   0x0000000202156950 <+1360>:	R2UR UR4, R18 
   0x0000000202156960 <+1376>:	R2UR UR5, R19 
   0x0000000202156970 <+1392>:	ST.E [R4.64], R6 
   0x0000000202156980 <+1408>:	S2R R6, SR_TID.X 
--Type <RET> for more, q to quit, c to continue without paging--c
   0x0000000202156990 <+1424>:	MOV R6, R6 
   0x00000002021569a0 <+1440>:	S2R R4, SR_TID.X 
   0x00000002021569b0 <+1456>:	MOV R4, R4 
   0x00000002021569c0 <+1472>:	IADD3 R4, R4, 0x20, RZ 
   0x00000002021569d0 <+1488>:	MOV R4, R4 
   0x00000002021569e0 <+1504>:	MOV R4, R4 
   0x00000002021569f0 <+1520>:	MOV R5, RZ 
   0x0000000202156a00 <+1536>:	SHF.L.U64.HI R5, R4, 0x2, R5 
   0x0000000202156a10 <+1552>:	SHF.L.U32 R4, R4, 0x2, RZ 
   0x0000000202156a20 <+1568>:	IADD3 R4, P0, R3, R4, RZ 
   0x0000000202156a30 <+1584>:	IADD3.X R5, R0, R5, RZ, P0, !PT 
   0x0000000202156a40 <+1600>:	MOV R4, R4 
   0x0000000202156a50 <+1616>:	MOV R5, R5 
   0x0000000202156a60 <+1632>:	MOV R4, R4 
   0x0000000202156a70 <+1648>:	MOV R5, R5 
   0x0000000202156a80 <+1664>:	R2UR UR4, R18 
   0x0000000202156a90 <+1680>:	R2UR UR5, R19 
   0x0000000202156aa0 <+1696>:	ST.E [R4.64], R6 
   0x0000000202156ab0 <+1712>:	BRA 0x6c0 
   0x0000000202156ac0 <+1728>:	BSYNC B0 
   0x0000000202156ad0 <+1744>:	S2R R0, SR_TID.X 
   0x0000000202156ae0 <+1760>:	MOV R0, R0 
   0x0000000202156af0 <+1776>:	ISETP.LT.U32.AND P0, PT, R0, 0x20, PT 
   0x0000000202156b00 <+1792>:	PLOP3.LUT P0, PT, P0, PT, PT, 0x8, 0x0 
   0x0000000202156b10 <+1808>:	@P0 BRA 0x9d0 
   0x0000000202156b20 <+1824>:	BRA 0x730 
   0x0000000202156b30 <+1840>:	BRA.CONV ~URZ, 0x790 
   0x0000000202156b40 <+1856>:	MOV R4, 0x20 
   0x0000000202156b50 <+1872>:	MOV R20, 0x0 
   0x0000000202156b60 <+1888>:	MOV R21, 0x0 
   0x0000000202156b70 <+1904>:	CALL.ABS.NOINC 0x0 
=> 0x0000000202156b80 <+1920>:	BRA 0x7a0 
   0x0000000202156b90 <+1936>:	BAR.SYNC 0x0, 0x20 
   0x0000000202156ba0 <+1952>:	S2R R0, SR_TID.X 
   0x0000000202156bb0 <+1968>:	MOV R0, R0 
   0x0000000202156bc0 <+1984>:	S2R R2, SR_TID.X 
   0x0000000202156bd0 <+2000>:	MOV R2, R2 
   0x0000000202156be0 <+2016>:	MOV R2, R2 
   0x0000000202156bf0 <+2032>:	MOV R6, R2 
   0x0000000202156c00 <+2048>:	MOV R7, RZ 
   0x0000000202156c10 <+2064>:	MOV R2, 0x0 
   0x0000000202156c20 <+2080>:	MOV R2, R2 
   0x0000000202156c30 <+2096>:	MOV R2, R2 
   0x0000000202156c40 <+2112>:	MOV R2, R2 
   0x0000000202156c50 <+2128>:	MOV R3, RZ 
   0x0000000202156c60 <+2144>:	MOV R4, c[0x0][0x18] 
   0x0000000202156c70 <+2160>:	MOV R5, c[0x0][0x1c] 
   0x0000000202156c80 <+2176>:	IADD3 R4, P0, R2, R4, RZ 
   0x0000000202156c90 <+2192>:	IADD3.X R5, R3, R5, RZ, P0, !PT 
   0x0000000202156ca0 <+2208>:	SHF.L.U64.HI R3, R6, 0x2, R7 
   0x0000000202156cb0 <+2224>:	SHF.L.U32 R2, R6, 0x2, RZ 
   0x0000000202156cc0 <+2240>:	IADD3 R2, P0, R4, R2, RZ 
   0x0000000202156cd0 <+2256>:	IADD3.X R3, R5, R3, RZ, P0, !PT 
   0x0000000202156ce0 <+2272>:	MOV R2, R2 
   0x0000000202156cf0 <+2288>:	MOV R3, R3 
   0x0000000202156d00 <+2304>:	MOV R2, R2 
   0x0000000202156d10 <+2320>:	MOV R3, R3 
   0x0000000202156d20 <+2336>:	R2UR UR4, R18 
   0x0000000202156d30 <+2352>:	R2UR UR5, R19 
   0x0000000202156d40 <+2368>:	ST.E [R2.64], R0 
   0x0000000202156d50 <+2384>:	BRA.CONV ~URZ, 0x9b0 
   0x0000000202156d60 <+2400>:	MOV R4, 0x20 
   0x0000000202156d70 <+2416>:	MOV R20, 0x0 
   0x0000000202156d80 <+2432>:	MOV R21, 0x0 
   0x0000000202156d90 <+2448>:	CALL.ABS.NOINC 0x0 
   0x0000000202156da0 <+2464>:	BRA 0x9c0 
   0x0000000202156db0 <+2480>:	BAR.ARV 0x1, 0x20 
   0x0000000202156dc0 <+2496>:	BRA 0xda0 
   0x0000000202156dd0 <+2512>:	BRA.CONV ~URZ, 0xa30 
   0x0000000202156de0 <+2528>:	MOV R4, 0x20 
   0x0000000202156df0 <+2544>:	MOV R20, 0x0 
   0x0000000202156e00 <+2560>:	MOV R21, 0x0 
   0x0000000202156e10 <+2576>:	CALL.ABS.NOINC 0x0 
   0x0000000202156e20 <+2592>:	BRA 0xa40 
   0x0000000202156e30 <+2608>:	BAR.ARV 0x0, 0x20 
   0x0000000202156e40 <+2624>:	BRA.CONV ~URZ, 0xaa0 
   0x0000000202156e50 <+2640>:	MOV R4, 0x20 
   0x0000000202156e60 <+2656>:	MOV R20, 0x0 
   0x0000000202156e70 <+2672>:	MOV R21, 0x0 
   0x0000000202156e80 <+2688>:	CALL.ABS.NOINC 0x0 
   0x0000000202156e90 <+2704>:	BRA 0xab0 
   0x0000000202156ea0 <+2720>:	BAR.SYNC 0x1, 0x20 
   0x0000000202156eb0 <+2736>:	S2R R0, SR_TID.X 
   0x0000000202156ec0 <+2752>:	MOV R0, R0 
   0x0000000202156ed0 <+2768>:	IADD3 R0, R0, -0x20, RZ 
   0x0000000202156ee0 <+2784>:	MOV R0, R0 
   0x0000000202156ef0 <+2800>:	MOV R6, R0 
   0x0000000202156f00 <+2816>:	MOV R7, RZ 
   0x0000000202156f10 <+2832>:	MOV R0, 0x0 
   0x0000000202156f20 <+2848>:	MOV R0, R0 
   0x0000000202156f30 <+2864>:	MOV R0, R0 
   0x0000000202156f40 <+2880>:	MOV R4, R0 
   0x0000000202156f50 <+2896>:	MOV R5, RZ 
   0x0000000202156f60 <+2912>:	MOV R0, c[0x0][0x18] 
   0x0000000202156f70 <+2928>:	MOV R3, c[0x0][0x1c] 
   0x0000000202156f80 <+2944>:	IADD3 R0, P0, R4, R0, RZ 
   0x0000000202156f90 <+2960>:	IADD3.X R3, R5, R3, RZ, P0, !PT 
   0x0000000202156fa0 <+2976>:	SHF.L.U64.HI R5, R6, 0x2, R7 
   0x0000000202156fb0 <+2992>:	SHF.L.U32 R4, R6, 0x2, RZ 
   0x0000000202156fc0 <+3008>:	IADD3 R4, P0, R0, R4, RZ 
   0x0000000202156fd0 <+3024>:	IADD3.X R5, R3, R5, RZ, P0, !PT 
   0x0000000202156fe0 <+3040>:	MOV R4, R4 
   0x0000000202156ff0 <+3056>:	MOV R5, R5 
   0x0000000202157000 <+3072>:	MOV R4, R4 
   0x0000000202157010 <+3088>:	MOV R5, R5 
   0x0000000202157020 <+3104>:	R2UR UR4, R18 
   0x0000000202157030 <+3120>:	R2UR UR5, R19 
   0x0000000202157040 <+3136>:	LD.E R4, [R4.64] 
   0x0000000202157050 <+3152>:	MOV R4, R4 
   0x0000000202157060 <+3168>:	MOV R4, R4 
   0x0000000202157070 <+3184>:	MOV R5, RZ 
   0x0000000202157080 <+3200>:	S2R R0, SR_TID.X 
   0x0000000202157090 <+3216>:	MOV R0, R0 
   0x00000002021570a0 <+3232>:	IADD3 R0, R0, -0x20, RZ 
   0x00000002021570b0 <+3248>:	MOV R0, R0 
   0x00000002021570c0 <+3264>:	MOV R0, R0 
   0x00000002021570d0 <+3280>:	MOV R3, RZ 
   0x00000002021570e0 <+3296>:	SHF.L.U64.HI R3, R0, 0x3, R3 
   0x00000002021570f0 <+3312>:	SHF.L.U32 R0, R0, 0x3, RZ 
   0x0000000202157100 <+3328>:	IADD3 R16, P0, R16, R0, RZ 
   0x0000000202157110 <+3344>:	IADD3.X R3, R2, R3, RZ, P0, !PT 
   0x0000000202157120 <+3360>:	MOV R2, R16 
   0x0000000202157130 <+3376>:	MOV R3, R3 
   0x0000000202157140 <+3392>:	MOV R2, R2 
   0x0000000202157150 <+3408>:	MOV R3, R3 
   0x0000000202157160 <+3424>:	R2UR UR4, R18 
   0x0000000202157170 <+3440>:	R2UR UR5, R19 
   0x0000000202157180 <+3456>:	ST.E.64 [R2.64], R4 
   0x0000000202157190 <+3472>:	BRA 0xda0 
   0x00000002021571a0 <+3488>:	MEMBAR.SC.VC 
   0x00000002021571b0 <+3504>:	ERRBAR 
   0x00000002021571c0 <+3520>:	EXIT 
   0x00000002021571d0 <+3536>:	MEMBAR.SC.VC 
   0x00000002021571e0 <+3552>:	ERRBAR 
   0x00000002021571f0 <+3568>:	EXIT 
   0x0000000202157200 <+3584>:	BRA 0xe00
   0x0000000202157210 <+3600>:	NOP
   0x0000000202157220 <+3616>:	NOP
   0x0000000202157230 <+3632>:	NOP
   0x0000000202157240 <+3648>:	NOP
   0x0000000202157250 <+3664>:	NOP
   0x0000000202157260 <+3680>:	NOP
   0x0000000202157270 <+3696>:	NOP
   0x0000000202157280 <+3712>:	NOP
   0x0000000202157290 <+3728>:	NOP
   0x00000002021572a0 <+3744>:	NOP
   0x00000002021572b0 <+3760>:	NOP
   0x00000002021572c0 <+3776>:	NOP
   0x00000002021572d0 <+3792>:	NOP
   0x00000002021572e0 <+3808>:	NOP
   0x00000002021572f0 <+3824>:	NOP
End of assembler dump.
(cuda-gdb) cuda device 0 sm 0 warp 0 lane 16
[Switching focus to CUDA kernel 0, grid 1, block (0,0,0), thread (16,0,0), device 0, sm 0, warp 0, lane 16]
0x0000000202159e70 in __cuda_sm70_barrier_sync_0_count ()
(cuda-gdb) bt  
#0  0x0000000202159e70 in __cuda_sm70_barrier_sync_0_count ()
#1  0x0000000202156b80 in test_bra<<<(1,1,1),(64,1,1)>>> (out=0x2050e0000, count=64) at braconv_syncthreads.cu:26
(cuda-gdb) frame 1 
#1  0x0000000202156b80 in test_bra<<<(1,1,1),(64,1,1)>>> (out=0x2050e0000, count=64) at braconv_syncthreads.cu:26
26	        asm("barrier.cta.sync 0, 32;\n\t");
(cuda-gdb) disas 
Dump of assembler code for function _Z8test_braPlj:
   0x0000000202156400 <+0>:	ISETP.NE.U32.AND P0, PT, RZ, UR2, PT 
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
   0x0000000202156550 <+336>:	MOV R18, c[0x0][0x118] 
   0x0000000202156560 <+352>:	MOV R19, c[0x0][0x11c] 
   0x0000000202156570 <+368>:	MOV R2, RZ 
   0x0000000202156580 <+384>:	LDC.64 R2, c[0x0][R2+0x160] 
   0x0000000202156590 <+400>:	MOV R16, R2 
   0x00000002021565a0 <+416>:	MOV R2, R3 
   0x00000002021565b0 <+432>:	MOV R16, R16 
   0x00000002021565c0 <+448>:	MOV R2, R2 
   0x00000002021565d0 <+464>:	MOV R0, 0x8 
   0x00000002021565e0 <+480>:	LDC R0, c[0x0][R0+0x160] 
   0x00000002021565f0 <+496>:	MOV R0, R0 
   0x0000000202156600 <+512>:	MOV R0, R0 
   0x0000000202156610 <+528>:	MOV R16, R16 
   0x0000000202156620 <+544>:	MOV R2, R2 
   0x0000000202156630 <+560>:	MOV R17, R0 
   0x0000000202156640 <+576>:	S2R R0, SR_TID.X 
   0x0000000202156650 <+592>:	MOV R0, R0 
   0x0000000202156660 <+608>:	ISETP.LT.U32.AND P0, PT, R0, 0x10, PT 
   0x0000000202156670 <+624>:	PLOP3.LUT P0, PT, P0, PT, PT, 0x8, 0x0 
   0x0000000202156680 <+640>:	BSSY B0, 0x6d0 
   0x0000000202156690 <+656>:	@P0 BRA 0x6c0 
   0x00000002021566a0 <+672>:	BRA 0x2b0 
   0x00000002021566b0 <+688>:	S2R R6, SR_TID.Y 
   0x00000002021566c0 <+704>:	MOV R6, R6 
   0x00000002021566d0 <+720>:	S2R R0, SR_TID.X 
   0x00000002021566e0 <+736>:	MOV R0, R0 
   0x00000002021566f0 <+752>:	MOV R0, R0 
   0x0000000202156700 <+768>:	MOV R7, R0 
   0x0000000202156710 <+784>:	MOV R8, RZ 
   0x0000000202156720 <+800>:	MOV R4, 0x0 
   0x0000000202156730 <+816>:	MOV R5, 0x0 
   0x0000000202156740 <+832>:	MOV R4, R4 
   0x0000000202156750 <+848>:	MOV R5, R5 
   0x0000000202156760 <+864>:	MOV R3, R4 
   0x0000000202156770 <+880>:	MOV R0, R5 
   0x0000000202156780 <+896>:	MOV R3, R3 
   0x0000000202156790 <+912>:	MOV R0, R0 
   0x00000002021567a0 <+928>:	SHF.L.U64.HI R5, R7, 0x2, R8 
   0x00000002021567b0 <+944>:	SHF.L.U32 R4, R7, 0x2, RZ 
   0x00000002021567c0 <+960>:	IADD3 R4, P0, R3, R4, RZ 
   0x00000002021567d0 <+976>:	IADD3.X R5, R0, R5, RZ, P0, !PT 
   0x00000002021567e0 <+992>:	MOV R4, R4 
   0x00000002021567f0 <+1008>:	MOV R5, R5 
   0x0000000202156800 <+1024>:	MOV R4, R4 
   0x0000000202156810 <+1040>:	MOV R5, R5 
   0x0000000202156820 <+1056>:	R2UR UR4, R18 
   0x0000000202156830 <+1072>:	R2UR UR5, R19 
   0x0000000202156840 <+1088>:	ST.E [R4.64], R6 
   0x0000000202156850 <+1104>:	S2R R6, SR_TID.Z 
   0x0000000202156860 <+1120>:	MOV R6, R6 
   0x0000000202156870 <+1136>:	S2R R4, SR_TID.X 
   0x0000000202156880 <+1152>:	MOV R4, R4 
   0x0000000202156890 <+1168>:	IADD3 R4, R4, 0x10, RZ 
   0x00000002021568a0 <+1184>:	MOV R4, R4 
   0x00000002021568b0 <+1200>:	MOV R4, R4 
   0x00000002021568c0 <+1216>:	MOV R5, RZ 
   0x00000002021568d0 <+1232>:	SHF.L.U64.HI R5, R4, 0x2, R5 
   0x00000002021568e0 <+1248>:	SHF.L.U32 R4, R4, 0x2, RZ 
   0x00000002021568f0 <+1264>:	IADD3 R4, P0, R3, R4, RZ 
   0x0000000202156900 <+1280>:	IADD3.X R5, R0, R5, RZ, P0, !PT 
   0x0000000202156910 <+1296>:	MOV R4, R4 
   0x0000000202156920 <+1312>:	MOV R5, R5 
   0x0000000202156930 <+1328>:	MOV R4, R4 
   0x0000000202156940 <+1344>:	MOV R5, R5 
   0x0000000202156950 <+1360>:	R2UR UR4, R18 
   0x0000000202156960 <+1376>:	R2UR UR5, R19 
   0x0000000202156970 <+1392>:	ST.E [R4.64], R6 
   0x0000000202156980 <+1408>:	S2R R6, SR_TID.X 
--Type <RET> for more, q to quit, c to continue without paging--c
   0x0000000202156990 <+1424>:	MOV R6, R6 
   0x00000002021569a0 <+1440>:	S2R R4, SR_TID.X 
   0x00000002021569b0 <+1456>:	MOV R4, R4 
   0x00000002021569c0 <+1472>:	IADD3 R4, R4, 0x20, RZ 
   0x00000002021569d0 <+1488>:	MOV R4, R4 
   0x00000002021569e0 <+1504>:	MOV R4, R4 
   0x00000002021569f0 <+1520>:	MOV R5, RZ 
   0x0000000202156a00 <+1536>:	SHF.L.U64.HI R5, R4, 0x2, R5 
   0x0000000202156a10 <+1552>:	SHF.L.U32 R4, R4, 0x2, RZ 
   0x0000000202156a20 <+1568>:	IADD3 R4, P0, R3, R4, RZ 
   0x0000000202156a30 <+1584>:	IADD3.X R5, R0, R5, RZ, P0, !PT 
   0x0000000202156a40 <+1600>:	MOV R4, R4 
   0x0000000202156a50 <+1616>:	MOV R5, R5 
   0x0000000202156a60 <+1632>:	MOV R4, R4 
   0x0000000202156a70 <+1648>:	MOV R5, R5 
   0x0000000202156a80 <+1664>:	R2UR UR4, R18 
   0x0000000202156a90 <+1680>:	R2UR UR5, R19 
   0x0000000202156aa0 <+1696>:	ST.E [R4.64], R6 
   0x0000000202156ab0 <+1712>:	BRA 0x6c0 
   0x0000000202156ac0 <+1728>:	BSYNC B0 
   0x0000000202156ad0 <+1744>:	S2R R0, SR_TID.X 
   0x0000000202156ae0 <+1760>:	MOV R0, R0 
   0x0000000202156af0 <+1776>:	ISETP.LT.U32.AND P0, PT, R0, 0x20, PT 
   0x0000000202156b00 <+1792>:	PLOP3.LUT P0, PT, P0, PT, PT, 0x8, 0x0 
   0x0000000202156b10 <+1808>:	@P0 BRA 0x9d0 
   0x0000000202156b20 <+1824>:	BRA 0x730 
   0x0000000202156b30 <+1840>:	BRA.CONV ~URZ, 0x790 
   0x0000000202156b40 <+1856>:	MOV R4, 0x20 
   0x0000000202156b50 <+1872>:	MOV R20, 0x0 
   0x0000000202156b60 <+1888>:	MOV R21, 0x0 
   0x0000000202156b70 <+1904>:	CALL.ABS.NOINC 0x0 
=> 0x0000000202156b80 <+1920>:	BRA 0x7a0 
   0x0000000202156b90 <+1936>:	BAR.SYNC 0x0, 0x20 
   0x0000000202156ba0 <+1952>:	S2R R0, SR_TID.X 
   0x0000000202156bb0 <+1968>:	MOV R0, R0 
   0x0000000202156bc0 <+1984>:	S2R R2, SR_TID.X 
   0x0000000202156bd0 <+2000>:	MOV R2, R2 
   0x0000000202156be0 <+2016>:	MOV R2, R2 
   0x0000000202156bf0 <+2032>:	MOV R6, R2 
   0x0000000202156c00 <+2048>:	MOV R7, RZ 
   0x0000000202156c10 <+2064>:	MOV R2, 0x0 
   0x0000000202156c20 <+2080>:	MOV R2, R2 
   0x0000000202156c30 <+2096>:	MOV R2, R2 
   0x0000000202156c40 <+2112>:	MOV R2, R2 
   0x0000000202156c50 <+2128>:	MOV R3, RZ 
   0x0000000202156c60 <+2144>:	MOV R4, c[0x0][0x18] 
   0x0000000202156c70 <+2160>:	MOV R5, c[0x0][0x1c] 
   0x0000000202156c80 <+2176>:	IADD3 R4, P0, R2, R4, RZ 
   0x0000000202156c90 <+2192>:	IADD3.X R5, R3, R5, RZ, P0, !PT 
   0x0000000202156ca0 <+2208>:	SHF.L.U64.HI R3, R6, 0x2, R7 
   0x0000000202156cb0 <+2224>:	SHF.L.U32 R2, R6, 0x2, RZ 
   0x0000000202156cc0 <+2240>:	IADD3 R2, P0, R4, R2, RZ 
   0x0000000202156cd0 <+2256>:	IADD3.X R3, R5, R3, RZ, P0, !PT 
   0x0000000202156ce0 <+2272>:	MOV R2, R2 
   0x0000000202156cf0 <+2288>:	MOV R3, R3 
   0x0000000202156d00 <+2304>:	MOV R2, R2 
   0x0000000202156d10 <+2320>:	MOV R3, R3 
   0x0000000202156d20 <+2336>:	R2UR UR4, R18 
   0x0000000202156d30 <+2352>:	R2UR UR5, R19 
   0x0000000202156d40 <+2368>:	ST.E [R2.64], R0 
   0x0000000202156d50 <+2384>:	BRA.CONV ~URZ, 0x9b0 
   0x0000000202156d60 <+2400>:	MOV R4, 0x20 
   0x0000000202156d70 <+2416>:	MOV R20, 0x0 
   0x0000000202156d80 <+2432>:	MOV R21, 0x0 
   0x0000000202156d90 <+2448>:	CALL.ABS.NOINC 0x0 
   0x0000000202156da0 <+2464>:	BRA 0x9c0 
   0x0000000202156db0 <+2480>:	BAR.ARV 0x1, 0x20 
   0x0000000202156dc0 <+2496>:	BRA 0xda0 
   0x0000000202156dd0 <+2512>:	BRA.CONV ~URZ, 0xa30 
   0x0000000202156de0 <+2528>:	MOV R4, 0x20 
   0x0000000202156df0 <+2544>:	MOV R20, 0x0 
   0x0000000202156e00 <+2560>:	MOV R21, 0x0 
   0x0000000202156e10 <+2576>:	CALL.ABS.NOINC 0x0 
   0x0000000202156e20 <+2592>:	BRA 0xa40 
   0x0000000202156e30 <+2608>:	BAR.ARV 0x0, 0x20 
   0x0000000202156e40 <+2624>:	BRA.CONV ~URZ, 0xaa0 
   0x0000000202156e50 <+2640>:	MOV R4, 0x20 
   0x0000000202156e60 <+2656>:	MOV R20, 0x0 
   0x0000000202156e70 <+2672>:	MOV R21, 0x0 
   0x0000000202156e80 <+2688>:	CALL.ABS.NOINC 0x0 
   0x0000000202156e90 <+2704>:	BRA 0xab0 
   0x0000000202156ea0 <+2720>:	BAR.SYNC 0x1, 0x20 
   0x0000000202156eb0 <+2736>:	S2R R0, SR_TID.X 
   0x0000000202156ec0 <+2752>:	MOV R0, R0 
   0x0000000202156ed0 <+2768>:	IADD3 R0, R0, -0x20, RZ 
   0x0000000202156ee0 <+2784>:	MOV R0, R0 
   0x0000000202156ef0 <+2800>:	MOV R6, R0 
   0x0000000202156f00 <+2816>:	MOV R7, RZ 
   0x0000000202156f10 <+2832>:	MOV R0, 0x0 
   0x0000000202156f20 <+2848>:	MOV R0, R0 
   0x0000000202156f30 <+2864>:	MOV R0, R0 
   0x0000000202156f40 <+2880>:	MOV R4, R0 
   0x0000000202156f50 <+2896>:	MOV R5, RZ 
   0x0000000202156f60 <+2912>:	MOV R0, c[0x0][0x18] 
   0x0000000202156f70 <+2928>:	MOV R3, c[0x0][0x1c] 
   0x0000000202156f80 <+2944>:	IADD3 R0, P0, R4, R0, RZ 
   0x0000000202156f90 <+2960>:	IADD3.X R3, R5, R3, RZ, P0, !PT 
   0x0000000202156fa0 <+2976>:	SHF.L.U64.HI R5, R6, 0x2, R7 
   0x0000000202156fb0 <+2992>:	SHF.L.U32 R4, R6, 0x2, RZ 
   0x0000000202156fc0 <+3008>:	IADD3 R4, P0, R0, R4, RZ 
   0x0000000202156fd0 <+3024>:	IADD3.X R5, R3, R5, RZ, P0, !PT 
   0x0000000202156fe0 <+3040>:	MOV R4, R4 
   0x0000000202156ff0 <+3056>:	MOV R5, R5 
   0x0000000202157000 <+3072>:	MOV R4, R4 
   0x0000000202157010 <+3088>:	MOV R5, R5 
   0x0000000202157020 <+3104>:	R2UR UR4, R18 
   0x0000000202157030 <+3120>:	R2UR UR5, R19 
   0x0000000202157040 <+3136>:	LD.E R4, [R4.64] 
   0x0000000202157050 <+3152>:	MOV R4, R4 
   0x0000000202157060 <+3168>:	MOV R4, R4 
   0x0000000202157070 <+3184>:	MOV R5, RZ 
   0x0000000202157080 <+3200>:	S2R R0, SR_TID.X 
   0x0000000202157090 <+3216>:	MOV R0, R0 
   0x00000002021570a0 <+3232>:	IADD3 R0, R0, -0x20, RZ 
   0x00000002021570b0 <+3248>:	MOV R0, R0 
   0x00000002021570c0 <+3264>:	MOV R0, R0 
   0x00000002021570d0 <+3280>:	MOV R3, RZ 
   0x00000002021570e0 <+3296>:	SHF.L.U64.HI R3, R0, 0x3, R3 
   0x00000002021570f0 <+3312>:	SHF.L.U32 R0, R0, 0x3, RZ 
   0x0000000202157100 <+3328>:	IADD3 R16, P0, R16, R0, RZ 
   0x0000000202157110 <+3344>:	IADD3.X R3, R2, R3, RZ, P0, !PT 
   0x0000000202157120 <+3360>:	MOV R2, R16 
   0x0000000202157130 <+3376>:	MOV R3, R3 
   0x0000000202157140 <+3392>:	MOV R2, R2 
   0x0000000202157150 <+3408>:	MOV R3, R3 
   0x0000000202157160 <+3424>:	R2UR UR4, R18 
   0x0000000202157170 <+3440>:	R2UR UR5, R19 
   0x0000000202157180 <+3456>:	ST.E.64 [R2.64], R4 
   0x0000000202157190 <+3472>:	BRA 0xda0 
   0x00000002021571a0 <+3488>:	MEMBAR.SC.VC 
   0x00000002021571b0 <+3504>:	ERRBAR 
   0x00000002021571c0 <+3520>:	EXIT 
   0x00000002021571d0 <+3536>:	MEMBAR.SC.VC 
   0x00000002021571e0 <+3552>:	ERRBAR 
   0x00000002021571f0 <+3568>:	EXIT 
   0x0000000202157200 <+3584>:	BRA 0xe00
   0x0000000202157210 <+3600>:	NOP
   0x0000000202157220 <+3616>:	NOP
   0x0000000202157230 <+3632>:	NOP
   0x0000000202157240 <+3648>:	NOP
   0x0000000202157250 <+3664>:	NOP
   0x0000000202157260 <+3680>:	NOP
   0x0000000202157270 <+3696>:	NOP
   0x0000000202157280 <+3712>:	NOP
   0x0000000202157290 <+3728>:	NOP
   0x00000002021572a0 <+3744>:	NOP
   0x00000002021572b0 <+3760>:	NOP
   0x00000002021572c0 <+3776>:	NOP
   0x00000002021572d0 <+3792>:	NOP
   0x00000002021572e0 <+3808>:	NOP
   0x00000002021572f0 <+3824>:	NOP
End of assembler dump.
(cuda-gdb) 
```

si one more: 
```
(cuda-gdb) si
0x0000000202159e80 in __cuda_sm70_barrier_sync_0_count ()
(cuda-gdb) info cuda lanes 
  Ln  State         PC         ThreadIdx Exception 
Device 0 SM 0 Warp 0
   0 active 0x0000000202159e80   (0,0,0)    None   
   1 active 0x0000000202159e80   (1,0,0)    None   
   2 active 0x0000000202159e80   (2,0,0)    None   
   3 active 0x0000000202159e80   (3,0,0)    None   
   4 active 0x0000000202159e80   (4,0,0)    None   
   5 active 0x0000000202159e80   (5,0,0)    None   
   6 active 0x0000000202159e80   (6,0,0)    None   
   7 active 0x0000000202159e80   (7,0,0)    None   
   8 active 0x0000000202159e80   (8,0,0)    None   
   9 active 0x0000000202159e80   (9,0,0)    None   
  10 active 0x0000000202159e80  (10,0,0)    None   
  11 active 0x0000000202159e80  (11,0,0)    None   
  12 active 0x0000000202159e80  (12,0,0)    None   
  13 active 0x0000000202159e80  (13,0,0)    None   
  14 active 0x0000000202159e80  (14,0,0)    None   
  15 active 0x0000000202159e80  (15,0,0)    None   
* 16 active 0x0000000202159e80  (16,0,0)    None   
  17 active 0x0000000202159e80  (17,0,0)    None   
  18 active 0x0000000202159e80  (18,0,0)    None   
  19 active 0x0000000202159e80  (19,0,0)    None   
  20 active 0x0000000202159e80  (20,0,0)    None   
  21 active 0x0000000202159e80  (21,0,0)    None   
  22 active 0x0000000202159e80  (22,0,0)    None   
  23 active 0x0000000202159e80  (23,0,0)    None   
  24 active 0x0000000202159e80  (24,0,0)    None   
  25 active 0x0000000202159e80  (25,0,0)    None   
  26 active 0x0000000202159e80  (26,0,0)    None   
  27 active 0x0000000202159e80  (27,0,0)    None   
  28 active 0x0000000202159e80  (28,0,0)    None   
  29 active 0x0000000202159e80  (29,0,0)    None   
  30 active 0x0000000202159e80  (30,0,0)    None   
  31 active 0x0000000202159e80  (31,0,0)    None   
(cuda-gdb) disas 
Dump of assembler code for function __cuda_sm70_barrier_sync_0_count:
   0x0000000202159d00 <+0>:	ISETP.NE.U32.AND P0, PT, RZ, UR2, PT 
   0x0000000202159d10 <+16>:	@P0 BRA 0x140 
   0x0000000202159d20 <+32>:	BMOV.32 B0, 0xffffffff 
   0x0000000202159d30 <+48>:	BMOV.32.CLEAR B1, B0 
   0x0000000202159d40 <+64>:	BMOV.32.CLEAR B2, B1 
   0x0000000202159d50 <+80>:	BMOV.32.CLEAR B3, B2 
   0x0000000202159d60 <+96>:	BMOV.32.CLEAR B4, B3 
   0x0000000202159d70 <+112>:	BMOV.32.CLEAR B5, B4 
   0x0000000202159d80 <+128>:	BMOV.32.CLEAR B6, B5 
   0x0000000202159d90 <+144>:	BMOV.32.CLEAR B7, B6 
   0x0000000202159da0 <+160>:	BMOV.32.CLEAR B8, B7 
   0x0000000202159db0 <+176>:	BMOV.32.CLEAR B9, B8 
   0x0000000202159dc0 <+192>:	BMOV.32.CLEAR B10, B9 
   0x0000000202159dd0 <+208>:	BMOV.32.CLEAR B11, B10 
   0x0000000202159de0 <+224>:	BMOV.32.CLEAR B12, B11 
   0x0000000202159df0 <+240>:	BMOV.32.CLEAR B13, B12 
   0x0000000202159e00 <+256>:	BMOV.32.CLEAR B14, B13 
   0x0000000202159e10 <+272>:	BMOV.32.CLEAR B15, B14 
   0x0000000202159e20 <+288>:	BMOV.32 B15, 0x0 
   0x0000000202159e30 <+304>:	UMOV UR2, 0x1 
   0x0000000202159e40 <+320>:	MOV R4, R4 
   0x0000000202159e50 <+336>:	MOV R4, R4 
   0x0000000202159e60 <+352>:	WARPSYNC 0xffffffff 
   0x0000000202159e70 <+368>:	BAR.SYNC 0x0, R4 
=> 0x0000000202159e80 <+384>:	MOV R4, RZ 
   0x0000000202159e90 <+400>:	MOV R4, R4 
   0x0000000202159ea0 <+416>:	RET.ABS.NODEC R20 0x0 
   0x0000000202159eb0 <+432>:	BRA 0x1b0
   0x0000000202159ec0 <+448>:	NOP
   0x0000000202159ed0 <+464>:	NOP
   0x0000000202159ee0 <+480>:	NOP
   0x0000000202159ef0 <+496>:	NOP
   0x0000000202159f00 <+512>:	NOP
   0x0000000202159f10 <+528>:	NOP
   0x0000000202159f20 <+544>:	NOP
   0x0000000202159f30 <+560>:	NOP
   0x0000000202159f40 <+576>:	NOP
   0x0000000202159f50 <+592>:	NOP
   0x0000000202159f60 <+608>:	NOP
   0x0000000202159f70 <+624>:	NOP
End of assembler dump.
(cuda-gdb) info register 
pc             0x202159e80         0x202159e80 <__cuda_sm70_barrier_sync_0_count+384>
errorpc        <unavailable>
R0             0x10                16
R1             0xfffdc0            16776640
R2             0x2                 2
R3             0x2                 2
R4             0x20                32
R5             0x0                 0
R6             0x0                 0
R7             0x0                 0
R8             0x0                 0
R9             0x0                 0
R10            0x0                 0
R11            0x0                 0
R12            0x0                 0
R13            0x0                 0
R14            0x0                 0
R15            0x0                 0
R16            0x50e0000           84803584
R17            0x40                64
R18            0x0                 0
R19            0x0                 0
R20            0x2156b80           34958208
R21            0x2                 2
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
--Type <RET> for more, q to quit, c to continue without paging--c
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
UR2            0x1                 1
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
(cuda-gdb) info cuda warps 
  Wp Active Lanes Mask Divergent Lanes Mask          Active PC Kernel BlockIdx First Active ThreadIdx 
Device 0 SM 0
   0        0xffffffff           0x00000000 0x0000000202159e80      0  (0,0,0)                (0,0,0) 
   1        0xffffffff           0x00000000 0x0000000202156640      0  (0,0,0)               (32,0,0) 
(cuda-gdb) 
```


cuda-gdb special variables doesn't work: 
```
(cuda-gdb) p/x $laneid
$1 = void
(cuda-gdb) p/x $warpid
$2 = void
(cuda-gdb) p/x $nwarpid
$3 = void
(cuda-gdb) p/x $smid   
$4 = void
(cuda-gdb) p/x $nsmid
$5 = void
(cuda-gdb) p/x $devid
$6 = void
(cuda-gdb) p/x $ndevid
$7 = void
(cuda-gdb) print $cluster_ctaid
$8 = void
(cuda-gdb) print $clusterid    
$9 = void
(cuda-gdb) p $aggr_smem_size 
$10 = void
(cuda-gdb) si 
0x0000000202159e90 in __cuda_sm70_barrier_sync_0_count ()
(cuda-gdb) disas 
Dump of assembler code for function __cuda_sm70_barrier_sync_0_count:
   0x0000000202159d00 <+0>:	ISETP.NE.U32.AND P0, PT, RZ, UR2, PT 
   0x0000000202159d10 <+16>:	@P0 BRA 0x140 
   0x0000000202159d20 <+32>:	BMOV.32 B0, 0xffffffff 
   0x0000000202159d30 <+48>:	BMOV.32.CLEAR B1, B0 
   0x0000000202159d40 <+64>:	BMOV.32.CLEAR B2, B1 
   0x0000000202159d50 <+80>:	BMOV.32.CLEAR B3, B2 
   0x0000000202159d60 <+96>:	BMOV.32.CLEAR B4, B3 
   0x0000000202159d70 <+112>:	BMOV.32.CLEAR B5, B4 
   0x0000000202159d80 <+128>:	BMOV.32.CLEAR B6, B5 
   0x0000000202159d90 <+144>:	BMOV.32.CLEAR B7, B6 
   0x0000000202159da0 <+160>:	BMOV.32.CLEAR B8, B7 
   0x0000000202159db0 <+176>:	BMOV.32.CLEAR B9, B8 
   0x0000000202159dc0 <+192>:	BMOV.32.CLEAR B10, B9 
   0x0000000202159dd0 <+208>:	BMOV.32.CLEAR B11, B10 
   0x0000000202159de0 <+224>:	BMOV.32.CLEAR B12, B11 
   0x0000000202159df0 <+240>:	BMOV.32.CLEAR B13, B12 
   0x0000000202159e00 <+256>:	BMOV.32.CLEAR B14, B13 
   0x0000000202159e10 <+272>:	BMOV.32.CLEAR B15, B14 
   0x0000000202159e20 <+288>:	BMOV.32 B15, 0x0 
   0x0000000202159e30 <+304>:	UMOV UR2, 0x1 
   0x0000000202159e40 <+320>:	MOV R4, R4 
   0x0000000202159e50 <+336>:	MOV R4, R4 
   0x0000000202159e60 <+352>:	WARPSYNC 0xffffffff 
   0x0000000202159e70 <+368>:	BAR.SYNC 0x0, R4 
   0x0000000202159e80 <+384>:	MOV R4, RZ 
=> 0x0000000202159e90 <+400>:	MOV R4, R4 
   0x0000000202159ea0 <+416>:	RET.ABS.NODEC R20 0x0 
   0x0000000202159eb0 <+432>:	BRA 0x1b0
   0x0000000202159ec0 <+448>:	NOP
   0x0000000202159ed0 <+464>:	NOP
   0x0000000202159ee0 <+480>:	NOP
   0x0000000202159ef0 <+496>:	NOP
   0x0000000202159f00 <+512>:	NOP
   0x0000000202159f10 <+528>:	NOP
   0x0000000202159f20 <+544>:	NOP
   0x0000000202159f30 <+560>:	NOP
   0x0000000202159f40 <+576>:	NOP
   0x0000000202159f50 <+592>:	NOP
   0x0000000202159f60 <+608>:	NOP
   0x0000000202159f70 <+624>:	NOP
End of assembler dump.
(cuda-gdb) si
0x0000000202159ea0 in __cuda_sm70_barrier_sync_0_count ()
(cuda-gdb) info register       
pc             0x202159ea0         0x202159ea0 <__cuda_sm70_barrier_sync_0_count+416>
errorpc        <unavailable>
R0             0x10                16
R1             0xfffdc0            16776640
R2             0x2                 2
R3             0x2                 2
R4             0x0                 0
R5             0x0                 0
R6             0x0                 0
R7             0x0                 0
R8             0x0                 0
R9             0x0                 0
R10            0x0                 0
R11            0x0                 0
R12            0x0                 0
R13            0x0                 0
R14            0x0                 0
R15            0x0                 0
R16            0x50e0000           84803584
R17            0x40                64
R18            0x0                 0
R19            0x0                 0
R20            0x2156b80           34958208
R21            0x2                 2
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
--Type <RET> for more, q to quit, c to continue without paging--q
Quit
(cuda-gdb) 
```

# Conclusion 
Now we have verified that BRA.CONV only branches when the warp is convergent, if not, it will NOT jump!!! 

# Conclusion 2 

For code in the following snippet: 
```
   BSSY B0, $L__BBMerge
@p BRA  $L__BSYNC  // warp diverged into T and NT 
   Some instructions...
$L__BSYNC:
   BSYNC B0
$L__BBMerge:
   More instructions... 

```

If we modify it to code like this: 
```
   BSSY B0, $L__BBMerge
@p BRA  $L__BSYNC  // warp diverged into T and NT
   Some instructions...
$L__BSYNC:
   NOP
$L__BBMerge:
   More instructions... 

```
After the modification, 
For the T-lanes, it will hang on si if we focus on them 

For the NT-lanes, it will continue to run until pc is pointing at $L__BBMerge, and without doing si on the NT-lanes again, 
all the T-lanes will still hang on si. 

However, if we do si on NT-lanes again, it will run as normal. 
In this case if we go back to T-lanes and do si, it will run back to normal, but in this case, 
we kinda lose single-stepping effect, and it runs like a horse, until we hit the WARPSYNC instruction in the subfunction. 



