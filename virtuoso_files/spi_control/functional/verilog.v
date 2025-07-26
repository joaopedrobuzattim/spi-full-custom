//Verilog HDL for "joaoPedroBuzatti_HDL", "spi_control" "functional"


`timescale 1ns/1ps

module spi_control (
    input wire [1:0] destination,
    input wire [7:0] data_in,
    input wire CLK,
    output wire CS,
    output wire S_OUT,
    output wire S_CLK
);

	parameter REGISTER_WIDTH = 8;
	
    reg [1:0] count_clk = 2'd0;
    reg clk_out =  1'd0;
    reg [1:0] current_state = 2'd0;
    reg [1:0] next_state = 2'd0;
	
    reg cs_internal = 1'd1;
    reg [REGISTER_WIDTH:0] shift_reg = 9'd0;
    integer cycle_count = 0;
    integer max_cycles = 0;

    assign CS = cs_internal;
    assign S_CLK = clk_out;

    // Clock Divider
    always @(posedge CLK) begin
         if (count_clk < 2'd3) begin
            count_clk <= count_clk + 1;
        end else begin
            count_clk <= 2'b0;
            clk_out <= ~clk_out;
        end
    end

    // FSM State Change
    always @(posedge clk_out) begin
        current_state <= next_state;
    end

    // CS Control
    always @(negedge clk_out) begin
        if (current_state == 2'd0) begin
            cs_internal <= 1'b0;
        end else if  (current_state == 2'd3 && cycle_count == max_cycles) begin
            cs_internal <= 1'b1;
        end
    end

    // Max Cycles Control
    always @(*) begin
        max_cycles = (destination + 1) * (REGISTER_WIDTH);
    end

    //reg s_out_buffer;
    assign S_OUT = shift_reg[0];


   always @(negedge clk_out)
   begin
    if(current_state == 2'd0 ) begin
      shift_reg <= {data_in, 1'b0};
    end
    else if (current_state == 2'd3) begin
      shift_reg <= {1'b0, shift_reg[8:1]};
    end
   end
   

    // FSM Logic
    always @(posedge clk_out) begin
            case (current_state)
                2'd0: begin
                    next_state <= 2'd3;
                end
                2'd1: begin
                    next_state <= 2'd3;
                end
                2'd3: begin
                    if (cycle_count == max_cycles) begin
                        next_state <= 2'd0;
                        cycle_count <= 0;
                    end else begin
                        next_state <= 2'd3;
                        cycle_count <= cycle_count + 1;
                    end
                end
                default: begin
                    next_state <= 2'd0;
                end
            endcase
    end

endmodule

