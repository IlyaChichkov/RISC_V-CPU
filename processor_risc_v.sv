`timescale 1ns / 1ps

module processor_risc_v(
  input              clk_i,
  input              arstn_i,
  
  input  [31:0]      instr_rdata_core,
  output [31:0]      instr_addr_core ,
                                      
  input  [31:0]      data_rdata_i ,
  output             data_req_o   ,
  output             data_we_o    ,
  output [3:0]       data_be_o    ,
  output [31:0]      data_addr_o  ,
  output [31:0]      data_wdata_o   
  );
  
  // Register memory signals
  logic     [4:0]   adr1;
  logic     [4:0]   adr2;
  logic     [4:0]   adr3;
  logic     [31:0]  rd1;
  logic     [31:0]  rd2;
  logic     [31:0]  wData;
  logic     [31:0]  jalr_add;
  
  // Program counter
  logic     [31:0]   addPC;
  logic              en_add = 0;
  logic     [31:0]   PC;
  
  // ALU Signals
  logic         [4:0]   alu_op;
  logic                flag_result;
  logic signed [31:0]  result;
  logic        [31:0]  alu_a;
  logic        [31:0]  alu_b;
  
  // Register signals
  logic     [1:0]   inst_sw;
  logic     [7:0]   inst_const;
  
  // Decoder signals
  logic [31:0]  fetched_instr_i;
  logic [1:0]   ex_op_a_sel_o;
  logic [2:0]   ex_op_b_sel_o;
  logic [4:0]   alu_op_o;
  logic         mem_req_o;
  logic        mem_we_o;
  logic [2:0]   mem_size_o;
  logic        gpr_we_a_o;
  logic        wb_src_sel_o;
  logic        illegal_instr_o;
  logic        branch_o;
  logic        jal_o;
  logic        jalr_o;
  logic        stall;
  logic        en_pc;
  
  // Instruction Constants
  wire [31:0] imm_I;
  assign imm_I = { 20'b0, instr_rdata_core[31:20] };
  
  wire [31:0] imm_S;
  assign imm_S = { 21'b0, instr_rdata_core[31:25], instr_rdata_core[11:7] };
  
  wire [31:0] imm_J;
  assign imm_J = { 12'b0, instr_rdata_core[31], instr_rdata_core[19:12], instr_rdata_core[20], instr_rdata_core[30:21]} << 1;
  
  wire [31:0] imm_B;
  assign imm_B = { 20'b0, instr_rdata_core[31], instr_rdata_core[7], instr_rdata_core[30:25], instr_rdata_core[11:7]};
  
  // Instruction memory
  assign instr_addr_core = PC;
  
  // Program Counter
  program_counter program_counter(
    .clk        (clk_i),
    .rst_n_i      (arstn_i),
    .additinal  (addPC),
    .en_add     (en_add),
    .jalr_add   (jalr_add),
    .jalr_o     (jalr_o),
    .en_pc      (en_pc),
    .pc         (PC)
  );
  
  // ALU module
  ALU_RISCV alu_modul (
    .ALU0p      (alu_op_o),
    .A          (alu_a),
    .B          (alu_b),
    .Result     (result),
    .Flag       (flag_result)
  );
  
  // Registers Module
  mem_16_32 mem16_32 (
    .clk        (clk_i),
    .adr1       (instr_rdata_core[19:15]),
    .adr2       (instr_rdata_core[24:20]),
    .adr3       (instr_rdata_core[11:7]),
    .wd3        (wData),
    .we         (gpr_we_a_o),
    .rd1        (rd1),
    .rd2        (rd2)
  );
  
  // Instructions Decoder
  decoder_riscv decoder(
    .fetched_instr_i    (instr_rdata_core),
    .ex_op_a_sel_o      (ex_op_a_sel_o),                         
    .ex_op_b_sel_o      (ex_op_b_sel_o),                         
    .alu_op_o           (alu_op_o),                                   
    .mem_req_o          (mem_req_o),                                 
    .mem_we_o           (mem_we_o),                                   
    .mem_size_o         (mem_size_o),                               
    .gpr_we_a_o         (gpr_we_a_o),                               
    .wb_src_sel_o       (wb_src_sel_o),                           
    .illegal_instr_o    (illegal_instr_o),                      
    .branch_o           (branch_o),                                   
    .jal_o              (jal_o),                                         
    .jalr_o             (jalr_o),
    .stall              (stall),  
    .en_pc              (en_pc)                                   
  );
  
  // Load And Save Module LAB-5
  logic [31:0] lsu_addr;
  assign lsu_addr = result;
  
  logic [31:0] lsu_data;
  
  // LSU
  miriscv_lsu miriscv_lsu(
    .clk_i              (clk_i),              // синхронизация                        // core
    .arst_n_i           (arstn_i),            // сброс
    .lsu_addr_i         (result),         // адрес по которому обращаемся
    .lsu_we_i           (mem_we_o),         // 1 - обращение к памяти
    .lsu_size_i         (mem_size_o),       // размер данных
    .lsu_data_i         (rd2),              // данные для записи в память
    .lsu_req_i          (mem_req_o),        // 1 - обращение к памяти
    .lsu_stall_req_o    (stall),            // !en_pc
    .lsu_data_o         (lsu_data),         // данные считанные из памяти
    .data_rdata_i       (data_rdata_i),  // запрошенные данные                   // ram
    .data_req_o         (data_req_o),    // 1 - обращение к памяти
    .data_we_o          (data_we_o),     // 1 - запрос на память
    .data_be_o          (data_be_o),     // к каким байтам идет обращение
    .data_addr_o        (data_addr_o),   // адрес по которому идет обращение
    .data_wdata_o       (data_wdata_o)   // данные которые требуется записать
  );

  always @(*)
  begin
    // Program counter
    addPC = branch_o? imm_B: imm_J;
    en_add = jal_o | flag_result & branch_o;
    jalr_add = rd1 + instr_rdata_core[31:20];

    // Register file
    adr1 = instr_rdata_core[22:18];
    adr2 = instr_rdata_core[17:13];
    adr3 = instr_rdata_core[4:0];
    // Register file switch
    inst_sw = instr_rdata_core[29:28];
    inst_const = instr_rdata_core[12:5];
    
    // Additional MUX for ALU input
    case(ex_op_a_sel_o)
      'b00: alu_a = rd1;
      'b01: alu_a = PC;
      'b10: alu_a = 0;
      default:  begin
        alu_a = 0;                  // Lutch fix
      end
    endcase
    
    case(ex_op_b_sel_o)
      'b000: alu_b = rd2;
      'b001: alu_b = imm_I;
      'b010: alu_b = instr_rdata_core[31:12];    // !TODO: Check scheme
      'b011: alu_b = imm_S;
      'b100: alu_b = 4;
      default:  begin
        alu_b = 0;                  // Lutch fix
      end
    endcase
    
    // MUX After ALU and DATA MEMOTY modules
    case(wb_src_sel_o)
      'b00: wData = result;
      'b01: wData = lsu_data;
    endcase
  end
  
endmodule
