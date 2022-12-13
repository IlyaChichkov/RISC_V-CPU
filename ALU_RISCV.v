`timescale 1ns / 1ps
`include "alu_operations.v"

module ALU_RISCV(
    input [4:0] ALU0p,
    input [31:0] A,
    input [31:0] B,
    output reg [31:0] Result,
    output reg Flag
    );
    
    always @(*) begin
        case(ALU0p)
        `SUM:       Result = A + B;
        `SUB:       Result = A - B;
        `LEFTSHIFT: Result = A << B;
        `SIGNCOMP:  Result = $signed(A) < $signed(B)? 1: 0;
        `COMP:      Result = A < B? 1: 0;
        `XOR:       Result = A ^ B;
        `RIGHTSHIFT:Result = A >> B;
        `MATHSHIFT: Result = $signed(A) >>> B;
        `OR:        Result = A | B;
        `AND:       Result = A & B;
        `EQL:       Result = 0;
        `NEQL:      Result = 0;
        `SIGNLESS:  Result = 0;
        `SINGMORE:  Result = 0;
        `LESS:      Result = 0;
        `MORE:      begin
        Result = 0;
        end
        endcase
    end
    
    always @(*) begin
        case(ALU0p)
        `SUM:       Flag = 0;
        `SUB:       Flag = 0;
        `LEFTSHIFT: Flag = 0;
        `SIGNCOMP:  Flag = 0;
        `COMP:      Flag = 0;
        `XOR:       Flag = 0;
        `RIGHTSHIFT:Flag = 0;
        `MATHSHIFT: Flag = 0;
        `OR:        Flag = 0;
        `AND:       Flag = 0;
        `EQL:       Flag = A == B? 1: 0;
        `NEQL:      Flag = A != B? 1: 0;
        `SIGNLESS:  Flag = $signed(A) < $signed(B)? 1: 0;
        `SINGMORE:  Flag = $signed(A) >= $signed(B)? 1: 0;
        `LESS:      Flag = A < B? 1: 0;
        `MORE:      Flag = A >= B? 1: 0;
        endcase
    end
endmodule
