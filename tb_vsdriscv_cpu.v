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

        // Give more time to execute all instructions
        #100;
        $display("Result from x7 register: %d", result);
        $finish;
    end

    always #5 clk = ~clk;

endmodule

