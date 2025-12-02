# BRA.CONV analysis (sm_86)

Source code
```
__global__
void test_bra(int64_t *out, uint32_t count){
    __shared__ uint32_t data[32];
    if (threadIdx.x < 32) {
        asm("barrier.cta.sync 0, 64;\n\t");
        data[threadIdx.x] = threadIdx.x;
        asm("barrier.cta.arrive 1, 64;\n\t");
    } else {
        asm("barrier.cta.arrive 0, 64;\n\t");
        asm("barrier.cta.sync 1, 64;\n\t");
        out[threadIdx.x - 32] = data[threadIdx.x - 32];
    }
}
```

In sm_86, the above code compiles to `braconv86.cubin` 
and the disassembly is `braconv86.list`, 
with `-O0` passed into `ptxas`

PTX is emitted separately as `braconv86.ptx`

Judging from the PTX, specifically line 34: `bra.uni`, it could be inferred that 
the nvcc at least detects that the if-branch is warp-aligned, since `bra.uni` is 
a warp-aligned branch instruction.

This explains the `BRA.CONV ~URZ` posted below
 -- a converging branch with a mask of all threads 
in a warp.

`barrier.cta.*`: causes the participating thread to wait for the other threads in the 
same warp to arrive (syncwarp effect), and then for `barrier.cta.arrive`, increase the 
barrier arrival count by a warp's threads. 
`barrier.cta.sync` will have an arrival effect, and further blocks the thread 
until the barrier count reaches to zero. 
Then the barrier will re-initialize atomically.
The `.aligned` suffix indicates all threads in CTA will execute this instruction.

To locate the code corresponding the branch and the inline assembly, we notice that 
```
        /*0130*/               @P0 BRA 0x150 ;                              /* 0x0000001000000947 */
                                                                    /* 0x003fde0003800000 */
        /*0140*/                   BRA 0x240 ;                              /* 0x000000f000007947 */
                                                                    /* 0x003fde0003800000 */
```
This infers 0x150 is hte starting point of BB1 and 0x240 the starting point of BB2

BB1: 
```
        /*0150*/                   BRA.CONV ~URZ, 0x1a0 ;                   /* 0x000000437f007947 */
                                                                            /* 0x003fde000b800000 */
        /*0160*/                   MOV R2, 0x40 ;                           /* 0x0000004000027802 */
                                                                            /* 0x003fde0000000f00 */
        /*0170*/                   MOV R3, 0x190 ;                          /* 0x0000019000037802 */
                                                                            /* 0x003fde0000000f00 */
        /*0180*/                   CALL.REL.NOINC 0x5b0 ;                   /* 0x0000042000007944 */
                                                                            /* 0x003fde0003c00000 */
        /*0190*/                   BRA 0x1b0 ;                              /* 0x0000001000007947 */
                                                                            /* 0x003fde0003800000 */
        /*01a0*/                   BAR.SYNC 0x0, 0x40 ;                     /* 0x0001000000007b1d */
                                                                            /* 0x0033de0000000000 */
        /*01b0*/                   MOV R4, R4 ;                             /* 0x0000000400047202 */
                                                                            /* 0x003fde0000000f00 */
        /*01c0*/                   STS [R4], R0 ;                           /* 0x0000000004007388 */
                                                                            /* 0x0033de0000000800 */
        /*01d0*/                   BRA.CONV ~URZ, 0x220 ;                   /* 0x000000437f007947 */
                                                                            /* 0x003fde000b800000 */
        /*01e0*/                   MOV R0, 0x40 ;                           /* 0x0000004000007802 */
                                                                            /* 0x003fde0000000f00 */
        /*01f0*/                   MOV R2, 0x210 ;                          /* 0x0000021000027802 */
                                                                            /* 0x003fde0000000f00 */
        /*0200*/                   CALL.REL.NOINC 0x520 ;                   /* 0x0000031000007944 */
                                                                            /* 0x003fde0003c00000 */
        /*0210*/                   BRA 0x230 ;                              /* 0x0000001000007947 */
                                                                            /* 0x003fde0003800000 */
        /*0220*/                   BAR.ARV 0x1, 0x40 ;                      /* 0x0041000000007b1d */
                                                                            /* 0x0033de0000002000 */
        /*0230*/                   BRA 0x480 ;                              /* 0x0000024000007947 */
                                                                            /* 0x003fde0003800000 */
```


Notice that the return address is also an operand of the `CALL.REL.NOINC` instruction

The code is roughly as follows: 
```

if ([BRA.CONV ~URZ]) then begin 
    Call 0x5b0 with param 0x40 (64) // emitted by ptxas
    // bar.sync in 0x01a0 is skipped
end

BAR.SYNC 0x0, 0x40
perform store 

if ([BRA.CONV ~URZ]) then begin
    Call 0x520 with param 0x40 (64)
end

BAR.ARV 0x1, 0x40
```

And 0x520 and 0x5b0 functions are just a single `WARPSYNC` instruction.

Now, we can infer that `BRA.CONV` is the branch taken
when the warp is NOT convergent, 
another possibility is that 
this branch has nothing difference than a regular `BRA`.

As for `BRA` instruction encoding, 
the following encoding is sufficient to show it's a relative jump: 

```
        /*0190*/                   BRA 0x1b0 ;                              /* 0x0000001000007947 */
                                                                            /* 0x003fde0003800000 */
        /*0210*/                   BRA 0x230 ;                              /* 0x0000001000007947 */
                                                                            /* 0x003fde0003800000 */
```
As you can see, the two branches branch forward by 0x020, 
and their encodings are exactly the same.

## Conclusion
`BRA` instruction is the relative branch, optionally with a conditional predicate.

`BRA.CONV` is either branching when divergent, or having the same behavior as `BRA`.




### Sidenote: how is PTX barrier is implemented in sm_90

Compile the source code for `sm_90`, the PTX emitted is exactly the same as the one emitted with `sm_86`,
but the generated SASS assembly is vastly different:
```
        /*0180*/                   MOV R4, 0x0 ;                            /* 0x0000000000047802 */
                                                                            /* 0x003fde0000000f00 */
        /*0190*/                   MOV R5, 0x40 ;                           /* 0x0000004000057802 */
                                                                            /* 0x003fde0000000f00 */
        /*01a0*/                   MOV R3, 0xffffffff ;                     /* 0xffffffff00037802 */
                                                                            /* 0x003fde0000000f00 */
        /*01b0*/                   WARPSYNC.COLLECTIVE.ALL 0x210 ;          /* 0x0000000000147948 */
                                                                            /* 0x003fde0003c00000 */
        /*01c0*/                   SHF.L.U32 R5, R5, 0x10, RZ ;             /* 0x0000001005057819 */
                                                                            /* 0x003fde00000006ff */
        /*01d0*/                   LOP3.LUT R5, R5, 0xf, R4, 0xf8, !PT ;    /* 0x0000000f05057812 */
                                                                            /* 0x003fde00078ef804 */
        /*01e0*/                   BAR.SYNC.DEFER_BLOCKING R5, R5 ;         /* 0x000000050000731d */
                                                                            /* 0x0033de0000010000 */
        /*01f0*/                   SHF.R.U32.HI R5, RZ, 0x10, R5 ;          /* 0x00000010ff057819 */
                                                                            /* 0x003fde0000011605 */
        /*0200*/                   ENDCOLLECTIVE ;                          /* 0x000000000000791b */
                                                                            /* 0x003fde0003800000 */
        /*0210*/                   MOV R2, R2 ;                             /* 0x0000000200027202 */
                                                                            /* 0x003fde0000000f00 */
        /*0220*/                   STS [R2], R0 ;                           /* 0x0000000002007388 */
                                                                            /* 0x0033de0000000800 */
        /*0230*/                   MOV R4, 0x1 ;                            /* 0x0000000100047802 */
                                                                            /* 0x003fde0000000f00 */
        /*0240*/                   MOV R5, 0x40 ;                           /* 0x0000004000057802 */
                                                                            /* 0x003fde0000000f00 */
        /*0250*/                   MOV R3, 0xffffffff ;                     /* 0xffffffff00037802 */
                                                                            /* 0x003fde0000000f00 */
        /*0260*/                   BSSY B0, 0x2e0 ;                         /* 0x0000007000007945 */
                                                                            /* 0x003fde0003800000 */
        /*0270*/                   WARPSYNC.COLLECTIVE.ALL 0x2d0 ;          /* 0x0000000000147948 */
                                                                            /* 0x003fde0003c00000 */
        /*0280*/                   SHF.L.U32 R5, R5, 0x10, RZ ;             /* 0x0000001005057819 */
                                                                            /* 0x003fde00000006ff */
        /*0290*/                   LOP3.LUT R5, R5, 0xf, R4, 0xf8, !PT ;    /* 0x0000000f05057812 */
                                                                            /* 0x003fde00078ef804 */
        /*02a0*/                   BAR.ARV R5, R5 ;                         /* 0x000000050000731d */
                                                                            /* 0x0033de0000002000 */
        /*02b0*/                   SHF.R.U32.HI R5, RZ, 0x10, R5 ;          /* 0x00000010ff057819 */
                                                                            /* 0x003fde0000011605 */
        /*02c0*/                   ENDCOLLECTIVE ;                          /* 0x000000000000791b */
                                                                            /* 0x003fde0003800000 */
        /*02d0*/                   BSYNC B0 ;                               /* 0x0000000000007941 */
                                                                            /* 0x003fde0003800000 */
```

The `LOP3.LUT` instruction seems to be an NAND instruction.
And `WARPSYNC.COLLECTIVE.ALL 0x210` denotes the warpsync region with relative encoding 
(does it also have a WARPSYNC effect?).
`ENDCOLLECTIVE` is the ending instruction of the 
sync region.

`BAR.SYNC.DETER_BLOCKING` might be the key to this synchronization implementation, does it perform a block 
on `ENDCOLLECTIVE`?

`BSSY` denotes the thread synchronization barrier, and `BSYNC` actually synchronizes on the barrier.








