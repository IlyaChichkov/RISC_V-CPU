`timescale 1ns / 1ps

module mem_16_32(
        input           clk,
        input   [4:0]   adr1,
        input   [4:0]   adr2,
        input   [4:0]   adr3,
        input           we,
        output  [31:0]  rd1,
        output  [31:0]  rd2,
        input   [31:0]  wd3
    );
    
    reg [31:0] RAM [0:32];
    
    assign rd1 = adr1 == 0? 0 : RAM[adr1];
    assign rd2 = adr2 == 0? 0 : RAM[adr2];
    
    always @ (posedge clk)
    begin
        if (we) RAM[adr3] <= wd3;
    end
endmodule
