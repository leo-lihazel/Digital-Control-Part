////////////////////////////////////////////////////////////////////////////////// Filename    : block.v// Author      : lihuang       5//6/2020// Description : Verilog module for digital control block////////////////////////////////////////////////////////////////////////////////`timescale 1ns/1psmodule block(clk,rst,data,n_data,n_clk,r,g,b);input       clk;input       rst;input       data;output      n_data;output      n_clk;output      [11:0]r;output      [11:0]g;output      [11:0]b;wire [10:0] count;wire rst2;wire w_en;wire [15:0] sf_reg;reg  [15:0] sg_reg;reg  n_data_en;reg  n_clk_en;reg  [38:0]rgb;reg  [11:0] r;reg  [11:0] g;reg  [11:0] b;   //multiplexer: should output the data or frame header or notassign n_data=(n_data_en==1)?              (w_en ==1 && count>=10'd40 && count <= 10'd55)? sg_reg[0]:data              :0;//multiplexer: should output the data clock or notassign n_clk=(n_clk_en ==1)? clk:0;//multiplexer: pass data or get hold frame headerassign w_en=(sf_reg==16'h7fff)? 1:0;//use shifter register to get the rgb informationalways @(posedge clk)    begin        if (!rst2)            begin                rgb<=0;                r<=0;                g<=0;                b<=0;            end        else if (w_en==0)            begin                rgb<=0;                r<=0;                g<=0;                b<=0;            end        else if (w_en==1)            begin                if (count >= 10'd16 && count <= 10'd55)                    begin                        rgb<={rgb[37:0],data};                        r<=0;                        g<=0;                        b<=0;                    end                else if (count >= 10'd55)                    beginrgb<=rgb;                        b<= rgb[11:0];                        g<= rgb[24:13];                        r<= rgb[37:26];                    end            end        else            begin                rgb<=0;                r<=0;                g<=0;                b<=0;            end    end//concatenate the remaining data with the frame header and pass them out   always @(posedge clk)    begin        if (!rst2)            begin                n_data_en<=0;                sg_reg<=0;                n_clk_en<=0;            end        else if (count < 10'd17)            begin                n_data_en<=0;                sg_reg<=0;                n_clk_en<=0;            end        else            begin                 if (w_en==0)                    begin                        n_data_en<=1;                        sg_reg<=0;                        n_clk_en<=1;                    end                else if (w_en==1)                    beginif (count == 10'd38)                            begin                                n_data_en<=0;                                sg_reg<=sf_reg;                                n_clk_en<=0;                            end                        else if (count>=10'd40 && count <= 10'd55)                            begin                                n_data_en<=1;                                sg_reg<={sg_reg[14:0],sg_reg[15]};                                n_clk_en<=1;                            end                        else if (count > 10'd55)                            begin                                n_data_en<=1;                                sg_reg<=sg_reg;                                n_clk_en<=1;                            end                        else                            begin                                n_data_en<=0;                                sg_reg<=sg_reg;                                n_clk_en<=0;                            end                    end             end    endcounter1 c1(    .clk(clk),    .rst(rst),    .counter(count)        ); //use shifter register s1 to detect the corrent frame header        shift_reg s1(    .clk(clk),    .rst(rst),    .data(data),    .w_en(w_en),    .count(count),    .sf_reg(sf_reg)        );Endmodule////////////////////////////////////////////////////////////////////////////////// Filename    : shift_reg.v// Author      : lihuang       5/6/2020// Description : Verilog module for shifter register////////////////////////////////////////////////////////////////////////////////module shift_reg(clk,rst,data,w_en,sf_reg,count);input   clk;input   rst;input   [10:0]count;input   data;input   w_en;output [15:0]sf_reg;reg [15:0] sf_reg;always @ (posedge clk)    begin        if(!rst)            begin                sf_reg<=0;            end        else if (w_en==1 || count>10'd15)            begin                sf_reg<=sf_reg;            end        else             begin                sf_reg<={sf_reg[14:0],data};            end    endendmodule////////////////////////////////////////////////////////////////////////////////// Filename    : counter.v// Author      : lihuang       4//22/2020// Description : Verilog module for counter////////////////////////////////////////////////////////////////////////////////module counter(clk,rst,count);input clk;input rst;output count;reg counter;wire rst_2;assign rst_2 = rst;assign count =counter;//use counter to define the period value of outputalways @ (posedge)       begin        if (!rst_2)            begin                  counter<=0;            end        else if (counter == 1'b1)            begin               counter<=0;            end        else            begin                counter<=counter+1;            end    endendmodule////////////////////////////////////////////////////////////////////////////////// Filename    : block_tb.v// Author      : lihuang       5/6/2020// Description : Verilog testbench module for digital block control testbench////////////////////////////////////////////////////////////////////////////////`timescale 1ns/1psmodule block_tb;reg clk;reg rst;reg data;wire n_data;wire n_clk;wire [11:0]r;wire [11:0]g;wire [11:0]b;reg [31:0]data_in;initial     begin        clk=0;        forever #5 clk=~clk;    end    initial     begin        #2 rst=0;        #17 rst=1;        #700 $finish;    end    initial     begin        data_in =32'b0;        #30 data_in=32'b1;        //#40  data_in=32‘d1;   // test vector for 2 ”0” and 14 “1”        #150 data_in = 32'd0;        forever #10 data_in = {$random}%2;    endinitial     begin        data= data_in[0];        #30 data= data_in[0];        //#40  data= data_in[0];        #150 data=data_in[0];        forever #10 data=data_in[0];    endblock b1(    .clk(clk),    .rst(rst),    .data(data),    .n_data(n_data),    .n_clk(n_clk),    .r(r),    .g(g),    .b(b)        );initial    begin        $vcdpluson;    endendmodule