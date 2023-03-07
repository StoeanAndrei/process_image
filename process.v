`timescale 1ns / 1ps

module process (
        input                clk,		    	// clock 
        input  [23:0]        in_pix,	        // valoarea pixelului de pe pozitia [in_row, in_col] din imaginea de intrare (R 23:16; G 15:8; B 7:0)
        input  [8*512-1:0]   hiding_string,     // sirul care trebuie codat
        output [6-1:0]       row, col, 	        // selecteaza un rand si o coloana din imagine
        output               out_we, 		    // activeaza scrierea pentru imaginea de iesire (write enable)
        output [23:0]        out_pix,	        // valoarea pixelului care va fi scrisa in imaginea de iesire pe pozitia [out_row, out_col] (R 23:16; G 15:8; B 7:0)
        output               gray_done,		    // semnaleaza terminarea actiunii de transformare in grayscale (activ pe 1)
        output               compress_done,		// semnaleaza terminarea actiunii de compresie (activ pe 1)
        output               encode_done        // semnaleaza terminarea actiunii de codare (activ pe 1)
    );	
    
	`define INIT 				0
	`define GRAY				1
	`define DONE				2
	`define AMBTC 				3
	`define BLOCKINIT 		4
	`define AVG 				5
	`define VAR 				6
	`define LH 					8
	`define RECONS 			9
	`define BLOCK 				10
	
	// variabile necesare pentru task 1
	reg [7 : 0] in_R;
	reg [7 : 0] in_G;
	reg [7 : 0] in_B;
	
	reg [7 : 0] min;
	reg [7 : 0] max;
	
	reg [8 : 0] av;
	
	reg gd = 0;
	assign gray_done = gd;
	
	reg [23 : 0] op;
	assign out_pix = op;
	
	reg [6 : 0] r = 0;
	reg [6 : 0] c = 0;
	
	reg [6 : 0] r_next = 0;
	reg [6 : 0] c_next = 0;
	
	reg [6-1 : 0] rl;
	reg [6-1 : 0] cl;
	assign row = rl;
	assign col = cl;
	
	reg owe;
	assign out_we = owe;
	
	reg 	[23 : 0] 	state = `INIT;
	reg 	[23 : 0]		next_state;
	
	// variabile necesare pentru task 2
	reg [12 : 0] M = 4;
	
	reg cd = 0;
	assign compress_done = cd;
	
	integer abs = 0;
	
	reg [28 : 0] avg = 0;
	reg [28 : 0] avg_next = 0;
	reg [28 : 0] var = 0;
	reg [28 : 0] var_next = 0;
	reg [3 : 0] b = 0;
	reg [3 : 0] next_b = 0;
	reg [28 : 0] Lm = 0;
	reg [28 : 0] Hm = 0;
	
	reg map [3 : 0][3 : 0];
	
	reg [6 : 0] blockr = 0;
	reg [6 : 0] blockc = 0;
	
	reg [6 : 0] blockr_next = 0;
	reg [6 : 0] blockc_next = 0;
	
	// variabile necesare pentru task 3
	
	reg ed = 0;
	assign encode_done = ed;
	
   reg 	[31 : 0] 			base3_noreg = 0;
	wire  [31 : 0] 			base3_no;
	assign base3_no = base3_noreg;
	
	reg 							donereg = 0;
   wire 							done;
	assign done = donereg;
	
   reg 	[15 : 0] 			base2_no = 0;
   reg 							en = 0;
	
    //TODO - instantiate base2_to_base3 here
	 
	 base2_to_base3 b2tb3(base3_no, done, base2_no, en, clk);
    
    //TODO - build your FSM here
	 
	always @(posedge clk) begin
		state <= next_state;
		c <= c_next; 
		r <= r_next;
		blockc <= blockc_next;
		blockr <= blockr_next;
		b <= next_b;
		avg <= avg_next;
		var <= var_next;
	end
	
	always @(*) begin
		case (state)
			`INIT: begin
				r_next = 0;
				c_next = 0;
				gd = 0;
				cd = 0;
				
				next_state = `GRAY;
			end
			
			`GRAY: begin
				in_R = in_pix[23 : 16];
				in_G = in_pix[15 : 8];
				in_B = in_pix[7 : 0];
				
				min = 0;
				max = 0;
				av = 0;
			
				if (in_R >= in_G && in_R >= in_B) begin
					max = in_R;
				end
				else if (in_G >= in_R && in_G >= in_B) begin
					max = in_G;
				end
				else if (in_B >= in_G && in_B >= in_R) begin
					max = in_B;
				end
				
				if (in_R <= in_G && in_R <= in_B) begin
					min = in_R;
				end
				else if (in_G <= in_R && in_G <= in_B) begin
					min = in_G;
				end
				else if (in_B <= in_G && in_B <= in_R) begin
					min = in_B;
				end
				
				av = min + max;
				av = av / 2;
				owe = 1;
				
				op[7 : 0] = 0;
				op[15 : 8] = av;
				op[23 : 16] = 0;
				
				c_next = c+1;
				if (c_next == 64) begin
					c_next = 0;
					r_next = r+1;
				end
				
				cl = c_next;
				rl = r_next;
				
				if (r_next == 64) begin
					r_next = 0;
					c_next = 0;
					next_state = `DONE;
				end
				else if (r_next < 64) begin
					next_state = `GRAY;
				end
			end
			
			`DONE: begin
				gd = 1;
				next_state = `AMBTC;
			end
			
			`AMBTC:begin
				M = 4;
				blockr = 0;
				blockc = 0;
				blockr_next = 0;
				blockc_next = 0;
				cd = 0;
				owe = 0;
				
				next_state = `BLOCKINIT;
			end
			
			`BLOCKINIT: begin 
				avg = 0;
				var = 0;
				avg_next = 0;
				var_next = 0;
				Lm = 0;
				Hm = 0;
				r = 0;
				c = 0;
				r_next = 0;
				c_next = 0;
				next_b = 0;
				b = 0;
				owe = 0;
				
				next_state = `AVG;
			end
				
			`AVG: begin
				cl = blockc*M + c;
				rl = blockr*M + r;
					
				avg_next = avg + in_pix[15 : 8];
					
				c_next = c+1;
				if (c_next == M) begin
					r_next = r+1;
					c_next = 0;
				end
					
				if (r_next == M) begin
					avg_next = avg_next / (M*M); 
					r_next = 0;
					c_next = 0;
					next_state = `VAR;
				end
				else if (r_next < M) begin
					next_state = `AVG;
				end
			end
			
			`VAR: begin
				cl = blockc*M + c;
				rl = blockr*M + r;
					
				if (avg <= in_pix[15 : 8]) begin
					abs = in_pix[15 : 8] - avg;
					next_b = b+1;
				end
				else if (avg > in_pix[15 : 8]) begin
					abs = avg - in_pix[15 : 8];
					next_b = b;
				end
					
				var_next = var + abs;
					
				c_next = c+1;
				if (c_next == M) begin
					r_next = r+1;
					c_next = 0;
				end
					
				if (r_next == M) begin
					var_next = var_next / (M*M); 
					r_next = 0;
					c_next = 0;
					next_state = `LH;
				end
				else if (r_next < M) begin
					next_state = `VAR;
				end
			end
			
			`LH: begin
				if (b > 0) begin
					if (avg > ((M*M*var) / (2*(M*M - b)))) begin
						Lm = avg - ((M*M*var) / (2*(M*M - b)));
					end 
					else if (avg <= ((M*M*var) / (2*(M*M - b)))) begin
						Lm = ((M*M*var) / (2*(M*M - b))) - avg;
					end
					Hm = avg + ((M*M*var) / (2*b));
					end
				else begin
					Lm = 1;
					Hm = 1;
				end
				
				next_state = `RECONS;
			end
			
			`RECONS: begin
				owe = 1;
					
				cl = blockc*M + c;
				rl = blockr*M + r;
					
				if (in_pix[15 : 8] < avg) begin 
					op[7 : 0] = 0;
					op[15 : 8] = Lm;
					op[23 : 16] = 0;
				end
				else if (in_pix[15 : 8] >= avg) begin 
					op[7 : 0] = 0;
					op[15 : 8] = Hm;
					op[23 : 16] = 0;
				end
					
				c_next = c+1;
				if (c_next == M) begin
					r_next = r+1;
					c_next = 0;
				end
					
				if (r_next == M) begin
					r_next = 0;
					c_next = 0;
					next_state = `BLOCK;
				end
				else if (r_next < M) begin
					next_state = `RECONS;
				end
			end
			
			`BLOCK: begin
				blockc_next = blockc+1;
				if (blockc_next == 16) begin
					blockc_next = 0;
					blockr_next = blockr+1;
				end
				
				if (blockr_next == 16) begin
					cd = 1;
				end
				else if (blockc_next < 16) begin
					next_state = `BLOCKINIT;
				end
			end
		endcase
	end
endmodule 