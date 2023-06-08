`timescale 1ns / 1ps

module linear_pwm(
    input clk,
    input rst,
    output [2:0] rgb
    );
    
    parameter resolution = 8;
    parameter grad_thresh = 2499999;
    
    logic [31:0] dvsr = 4882;   // sysclk/(pwm_freq*2**8)
    logic [resolution:0] duty;
    logic pwm_out1;
    
    integer counter;
    logic gradient_pulse;
    logic [resolution:0] duty_reg;
    
    assign duty = duty_reg;
    
    pwm_enhanced #(.R(resolution)) p_i0(
        .clk(clk),
        .rst(rst),
        .dvsr(dvsr),
        .duty(duty),
        .pwm_out(pwm_out1)
    );
    
    assign rgb[0] = pwm_out1;
    assign rgb[1] = 0;
    assign rgb[2] = 0;
    
    always_ff@(posedge clk, posedge rst) begin
        if (rst) begin
            counter <= 0;
            duty_reg <= 0;
        end else begin
            if (counter < grad_thresh) begin
                counter <= counter + 1;
                gradient_pulse <= 0;
            end else begin
                counter <= 0;
                gradient_pulse <= 1;
            end
            if (gradient_pulse == 1) begin
                duty_reg <= duty_reg + 1;
            end
            if (duty_reg == 256) begin
                duty_reg <= 0;
            end
        end
    end
    
endmodule
