.section .text
.globl _start

_start:
    addi x5, x0, 5
    addi x6, x5, 10
    andi x7, x6, 0xF

    # Infinite loop (or halt simulation in Verilog)
    j _start

