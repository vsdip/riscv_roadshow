# RISC-V RV64I Minimal CPU Simulation

This repository provides a simple Verilog-based RISC-V RV64I CPU simulation capable of executing a small subset of instructions, including `addi`, `andi`, and `jal`. The CPU reads instructions from a hex file and simulates their execution.

## Overview
This project walks through a complete industry-like flow from a simple C program to Verilog CPU simulation:
1. Writing a simple C program.
2. Compiling C to RISC-V machine code using GCC.
3. Running the compiled binary using Spike RISC-V simulator.
4. Understanding the need for assembly in Verilog simulation.
5. Converting the machine code to a hex file.
6. Implementing a minimal RISC-V CPU in Verilog.
7. Running the Verilog CPU with the hex file as input.
8. Simulating the result and verifying the output.

## Step 1: Write a Simple C Program Without `printf()` (Bare-metal Style)
```c
#include <stdint.h>

int main() {
    int64_t x = 5;
    int64_t y = x + 20;
    int64_t z = y & 0x3F;
    return z;
}
```
- **Result is returned in register `x10` (a0)** as per RISC-V ABI.
- **Check `x10` in Verilog simulation later instead of printing.**

## Step 2: Compile C Program Using RISC-V GCC
```bash
riscv64-unknown-elf-gcc -o program.elf program.c
```

## Step 3: Run the Compiled Binary on Spike (RISC-V Simulator)
### Option 1: Check Return Value (Recommended)
```bash
spike -d --isa=rv64i pk program.elf
```
Enter Spike Debug Shell:
```
:run
reg 10
```
Expected Output:
```
x10 0x0000000000000019  # 25 in decimal
```

### Option 2: Default Exit Code (Less Control)
```bash
spike --isa=rv64i pk program.elf
```
Output (if return value is nonzero):
```
[vp] exiting with code 25
```

## Why `printf()` Cannot Be Used for Verifying Custom Verilog CPUs

Consider the following C program with `printf()`:
```c
#include <stdint.h>
#include <stdio.h>

int main() {
    int64_t x = 5;
    int64_t y = x + 20;
    int64_t z = y & 0x3F;
    printf("Result: %ld\n", z);
    return 0;
}
```
This program **cannot be used for Verilog CPU verification** because:

| **Reason**                                     | **Explanation**                                                                                                              |
|-------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------|
| **Requires `printf()` and Standard Library (libc)** | `printf()` involves system calls, memory management, and I/O, which are **not available in a simple Verilog RISC-V CPU**. |
| **Relies on OS Services (I/O, Syscalls)**       | `printf()` requires an OS like Proxy Kernel (`pk`) to handle syscalls like `write()`. A minimal Verilog CPU has **no OS**. |
| **Complex Assembly Output**                     | Compiling `printf()` pulls in large dependencies, making assembly complex.                                                  |
| **Processor is Not Full System (No UART/Console)** | Custom Verilog CPUs typically **do not have peripherals like UART/console**; they **only execute instructions**.           |
| **Focus in Processor Verification is Arithmetic & Logic** | CPU verification focuses on **basic instructions (e.g., `addi`, `andi`)**, not on I/O operations.                         |

## Step 4: Generate Assembly for a C Program
### View the Assembly Code Generated by RISC-V GCC
```bash
riscv64-unknown-elf-gcc -S -o program.s program.c
cat program.s
```
This is the compiler-generated RISC-V assembly code.

## Step 5: Handwritten Minimal Assembly (For Focused Validation)
To **validate a custom Verilog CPU**, it is often easier to **handwrite simple assembly**:
```assembly
.section .text
.globl _start

_start:
    addi x5, x0, 5
    addi x6, x5, 20
    andi x7, x6, 0x3F
    mv a0, x7
    ret
```

- Useful for **validating specific instructions (`addi`, `andi`, etc.)**.
- **Manually control the exact sequence of instructions**.

## Step 6: Assemble and Link
```bash
riscv64-unknown-elf-as -march=rv64i -mabi=lp64 -o program.o program.s
riscv64-unknown-elf-ld -o program.elf program.o
```
Note: You may see this warning:
```
riscv64-unknown-elf-ld: warning: cannot find entry symbol _start; defaulting to 0000000000010078
```
This can be ignored, or you can **use `-nostdlib` in GCC for a cleaner build**:
```bash
riscv64-unknown-elf-gcc -nostdlib -o program.elf program.c
```

## Step 7: Convert ELF to Binary and Hex
```bash
riscv64-unknown-elf-objcopy -O binary program.elf program.bin
hexdump -v -e '1/4 "%08x\n"' program.bin > program.hex
```
This generates `program.hex` in little-endian format.

## Step 8: Verilog CPU Implementation
Create `vsdriscv_cpu.v`:
```verilog
module vsdriscv_cpu(
    input clk,
    input reset,
    output [63:0] result
);

    reg [31:0] instr_mem [0:255];
    reg [63:0] regfile [0:31];
    reg [63:0] pc;

    wire [31:0] instr = instr_mem[pc[7:0]];
    wire [6:0] opcode = instr[6:0];
    wire [4:0] rd = instr[11:7];
    wire [2:0] funct3 = instr[14:12];
    wire [4:0] rs1 = instr[19:15];
    wire [11:0] imm12 = instr[31:20];

    initial begin
        $readmemh("program.hex", instr_mem);
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 0;
            regfile[0] <= 0;
        end else begin
            case (opcode)
                7'b0010011: begin
                    case (funct3)
                        3'b000: regfile[rd] <= regfile[rs1] + $signed(imm12);
                        3'b111: regfile[rd] <= regfile[rs1] & $signed(imm12);
                    endcase
                    pc <= pc + 1;
                end
                default: pc <= pc + 1;
            endcase
        end
    end

    assign result = regfile[10]; // x10 holds the return value
endmodule
```

## Step 9: Testbench
Create `tb_vsdriscv_cpu.v`.
```verilog
module tb_vsdriscv_cpu;
    reg clk;
    reg reset;
    wire [63:0] result;

    initial begin
        clk = 0;
        reset = 1;
        #10 reset = 0;
        #100;
        $display("Result from x10 (a0) register: %d", result);
        $finish;
    end
    always #5 clk = ~clk;
endmodule
```
## License
MIT License.

