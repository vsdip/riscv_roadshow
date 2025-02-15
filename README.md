# RISC-V RV64I Minimal CPU Simulation

This repository provides a simple Verilog-based RISC-V RV64I CPU simulation capable of executing a small subset of instructions, including `addi`, `andi`, and `jal`. The CPU reads instructions from a hex file and simulates their execution.

## Overview

This project walks through a complete flow:
1. Writing a simple RISC-V assembly program.
2. Compiling the assembly to machine code.
3. Converting the machine code to a hex file.
4. Implementing a minimal RISC-V CPU in Verilog.
5. Running the Verilog CPU with the hex file as input.
6. Simulating the result and verifying the output.

## Directory Structure
```
|-- main.s            # Assembly source file
|-- main.o            # Assembled object file
|-- main.elf          # Linked ELF file
|-- main.bin          # Binary output
|-- main.hex          # Hex file (for Verilog CPU simulation)
|-- vsdriscv_cpu.v    # Verilog CPU
|-- tb_vsdriscv_cpu.v # Verilog testbench
|-- README.md         # This documentation
```

## Step 1: Write RISC-V Assembly
Create a file `main.s` with the following content:

```
.section .text
.globl _start

_start:
    addi x5, x0, 5
    addi x6, x5, 10
    andi x7, x6, 0xF
    j _start
```

This program initializes x5 to 5, adds 10 to x5 into x6, and performs bitwise AND on x6 with 0xF, storing the result in x7.

## Step 2: Assemble and Link
```bash
riscv64-unknown-elf-as -march=rv64i -mabi=lp64 -o main.o main.s
riscv64-unknown-elf-ld -o main.elf main.o
```

## Step 3: Convert ELF to Binary and Hex
```bash
riscv64-unknown-elf-objcopy -O binary main.elf main.bin
hexdump -v -e '1/4 "%08x\n"' main.bin > main.hex
```
This generates `main.hex` in little-endian format.

## Step 4: Verilog CPU Implementation
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
        $readmemh("main.hex", instr_mem);
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
                7'b1101111: begin
                    pc <= pc + $signed({instr[31], instr[19:12], instr[20], instr[30:21], 1'b0});
                end
                default: pc <= pc + 1;
            endcase
        end
    end

    assign result = regfile[7];
endmodule
```

## Step 5: Testbench
Create `tb_vsdriscv_cpu.v`:
```verilog
module tb_vsdriscv_cpu;
    reg clk;
    reg reset;
    wire [63:0] result;

    vsdriscv_cpu dut(
        .clk(clk),
        .reset(reset),
        .result(result)
    );

    initial begin
        $dumpfile("tb_vsdriscv_cpu.vcd");
        $dumpvars(0, tb_vsdriscv_cpu);
        clk = 0;
        reset = 1;
        #10 reset = 0;
        #500;
        $display("Result from x7 register: %d", result);
        $finish;
    end

    always #5 clk = ~clk;
endmodule
```

## Step 6: Compile and Simulate
```bash
iverilog -o sim.out vsdriscv_cpu.v tb_vsdriscv_cpu.v
vvp sim.out
```
Expected output:
```
Result from x7 register: 15
```

## Optional: View Waveform
```bash
gtkwave tb_vsdriscv_cpu.vcd
```

## Key Notes
- `$readmemh()` is for **simulation only** and not synthesizable.
- For synthesis, use a pre-initialized ROM or memory.
- This CPU only supports `addi`, `andi`, and `jal` for demonstration.

## License
MIT License.

