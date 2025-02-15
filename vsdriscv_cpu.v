module vsdriscv_cpu(
    input clk,
    input reset,
    output [63:0] result
);

    reg [31:0] instr_mem [0:255]; // Instruction memory
    reg [63:0] regfile [0:31];    // 32 general-purpose registers
    reg [63:0] pc;                // Program counter

    wire [31:0] instr;
    wire [6:0] opcode;
    wire [4:0] rd;
    wire [2:0] funct3;
    wire [4:0] rs1;
    wire [11:0] imm12;

    assign instr = instr_mem[pc[7:0]];
    assign opcode = instr[6:0];
    assign rd = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1 = instr[19:15];
    assign imm12 = instr[31:20];

    initial begin
        $readmemh("main.hex", instr_mem);
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 0;
            regfile[0] <= 0; // x0 is always 0
        end else begin
            case (opcode)
                7'b0010011: begin // I-type instructions
                    case (funct3)
                        3'b000: regfile[rd] <= regfile[rs1] + $signed(imm12); // ADDI
                        3'b111: regfile[rd] <= regfile[rs1] & $signed(imm12); // ANDI
                    endcase
                    pc <= pc + 1;
                end
                7'b1101111: begin // JAL - unconditional jump (infinite loop)
                    pc <= pc + $signed({instr[31], instr[19:12], instr[20], instr[30:21], 1'b0});
                end
                default: begin
                    pc <= pc + 1; // Unhandled instructions
                end
            endcase
        end
    end

    assign result = regfile[7]; // Assuming x7 holds the result

endmodule

