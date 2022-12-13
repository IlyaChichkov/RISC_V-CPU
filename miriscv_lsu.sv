`define RAM_DATA_BORDER 8

module miriscv_lsu(
    input clk_i,
    input arst_n_i,
    
    // core protocol
    input reg   [31:0]  lsu_addr_i,
    input reg           lsu_we_i,       // positive if write enabled
    input reg   [2:0]   lsu_size_i,     // data size
    input reg   [31:0]  lsu_data_i,
    input reg           lsu_req_i,      // memory request
    
    output reg           lsu_stall_req_o,
    output reg  [31:0]   lsu_data_o,
    
    // memory protocol
    input  reg  [31:0]   data_rdata_i,   // requested data memory
    output reg           data_req_o,     
    output reg           data_we_o,
    output reg  [3:0]    data_be_o,
    output reg  [31:0]   data_addr_o,
    output reg  [31:0]   data_wdata_o
    );

reg buff_stall = 1;

always@(posedge clk_i or posedge arst_n_i)
begin
    if(!arst_n_i || !buff_stall)
    begin
        buff_stall <= 1;
    end
    else
    begin
        buff_stall <= !lsu_req_i;
    end
end

always@(*)
begin
    lsu_stall_req_o = lsu_req_i & buff_stall;
    
    if(lsu_req_i == 1)
    begin
        if(lsu_we_i == 0)
        begin
            data_req_o  = 1;
            data_we_o   = 0;
            data_addr_o = lsu_addr_i;
            case (lsu_size_i)
            3'd0:
              case (lsu_addr_i[1:0])
                2'b00:
                  lsu_data_o = { {24{ data_rdata_i[7] }} , data_rdata_i[7:0] };
                2'b01:
                  lsu_data_o = { {24{ data_rdata_i[15] }}, data_rdata_i[15:8] };
                2'b10:
                  lsu_data_o = { {24{ data_rdata_i[23] }}, data_rdata_i[23:16] };
                2'b11:
                  lsu_data_o = { {24{ data_rdata_i[31] }}, data_rdata_i[31:14] };
                default:
                  lsu_data_o = 32'b0;
              endcase
            3'd1:
              case (lsu_addr_i[1:0])
                2'b00:
                  lsu_data_o = { {16{data_rdata_i[15]}} , data_rdata_i[15:0] };
                2'b10:
                  lsu_data_o = { {16{data_rdata_i[31]}} , data_rdata_i[31:16] };
                default:
                  lsu_data_o = 32'b0;
              endcase
                //lsu_data_o = { {16{ data_rdata_i[15] }}, data_rdata_i[15:0] };
            3'd2:
                lsu_data_o = data_rdata_i[31:0];
            3'd4:
              case (lsu_addr_i[1:0])
                2'b00:
                  lsu_data_o = { 24'b0 , data_rdata_i[7:0] };
                2'b01:
                  lsu_data_o = { 24'b0 , data_rdata_i[15:8] };
                2'b10:
                  lsu_data_o = { 24'b0 , data_rdata_i[23:16] };
                2'b11:
                  lsu_data_o = { 24'b0 , data_rdata_i[31:14] };
                default:
                  lsu_data_o = 32'b0;
                endcase
            3'd5:
              case (lsu_addr_i[1:0])
                2'b00:
                  lsu_data_o = { 16'b0 , data_rdata_i[15:0] };
                2'b10:
                  lsu_data_o = { 16'b0 , data_rdata_i[31:16] };
                default:
                  lsu_data_o = 32'b0;
                endcase
            default:
                lsu_data_o = 32'b0;
            endcase
        end
        else
        begin
            data_req_o = 1;
            data_we_o = 1;
            data_addr_o = lsu_addr_i;
            case (lsu_size_i)
            3'd0:
                begin
                    data_wdata_o = { 4{lsu_data_i[7:0]}};
                    case (lsu_addr_i[1:0])
                        2'b00:
                            data_be_o = 4'b0001;
                        2'b01:
                            data_be_o = 4'b0010;
                        2'b10:
                            data_be_o = 4'b0100;
                        2'b11:
                            data_be_o = 4'b1000;
                        default:
                            data_be_o = 4'b0000;
                    endcase
                end
             3'd1:
                begin
                    data_wdata_o <= { 2{lsu_data_i[15:0]}};
                    case (lsu_addr_i[1:0])
                        2'b00:
                            data_be_o = 4'b0011;
                        2'b10:
                            data_be_o = 4'b1100;
                        default:
                            data_be_o = 4'b0000;
                    endcase
                end
             3'd2:
                begin
                    data_wdata_o <= lsu_data_i[31:0];
                    
                    if(lsu_addr_i[1:0] == 2'b00)
                    begin
                        data_be_o = 4'b1111;
                    end
                    else
                    begin
                        data_be_o = 4'b0000;
                    end
                end
              default:
                data_be_o = 4'b0000;
             endcase
        end
    end
    else
    begin
        data_req_o = 0;
        data_we_o = 0;
    end
end
    
endmodule
