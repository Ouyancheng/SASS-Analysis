# Calling convention analysis based on cuda-gdb and SASS

Cuda code:
```

__device__ __noinline__ int atomicFoo(int *a) {
    return atomicAdd(a, 1);
}
#define GEN(a) a, a+1, a+2, a+3, a+4, a+5, a+6, a+7
#define GEN2(b) GEN(b), GEN(b+8), GEN(b+16), GEN(b+24), GEN(b+32), GEN(b+40), GEN(b+48), GEN(b+56)
__constant__ int array[64] = {GEN2(0)}; // must be outside of function body,
// otherwise error: an automatic "__constant__" variable declaration is not allowed inside a device function body
__global__
void test_atomic(int64_t *out, uint32_t count) {    
    int r = atomicFoo(&(array[threadIdx.x]));
    // int a = threadIdx.x * 10;
    // printf(
    //     "threadIdx.x = %d, arr[tid] = %d\n", threadIdx.x, array[threadIdx.x]
    // );
    out[threadIdx.x] = (int64_t)array[threadIdx.x];
}

```

Typical SASS:
```
(cuda-gdb) disas
Dump of assembler code for function _Z11test_atomicPlj:
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
   0x0000000202156550 <+336>:	MOV R22, c[0x0][0x118] 
   0x0000000202156560 <+352>:	MOV R23, c[0x0][0x11c] 
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
   0x0000000202156630 <+560>:	MOV R19, R0 
   0x0000000202156640 <+576>:	S2R R0, SR_TID.X 
   0x0000000202156650 <+592>:	MOV R0, R0 
   0x0000000202156660 <+608>:	MOV R0, R0 
   0x0000000202156670 <+624>:	MOV R3, R0 
   0x0000000202156680 <+640>:	MOV R6, RZ 
   0x0000000202156690 <+656>:	MOV R0, 0x0 
   0x00000002021566a0 <+672>:	MOV R4, R0 
   0x00000002021566b0 <+688>:	MOV R5, RZ 
   0x00000002021566c0 <+704>:	MOV R18, R4 
   0x00000002021566d0 <+720>:	MOV R17, R5 
   0x00000002021566e0 <+736>:	MOV R18, R18 
   0x00000002021566f0 <+752>:	MOV R17, R17 
   0x0000000202156700 <+768>:	IADD3 R18, P0, R18, c[0x0][0x50], RZ 
   0x0000000202156710 <+784>:	IADD3.X R17, R17, c[0x0][0x54], RZ, P0, !PT 
   0x0000000202156720 <+800>:	SHF.L.U64.HI R5, R3, 0x2, R6 
   0x0000000202156730 <+816>:	SHF.L.U32 R4, R3, 0x2, RZ 
   0x0000000202156740 <+832>:	IADD3 R4, P0, R18, R4, RZ 
   0x0000000202156750 <+848>:	IADD3.X R5, R17, R5, RZ, P0, !PT 
   0x0000000202156760 <+864>:	MOV R4, R4 
   0x0000000202156770 <+880>:	MOV R5, R5 
   0x0000000202156780 <+896>:	MOV R18, R18 
   0x0000000202156790 <+912>:	MOV R17, R17 
   0x00000002021567a0 <+928>:	MOV R20, 0x0 
   0x00000002021567b0 <+944>:	MOV R21, 0x0 
=> 0x00000002021567c0 <+960>:	CALL.ABS.NOINC 0x0 
   0x00000002021567d0 <+976>:	MOV R4, R4 
   0x00000002021567e0 <+992>:	MOV R4, R4 
--Type <RET> for more, q to quit, c to continue without paging--
   0x00000002021567f0 <+1008>:	MOV R0, R4 
   0x0000000202156800 <+1024>:	S2R R3, SR_TID.X 
   0x0000000202156810 <+1040>:	MOV R3, R3 
   0x0000000202156820 <+1056>:	MOV R3, R3 
   0x0000000202156830 <+1072>:	MOV R3, R3 
   0x0000000202156840 <+1088>:	MOV R5, RZ 
   0x0000000202156850 <+1104>:	SHF.L.U64.HI R5, R3, 0x2, R5 
   0x0000000202156860 <+1120>:	SHF.L.U32 R4, R3, 0x2, RZ 
   0x0000000202156870 <+1136>:	IADD3 R4, P0, R18, R4, RZ 
   0x0000000202156880 <+1152>:	IADD3.X R5, R17, R5, RZ, P0, !PT 
   0x0000000202156890 <+1168>:	MOV R4, R4 
   0x00000002021568a0 <+1184>:	MOV R5, R5 
   0x00000002021568b0 <+1200>:	MOV R4, R4 
   0x00000002021568c0 <+1216>:	MOV R5, R5 
   0x00000002021568d0 <+1232>:	R2UR UR4, R22 
   0x00000002021568e0 <+1248>:	R2UR UR5, R23 
   0x00000002021568f0 <+1264>:	LD.E R4, [R4.64] 
   0x0000000202156900 <+1280>:	MOV R4, R4 
   0x0000000202156910 <+1296>:	SHF.R.S32.HI R5, RZ, 0x1f, R4 
   0x0000000202156920 <+1312>:	MOV R4, R4 
   0x0000000202156930 <+1328>:	MOV R5, R5 
   0x0000000202156940 <+1344>:	S2R R3, SR_TID.X 
   0x0000000202156950 <+1360>:	MOV R3, R3 
   0x0000000202156960 <+1376>:	MOV R3, R3 
   0x0000000202156970 <+1392>:	MOV R3, R3 
   0x0000000202156980 <+1408>:	MOV R6, RZ 
   0x0000000202156990 <+1424>:	SHF.L.U64.HI R6, R3, 0x3, R6 
   0x00000002021569a0 <+1440>:	SHF.L.U32 R3, R3, 0x3, RZ 
   0x00000002021569b0 <+1456>:	IADD3 R16, P0, R16, R3, RZ 
   0x00000002021569c0 <+1472>:	IADD3.X R3, R2, R6, RZ, P0, !PT 
   0x00000002021569d0 <+1488>:	MOV R2, R16 
   0x00000002021569e0 <+1504>:	MOV R3, R3 
   0x00000002021569f0 <+1520>:	MOV R2, R2 
   0x0000000202156a00 <+1536>:	MOV R3, R3 
   0x0000000202156a10 <+1552>:	R2UR UR4, R22 
   0x0000000202156a20 <+1568>:	R2UR UR5, R23 
   0x0000000202156a30 <+1584>:	ST.E.64 [R2.64], R4 
   0x0000000202156a40 <+1600>:	MEMBAR.SC.VC 
   0x0000000202156a50 <+1616>:	ERRBAR 
   0x0000000202156a60 <+1632>:	EXIT 
   0x0000000202156a70 <+1648>:	MEMBAR.SC.VC 
   0x0000000202156a80 <+1664>:	ERRBAR 
   0x0000000202156a90 <+1680>:	EXIT 
   0x0000000202156aa0 <+1696>:	BRA 0x6a0
   0x0000000202156ab0 <+1712>:	NOP
   0x0000000202156ac0 <+1728>:	NOP
   0x0000000202156ad0 <+1744>:	NOP
   0x0000000202156ae0 <+1760>:	NOP
   0x0000000202156af0 <+1776>:	NOP
   0x0000000202156b00 <+1792>:	NOP
   0x0000000202156b10 <+1808>:	NOP
   0x0000000202156b20 <+1824>:	NOP
   0x0000000202156b30 <+1840>:	NOP
   0x0000000202156b40 <+1856>:	NOP
   0x0000000202156b50 <+1872>:	NOP
   0x0000000202156b60 <+1888>:	NOP
   0x0000000202156b70 <+1904>:	NOP
End of assembler dump.

```

`info register` at the callsite: 
```
(cuda-gdb) info register 
pc             0x2021567c0         0x2021567c0 <test_atomic(long*, unsigned int)+960>
errorpc        <unavailable>
R0             0x0                 0
R1             0xfffdc0            16776640
R2             0x2                 2
R3             0x0                 0
R4             0x52e0000           86900736
R5             0x2                 2
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
R17            0x2                 2
R18            0x52e0000           86900736
R19            0x40                64
R20            0x21567d0           34957264
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
--Type <RET> for more, q to quit, c to continue without paging--
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
--Type <RET> for more, q to quit, c to continue without paging--
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
--Type <RET> for more, q to quit, c to continue without paging--
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
--Type <RET> for more, q to quit, c to continue without paging--
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
--Type <RET> for more, q to quit, c to continue without paging--
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

```

After the call is executed, notice that call.abs.noinc 0x0 jumps to a different function:
```
(cuda-gdb) disas 
Dump of assembler code for function _Z9atomicFooPi:
   0x0000000202157400 <+0>:	ISETP.NE.U32.AND P0, PT, RZ, UR2, PT 
   0x0000000202157410 <+16>:	@P0 BRA 0x140 
   0x0000000202157420 <+32>:	BMOV.32 B0, 0xffffffff 
   0x0000000202157430 <+48>:	BMOV.32.CLEAR B1, B0 
   0x0000000202157440 <+64>:	BMOV.32.CLEAR B2, B1 
   0x0000000202157450 <+80>:	BMOV.32.CLEAR B3, B2 
   0x0000000202157460 <+96>:	BMOV.32.CLEAR B4, B3 
   0x0000000202157470 <+112>:	BMOV.32.CLEAR B5, B4 
   0x0000000202157480 <+128>:	BMOV.32.CLEAR B6, B5 
   0x0000000202157490 <+144>:	BMOV.32.CLEAR B7, B6 
   0x00000002021574a0 <+160>:	BMOV.32.CLEAR B8, B7 
   0x00000002021574b0 <+176>:	BMOV.32.CLEAR B9, B8 
   0x00000002021574c0 <+192>:	BMOV.32.CLEAR B10, B9 
   0x00000002021574d0 <+208>:	BMOV.32.CLEAR B11, B10 
   0x00000002021574e0 <+224>:	BMOV.32.CLEAR B12, B11 
   0x00000002021574f0 <+240>:	BMOV.32.CLEAR B13, B12 
   0x0000000202157500 <+256>:	BMOV.32.CLEAR B14, B13 
   0x0000000202157510 <+272>:	BMOV.32.CLEAR B15, B14 
   0x0000000202157520 <+288>:	BMOV.32 B15, 0x0 
   0x0000000202157530 <+304>:	UMOV UR2, 0x1 
   0x0000000202157540 <+320>:	IADD3 R1, R1, -0x10, RZ 
   0x0000000202157550 <+336>:	S2R R0, SR_LMEMHIOFF 
   0x0000000202157560 <+352>:	ISETP.GE.U32.AND P0, PT, R1, R0, PT 
   0x0000000202157570 <+368>:	@P0 BRA 0x190 
   0x0000000202157580 <+384>:	BPT.TRAP 0x1 
   0x0000000202157590 <+400>:	STL [R1+0xc], R21 
   0x00000002021575a0 <+416>:	STL [R1+0x8], R20 
   0x00000002021575b0 <+432>:	STL [R1+0x4], R16 
   0x00000002021575c0 <+448>:	STL [R1], R2 
   0x00000002021575d0 <+464>:	MOV R4, R4 
   0x00000002021575e0 <+480>:	MOV R5, R5 
   0x00000002021575f0 <+496>:	MOV R0, R4 
   0x0000000202157600 <+512>:	MOV R4, R5 
   0x0000000202157610 <+528>:	MOV R16, R0 
   0x0000000202157620 <+544>:	MOV R2, R4 
=> 0x0000000202157630 <+560>:	MOV R4, R16 
   0x0000000202157640 <+576>:	MOV R5, R2 
   0x0000000202157650 <+592>:	MOV R6, 0x1 
   0x0000000202157660 <+608>:	MOV R20, 0x0 
   0x0000000202157670 <+624>:	MOV R21, 0x0 
   0x0000000202157680 <+640>:	CALL.ABS.NOINC 0x0 
   0x0000000202157690 <+656>:	MOV R4, R4 
   0x00000002021576a0 <+672>:	MOV R4, R4 
   0x00000002021576b0 <+688>:	BRA 0x2c0 
   0x00000002021576c0 <+704>:	LDL R2, [R1] 
   0x00000002021576d0 <+720>:	LDL R16, [R1+0x4] 
   0x00000002021576e0 <+736>:	LDL R20, [R1+0x8] 
   0x00000002021576f0 <+752>:	LDL R21, [R1+0xc] 
   0x0000000202157700 <+768>:	IADD3 R1, R1, 0x10, RZ 
   0x0000000202157710 <+784>:	RET.ABS.NODEC R20 0x0 
   0x0000000202157720 <+800>:	BRA 0x320
   0x0000000202157730 <+816>:	NOP
   0x0000000202157740 <+832>:	NOP
   0x0000000202157750 <+848>:	NOP
   0x0000000202157760 <+864>:	NOP
   0x0000000202157770 <+880>:	NOP
   0x0000000202157780 <+896>:	NOP
   0x0000000202157790 <+912>:	NOP
   0x00000002021577a0 <+928>:	NOP
   0x00000002021577b0 <+944>:	NOP
   0x00000002021577c0 <+960>:	NOP
   0x00000002021577d0 <+976>:	NOP
   0x00000002021577e0 <+992>:	NOP

```

A typical calling snippet is like this, with debug mode

```
   0x0000000202157590 <+400>:	STL [R1+0xc], R21 
   0x00000002021575a0 <+416>:	STL [R1+0x8], R20 
   0x00000002021575b0 <+432>:	STL [R1+0x4], R16 
   0x00000002021575c0 <+448>:	STL [R1], R2 
   0x00000002021575d0 <+464>:	MOV R4, R4 
   0x00000002021575e0 <+480>:	MOV R5, R5 
   0x00000002021575f0 <+496>:	MOV R0, R4 
   0x0000000202157600 <+512>:	MOV R4, R5 
   0x0000000202157610 <+528>:	MOV R16, R0 
   0x0000000202157620 <+544>:	MOV R2, R4 
   0x0000000202157630 <+560>:	MOV R4, R16 
   0x0000000202157640 <+576>:	MOV R5, R2 
   0x0000000202157650 <+592>:	MOV R6, 0x1 
   0x0000000202157660 <+608>:	MOV R20, 0x0 
   0x0000000202157670 <+624>:	MOV R21, 0x0 
   0x0000000202157680 <+640>:	CALL.ABS.NOINC 0x0 

```
Moreover, if you set the breakpoint at cuda-c's function call, it will set the breakpoint here: 

```
   0x00000002021575d0 <+464>:	MOV R4, R4 
   0x00000002021575e0 <+480>:	MOV R5, R5 
   0x00000002021575f0 <+496>:	MOV R0, R4 
   0x0000000202157600 <+512>:	MOV R4, R5 
   0x0000000202157610 <+528>:	MOV R16, R0 
   0x0000000202157620 <+544>:	MOV R2, R4 
=> 0x0000000202157630 <+560>:	MOV R4, R16 
   0x0000000202157640 <+576>:	MOV R5, R2 
   0x0000000202157650 <+592>:	MOV R6, 0x1 
   0x0000000202157660 <+608>:	MOV R20, 0x0 
   0x0000000202157670 <+624>:	MOV R21, 0x0 
   0x0000000202157680 <+640>:	CALL.ABS.NOINC 0x0 

```
(the actual breakpoint maybe one instruction before)

`info register` at this point gives: 
```
(cuda-gdb) info register
pc             0x202157630         0x202157630 <atomicFoo(int*)+560>
errorpc        <unavailable>
R0             0x52e0000           86900736
R1             0xfffdb0            16776624
R2             0x2                 2
R3             0x0                 0
R4             0x2                 2
R5             0x2                 2
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
R16            0x52e0000           86900736
R17            0x2                 2
R18            0x52e0000           86900736
R19            0x40                64
R20            0x21567d0           34957264
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
--Type <RET> for more, q to quit, c to continue without paging--q
Quit
```
R20 at least now is the return address of the function 

R2 looks like the VA base pointer of the current image?

R6 is susceptible, 
it might be the text section (segment) number of the function to jump to, 
and the abs address is the offset to that segment.
Because this call's R6 is 0x1, previous call's R6 is 0x0.. 
OR: it might just be argument 1, because we are calling `atomicAdd(a, 1)` :-P.

stepi until before the call.abs.noinc: 
```
(cuda-gdb) x/i $pc
=> 0x202157680 <_Z9atomicFooPi+640>:	CALL.ABS.NOINC 0x0 
(cuda-gdb) disas 
Dump of assembler code for function _Z9atomicFooPi:
   0x0000000202157400 <+0>:	ISETP.NE.U32.AND P0, PT, RZ, UR2, PT 
   0x0000000202157410 <+16>:	@P0 BRA 0x140 
   0x0000000202157420 <+32>:	BMOV.32 B0, 0xffffffff 
   0x0000000202157430 <+48>:	BMOV.32.CLEAR B1, B0 
   0x0000000202157440 <+64>:	BMOV.32.CLEAR B2, B1 
   0x0000000202157450 <+80>:	BMOV.32.CLEAR B3, B2 
   0x0000000202157460 <+96>:	BMOV.32.CLEAR B4, B3 
   0x0000000202157470 <+112>:	BMOV.32.CLEAR B5, B4 
   0x0000000202157480 <+128>:	BMOV.32.CLEAR B6, B5 
   0x0000000202157490 <+144>:	BMOV.32.CLEAR B7, B6 
   0x00000002021574a0 <+160>:	BMOV.32.CLEAR B8, B7 
   0x00000002021574b0 <+176>:	BMOV.32.CLEAR B9, B8 
   0x00000002021574c0 <+192>:	BMOV.32.CLEAR B10, B9 
   0x00000002021574d0 <+208>:	BMOV.32.CLEAR B11, B10 
   0x00000002021574e0 <+224>:	BMOV.32.CLEAR B12, B11 
   0x00000002021574f0 <+240>:	BMOV.32.CLEAR B13, B12 
   0x0000000202157500 <+256>:	BMOV.32.CLEAR B14, B13 
   0x0000000202157510 <+272>:	BMOV.32.CLEAR B15, B14 
   0x0000000202157520 <+288>:	BMOV.32 B15, 0x0 
   0x0000000202157530 <+304>:	UMOV UR2, 0x1 
   0x0000000202157540 <+320>:	IADD3 R1, R1, -0x10, RZ 
   0x0000000202157550 <+336>:	S2R R0, SR_LMEMHIOFF 
   0x0000000202157560 <+352>:	ISETP.GE.U32.AND P0, PT, R1, R0, PT 
   0x0000000202157570 <+368>:	@P0 BRA 0x190 
   0x0000000202157580 <+384>:	BPT.TRAP 0x1 
   0x0000000202157590 <+400>:	STL [R1+0xc], R21 
   0x00000002021575a0 <+416>:	STL [R1+0x8], R20 
   0x00000002021575b0 <+432>:	STL [R1+0x4], R16 
   0x00000002021575c0 <+448>:	STL [R1], R2 
   0x00000002021575d0 <+464>:	MOV R4, R4 
   0x00000002021575e0 <+480>:	MOV R5, R5 
   0x00000002021575f0 <+496>:	MOV R0, R4 
   0x0000000202157600 <+512>:	MOV R4, R5 
   0x0000000202157610 <+528>:	MOV R16, R0 
   0x0000000202157620 <+544>:	MOV R2, R4 
   0x0000000202157630 <+560>:	MOV R4, R16 
   0x0000000202157640 <+576>:	MOV R5, R2 
   0x0000000202157650 <+592>:	MOV R6, 0x1 
   0x0000000202157660 <+608>:	MOV R20, 0x0 
   0x0000000202157670 <+624>:	MOV R21, 0x0 
=> 0x0000000202157680 <+640>:	CALL.ABS.NOINC 0x0 
   0x0000000202157690 <+656>:	MOV R4, R4 
   0x00000002021576a0 <+672>:	MOV R4, R4 
   0x00000002021576b0 <+688>:	BRA 0x2c0 
   0x00000002021576c0 <+704>:	LDL R2, [R1] 
   0x00000002021576d0 <+720>:	LDL R16, [R1+0x4] 
   0x00000002021576e0 <+736>:	LDL R20, [R1+0x8] 
   0x00000002021576f0 <+752>:	LDL R21, [R1+0xc] 
   0x0000000202157700 <+768>:	IADD3 R1, R1, 0x10, RZ 
   0x0000000202157710 <+784>:	RET.ABS.NODEC R20 0x0 
   0x0000000202157720 <+800>:	BRA 0x320
   0x0000000202157730 <+816>:	NOP
   0x0000000202157740 <+832>:	NOP
   0x0000000202157750 <+848>:	NOP
   0x0000000202157760 <+864>:	NOP
   0x0000000202157770 <+880>:	NOP
   0x0000000202157780 <+896>:	NOP
   0x0000000202157790 <+912>:	NOP
   0x00000002021577a0 <+928>:	NOP
   0x00000002021577b0 <+944>:	NOP
   0x00000002021577c0 <+960>:	NOP
   0x00000002021577d0 <+976>:	NOP
   0x00000002021577e0 <+992>:	NOP
--Type <RET> for more, q to quit, c to continue without paging--
   0x00000002021577f0 <+1008>:	NOP
End of assembler dump.

```

NOW, `info register` gives: 
```
(cuda-gdb) info register 
pc             0x202157680         0x202157680 <atomicFoo(int*)+640>
errorpc        <unavailable>
R0             0x52e0000           86900736
R1             0xfffdb0            16776624
R2             0x2                 2
R3             0x0                 0
R4             0x52e0000           86900736
R5             0x2                 2
R6             0x1                 1
R7             0x0                 0
R8             0x0                 0
R9             0x0                 0
R10            0x0                 0
R11            0x0                 0
R12            0x0                 0
R13            0x0                 0
R14            0x0                 0
R15            0x0                 0
R16            0x52e0000           86900736
R17            0x2                 2
R18            0x52e0000           86900736
R19            0x40                64
R20            0x2157690           34961040
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
--Type <RET> for more, q to quit, c to continue without paging--c
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

```

Compare: 
New: 
```
(cuda-gdb) info register 
pc             0x202157680         0x202157680 <atomicFoo(int*)+640>
errorpc        <unavailable>
R0             0x52e0000           86900736
R1             0xfffdb0            16776624
R2             0x2                 2
R3             0x0                 0
R4             0x52e0000           86900736
R5             0x2                 2
R6             0x1                 1
R7             0x0                 0
R8             0x0                 0
R9             0x0                 0
R10            0x0                 0
R11            0x0                 0
R12            0x0                 0
R13            0x0                 0
R14            0x0                 0
R15            0x0                 0
R16            0x52e0000           86900736
R17            0x2                 2
R18            0x52e0000           86900736
R19            0x40                64
R20            0x2157690           34961040
R21            0x2                 2
```
Prev:
```
pc             0x2021567c0         0x2021567c0 <test_atomic(long*, unsigned int)+960>
errorpc        <unavailable>
R0             0x0                 0
R1             0xfffdc0            16776640
R2             0x2                 2
R3             0x0                 0
R4             0x52e0000           86900736
R5             0x2                 2
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
R17            0x2                 2
R18            0x52e0000           86900736
R19            0x40                64
R20            0x21567d0           34957264
R21            0x2                 2
```
Prev calls to: 0x0000000202157400 atomicFoo, 

Next calls to: `=> 0x202158100 <_ZN44_INTERNAL_b506f649_13_testatomic_cu_555bfaa09atomicAddEPii>:	ISETP.NE.U32.AND P0, PT, RZ, UR2, PT `



Return address is inferred to be {R21, R20}, it makes so much sense! 
What is {R17, R16}? It's 0x2050e0000 in Prev and 0x2052e0000 in New. 
But I think it's a pointer pointing to constant memory... 

What is {R1, R0}? 0x00FF_FDC0_0000_0000 in Prev, 0x00ff_fdb0_052e_0000 in New. 
```
(cuda-gdb) bt
#0  _INTERNAL_b506f649_13_testatomic_cu_555bfaa0::atomicAdd (address=<unavailable>, val=<unavailable>) at /usr/local/cuda-12.6/bin/../targets/aarch64-linux/include/device_atomic_functions.hpp:105
#1  0x0000000202157690 in atomicFoo (a=0x2052e0000) at ./testatomic.cu:9
#2  0x00000002021567d0 in test_atomic<<<(1,1,1),(64,1,1)>>> (out=0x2050e0000, count=64) at ./testatomic.cu:17
(cuda-gdb) frame 2
#2  0x00000002021567d0 in test_atomic<<<(1,1,1),(64,1,1)>>> (out=0x2050e0000, count=64) at ./testatomic.cu:17
17	    int r = atomicFoo(&(array[threadIdx.x]));
(cuda-gdb) print out 
$11 = (@generic int64_t * @parameter) 0x2050e0000

```

Interestingly:
```
(cuda-gdb) print array 
$13 = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63}
(cuda-gdb) print &array 
$14 = (@constant int (*)[64]) 0x2052e0000

```

If you wonder what is `a`:
```
(cuda-gdb) print a
$10 = (@generic int * @register) 0x2052e0000
(cuda-gdb) 

```
It's R4 + R5!!
So we infer that R6 is the second argument, sad...

The Next candidate is R0 and R1, what is R1...

Base on the prologue of the function: 
```
=> 0x0000000202158240 <+320>:	IADD3 R1, R1, -0x18, RZ 
   0x0000000202158250 <+336>:	S2R R0, SR_LMEMHIOFF 
   0x0000000202158260 <+352>:	ISETP.GE.U32.AND P0, PT, R1, R0, PT 
   0x0000000202158270 <+368>:	@P0 BRA 0x190 

```
R1 is somehow related to the available stack memory size, or something related to this...
SR_LMEMHIOFF is: 
```
(cuda-gdb) p/x $R0  
$16 = 0xfff9c0
```


Register calling convention: 
```
// at previous call frame
(cuda-gdb) info register 
pc             0x202157690         0x202157690 <atomicFoo(int*)+656>
errorpc        <unavailable>
R0             <not saved>
R1             0xfffdb0            16776624
R2             0x2                 2
R3             <not saved>
R4             <not saved>
R5             <not saved>
R6             <not saved>
R7             <not saved>
R8             <not saved>
R9             <not saved>
R10            <not saved>
R11            <not saved>
R12            <not saved>
R13            <not saved>
R14            <not saved>
R15            <not saved>
R16            0x52e0000           86900736
R17            0x2                 2
R18            0x52e0000           86900736
R19            0x40                64
R20            0x2157690           34961040
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
R32            <not saved>
R33            <not saved>
R34            <not saved>
R35            <not saved>
R36            0x0                 0
R37            0x0                 0
R38            0x0                 0
R39            0x0                 0
R40            <not saved>
R41            <not saved>
R42            <not saved>
R43            <not saved>
R44            0x0                 0
R45            0x0                 0
R46            0x0                 0
R47            0x0                 0
R48            <not saved>
R49            <not saved>
R50            <not saved>
R51            <not saved>
R52            0x0                 0
R53            0x0                 0
R54            0x0                 0
R55            0x0                 0
R56            <not saved>
R57            <not saved>
R58            <not saved>
R59            <not saved>
R60            0x0                 0
R61            0x0                 0
--Type <RET> for more, q to quit, c to continue without paging--
R62            0x0                 0
R63            0x0                 0
R64            <not saved>
R65            <not saved>
R66            <not saved>
R67            <not saved>
R68            0x0                 0
R69            0x0                 0
R70            0x0                 0
R71            0x0                 0
R72            <not saved>
R73            <not saved>
R74            <not saved>
R75            <not saved>
R76            0x0                 0
R77            0x0                 0
R78            0x0                 0
R79            0x0                 0
R80            <not saved>
R81            <not saved>
R82            <not saved>
R83            <not saved>
R84            0x0                 0
R85            0x0                 0
R86            0x0                 0
R87            0x0                 0
R88            <not saved>
R89            <not saved>
R90            <not saved>
R91            <not saved>
R92            0x0                 0
R93            0x0                 0
R94            0x0                 0
R95            0x0                 0
R96            <not saved>
R97            <not saved>
R98            <not saved>
R99            <not saved>
R100           0x0                 0
R101           0x0                 0
R102           0x0                 0
R103           0x0                 0
R104           <not saved>
R105           <not saved>
R106           <not saved>
R107           <not saved>
R108           0x0                 0
R109           0x0                 0
R110           0x0                 0
R111           0x0                 0
R112           <not saved>
R113           <not saved>
R114           <not saved>
R115           <not saved>
R116           0x0                 0
R117           0x0                 0
R118           0x0                 0
R119           0x0                 0
R120           <not saved>
R121           <not saved>
R122           <not saved>
R123           <not saved>
R124           0x0                 0
R125           0x0                 0
--Type <RET> for more, q to quit, c to continue without paging--c
R126           0x0                 0
R127           0x0                 0
R128           <not saved>
R129           <not saved>
R130           <not saved>
R131           <not saved>
R132           0x0                 0
R133           0x0                 0
R134           0x0                 0
R135           0x0                 0
R136           <not saved>
R137           <not saved>
R138           <not saved>
R139           <not saved>
R140           0x0                 0
R141           0x0                 0
R142           0x0                 0
R143           0x0                 0
R144           <not saved>
R145           <not saved>
R146           <not saved>
R147           <not saved>
R148           0x0                 0
R149           0x0                 0
R150           0x0                 0
R151           0x0                 0
R152           <not saved>
R153           <not saved>
R154           <not saved>
R155           <not saved>
R156           0x0                 0
R157           0x0                 0
R158           0x0                 0
R159           0x0                 0
R160           <not saved>
R161           <not saved>
R162           <not saved>
R163           <not saved>
R164           0x0                 0
R165           0x0                 0
R166           0x0                 0
R167           0x0                 0
R168           <not saved>
R169           <not saved>
R170           <not saved>
R171           <not saved>
R172           0x0                 0
R173           0x0                 0
R174           0x0                 0
R175           0x0                 0
R176           <not saved>
R177           <not saved>
R178           <not saved>
R179           <not saved>
R180           0x0                 0
R181           0x0                 0
R182           0x0                 0
R183           0x0                 0
R184           <not saved>
R185           <not saved>
R186           <not saved>
R187           <not saved>
R188           0x0                 0
R189           0x0                 0
R190           0x0                 0
R191           0x0                 0
R192           <not saved>
R193           <not saved>
R194           <not saved>
R195           <not saved>
R196           0x0                 0
R197           0x0                 0
R198           0x0                 0
R199           0x0                 0
R200           <not saved>
R201           <not saved>
R202           <not saved>
R203           <not saved>
R204           0x0                 0
R205           0x0                 0
R206           0x0                 0
R207           0x0                 0
R208           <not saved>
R209           <not saved>
R210           <not saved>
R211           <not saved>
R212           0x0                 0
R213           0x0                 0
R214           0x0                 0
R215           0x0                 0
R216           <not saved>
R217           <not saved>
R218           <not saved>
R219           <not saved>
R220           0x0                 0
R221           0x0                 0
R222           0x0                 0
R223           0x0                 0
R224           <not saved>
R225           <not saved>
R226           <not saved>
R227           <not saved>
R228           0x0                 0
R229           0x0                 0
R230           0x0                 0
R231           0x0                 0
R232           <not saved>
R233           <not saved>
R234           <not saved>
R235           <not saved>
R236           0x0                 0
R237           0x0                 0
R238           0x0                 0
R239           0x0                 0
R240           <not saved>
R241           <not saved>
R242           <not saved>
R243           <not saved>
R244           0x0                 0
R245           0x0                 0
R246           0x0                 0
R247           0x0                 0
R248           <not saved>
R249           <not saved>
R250           <not saved>
R251           <not saved>
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
UR4            <not saved>
UR5            <not saved>
UR6            <not saved>
UR7            <not saved>
UR8            <not saved>
UR9            <not saved>
UR10           <not saved>
UR11           <not saved>
UR12           <not saved>
UR13           <not saved>
UR14           <not saved>
UR15           <not saved>
UR16           <not saved>
UR17           <not saved>
UR18           <not saved>
UR19           <not saved>
UR20           <not saved>
UR21           <not saved>
UR22           <not saved>
UR23           <not saved>
UR24           <not saved>
UR25           <not saved>
UR26           <not saved>
UR27           <not saved>
UR28           <not saved>
UR29           <not saved>
UR30           <not saved>
UR31           <not saved>
UR32           <not saved>
UR33           <not saved>
UR34           <not saved>
UR35           <not saved>
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


OHHH, cuda does dynamic linking on kernel launch in debug mode!!!: 
```
(cuda-gdb) x/x 0x0000000202157680 
0x202157680 <_Z9atomicFooPi+640>:	0x00007943
(cuda-gdb) x/x 0x0000000202157684 
0x202157684 <_Z9atomicFooPi+644>:	0x02158100
(cuda-gdb) x/x 0x0000000202157688 
0x202157688 <_Z9atomicFooPi+648>:	0x03c00002
(cuda-gdb) x/x 0x000000020215768c 
0x20215768c <_Z9atomicFooPi+652>:	0x003fde00

call.abs.noinc to: 0x202158100
0x02158100 00007943
0x003fde00 03c00002

(cuda-gdb) x/x 0x00000002021567c0  
0x2021567c0 <_Z11test_atomicPlj+960>:	0x00007943
(cuda-gdb) x/x 0x00000002021567c4 
0x2021567c4 <_Z11test_atomicPlj+964>:	0x02157400
(cuda-gdb) x/x 0x00000002021567c8 
0x2021567c8 <_Z11test_atomicPlj+968>:	0x03c00002
(cuda-gdb) x/x 0x00000002021567cc 
0x2021567cc <_Z11test_atomicPlj+972>:	0x003fde00
(cuda-gdb) 


call.abs.noinc to: 0x0000000202157400
0x02157400_00007943
0x003fde00_03c00002

vs

/*0280*/                   CALL.ABS.NOINC 0x0 ;                           /* 0x0000000000007943 */
                                                                          /* 0x003fde0003c00000 */
```


Look at the cubin section table!
```
jetson@yahboom:~/workspace/experiment/test$ readelf -SW testatomic87.cubin 
There are 36 section headers, starting at offset 0x7f80:

Section Headers:
  [Nr] Name              Type            Address          Off    Size   ES Flg Lk Inf Al
  [ 0]                   NULL            0000000000000000 000000 000000 00      0   0  0
  [ 1] .shstrtab         STRTAB          0000000000000000 000040 00040f 00      0   0  1
  [ 2] .strtab           STRTAB          0000000000000000 00044f 000484 00      0   0  1
  [ 3] .symtab           SYMTAB          0000000000000000 0008d8 000228 18      2  21  8
  [ 4] .debug_frame      PROGBITS        0000000000000000 000b00 002af0 00      0   0  1
  [ 5] .debug_line       PROGBITS        0000000000000000 0035f0 0001ec 00      0   0  1
  [ 6] .nv_debug_line_sass PROGBITS        0000000000000000 0037dc 000148 00      0   0  1
  [ 7] .nv_debug_ptx_txt PROGBITS        0000000000000000 003924 0013a7 00      0   0  1
  [ 8] .nv_debug_info_reg_sass PROGBITS        0000000000000000 004ccb 00050f 00      0   0  1
  [ 9] .nv_debug_info_reg_type PROGBITS        0000000000000000 0051da 0000b7 00      0   0  1
  [10] .debug_abbrev     PROGBITS        0000000000000000 005291 000101 00      0   0  1
  [11] .debug_info       PROGBITS        0000000000000000 005392 0012b7 00      0   0  1
  [12] .debug_macinfo    PROGBITS        0000000000000000 006649 000001 00      0   0  1
  [13] .nv.info          LOPROC+0        0000000000000000 00664c 00007c 00      3   0  4
  [14] .nv.info._Z9atomicFooPi LOPROC+0        0000000000000000 0066c8 000014 00   I  3  32  4
  [15] .nv.info._Z11test_atomicPlj LOPROC+0        0000000000000000 0066dc 000054 00   I  3  33  4
  [16] .nv.info.__iAtomicAdd LOPROC+0        0000000000000000 006730 000014 00   I  3  34  4
  [17] .nv.info._ZN44_INTERNAL_b506f649_13_testatomic_cu_555bfaa09atomicAddEPii LOPROC+0        0000000000000000 006744 000014 00   I  3  35  4
  [18] .nv.callgraph     LOPROC+0x1      0000000000000000 006758 000038 08      3   0  4
  [19] .nv.rel.action    LOPROC+0xb      0000000000000000 006790 000010 08      0   0  8
  [20] .rela.text._Z9atomicFooPi RELA            0000000000000000 0067a0 000030 18   I  3  32  8
  [21] .rel.text._Z9atomicFooPi REL             0000000000000000 0067d0 000010 10   I  3  32  8
  [22] .rel.text._Z11test_atomicPlj REL             0000000000000000 0067e0 000010 10   I  3  33  8
  [23] .rela.text._Z11test_atomicPlj RELA            0000000000000000 0067f0 000030 18   I  3  33  8
  [24] .rela.text._ZN44_INTERNAL_b506f649_13_testatomic_cu_555bfaa09atomicAddEPii RELA            0000000000000000 006820 000030 18   I  3  35  8
  [25] .rel.text._ZN44_INTERNAL_b506f649_13_testatomic_cu_555bfaa09atomicAddEPii REL             0000000000000000 006850 000010 10   I  3  35  8
  [26] .rel.debug_line   REL             0000000000000000 006860 000030 10   I  3   5  8
  [27] .rel.nv_debug_line_sass REL             0000000000000000 006890 000040 10   I  3   6  8
  [28] .rela.debug_info  RELA            0000000000000000 0068d0 0000d8 18   I  3  11  8
  [29] .rel.debug_frame  REL             0000000000000000 0069a8 000040 10   I  3   4  8
  [30] .nv.constant3     PROGBITS        0000000000000000 0069e8 000100 00   A  0   0  4
  [31] .nv.constant0._Z11test_atomicPlj PROGBITS        0000000000000000 006ae8 00016c 00  AI  0  33  4
readelf: Warning: [32]: Unexpected value (402653205) in info field.
  [32] .text._Z9atomicFooPi PROGBITS        0000000000000000 006c80 000400 00  AX  3 402653205 128
readelf: Warning: [33]: Unexpected value (436207638) in info field.
  [33] .text._Z11test_atomicPlj PROGBITS        0000000000000000 007080 000780 00  AX  3 436207638 128
readelf: Warning: [34]: Unexpected value (402653191) in info field.
  [34] .text.__iAtomicAdd PROGBITS        0000000000000000 007800 000300 00  AX  3 402653191 128
readelf: Warning: [35]: Unexpected value (402653188) in info field.
  [35] .text._ZN44_INTERNAL_b506f649_13_testatomic_cu_555bfaa09atomicAddEPii PROGBITS        0000000000000000 007b00 000480 00  AX  3 402653188 128
Key to Flags:
  W (write), A (alloc), X (execute), M (merge), S (strings), I (info),
  L (link order), O (extra OS processing required), G (group), T (TLS),
  C (compressed), x (unknown), o (OS specific), E (exclude),
  p (processor specific)

```

```
jetson@yahboom:~/workspace/experiment/test$ cuobjdump --dump-elf testatomic87.cubin 

64bit elf: type=2, abi=7, sm=87, toolkit=126, flags = 0x570557
Sections:
Index Offset   Size ES Align                      Type    Flags Link     Info Name
    1     40    40f  0  1                       STRTAB        0    0        0 .shstrtab
    2    44f    484  0  1                       STRTAB        0    0        0 .strtab
    3    8d8    228 18  8                       SYMTAB        0    2       15 .symtab
    4    b00   2af0  0  1                     PROGBITS        0    0        0 .debug_frame
    5   35f0    1ec  0  1                     PROGBITS        0    0        0 .debug_line
    6   37dc    148  0  1                     PROGBITS        0    0        0 .nv_debug_line_sass
    7   3924   13a7  0  1                     PROGBITS        0    0        0 .nv_debug_ptx_txt
    8   4ccb    50f  0  1                     PROGBITS        0    0        0 .nv_debug_info_reg_sass
    9   51da     b7  0  1                     PROGBITS        0    0        0 .nv_debug_info_reg_type
    a   5291    101  0  1                     PROGBITS        0    0        0 .debug_abbrev
    b   5392   12b7  0  1                     PROGBITS        0    0        0 .debug_info
    c   6649      1  0  1                     PROGBITS        0    0        0 .debug_macinfo
    d   664c     7c  0  4                    CUDA_INFO        0    3        0 .nv.info
    e   66c8     14  0  4                    CUDA_INFO       40    3       20 .nv.info._Z9atomicFooPi
    f   66dc     54  0  4                    CUDA_INFO       40    3       21 .nv.info._Z11test_atomicPlj
   10   6730     14  0  4                    CUDA_INFO       40    3       22 .nv.info.__iAtomicAdd
   11   6744     14  0  4                    CUDA_INFO       40    3       23 .nv.info._ZN44_INTERNAL_b506f649_13_testatomic_cu_555bfaa09atomicAddEPii
   12   6758     38  8  4               CUDA_CALLGRAPH        0    3        0 .nv.callgraph
   13   6790     10  8  8               CUDA_RELOCINFO        0    0        0 .nv.rel.action
   14   67a0     30 18  8                         RELA       40    3       20 .rela.text._Z9atomicFooPi
   15   67d0     10 10  8                          REL       40    3       20 .rel.text._Z9atomicFooPi
   16   67e0     10 10  8                          REL       40    3       21 .rel.text._Z11test_atomicPlj
   17   67f0     30 18  8                         RELA       40    3       21 .rela.text._Z11test_atomicPlj
   18   6820     30 18  8                         RELA       40    3       23 .rela.text._ZN44_INTERNAL_b506f649_13_testatomic_cu_555bfaa09atomicAddEPii
   19   6850     10 10  8                          REL       40    3       23 .rel.text._ZN44_INTERNAL_b506f649_13_testatomic_cu_555bfaa09atomicAddEPii
   1a   6860     30 10  8                          REL       40    3        5 .rel.debug_line
   1b   6890     40 10  8                          REL       40    3        6 .rel.nv_debug_line_sass
   1c   68d0     d8 18  8                         RELA       40    3        b .rela.debug_info
   1d   69a8     40 10  8                          REL       40    3        4 .rel.debug_frame
   1e   69e8    100  0  4                     PROGBITS        2    0        0 .nv.constant3
   1f   6ae8    16c  0  4                     PROGBITS       42    0       21 .nv.constant0._Z11test_atomicPlj
   20   6c80    400  0 80                     PROGBITS        6    3 18000015 .text._Z9atomicFooPi
   21   7080    780  0 80                     PROGBITS        6    3 1a000016 .text._Z11test_atomicPlj
   22   7800    300  0 80                     PROGBITS        6    3 18000007 .text.__iAtomicAdd
   23   7b00    480  0 80                     PROGBITS        6    3 18000004 .text._ZN44_INTERNAL_b506f649_13_testatomic_cu_555bfaa09atomicAddEPii

.section .strtab

```


I tried to modify `testatomic87.cubin` offset 0000_6F00 + 0x8, to be 0x02, 
but after the modification, cuobjdump and nvdisasm fails to disassemble the elf, 
there might be some sort of checksum mechanism that protects this...


For the ret.abs.nodec: 

```
   0x0000000202158480 <+896>:	RET.ABS.NODEC R20 0x0 

(cuda-gdb) x/x 0x0000000202158480 
0x202158480 <_ZN44_INTERNAL_b506f649_13_testatomic_cu_555bfaa09atomicAddEPii+896>:	0x14007950
(cuda-gdb) x/x 0x0000000202158484 
0x202158484 <_ZN44_INTERNAL_b506f649_13_testatomic_cu_555bfaa09atomicAddEPii+900>:	0x00000000
(cuda-gdb) x/x 0x0000000202158488 
0x202158488 <_ZN44_INTERNAL_b506f649_13_testatomic_cu_555bfaa09atomicAddEPii+904>:	0x03e00000
(cuda-gdb) x/x 0x000000020215848c 
0x20215848c <_ZN44_INTERNAL_b506f649_13_testatomic_cu_555bfaa09atomicAddEPii+908>:	0x003fde00
(cuda-gdb) 

```
Obviously the return instruction does not perform relocation...... Luckily......

And for return address loading: 
```
   0x00000002021583c0 <+704>:	MOV R20, 0x0 
   0x00000002021583d0 <+720>:	MOV R21, 0x0 
   0x00000002021583e0 <+736>:	CALL.ABS.NOINC 0x0 

(cuda-gdb) x/x 0x00000002021583c0 
0x2021583c0 <_ZN44_INTERNAL_b506f649_13_testatomic_cu_555bfaa09atomicAddEPii+704>:	0x00147802
(cuda-gdb) x/x 0x00000002021583c4 
0x2021583c4 <_ZN44_INTERNAL_b506f649_13_testatomic_cu_555bfaa09atomicAddEPii+708>:	0x021583f0
(cuda-gdb) x/x 0x00000002021583c8 
0x2021583c8 <_ZN44_INTERNAL_b506f649_13_testatomic_cu_555bfaa09atomicAddEPii+712>:	0x00000f00
(cuda-gdb) x/x 0x00000002021583cc 
0x2021583cc <_ZN44_INTERNAL_b506f649_13_testatomic_cu_555bfaa09atomicAddEPii+716>:	0x003fde00
(cuda-gdb) 

compare this to 
    /*0260*/                   MOV R20, 0x0 ;                                 /* 0x0000000000147802 */
                                                                              /* 0x003fde0000000f00 */

AND: 
(cuda-gdb) si
0x00000002021583c0	107	  return __iAtomicAdd(address, val);
(cuda-gdb) x/i $pc
=> 0x2021583c0 <_ZN44_INTERNAL_b506f649_13_testatomic_cu_555bfaa09atomicAddEPii+704>:	MOV R20, 0x0 
(cuda-gdb) p/x $R20  
$17 = 0x2157690
(cuda-gdb) 

(cuda-gdb) si      
0x00000002021583d0	107	  return __iAtomicAdd(address, val);
(cuda-gdb) x/i $pc
=> 0x2021583d0 <_ZN44_INTERNAL_b506f649_13_testatomic_cu_555bfaa09atomicAddEPii+720>:	MOV R21, 0x0 
(cuda-gdb) p/x $R21
$18 = 0x2

```

Relocation is filled!!




Call sequence: 
```
=> 0x0000000202158340 <+576>:	MOV R4, R16 
   0x0000000202158350 <+592>:	MOV R5, R17 
   0x0000000202158360 <+608>:	MOV R4, R4 
   0x0000000202158370 <+624>:	MOV R5, R5 
   0x0000000202158380 <+640>:	MOV R6, R2 
   0x0000000202158390 <+656>:	MOV R4, R4 
   0x00000002021583a0 <+672>:	MOV R5, R5 
   0x00000002021583b0 <+688>:	MOV R6, R6 
   0x00000002021583c0 <+704>:	MOV R20, 0x0 
   0x00000002021583d0 <+720>:	MOV R21, 0x0 
   0x00000002021583e0 <+736>:	CALL.ABS.NOINC 0x0 

```

As we can see, {R17, R16} seems to be the constant memory base address for the function 


So... what's the difference between a CALL and a BRAnch in SASS? 

Registers before a call:
```
(cuda-gdb) info register 
pc             0x2021583e0         0x2021583e0 <_INTERNAL_b506f649_13_testatomic_cu_555bfaa0::atomicAdd(int*, int)+736>
errorpc        <unavailable>
R0             0xfff9c0            16775616
R1             0xfffd98            16776600
R2             0x1                 1
R3             0x0                 0
R4             0x52e0000           86900736
R5             0x2                 2
R6             0x1                 1
R7             0x0                 0
R8             0x0                 0
R9             0x0                 0
R10            0x0                 0
R11            0x0                 0
R12            0x0                 0
R13            0x0                 0
R14            0x0                 0
R15            0x0                 0
R16            0x52e0000           86900736
R17            0x2                 2
R18            0x52e0000           86900736
R19            0x40                64
R20            0x21583f0           34964464
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
--Type <RET> for more, q to quit, c to continue without paging--c
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

Registers after a call:
```
(cuda-gdb) si
0x0000000202158e00 in __iAtomicAdd ()
(cuda-gdb) info register 
pc             0x202158e00         0x202158e00 <__iAtomicAdd>
errorpc        <unavailable>
R0             0xfff9c0            16775616
R1             0xfffd98            16776600
R2             0x1                 1
R3             0x0                 0
R4             0x52e0000           86900736
R5             0x2                 2
R6             0x1                 1
R7             0x0                 0
R8             0x0                 0
R9             0x0                 0
R10            0x0                 0
R11            0x0                 0
R12            0x0                 0
R13            0x0                 0
R14            0x0                 0
R15            0x0                 0
R16            0x52e0000           86900736
R17            0x2                 2
R18            0x52e0000           86900736
R19            0x40                64
R20            0x21583f0           34964464
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
--Type <RET> for more, q to quit, c to continue without paging--c
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

Compare: 
```
After:
(cuda-gdb) si
0x0000000202158e00 in __iAtomicAdd ()
(cuda-gdb) info register 
pc             0x202158e00         0x202158e00 <__iAtomicAdd>
errorpc        <unavailable>
R0             0xfff9c0            16775616
R1             0xfffd98            16776600
R2             0x1                 1
R3             0x0                 0
R4             0x52e0000           86900736
R5             0x2                 2
R6             0x1                 1
R7             0x0                 0
R8             0x0                 0
R9             0x0                 0
R10            0x0                 0
R11            0x0                 0
R12            0x0                 0
R13            0x0                 0
R14            0x0                 0
R15            0x0                 0
R16            0x52e0000           86900736
R17            0x2                 2
R18            0x52e0000           86900736
R19            0x40                64
R20            0x21583f0           34964464
R21            0x2                 2

Before:
(cuda-gdb) info register 
pc             0x2021583e0         0x2021583e0 <_INTERNAL_b506f649_13_testatomic_cu_555bfaa0::atomicAdd(int*, int)+736>
errorpc        <unavailable>
R0             0xfff9c0            16775616
R1             0xfffd98            16776600
R2             0x1                 1
R3             0x0                 0
R4             0x52e0000           86900736
R5             0x2                 2
R6             0x1                 1
R7             0x0                 0
R8             0x0                 0
R9             0x0                 0
R10            0x0                 0
R11            0x0                 0
R12            0x0                 0
R13            0x0                 0
R14            0x0                 0
R15            0x0                 0
R16            0x52e0000           86900736
R17            0x2                 2
R18            0x52e0000           86900736
R19            0x40                64
R20            0x21583f0           34964464
R21            0x2                 2
```

## Conclusion (CALL.ABS.NOINC)
Call has NO difference than an absolute jump, maybe it has some of the RAS optimizations in uarch, 
but behaviourally, there's NO difference from the programmer's perspective!! 



NVIDIA's atomicAdd implementation: 
```
(cuda-gdb) disas 
Dump of assembler code for function __iAtomicAdd:
=> 0x0000000202158e00 <+0>:	ISETP.NE.U32.AND P0, PT, RZ, UR2, PT 
   0x0000000202158e10 <+16>:	@P0 BRA 0x140 
   0x0000000202158e20 <+32>:	BMOV.32 B0, 0xffffffff 
   0x0000000202158e30 <+48>:	BMOV.32.CLEAR B1, B0 
   0x0000000202158e40 <+64>:	BMOV.32.CLEAR B2, B1 
   0x0000000202158e50 <+80>:	BMOV.32.CLEAR B3, B2 
   0x0000000202158e60 <+96>:	BMOV.32.CLEAR B4, B3 
   0x0000000202158e70 <+112>:	BMOV.32.CLEAR B5, B4 
   0x0000000202158e80 <+128>:	BMOV.32.CLEAR B6, B5 
   0x0000000202158e90 <+144>:	BMOV.32.CLEAR B7, B6 
   0x0000000202158ea0 <+160>:	BMOV.32.CLEAR B8, B7 
   0x0000000202158eb0 <+176>:	BMOV.32.CLEAR B9, B8 
   0x0000000202158ec0 <+192>:	BMOV.32.CLEAR B10, B9 
   0x0000000202158ed0 <+208>:	BMOV.32.CLEAR B11, B10 
   0x0000000202158ee0 <+224>:	BMOV.32.CLEAR B12, B11 
   0x0000000202158ef0 <+240>:	BMOV.32.CLEAR B13, B12 
   0x0000000202158f00 <+256>:	BMOV.32.CLEAR B14, B13 
   0x0000000202158f10 <+272>:	BMOV.32.CLEAR B15, B14 
   0x0000000202158f20 <+288>:	BMOV.32 B15, 0x0 
   0x0000000202158f30 <+304>:	UMOV UR2, 0x1 
   0x0000000202158f40 <+320>:	YIELD 
   0x0000000202158f50 <+336>:	MOV R8, c[0x0][0x118] 
   0x0000000202158f60 <+352>:	MOV R9, c[0x0][0x11c] 
   0x0000000202158f70 <+368>:	MOV R4, R4 
   0x0000000202158f80 <+384>:	MOV R5, R5 
   0x0000000202158f90 <+400>:	MOV R6, R6 
   0x0000000202158fa0 <+416>:	MOV R4, R4 
   0x0000000202158fb0 <+432>:	MOV R5, R5 
   0x0000000202158fc0 <+448>:	R2UR UR4, R8 
   0x0000000202158fd0 <+464>:	R2UR UR5, R9 
   0x0000000202158fe0 <+480>:	ATOM.E.ADD.STRONG.GPU PT, R4, [R4.64], R6 
   0x0000000202158ff0 <+496>:	MOV R4, R4 
   0x0000000202159000 <+512>:	BRA 0x210 
   0x0000000202159010 <+528>:	RET.ABS.NODEC R20 0x0 
   0x0000000202159020 <+544>:	BRA 0x220
   0x0000000202159030 <+560>:	NOP
   0x0000000202159040 <+576>:	NOP
   0x0000000202159050 <+592>:	NOP
   0x0000000202159060 <+608>:	NOP
   0x0000000202159070 <+624>:	NOP
   0x0000000202159080 <+640>:	NOP
   0x0000000202159090 <+656>:	NOP
   0x00000002021590a0 <+672>:	NOP
   0x00000002021590b0 <+688>:	NOP
   0x00000002021590c0 <+704>:	NOP
   0x00000002021590d0 <+720>:	NOP
   0x00000002021590e0 <+736>:	NOP
   0x00000002021590f0 <+752>:	NOP
End of assembler dump.

```

Testing the behaviour of `YIELD`... 
```
(cuda-gdb) si
0x0000000202158e10 in __iAtomicAdd ()
(cuda-gdb) x/i $pc
=> 0x202158e10 <__iAtomicAdd+16>:	@P0 BRA 0x140 
(cuda-gdb) si
0x0000000202158f40 in __iAtomicAdd ()
(cuda-gdb) x/i $pc
=> 0x202158f40 <__iAtomicAdd+320>:	YIELD 
(cuda-gdb) set cuda step_divergent_lanes off 
(cuda-gdb) 

```
Nothing happened... 

OKay...

Inspecting the behaviour of `RET.ABS.NODEC`...

```
(cuda-gdb) si
0x0000000202159010 in __iAtomicAdd ()
(cuda-gdb) x/i $pc
=> 0x202159010 <__iAtomicAdd+528>:	RET.ABS.NODEC R20 0x0 
(cuda-gdb)    
```


```
Before:
(cuda-gdb) x/i $pc
=> 0x202159000 <__iAtomicAdd+512>:	BRA 0x210 
(cuda-gdb) si
0x0000000202159010 in __iAtomicAdd ()
(cuda-gdb) x/i $pc
=> 0x202159010 <__iAtomicAdd+528>:	RET.ABS.NODEC R20 0x0 
(cuda-gdb) info register 
pc             0x202159010         0x202159010 <__iAtomicAdd+528>
errorpc        <unavailable>
R0             0xfff9c0            16775616
R1             0xfffd98            16776600
R2             0x1                 1
R3             0x0                 0
R4             0x0                 0
R5             0x2                 2
R6             0x1                 1
R7             0x0                 0
R8             0x0                 0
R9             0x0                 0
R10            0x0                 0
R11            0x0                 0
R12            0x0                 0
R13            0x0                 0
R14            0x0                 0
R15            0x0                 0
R16            0x52e0000           86900736
R17            0x2                 2
R18            0x52e0000           86900736
R19            0x40                64
R20            0x21583f0           34964464
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
--Type <RET> for more, q to quit, c to continue without paging--c
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



After:
(cuda-gdb) si
0x00000002021583f0 in _INTERNAL_b506f649_13_testatomic_cu_555bfaa0::atomicAdd (address=0x2052e0000, val=1) at /usr/local/cuda-12.6/bin/../targets/aarch64-linux/include/device_atomic_functions.hpp:107
107	  return __iAtomicAdd(address, val);
(cuda-gdb) x/i $pc       
=> 0x2021583f0 <_ZN44_INTERNAL_b506f649_13_testatomic_cu_555bfaa09atomicAddEPii+752>:	MOV R4, R4 
(cuda-gdb) disas
Dump of assembler code for function _ZN44_INTERNAL_b506f649_13_testatomic_cu_555bfaa09atomicAddEPii:
   0x0000000202158100 <+0>:	ISETP.NE.U32.AND P0, PT, RZ, UR2, PT 
   0x0000000202158110 <+16>:	@P0 BRA 0x140 
   0x0000000202158120 <+32>:	BMOV.32 B0, 0xffffffff 
   0x0000000202158130 <+48>:	BMOV.32.CLEAR B1, B0 
   0x0000000202158140 <+64>:	BMOV.32.CLEAR B2, B1 
   0x0000000202158150 <+80>:	BMOV.32.CLEAR B3, B2 
   0x0000000202158160 <+96>:	BMOV.32.CLEAR B4, B3 
   0x0000000202158170 <+112>:	BMOV.32.CLEAR B5, B4 
   0x0000000202158180 <+128>:	BMOV.32.CLEAR B6, B5 
   0x0000000202158190 <+144>:	BMOV.32.CLEAR B7, B6 
   0x00000002021581a0 <+160>:	BMOV.32.CLEAR B8, B7 
   0x00000002021581b0 <+176>:	BMOV.32.CLEAR B9, B8 
   0x00000002021581c0 <+192>:	BMOV.32.CLEAR B10, B9 
   0x00000002021581d0 <+208>:	BMOV.32.CLEAR B11, B10 
   0x00000002021581e0 <+224>:	BMOV.32.CLEAR B12, B11 
   0x00000002021581f0 <+240>:	BMOV.32.CLEAR B13, B12 
   0x0000000202158200 <+256>:	BMOV.32.CLEAR B14, B13 
   0x0000000202158210 <+272>:	BMOV.32.CLEAR B15, B14 
   0x0000000202158220 <+288>:	BMOV.32 B15, 0x0 
   0x0000000202158230 <+304>:	UMOV UR2, 0x1 
   0x0000000202158240 <+320>:	IADD3 R1, R1, -0x18, RZ 
   0x0000000202158250 <+336>:	S2R R0, SR_LMEMHIOFF 
   0x0000000202158260 <+352>:	ISETP.GE.U32.AND P0, PT, R1, R0, PT 
   0x0000000202158270 <+368>:	@P0 BRA 0x190 
   0x0000000202158280 <+384>:	BPT.TRAP 0x1 
   0x0000000202158290 <+400>:	STL [R1+0x10], R21 
   0x00000002021582a0 <+416>:	STL [R1+0xc], R20 
   0x00000002021582b0 <+432>:	STL [R1+0x8], R17 
   0x00000002021582c0 <+448>:	STL [R1+0x4], R16 
   0x00000002021582d0 <+464>:	STL [R1], R2 
   0x00000002021582e0 <+480>:	MOV R4, R4 
   0x00000002021582f0 <+496>:	MOV R5, R5 
   0x0000000202158300 <+512>:	MOV R6, R6 
   0x0000000202158310 <+528>:	MOV R16, R4 
   0x0000000202158320 <+544>:	MOV R17, R5 
   0x0000000202158330 <+560>:	MOV R2, R6 
   0x0000000202158340 <+576>:	MOV R4, R16 
   0x0000000202158350 <+592>:	MOV R5, R17 
   0x0000000202158360 <+608>:	MOV R4, R4 
   0x0000000202158370 <+624>:	MOV R5, R5 
   0x0000000202158380 <+640>:	MOV R6, R2 
   0x0000000202158390 <+656>:	MOV R4, R4 
   0x00000002021583a0 <+672>:	MOV R5, R5 
   0x00000002021583b0 <+688>:	MOV R6, R6 
   0x00000002021583c0 <+704>:	MOV R20, 0x0 
   0x00000002021583d0 <+720>:	MOV R21, 0x0 
   0x00000002021583e0 <+736>:	CALL.ABS.NOINC 0x0 
=> 0x00000002021583f0 <+752>:	MOV R4, R4 
   0x0000000202158400 <+768>:	MOV R4, R4 
   0x0000000202158410 <+784>:	BRA 0x320 
   0x0000000202158420 <+800>:	LDL R2, [R1] 
   0x0000000202158430 <+816>:	LDL R16, [R1+0x4] 
   0x0000000202158440 <+832>:	LDL R17, [R1+0x8] 
   0x0000000202158450 <+848>:	LDL R20, [R1+0xc] 
   0x0000000202158460 <+864>:	LDL R21, [R1+0x10] 
   0x0000000202158470 <+880>:	IADD3 R1, R1, 0x18, RZ 
   0x0000000202158480 <+896>:	RET.ABS.NODEC R20 0x0 
   0x0000000202158490 <+912>:	BRA 0x390
   0x00000002021584a0 <+928>:	NOP
   0x00000002021584b0 <+944>:	NOP
   0x00000002021584c0 <+960>:	NOP
   0x00000002021584d0 <+976>:	NOP
   0x00000002021584e0 <+992>:	NOP
--Type <RET> for more, q to quit, c to continue without paging--q
Quit
(cuda-gdb) info register 
pc             0x2021583f0         0x2021583f0 <_INTERNAL_b506f649_13_testatomic_cu_555bfaa0::atomicAdd(int*, int)+752>
errorpc        <unavailable>
R0             0xfff9c0            16775616
R1             0xfffd98            16776600
R2             0x1                 1
R3             0x0                 0
R4             0x0                 0
R5             0x2                 2
R6             0x1                 1
R7             0x0                 0
R8             0x0                 0
R9             0x0                 0
R10            0x0                 0
R11            0x0                 0
R12            0x0                 0
R13            0x0                 0
R14            0x0                 0
R15            0x0                 0
R16            0x52e0000           86900736
R17            0x2                 2
R18            0x52e0000           86900736
R19            0x40                64
R20            0x21583f0           34964464
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
--Type <RET> for more, q to quit, c to continue without paging--c
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

```
Compare: 
Before:
pc             0x202159010         0x202159010 <__iAtomicAdd+528>
errorpc        <unavailable>
R0             0xfff9c0            16775616
R1             0xfffd98            16776600
R2             0x1                 1
R3             0x0                 0
R4             0x0                 0
R5             0x2                 2
R6             0x1                 1
R7             0x0                 0
R8             0x0                 0
R9             0x0                 0
R10            0x0                 0
R11            0x0                 0
R12            0x0                 0
R13            0x0                 0
R14            0x0                 0
R15            0x0                 0
R16            0x52e0000           86900736
R17            0x2                 2
R18            0x52e0000           86900736
R19            0x40                64
R20            0x21583f0           34964464
R21            0x2                 2

After:
pc             0x2021583f0         0x2021583f0 <_INTERNAL_b506f649_13_testatomic_cu_555bfaa0::atomicAdd(int*, int)+752>
errorpc        <unavailable>
R0             0xfff9c0            16775616
R1             0xfffd98            16776600
R2             0x1                 1
R3             0x0                 0
R4             0x0                 0
R5             0x2                 2
R6             0x1                 1
R7             0x0                 0
R8             0x0                 0
R9             0x0                 0
R10            0x0                 0
R11            0x0                 0
R12            0x0                 0
R13            0x0                 0
R14            0x0                 0
R15            0x0                 0
R16            0x52e0000           86900736
R17            0x2                 2
R18            0x52e0000           86900736
R19            0x40                64
R20            0x21583f0           34964464
R21            0x2                 2
```

## Conclusion (RET.ABS.NOINC)
RET has NO difference than an indirect jump, maybe it has some of the RAS optimizations in uarch, 
but behaviourally, there's NO difference from the programmer's perspective!! 

TODO: what is the 0x0 immediate of the RET instruction?? And what's the difference between RET.ABS and RET.REL???


NOTE2: 
```
=> 0x0000000202158420 <+800>:	LDL R2, [R1] 
   0x0000000202158430 <+816>:	LDL R16, [R1+0x4] 
   0x0000000202158440 <+832>:	LDL R17, [R1+0x8] 
   0x0000000202158450 <+848>:	LDL R20, [R1+0xc] 
   0x0000000202158460 <+864>:	LDL R21, [R1+0x10] 

```
R1 is the frame pointer 

R16 and R17 might be the constant memory address? Or shared memory address??

```
=> 0x00000002021576c0 <+704>:	LDL R2, [R1] 
   0x00000002021576d0 <+720>:	LDL R16, [R1+0x4] 
   0x00000002021576e0 <+736>:	LDL R20, [R1+0x8] 
   0x00000002021576f0 <+752>:	LDL R21, [R1+0xc] 
   0x0000000202157700 <+768>:	IADD3 R1, R1, 0x10, RZ 
   0x0000000202157710 <+784>:	RET.ABS.NODEC R20 0x0 
   0x0000000202157720 <+800>:	BRA 0x320
   0x0000000202157730 <+816>:	NOP
   0x0000000202157740 <+832>:	NOP
   0x0000000202157750 <+848>:	NOP
   0x0000000202157760 <+864>:	NOP
   0x0000000202157770 <+880>:	NOP
   0x0000000202157780 <+896>:	NOP
   0x0000000202157790 <+912>:	NOP
   0x00000002021577a0 <+928>:	NOP
   0x00000002021577b0 <+944>:	NOP
   0x00000002021577c0 <+960>:	NOP
   0x00000002021577d0 <+976>:	NOP
   0x00000002021577e0 <+992>:	NOP
--Type <RET> for more, q to quit, c to continue without paging--q
Quit
(cuda-gdb) x/x $R1
0xfffdb0:	Cannot access memory at address 0xfffdb0
(cuda-gdb) p/x $R1
$22 = 0xfffdb0
(cuda-gdb) p/x $R0
$23 = 0xfff9c0
(cuda-gdb) x/x 0xfffdb0fff9c0
0xfffdb0fff9c0:	Cannot access memory at address 0xfffdb0fff9c0
(cuda-gdb) p/x $R2           
$24 = 0x2
(cuda-gdb) x/x 0x200fffdb0 
0x200fffdb0:	0x00000000
(cuda-gdb) si
0x00000002021576d0	9	    return atomicAdd(a, 1);
(cuda-gdb) p/x $R2
$25 = 0x2
(cuda-gdb) x/x 0x200fffdb0
0x200fffdb0:	0x00000000
(cuda-gdb) x/x 0x200fffdb4
0x200fffdb4:	0x00000000
(cuda-gdb) x/x 0x200fffdb8
0x200fffdb8:	0x00000000
(cuda-gdb) x/x 0x0fffdb0  
0xfffdb0:	Cannot access memory at address 0xfffdb0
(cuda-gdb) info register 
pc             0x2021576d0         0x2021576d0 <atomicFoo(int*)+720>
errorpc        <unavailable>
R0             0xfff9c0            16775616
R1             0xfffdb0            16776624
R2             0x2                 2
R3             0x0                 0
R4             0x0                 0
R5             0x2                 2
R6             0x1                 1
R7             0x0                 0
R8             0x0                 0
R9             0x0                 0
R10            0x0                 0
R11            0x0                 0
R12            0x0                 0
R13            0x0                 0
R14            0x0                 0
R15            0x0                 0
R16            0x52e0000           86900736
R17            0x2                 2
R18            0x52e0000           86900736
R19            0x40                64
R20            0x2157690           34961040
R21            0x2                 2
...
(cuda-gdb) x/x 0x40052e0000
0x40052e0000:	Cannot access memory at address 0x40052e0000
(cuda-gdb) x/x 0x02052e0000
0x2052e0000:	0x00000001
(cuda-gdb) x/x 0x02052e000 
0x2052e000:	Cannot access memory at address 0x2052e000
(cuda-gdb) x/x 0x02052e0004
0x2052e0004:	0x00000002
(cuda-gdb) x/x 0x02052e0008
0x2052e0008:	0x00000003
(cuda-gdb) x/x 0x02052e000c
0x2052e000c:	0x00000004
(cuda-gdb) x/x 0x02052e000f
0x2052e000f:	0x00000500
(cuda-gdb) x/x 0x02052e0010
0x2052e0010:	0x00000005
(cuda-gdb) 


```

Register R2 seems to be the base address overall if you do a LD.E Rx, [Ry.64], 
then the address MIGHT be {R2, Ry} or {R17, Ry}.

As you can see here:
```
(cuda-gdb) x/i $pc
=> 0x202156a20 <_Z11test_atomicPlj+1568>:	R2UR UR5, R23 
(cuda-gdb) si     
0x0000000202156a30	22	    out[threadIdx.x] = (int64_t)array[threadIdx.x];
(cuda-gdb) x/i $pc
=> 0x202156a30 <_Z11test_atomicPlj+1584>:	ST.E.64 [R2.64], R4 
(cuda-gdb) p/x $R2
$47 = 0x50e0000
(cuda-gdb) p/x &out  
$48 = 0x160
(cuda-gdb) p/x out 
$49 = 0x2050e0000
(cuda-gdb) 


```

