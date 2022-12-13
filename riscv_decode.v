`include "defines_riscv.v"

`define FUNC7_00 7'b0000000
`define FUNC7_20 7'b0100000

module decoder_riscv (
  input       [31:0]  fetched_instr_i,
  input               stall,
  output  reg [1:0]   ex_op_a_sel_o,      
  output  reg [2:0]   ex_op_b_sel_o,      
  output  reg [4:0]   alu_op_o,           
  output  reg         mem_req_o,         
  output  reg         mem_we_o,           
  output  reg [2:0]   mem_size_o,        
  output  reg         gpr_we_a_o,         
  output  reg         wb_src_sel_o,      
  output  reg         illegal_instr_o,   
  output  reg         branch_o,           
  output  reg         jal_o,              
  output  reg         jalr_o,            
  output  reg         en_pc
);

// TYPE-R OP_OPCODE
// TYPE-I LOAD_OPCODE OP_IMM_OPCODE JALR_OPCODE SYSTEM_OPCODE
// TYPE-S STORE_OPCODE
// TYPE-B BRANCH_OPCODE
// TYPE-U AUIPC_OPCODE LUI_OPCODE
// TYPE-J JAL_OPCODE


reg [6:0]   opcode;
reg [14:12] func3;
reg [31:25] func7;

reg [24:20] rs2;
reg [19:15] rs1;
reg [11:7]  rd ;

always @(*) begin
  opcode = fetched_instr_i[6:0];
  func3  = fetched_instr_i[14:12];
  func7  = fetched_instr_i[31:25];
  en_pc = !stall;
  
  rs2 = fetched_instr_i[24:20];
  rs1 = fetched_instr_i[19:15];
  rd  = fetched_instr_i[11:7];
  
  case(opcode)
    {`OP_OPCODE, 2'b11}: begin
     ex_op_a_sel_o     = `OP_A_RS1;   
     ex_op_b_sel_o     = `OP_B_RS2;
     alu_op_o          = { 2'b00, func3 };
     mem_req_o         = 0;
     mem_we_o          = 0;
     mem_size_o        = `LDST_B;
     gpr_we_a_o        = 1;
     wb_src_sel_o      = `WB_EX_RESULT;
     illegal_instr_o   = 0;
     branch_o          = 0;
     jal_o             = 0;
     jalr_o            = 0;
     
     if( func7 == 7'b0100000 )
       alu_op_o          = { 2'b01, func3 };
     
     if( func7 == 7'b0100000 ) begin
       if( func3 != 3'b000 &&
           func3 != 3'b101 )
         illegal_instr_o   = 1;
     end else
       if( func7 != 7'b0000000 )
         illegal_instr_o   = 1;
    end
    {`LOAD_OPCODE, 2'b11}: begin
    ex_op_a_sel_o     = `OP_A_RS1;   
    ex_op_b_sel_o     = `OP_B_IMM_I;
    alu_op_o          = `ALU_ADD;
    mem_req_o         = 1;
    mem_we_o          = 0;
    mem_size_o        = func3;
    gpr_we_a_o        = 1;
    wb_src_sel_o      = `WB_LSU_DATA;
    illegal_instr_o   = 0;
    branch_o          = 0;
    jal_o             = 0;
    jalr_o            = 0;
    
    if( func3 != `LDST_B  &&
        func3 != `LDST_H  &&
        func3 != `LDST_W  &&
        func3 != `LDST_BU &&
        func3 != `LDST_HU ) begin
      illegal_instr_o = 1;
      mem_size_o = `LDST_B;
    end
    end
    {`OP_IMM_OPCODE, 2'b11}: begin
    ex_op_a_sel_o     = `OP_A_RS1;   
    ex_op_b_sel_o     = `OP_B_IMM_I;
    alu_op_o          = { 2'b00, func3 };
    mem_req_o         = 0;
    mem_we_o          = 0;
    mem_size_o        = 0;
    gpr_we_a_o        = 1;
    wb_src_sel_o      = `WB_EX_RESULT;
    illegal_instr_o   = 0;
    branch_o          = 0;
    jal_o             = 0;
    jalr_o            = 0;    
    
    if( alu_op_o == `ALU_SRL && func7 == 7'b0100000 )
        alu_op_o          = { 2'b01, func3 };  
                  
    if( alu_op_o == `ALU_SLL ||
        alu_op_o == `ALU_SRL ) begin
      if( func7 != 7'b0000000 )
        illegal_instr_o = 1;
    end else
      if( alu_op_o == `ALU_SRA )
        if( func7 != 7'b0100000 )
          illegal_instr_o = 1;
    end
    {`JALR_OPCODE, 2'b11}: begin
    ex_op_a_sel_o     = `OP_A_CURR_PC;   
    ex_op_b_sel_o     = `OP_B_INCR;
    alu_op_o          = `ALU_ADD;
    mem_req_o         = 0;
    mem_we_o          = 0;
    mem_size_o        = 0;
    gpr_we_a_o        = 1;
    wb_src_sel_o      = `WB_EX_RESULT;
    illegal_instr_o   = 0;
    branch_o          = 0;
    jal_o             = 0;
    jalr_o            = 1;
    
    if( func3 != 3'b000 ) begin
      illegal_instr_o   = 1;
    end
    end
    { `AUIPC_OPCODE, 2'b11 }: begin
      ex_op_a_sel_o     = `OP_A_CURR_PC;   
      ex_op_b_sel_o     = `OP_B_IMM_U;
      alu_op_o          = `ALU_ADD;
      mem_req_o         = 0;
      mem_we_o          = 0;
      mem_size_o        = `LDST_B;
      gpr_we_a_o        = 1;
      wb_src_sel_o      = `WB_EX_RESULT;
      illegal_instr_o   = 0;
      branch_o          = 0;
      jal_o             = 0;
      jalr_o            = 0;
    end 
    {`STORE_OPCODE, 2'b11}: begin
      ex_op_a_sel_o     = `OP_A_RS1;   
      ex_op_b_sel_o     = `OP_B_IMM_S;
      alu_op_o          = `ALU_ADD;
      mem_req_o         = 1;
      mem_we_o          = 1;
      mem_size_o        = func3;
      gpr_we_a_o        = 0;
      wb_src_sel_o      = `WB_LSU_DATA;
      illegal_instr_o   = 0;
      branch_o          = 0;
      jal_o             = 0;
      jalr_o            = 0;
      
      if( func3 != `LDST_B  &&
          func3 != `LDST_H  &&
          func3 != `LDST_W ) begin
        illegal_instr_o = 1;
        mem_size_o = `LDST_B;
      end
    end
    {`BRANCH_OPCODE, 2'b11}: begin
    ex_op_a_sel_o     = `OP_A_RS1;   
    ex_op_b_sel_o     = `OP_B_RS2;
    alu_op_o          = { 2'b11, func3 };
    mem_req_o         = 0;
    mem_we_o          = 0;
    mem_size_o        = `LDST_B;
    gpr_we_a_o        = 0;
    wb_src_sel_o      = `WB_EX_RESULT;
    illegal_instr_o   = 0;
    branch_o          = 1;
    jal_o             = 0;
    jalr_o            = 0;
    
    if( func3 == 3'b011 ||
        func3 == 3'b010 ) begin
      illegal_instr_o   = 1;
      alu_op_o          = `ALU_EQ;
    end
    end
    {`AUIPC_OPCODE, 2'b11}: begin
    ex_op_a_sel_o     = `OP_A_CURR_PC;   
    ex_op_b_sel_o     = `OP_B_IMM_U;
    alu_op_o          = `ALU_ADD;
    mem_req_o         = 0;
    mem_we_o          = 0;
    mem_size_o        = `LDST_B;
    gpr_we_a_o        = 1;
    wb_src_sel_o      = `WB_EX_RESULT;
    illegal_instr_o   = 0;
    branch_o          = 0;
    jal_o             = 0;
    jalr_o            = 0;
    end
    {`LUI_OPCODE, 2'b11}: begin
      ex_op_a_sel_o     = `OP_A_ZERO ;   
      ex_op_b_sel_o     = `OP_B_IMM_U;
      alu_op_o          = `ALU_ADD;
      mem_req_o         = 0;
      mem_we_o          = 0;
      mem_size_o        = `LDST_B;
      gpr_we_a_o        = 1;
      wb_src_sel_o      = `WB_EX_RESULT;
      illegal_instr_o   = 0;
      branch_o          = 0;
      jal_o             = 0;
      jalr_o            = 0;
    end
    {`JAL_OPCODE, 2'b11}: begin
      ex_op_a_sel_o     = `OP_A_CURR_PC;   
      ex_op_b_sel_o     = `OP_B_INCR;
      alu_op_o          = `ALU_ADD;
      mem_req_o         = 0;
      mem_we_o          = 0;
      mem_size_o        = `LDST_B;
      gpr_we_a_o        = 1;
      wb_src_sel_o      = `WB_EX_RESULT;
      illegal_instr_o   = 0;
      branch_o          = 0;
      jal_o             = 1;
      jalr_o            = 0;
    end
    {`MISC_MEM_OPCODE, 2'b11}: begin
      ex_op_a_sel_o     = `OP_A_RS1;   
      ex_op_b_sel_o     = `OP_B_IMM_I;
      alu_op_o          = `ALU_ADD;
      mem_req_o         = 0;
      mem_we_o          = 0;
      mem_size_o        = `LDST_B;
      gpr_we_a_o        = 0;
      wb_src_sel_o      = `WB_LSU_DATA;
      illegal_instr_o   = 0;
      branch_o          = 0;
      jal_o             = 0;
      jalr_o            = 0;
    end
    {`SYSTEM_OPCODE, 2'b11}: begin
            ex_op_a_sel_o     = `OP_A_CURR_PC;   
            ex_op_b_sel_o     = `OP_B_INCR;
            alu_op_o          = `ALU_ADD;
            mem_req_o         = 0;
            mem_we_o          = 0;
            mem_size_o        = `LDST_B;
            gpr_we_a_o        = 0;
            wb_src_sel_o      = `WB_EX_RESULT;
            illegal_instr_o   = 0;
            branch_o          = 0;
            jal_o             = 0;
            jalr_o            = 0;   
    
            if( fetched_instr_i[31:7] == { 25{ 1'b0 } } || 
                fetched_instr_i[31:7] == { { 11{ 1'b0 } }, 1'b1 } ) begin
              illegal_instr_o   = 1;
      end 
    end
    default: begin
      illegal_instr_o = 1;
    end
  endcase
end

endmodule
