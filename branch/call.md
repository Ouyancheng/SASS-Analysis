# Analysis on CALL instructions in SASS 

We compile indcall.cu without debug information, and we can see some CALL.REL instructions. 

Particularly: 
```
        /*02d0*/                   CALL.REL.NOINC R8 0x0 ;                            /* 0xfffffd2008007344 */
                                                                                      /* 0x020fea0003c3ffff */
        /*02e0*/                   BSYNC B6 ;                                         /* 0x0000000000067941 */
                                                                                      /* 0x000fea0003800000 */
        /*02f0*/                   LDL R4, [R1+0x4] ;                                 /* 0x0000040001047983 */
                                                                                      /* 0x0001620000100800 */
        /*0300*/                   MOV R8, 0x320 ;                                    /* 0x0000032000087802 */
                                                                                      /* 0x000fc60000000f00 */
        /*0310*/                   CALL.REL.NOINC 0x410 ;                             /* 0x000000f000007944 */
                                                                                      /* 0x021fea0003c00000 */
```
Instruction CALL.REL.NOINC R8 0x0 is very iconic: 
```
        /*02d0*/                   CALL.REL.NOINC R8 0x0 ;                            /* 0xfffffd2008007344 */
                                                                                      /* 0x020fea0003c3ffff */
```

If we compare this to a BRX instruction in brx.md: 
```
        /*0400*/                   BRX R2 -0x410 ;                         /* 0xfffffbf002007949 */
                                                                           /* 0x003fde000383ffff */
```
We can see similarly pattern in the second 32-bit chunk -- a negative 32-bit integer: 
```
0xfffffd20

>>> hex(0xfffffd20-0x100000000)
'-0x2e0'
```

Notice taht 0x2e0 is actually the next instruction of the CALL.REL.NOINC R8 0x0... 
Does it mean that it behave similarly as the BRX instruction? 

Let's run it with cuda-gdb and inspect R8: 

```
                              [System Information]
ROS: humble
DOMAIN_ID: 99
IP_Address_1: 100.69.39.187
IP_Address_2: 172.17.0.1
jetson@yahboom:~$ cd workspace/experiment/branch/indcall/
jetson@yahboom:~/workspace/experiment/branch/indcall$ ls
indcall87.cubin  indcall87.list  indcall87.out  indcall87.ptx  indcall.cu  indcall_opt87.cubin  indcall_opt87.list  indcall.out
jetson@yahboom:~/workspace/experiment/branch/indcall$ nvcc indcall.cu -o indcall_opt87.out -gencode arch=compute_87,code=sm_87
jetson@yahboom:~/workspace/experiment/branch/indcall$ cuda-gdb indcall_opt87.out 
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
Reading symbols from indcall_opt87.out...
(No debugging symbols found in indcall_opt87.out)
(cuda-gdb) set cuda break_on_launch application 
(cuda-gdb) run 
Starting program: /home/jetson/workspace/experiment/branch/indcall/indcall_opt87.out 
[Thread debugging using libthread_db enabled]
Using host libthread_db library "/lib/aarch64-linux-gnu/libthread_db.so.1".
[New Thread 0xfffff47dc840 (LWP 13919)]
[Detaching after fork from child process 13920]
[New Thread 0xfffff3edb840 (LWP 13928)]
[Switching focus to CUDA kernel 0, grid 1, block (0,0,0), thread (0,0,0), device 0, sm 0, warp 0, lane 0]

CUDA thread hit application kernel entry function breakpoint, 0x0000000202156400 in add_kernel(int*, int*, int*, int)
   <<<(1,1,1),(256,1,1)>>> ()
(cuda-gdb) disas 
Dump of assembler code for function _Z10add_kernelPiS_S_i:
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
   0x0000000202156540 <+320>:	IMAD.MOV.U32 R1, RZ, RZ, c[0x0][0x28] 
   0x0000000202156550 <+336>:	S2R R17, SR_CTAID.X 
   0x0000000202156560 <+352>:	IADD3 R1, R1, -0x8, RZ 
   0x0000000202156570 <+368>:	S2R R0, SR_TID.X 
   0x0000000202156580 <+384>:	IADD3 R16, P0, R1, c[0x0][0x20], RZ 
   0x0000000202156590 <+400>:	IMAD R17, R17, c[0x0][0x0], R0 
   0x00000002021565a0 <+416>:	ISETP.GE.AND P1, PT, R17, c[0x0][0x178], PT 
   0x00000002021565b0 <+432>:	@P1 EXIT 
   0x00000002021565c0 <+448>:	IMAD.MOV.U32 R10, RZ, RZ, 0x4 
   0x00000002021565d0 <+464>:	ULDC.64 UR36, c[0x0][0x118] 
   0x00000002021565e0 <+480>:	IMAD.WIDE R8, R17, R10, c[0x0][0x160] 
   0x00000002021565f0 <+496>:	IMAD.WIDE R10, R17, R10, c[0x0][0x168] 
   0x0000000202156600 <+512>:	LDG.E R4, [R8.64] 
   0x0000000202156610 <+528>:	LDG.E R5, [R10.64] 
   0x0000000202156620 <+544>:	IADD3 R6, P1, R16, 0x4, RZ 
   0x0000000202156630 <+560>:	IADD3.X R2, RZ, c[0x0][0x24], RZ, P0, !PT 
   0x0000000202156640 <+576>:	MOV R8, 0x280 
   0x0000000202156650 <+592>:	IMAD.X R7, RZ, RZ, R2, P1 
   0x0000000202156660 <+608>:	STL.64 [R1], R4 
   0x0000000202156670 <+624>:	CALL.REL.NOINC 0x410 
   0x0000000202156680 <+640>:	LD.E.64 R8, [R4.64] 
--Type <RET> for more, q to quit, c to continue without paging--c
   0x0000000202156690 <+656>:	BSSY B6, 0x2f0 
   0x00000002021566a0 <+672>:	MOV R20, 0x2e0 
   0x00000002021566b0 <+688>:	IMAD.MOV.U32 R21, RZ, RZ, 0x0 
   0x00000002021566c0 <+704>:	LD.E.64 R8, [R8.64] 
   0x00000002021566d0 <+720>:	CALL.REL.NOINC R8 0x0 
   0x00000002021566e0 <+736>:	BSYNC B6 
   0x00000002021566f0 <+752>:	LDL R4, [R1+0x4] 
   0x0000000202156700 <+768>:	MOV R8, 0x320 
   0x0000000202156710 <+784>:	CALL.REL.NOINC 0x410 
   0x0000000202156720 <+800>:	LD.E.64 R8, [R4.64] 
   0x0000000202156730 <+816>:	BSSY B6, 0x3b0 
   0x0000000202156740 <+832>:	MOV R6, R16 
   0x0000000202156750 <+848>:	IMAD.MOV.U32 R7, RZ, RZ, R2 
   0x0000000202156760 <+864>:	MOV R20, 0x3a0 
   0x0000000202156770 <+880>:	LD.E.64 R8, [R8.64] 
   0x0000000202156780 <+896>:	IMAD.MOV.U32 R21, RZ, RZ, 0x0 
   0x0000000202156790 <+912>:	CALL.REL.NOINC R8 0x0 
   0x00000002021567a0 <+928>:	BSYNC B6 
   0x00000002021567b0 <+944>:	LDL.64 R4, [R1] 
   0x00000002021567c0 <+960>:	HFMA2.MMA R2, -RZ, RZ, 0, 2.384185791015625e-07 
   0x00000002021567d0 <+976>:	IMAD.WIDE R2, R17, R2, c[0x0][0x170] 
   0x00000002021567e0 <+992>:	IMAD.IADD R0, R5, 0x1, R4 
   0x00000002021567f0 <+1008>:	STG.E [R2.64], R0 
   0x0000000202156800 <+1024>:	EXIT 
   0x0000000202156810 <+0>:	MOV R9, 0x0 
   0x0000000202156820 <+16>:	SHF.R.S32.HI R5, RZ, 0x1f, R4 
   0x0000000202156830 <+32>:	RET.REL.NODEC R8 0x0 
   0x0000000202156840 <+48>:	BRA 0x440
   0x0000000202156850 <+64>:	NOP
   0x0000000202156860 <+80>:	NOP
   0x0000000202156870 <+96>:	NOP
   0x0000000202156880 <+112>:	NOP
   0x0000000202156890 <+128>:	NOP
   0x00000002021568a0 <+144>:	NOP
   0x00000002021568b0 <+160>:	NOP
   0x00000002021568c0 <+176>:	NOP
   0x00000002021568d0 <+192>:	NOP
   0x00000002021568e0 <+208>:	NOP
   0x00000002021568f0 <+224>:	NOP
End of assembler dump.
(cuda-gdb) info registers
pc             0x202156400         0x202156400 <add_kernel(int*, int*, int*, int)>
errorpc        <unavailable>
R0             0x0                 0
R1             0x0                 0
R2             0x0                 0
R3             0x0                 0
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

si to a CALL: 
```
(cuda-gdb) si 10 
0x00000002021565c0 in add_kernel(int*, int*, int*, int)<<<(1,1,1),(256,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x2021565c0 <_Z10add_kernelPiS_S_i+448>:	IMAD.MOV.U32 R10, RZ, RZ, 0x4 
(cuda-gdb) si 5
0x0000000202156610 in add_kernel(int*, int*, int*, int)<<<(1,1,1),(256,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156610 <_Z10add_kernelPiS_S_i+528>:	LDG.E R5, [R10.64] 
(cuda-gdb) si 5
0x0000000202156660 in add_kernel(int*, int*, int*, int)<<<(1,1,1),(256,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156660 <_Z10add_kernelPiS_S_i+608>:	STL.64 [R1], R4 
(cuda-gdb) si
0x0000000202156670 in add_kernel(int*, int*, int*, int)<<<(1,1,1),(256,1,1)>>> ()
(cuda-gdb) x/i $pc
=> 0x202156670 <_Z10add_kernelPiS_S_i+624>:	CALL.REL.NOINC 0x410 
(cuda-gdb) x/x $pc
0x202156670 <_Z10add_kernelPiS_S_i+624>:	0x0000794a
(cuda-gdb) x/x $pc+4
0x202156674 <_Z10add_kernelPiS_S_i+628>:	0x040b1970
(cuda-gdb) x/x $pc+8
0x202156678 <_Z10add_kernelPiS_S_i+632>:	0x03800002
(cuda-gdb) x/x $pc+12
0x20215667c <_Z10add_kernelPiS_S_i+636>:	0x000fc000
(cuda-gdb) 
```

BUT: 
```
(cuda-gdb) x/x 0x0000000202156670 
0x202156670 <_Z10add_kernelPiS_S_i+624>:	0x00007944
(cuda-gdb) x/x 0x0000000202156674 
0x202156674 <_Z10add_kernelPiS_S_i+628>:	0x00000190
(cuda-gdb) x/x 0x0000000202156678 
0x202156678 <_Z10add_kernelPiS_S_i+632>:	0x03c00000
(cuda-gdb) x/x 0x000000020215667c 
0x20215667c <_Z10add_kernelPiS_S_i+636>:	0x001fea00
(cuda-gdb) 
```

Strange...

This is corresponding to SASS: 
```
        /*0270*/                   CALL.REL.NOINC 0x410 ;                             /* 0x0000019000007944 */
                                                                                      /* 0x001fea0003c00000 */
```

si on this instruction jumps to: 
```
(cuda-gdb) info registers 
pc             0x202156670         0x202156670 <add_kernel(int*, int*, int*, int)+624>
errorpc        <unavailable>
R0             0x0                 0
R1             0xfffdb8            16776632
R2             0xffff              65535
R3             0x0                 0
R4             0x0                 0
R5             0x0                 0
R6             0xe7fffdbc          -402653764
R7             0xffff              65535
R8             0x280               640
R9             0x2                 2
R10            0x50e0200           84804096
R11            0x2                 2
R12            0x0                 0
R13            0x0                 0
R14            0x0                 0
R15            0x0                 0
R16            0xe7fffdb8          -402653768
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
--Type <RET> for more, q to quit, c to continue without paging--q
Quit
(cuda-gdb) si
0x0000000202156810 in getA(int) [clone add_kernel(int*, int*, int*, int)] ()
(cuda-gdb) info registers 
pc             0x202156810         0x202156810 <getA(int) [clone add_kernel(int*, int*, int*, int)]>
errorpc        <unavailable>
R0             0x0                 0
R1             0xfffdb8            16776632
R2             0xffff              65535
R3             0x0                 0
R4             0x0                 0
R5             0x0                 0
R6             0xe7fffdbc          -402653764
R7             0xffff              65535
R8             0x280               640
R9             0x2                 2
R10            0x50e0200           84804096
R11            0x2                 2
R12            0x0                 0
R13            0x0                 0
R14            0x0                 0
R15            0x0                 0
R16            0xe7fffdb8          -402653768
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
--Type <RET> for more, q to quit, c to continue without paging--q
Quit
(cuda-gdb) 
```

Registers except for pc and not changed across this call instruction. 
And the call sets pc from 0x202156670 (call instr pc), to 0x202156810. 
And its encoding is: 
```
(cuda-gdb) x/x $pc
0x202156670 <_Z10add_kernelPiS_S_i+624>:	0x0000794a
(cuda-gdb) x/x $pc+4
0x202156674 <_Z10add_kernelPiS_S_i+628>:	0x040b1970
(cuda-gdb) x/x $pc+8
0x202156678 <_Z10add_kernelPiS_S_i+632>:	0x03800002
(cuda-gdb) x/x $pc+12
0x20215667c <_Z10add_kernelPiS_S_i+636>:	0x000fc000
```

However, if we view from the absolute address's perspective: 
```
(cuda-gdb) x/x 0x0000000202156670 
0x202156670 <_Z10add_kernelPiS_S_i+624>:	0x00007944
(cuda-gdb) x/x 0x0000000202156674 
0x202156674 <_Z10add_kernelPiS_S_i+628>:	0x00000190
(cuda-gdb) x/x 0x0000000202156678 
0x202156678 <_Z10add_kernelPiS_S_i+632>:	0x03c00000
(cuda-gdb) x/x 0x000000020215667c 
0x20215667c <_Z10add_kernelPiS_S_i+636>:	0x001fea00
(cuda-gdb) 
```

In the original instruction, the second 32-bit offset is 0x190, which is exactly: 
```
>>> hex(0x6810-0x6680)
'0x190'
```

## Conclusion: Direct CALL.REL.NOINC 
CALL.REL.NOINC takes an offset and the target PC is: 
```
TargetPC = CALLInstrPC + 0x10 + (signed int32_t)offset 
```
Remaining issue: Why viewing hex from $pc is different than viewing hex from the absolute address pointed by $pc??? 



Continue... 
```
(cuda-gdb) disas 
Dump of assembler code for function _Z10add_kernelPiS_S_i:
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
   0x0000000202156540 <+320>:	IMAD.MOV.U32 R1, RZ, RZ, c[0x0][0x28] 
   0x0000000202156550 <+336>:	S2R R17, SR_CTAID.X 
   0x0000000202156560 <+352>:	IADD3 R1, R1, -0x8, RZ 
   0x0000000202156570 <+368>:	S2R R0, SR_TID.X 
   0x0000000202156580 <+384>:	IADD3 R16, P0, R1, c[0x0][0x20], RZ 
   0x0000000202156590 <+400>:	IMAD R17, R17, c[0x0][0x0], R0 
   0x00000002021565a0 <+416>:	ISETP.GE.AND P1, PT, R17, c[0x0][0x178], PT 
   0x00000002021565b0 <+432>:	@P1 EXIT 
   0x00000002021565c0 <+448>:	IMAD.MOV.U32 R10, RZ, RZ, 0x4 
   0x00000002021565d0 <+464>:	ULDC.64 UR36, c[0x0][0x118] 
   0x00000002021565e0 <+480>:	IMAD.WIDE R8, R17, R10, c[0x0][0x160] 
   0x00000002021565f0 <+496>:	IMAD.WIDE R10, R17, R10, c[0x0][0x168] 
   0x0000000202156600 <+512>:	LDG.E R4, [R8.64] 
   0x0000000202156610 <+528>:	LDG.E R5, [R10.64] 
   0x0000000202156620 <+544>:	IADD3 R6, P1, R16, 0x4, RZ 
   0x0000000202156630 <+560>:	IADD3.X R2, RZ, c[0x0][0x24], RZ, P0, !PT 
   0x0000000202156640 <+576>:	MOV R8, 0x280 
   0x0000000202156650 <+592>:	IMAD.X R7, RZ, RZ, R2, P1 
   0x0000000202156660 <+608>:	STL.64 [R1], R4 
   0x0000000202156670 <+624>:	CALL.REL.NOINC 0x410 
   0x0000000202156680 <+640>:	LD.E.64 R8, [R4.64] 
--Type <RET> for more, q to quit, c to continue without paging--c
   0x0000000202156690 <+656>:	BSSY B6, 0x2f0 
   0x00000002021566a0 <+672>:	MOV R20, 0x2e0 
   0x00000002021566b0 <+688>:	IMAD.MOV.U32 R21, RZ, RZ, 0x0 
   0x00000002021566c0 <+704>:	LD.E.64 R8, [R8.64] 
   0x00000002021566d0 <+720>:	CALL.REL.NOINC R8 0x0 
   0x00000002021566e0 <+736>:	BSYNC B6 
   0x00000002021566f0 <+752>:	LDL R4, [R1+0x4] 
   0x0000000202156700 <+768>:	MOV R8, 0x320 
   0x0000000202156710 <+784>:	CALL.REL.NOINC 0x410 
   0x0000000202156720 <+800>:	LD.E.64 R8, [R4.64] 
   0x0000000202156730 <+816>:	BSSY B6, 0x3b0 
   0x0000000202156740 <+832>:	MOV R6, R16 
   0x0000000202156750 <+848>:	IMAD.MOV.U32 R7, RZ, RZ, R2 
   0x0000000202156760 <+864>:	MOV R20, 0x3a0 
   0x0000000202156770 <+880>:	LD.E.64 R8, [R8.64] 
   0x0000000202156780 <+896>:	IMAD.MOV.U32 R21, RZ, RZ, 0x0 
   0x0000000202156790 <+912>:	CALL.REL.NOINC R8 0x0 
   0x00000002021567a0 <+928>:	BSYNC B6 
   0x00000002021567b0 <+944>:	LDL.64 R4, [R1] 
   0x00000002021567c0 <+960>:	HFMA2.MMA R2, -RZ, RZ, 0, 2.384185791015625e-07 
   0x00000002021567d0 <+976>:	IMAD.WIDE R2, R17, R2, c[0x0][0x170] 
   0x00000002021567e0 <+992>:	IMAD.IADD R0, R5, 0x1, R4 
   0x00000002021567f0 <+1008>:	STG.E [R2.64], R0 
   0x0000000202156800 <+1024>:	EXIT 
=> 0x0000000202156810 <+0>:	MOV R9, 0x0 
   0x0000000202156820 <+16>:	SHF.R.S32.HI R5, RZ, 0x1f, R4 
   0x0000000202156830 <+32>:	RET.REL.NODEC R8 0x0 
   0x0000000202156840 <+48>:	BRA 0x440
   0x0000000202156850 <+64>:	NOP
   0x0000000202156860 <+80>:	NOP
   0x0000000202156870 <+96>:	NOP
   0x0000000202156880 <+112>:	NOP
   0x0000000202156890 <+128>:	NOP
   0x00000002021568a0 <+144>:	NOP
   0x00000002021568b0 <+160>:	NOP
   0x00000002021568c0 <+176>:	NOP
   0x00000002021568d0 <+192>:	NOP
   0x00000002021568e0 <+208>:	NOP
   0x00000002021568f0 <+224>:	NOP
End of assembler dump.
(cuda-gdb) info registers 
pc             0x202156810         0x202156810 <getA(int) [clone add_kernel(int*, int*, int*, int)]>
errorpc        <unavailable>
R0             0x0                 0
R1             0xfffdb8            16776632
R2             0xffff              65535
R3             0x0                 0
R4             0x0                 0
R5             0x0                 0
R6             0xe7fffdbc          -402653764
R7             0xffff              65535
R8             0x280               640
R9             0x2                 2
R10            0x50e0200           84804096
R11            0x2                 2
R12            0x0                 0
R13            0x0                 0
R14            0x0                 0
R15            0x0                 0
R16            0xe7fffdb8          -402653768
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
--Type <RET> for more, q to quit, c to continue without paging--q
Quit
(cuda-gdb) si
0x0000000202156820 in getA(int) [clone add_kernel(int*, int*, int*, int)] ()
(cuda-gdb) x/i $pc
=> 0x202156820 <$_Z10add_kernelPiS_S_i$_Z4getAi+16>:	SHF.R.S32.HI R5, RZ, 0x1f, R4 
(cuda-gdb) si
0x0000000202156830 in getA(int) [clone add_kernel(int*, int*, int*, int)] ()
(cuda-gdb) x/i $pc
=> 0x202156830 <$_Z10add_kernelPiS_S_i$_Z4getAi+32>:	RET.REL.NODEC R8 0x0 
(cuda-gdb) 
```

Register R8 is 0x280... 
```
(cuda-gdb) x/x 0x202156830 
0x202156830 <$_Z10add_kernelPiS_S_i$_Z4getAi+32>:	0x0000794a
(cuda-gdb) x/x 0x202156834 
0x202156834 <$_Z10add_kernelPiS_S_i$_Z4getAi+36>:	0x040b30f0
(cuda-gdb) x/x 0x202156838 
0x202156838 <$_Z10add_kernelPiS_S_i$_Z4getAi+40>:	0x03800002
(cuda-gdb) x/x 0x20215683c 
0x20215683c <$_Z10add_kernelPiS_S_i$_Z4getAi+44>:	0x000fc000
(cuda-gdb) x/i $pc   
=> 0x202156830 <$_Z10add_kernelPiS_S_i$_Z4getAi+32>:	RET.REL.NODEC R8 0x0 
(cuda-gdb) x/x $pc
0x202156830 <$_Z10add_kernelPiS_S_i$_Z4getAi+32>:	0x0000794a
(cuda-gdb) x/x $pc+4
0x202156834 <$_Z10add_kernelPiS_S_i$_Z4getAi+36>:	0x040b30f0
(cuda-gdb) x/x $pc+8
0x202156838 <$_Z10add_kernelPiS_S_i$_Z4getAi+40>:	0x03800002
(cuda-gdb) x/x $pc+12
0x20215683c <$_Z10add_kernelPiS_S_i$_Z4getAi+44>:	0x000fc000
(cuda-gdb) p/x $R8
$1 = 0x280
```

And the RET instruction encoding is (?): 
```
(cuda-gdb) x/x 0x202156830 
0x202156830 <$_Z10add_kernelPiS_S_i$_Z4getAi+32>:	0x0000794a
(cuda-gdb) x/x 0x202156834 
0x202156834 <$_Z10add_kernelPiS_S_i$_Z4getAi+36>:	0x040b30f0
(cuda-gdb) x/x 0x202156838 
0x202156838 <$_Z10add_kernelPiS_S_i$_Z4getAi+40>:	0x03800002
(cuda-gdb) x/x 0x20215683c 
0x20215683c <$_Z10add_kernelPiS_S_i$_Z4getAi+44>:	0x000fc000
(cuda-gdb) 
```

si and return: 
```
(cuda-gdb) si 
0x0000000202156680 in add_kernel(int*, int*, int*, int)<<<(1,1,1),(256,1,1)>>> ()
(cuda-gdb) x/i $pc   
=> 0x202156680 <_Z10add_kernelPiS_S_i+640>:	LD.E.64 R8, [R4.64] 
(cuda-gdb) 
```
Seems like the kernel launch will modify the instructions and perform some kind of relocation 
If we inspect the SASS dump, it's clear that the offset works similarly to the BRX: 
```
        /*0430*/                   RET.REL.NODEC R8 0x0 ;                             /* 0xfffffbc008007950 */
                                                                                      /* 0x000fea0003c3ffff */
        /*0440*/                   BRA 0x440;                                         /* 0xfffffff000007947 */
                                                                                      /* 0x000fc0000383ffff */
```
And we can see that: 
```
>>> hex(0xfffffbc0 - 0x100000000)
'-0x440'
```

After the si, we can see: 
```
(cuda-gdb) disas
Dump of assembler code for function _Z10add_kernelPiS_S_i:
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
   0x0000000202156540 <+320>:	IMAD.MOV.U32 R1, RZ, RZ, c[0x0][0x28] 
   0x0000000202156550 <+336>:	S2R R17, SR_CTAID.X 
   0x0000000202156560 <+352>:	IADD3 R1, R1, -0x8, RZ 
   0x0000000202156570 <+368>:	S2R R0, SR_TID.X 
   0x0000000202156580 <+384>:	IADD3 R16, P0, R1, c[0x0][0x20], RZ 
   0x0000000202156590 <+400>:	IMAD R17, R17, c[0x0][0x0], R0 
   0x00000002021565a0 <+416>:	ISETP.GE.AND P1, PT, R17, c[0x0][0x178], PT 
   0x00000002021565b0 <+432>:	@P1 EXIT 
   0x00000002021565c0 <+448>:	IMAD.MOV.U32 R10, RZ, RZ, 0x4 
   0x00000002021565d0 <+464>:	ULDC.64 UR36, c[0x0][0x118] 
   0x00000002021565e0 <+480>:	IMAD.WIDE R8, R17, R10, c[0x0][0x160] 
   0x00000002021565f0 <+496>:	IMAD.WIDE R10, R17, R10, c[0x0][0x168] 
   0x0000000202156600 <+512>:	LDG.E R4, [R8.64] 
   0x0000000202156610 <+528>:	LDG.E R5, [R10.64] 
   0x0000000202156620 <+544>:	IADD3 R6, P1, R16, 0x4, RZ 
   0x0000000202156630 <+560>:	IADD3.X R2, RZ, c[0x0][0x24], RZ, P0, !PT 
   0x0000000202156640 <+576>:	MOV R8, 0x280 
   0x0000000202156650 <+592>:	IMAD.X R7, RZ, RZ, R2, P1 
   0x0000000202156660 <+608>:	STL.64 [R1], R4 
   0x0000000202156670 <+624>:	CALL.REL.NOINC 0x410 
=> 0x0000000202156680 <+640>:	LD.E.64 R8, [R4.64] 
--Type <RET> for more, q to quit, c to continue without paging--c
   0x0000000202156690 <+656>:	BSSY B6, 0x2f0 
   0x00000002021566a0 <+672>:	MOV R20, 0x2e0 
   0x00000002021566b0 <+688>:	IMAD.MOV.U32 R21, RZ, RZ, 0x0 
   0x00000002021566c0 <+704>:	LD.E.64 R8, [R8.64] 
   0x00000002021566d0 <+720>:	CALL.REL.NOINC R8 0x0 
   0x00000002021566e0 <+736>:	BSYNC B6 
   0x00000002021566f0 <+752>:	LDL R4, [R1+0x4] 
   0x0000000202156700 <+768>:	MOV R8, 0x320 
   0x0000000202156710 <+784>:	CALL.REL.NOINC 0x410 
   0x0000000202156720 <+800>:	LD.E.64 R8, [R4.64] 
   0x0000000202156730 <+816>:	BSSY B6, 0x3b0 
   0x0000000202156740 <+832>:	MOV R6, R16 
   0x0000000202156750 <+848>:	IMAD.MOV.U32 R7, RZ, RZ, R2 
   0x0000000202156760 <+864>:	MOV R20, 0x3a0 
   0x0000000202156770 <+880>:	LD.E.64 R8, [R8.64] 
   0x0000000202156780 <+896>:	IMAD.MOV.U32 R21, RZ, RZ, 0x0 
   0x0000000202156790 <+912>:	CALL.REL.NOINC R8 0x0 
   0x00000002021567a0 <+928>:	BSYNC B6 
   0x00000002021567b0 <+944>:	LDL.64 R4, [R1] 
   0x00000002021567c0 <+960>:	HFMA2.MMA R2, -RZ, RZ, 0, 2.384185791015625e-07 
   0x00000002021567d0 <+976>:	IMAD.WIDE R2, R17, R2, c[0x0][0x170] 
   0x00000002021567e0 <+992>:	IMAD.IADD R0, R5, 0x1, R4 
   0x00000002021567f0 <+1008>:	STG.E [R2.64], R0 
   0x0000000202156800 <+1024>:	EXIT 
   0x0000000202156810 <+0>:	MOV R9, 0x0 
   0x0000000202156820 <+16>:	SHF.R.S32.HI R5, RZ, 0x1f, R4 
   0x0000000202156830 <+32>:	RET.REL.NODEC R8 0x0 
   0x0000000202156840 <+48>:	BRA 0x440
   0x0000000202156850 <+64>:	NOP
   0x0000000202156860 <+80>:	NOP
   0x0000000202156870 <+96>:	NOP
   0x0000000202156880 <+112>:	NOP
   0x0000000202156890 <+128>:	NOP
   0x00000002021568a0 <+144>:	NOP
   0x00000002021568b0 <+160>:	NOP
   0x00000002021568c0 <+176>:	NOP
   0x00000002021568d0 <+192>:	NOP
   0x00000002021568e0 <+208>:	NOP
   0x00000002021568f0 <+224>:	NOP
End of assembler dump.
(cuda-gdb) x/i 0x0000000202156830 
   0x202156830 <$_Z10add_kernelPiS_S_i$_Z4getAi+32>:	RET.REL.NODEC R8 0x0 
(cuda-gdb) x/x 0x0000000202156830 
0x202156830 <$_Z10add_kernelPiS_S_i$_Z4getAi+32>:	0x08007950
(cuda-gdb) x/x 0x0000000202156834 
0x202156834 <$_Z10add_kernelPiS_S_i$_Z4getAi+36>:	0xfffffbc0
(cuda-gdb) x/x 0x0000000202156838 
0x202156838 <$_Z10add_kernelPiS_S_i$_Z4getAi+40>:	0x03c3ffff
(cuda-gdb) x/x 0x000000020215683c 
0x20215683c <$_Z10add_kernelPiS_S_i$_Z4getAi+44>:	0x000fea00
(cuda-gdb) 
```

The RET instruction resumed back to normal!!! 

# Conclusion (sidetrack)
NOW we can infer that: when we are doing single-stepping, the next instruction is replaced by a trap instruction, 
so that we can achieve a single-stepping effect!!! 

And the trap instruction encodes somehow like this: 
```
(cuda-gdb) x/x $pc
0x202156680 <_Z10add_kernelPiS_S_i+640>:	0x0000794a
(cuda-gdb) x/x $pc+4
0x202156684 <_Z10add_kernelPiS_S_i+644>:	0x040b1e90 (changes if we print $pc at different locations)
(cuda-gdb) x/x $pc+8
0x202156688 <_Z10add_kernelPiS_S_i+648>:	0x03800002
(cuda-gdb) x/x $pc+12
0x20215668c <_Z10add_kernelPiS_S_i+652>:	0x000fc000
(cuda-gdb) 
```

# Conclusion: RET 
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
```

This is the return instruction. 

Continue...... 

```
(cuda-gdb) disas 
Dump of assembler code for function _Z10add_kernelPiS_S_i:
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
   0x0000000202156540 <+320>:	IMAD.MOV.U32 R1, RZ, RZ, c[0x0][0x28] 
   0x0000000202156550 <+336>:	S2R R17, SR_CTAID.X 
   0x0000000202156560 <+352>:	IADD3 R1, R1, -0x8, RZ 
   0x0000000202156570 <+368>:	S2R R0, SR_TID.X 
   0x0000000202156580 <+384>:	IADD3 R16, P0, R1, c[0x0][0x20], RZ 
   0x0000000202156590 <+400>:	IMAD R17, R17, c[0x0][0x0], R0 
   0x00000002021565a0 <+416>:	ISETP.GE.AND P1, PT, R17, c[0x0][0x178], PT 
   0x00000002021565b0 <+432>:	@P1 EXIT 
   0x00000002021565c0 <+448>:	IMAD.MOV.U32 R10, RZ, RZ, 0x4 
   0x00000002021565d0 <+464>:	ULDC.64 UR36, c[0x0][0x118] 
   0x00000002021565e0 <+480>:	IMAD.WIDE R8, R17, R10, c[0x0][0x160] 
   0x00000002021565f0 <+496>:	IMAD.WIDE R10, R17, R10, c[0x0][0x168] 
   0x0000000202156600 <+512>:	LDG.E R4, [R8.64] 
   0x0000000202156610 <+528>:	LDG.E R5, [R10.64] 
   0x0000000202156620 <+544>:	IADD3 R6, P1, R16, 0x4, RZ 
   0x0000000202156630 <+560>:	IADD3.X R2, RZ, c[0x0][0x24], RZ, P0, !PT 
   0x0000000202156640 <+576>:	MOV R8, 0x280 
   0x0000000202156650 <+592>:	IMAD.X R7, RZ, RZ, R2, P1 
   0x0000000202156660 <+608>:	STL.64 [R1], R4 
   0x0000000202156670 <+624>:	CALL.REL.NOINC 0x410 
=> 0x0000000202156680 <+640>:	LD.E.64 R8, [R4.64] 
--Type <RET> for more, q to quit, c to continue without paging--c
   0x0000000202156690 <+656>:	BSSY B6, 0x2f0 
   0x00000002021566a0 <+672>:	MOV R20, 0x2e0 
   0x00000002021566b0 <+688>:	IMAD.MOV.U32 R21, RZ, RZ, 0x0 
   0x00000002021566c0 <+704>:	LD.E.64 R8, [R8.64] 
   0x00000002021566d0 <+720>:	CALL.REL.NOINC R8 0x0 
   0x00000002021566e0 <+736>:	BSYNC B6 
   0x00000002021566f0 <+752>:	LDL R4, [R1+0x4] 
   0x0000000202156700 <+768>:	MOV R8, 0x320 
   0x0000000202156710 <+784>:	CALL.REL.NOINC 0x410 
   0x0000000202156720 <+800>:	LD.E.64 R8, [R4.64] 
   0x0000000202156730 <+816>:	BSSY B6, 0x3b0 
   0x0000000202156740 <+832>:	MOV R6, R16 
   0x0000000202156750 <+848>:	IMAD.MOV.U32 R7, RZ, RZ, R2 
   0x0000000202156760 <+864>:	MOV R20, 0x3a0 
   0x0000000202156770 <+880>:	LD.E.64 R8, [R8.64] 
   0x0000000202156780 <+896>:	IMAD.MOV.U32 R21, RZ, RZ, 0x0 
   0x0000000202156790 <+912>:	CALL.REL.NOINC R8 0x0 
   0x00000002021567a0 <+928>:	BSYNC B6 
   0x00000002021567b0 <+944>:	LDL.64 R4, [R1] 
   0x00000002021567c0 <+960>:	HFMA2.MMA R2, -RZ, RZ, 0, 2.384185791015625e-07 
   0x00000002021567d0 <+976>:	IMAD.WIDE R2, R17, R2, c[0x0][0x170] 
   0x00000002021567e0 <+992>:	IMAD.IADD R0, R5, 0x1, R4 
   0x00000002021567f0 <+1008>:	STG.E [R2.64], R0 
   0x0000000202156800 <+1024>:	EXIT 
   0x0000000202156810 <+0>:	MOV R9, 0x0 
   0x0000000202156820 <+16>:	SHF.R.S32.HI R5, RZ, 0x1f, R4 
   0x0000000202156830 <+32>:	RET.REL.NODEC R8 0x0 
   0x0000000202156840 <+48>:	BRA 0x440
   0x0000000202156850 <+64>:	NOP
   0x0000000202156860 <+80>:	NOP
   0x0000000202156870 <+96>:	NOP
   0x0000000202156880 <+112>:	NOP
   0x0000000202156890 <+128>:	NOP
   0x00000002021568a0 <+144>:	NOP
   0x00000002021568b0 <+160>:	NOP
   0x00000002021568c0 <+176>:	NOP
   0x00000002021568d0 <+192>:	NOP
   0x00000002021568e0 <+208>:	NOP
   0x00000002021568f0 <+224>:	NOP
End of assembler dump.
(cuda-gdb) si

CUDA Exception: Warp Misaligned Address
The exception was triggered at PC 0x2040b2170

Thread 1 "indcall_opt87.o" received signal CUDA_EXCEPTION_6, Warp Misaligned Address.
0x0000000202156680 in add_kernel(int*, int*, int*, int)<<<(1,1,1),(256,1,1)>>> ()
(cuda-gdb) info cuda lanes 
  Ln  State         PC         ThreadIdx        Exception        
Device 0 SM 0 Warp 0
*  0 active 0x0000000202156680   (0,0,0) Warp Misaligned Address 
   1 active 0x0000000202156680   (1,0,0) Warp Misaligned Address 
   2 active 0x0000000202156680   (2,0,0) Warp Misaligned Address 
   3 active 0x0000000202156680   (3,0,0) Warp Misaligned Address 
   4 active 0x0000000202156680   (4,0,0) Warp Misaligned Address 
   5 active 0x0000000202156680   (5,0,0) Warp Misaligned Address 
   6 active 0x0000000202156680   (6,0,0) Warp Misaligned Address 
   7 active 0x0000000202156680   (7,0,0) Warp Misaligned Address 
   8 active 0x0000000202156680   (8,0,0) Warp Misaligned Address 
   9 active 0x0000000202156680   (9,0,0) Warp Misaligned Address 
(cuda-gdb) info cuda warps 
  Wp Active Lanes Mask Divergent Lanes Mask          Active PC Kernel BlockIdx First Active ThreadIdx 
Device 0 SM 0
*  0        0x000003ff           0x00000000 0x0000000202156680      0  (0,0,0)                (0,0,0) 
   1        0xffffffff           0x00000000 0x0000000202156400      0  (0,0,0)               (32,0,0) 
   2        0xffffffff           0x00000000 0x0000000202156400      0  (0,0,0)               (64,0,0) 
   3        0xffffffff           0x00000000 0x0000000202156400      0  (0,0,0)               (96,0,0) 
   4        0xffffffff           0x00000000 0x0000000202156400      0  (0,0,0)              (128,0,0) 
   5        0xffffffff           0x00000000 0x0000000202156400      0  (0,0,0)              (160,0,0) 
   6        0xffffffff           0x00000000 0x0000000202156400      0  (0,0,0)              (192,0,0) 
   7        0xffffffff           0x00000000 0x0000000202156400      0  (0,0,0)              (224,0,0) 
(cuda-gdb) info registers 
pc             0x202156680         0x202156680 <add_kernel(int*, int*, int*, int)+640>
errorpc        0x2040b2170         0x2040b2170
R0             0x0                 0
R1             0xfffdb8            16776632
R2             0xffff              65535
R3             0x0                 0
R4             0x0                 0
R5             0x0                 0
R6             0xe7fffdbc          -402653764
R7             0xffff              65535
R8             0x0                 0
R9             0x0                 0
R10            0x50e0200           84804096
R11            0x2                 2
R12            0x0                 0
R13            0x0                 0
R14            0x0                 0
R15            0x0                 0
R16            0xe7fffdb8          -402653768
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
--Type <RET> for more, q to quit, c to continue without paging--q
Quit
(cuda-gdb) 

```

Ohhh...... 

Continue again... 

And the board crashed...... 

Okay...... 

## Infer Indirect Call......
Let's infer the indirect call instruction instead... 
```
        /*0390*/                   CALL.REL.NOINC R8 0x0 ;                            /* 0xfffffc6008007344 */
                                                                                      /* 0x020fea0003c3ffff */
```
We assume R8 is the target, let's say 0x0410 or something else... 

Then 
```
CALL.REL.NOINC Rx 0x0; 

encoded_imm is the second 32-bit chunk of the CALL instruction encoding, 

TargetPC = INDCALLInstrPC + 0x10 + Rx + encoded_imm - 0x100000000 
```

## Side: relative branch 
```
        /*0440*/                   BRA 0x440;                                         /* 0xfffffff000007947 */
                                                                                      /* 0x000fc0000383ffff */
```
It works the same as relative call: 
```
TargetPC = BRAInstrPC + 0x10 + (signed int32_t)encoded_imm
```

Notice that this casting is different than the - 0x100000000 operation... 

