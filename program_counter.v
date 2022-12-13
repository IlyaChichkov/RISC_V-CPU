`timescale 1ns / 1ps

module program_counter(
      input           clk,
      input           rst_n_i,
      input   [31:0]  additinal,
      input   [31:0]  jalr_add,
      input           jalr_o,
      input           en_add,
      input           en_pc,
      output  [31:0]  pc
  );
  
  reg [31:0] currentPC = 0;
  
  always @ (posedge clk or posedge rst_n_i)
  begin
    if (!rst_n_i)
    begin 
        currentPC = 0;
    end
    else
    if (en_pc == 1)
    begin
      if(jalr_o == 'b1)
        begin
          currentPC = jalr_add / 4;
        end
      else
        begin
          if(!en_add)
            currentPC = pc + 1;
          else
            currentPC = pc + ($signed(additinal) / 4);
        end
    end
  end
  
  assign pc = currentPC;
endmodule
