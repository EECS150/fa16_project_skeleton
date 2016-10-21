.section    .start
.global     _start

_start:
    #li      sp, 0x10000600
    #jal     main

    li      x3, 0x30002000
    li      x4, 0x05000293
    sw      x4, 0(x3)
    li      x4, 0x05000313
    sw      x4, 4(x3)
    li      x4, 0x05000393
    sw      x4, 8(x3)
    li      x4, 0x00000013
    sw      x4, 12(x3)
    li      x3, 0x10002000
    lw      x5, 0(x3)
    lw      x6, 4(x3) 
    lw      x7, 8(x3)
    #jalr    x1, x3, 0 
    li	    x4, 0x30000000
    li      x4, 0x40000000
    nop
