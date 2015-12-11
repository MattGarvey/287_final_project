module graphingCalc(clk, rst, color, LEDR, 
				hsync, vsync, vga_R, vga_G, vga_B, vga_blank, vga_clk, saveCoef, signpick, signs, doneInput, coefSelect, coefInVal, hexOne, hexTwo, hexThree, hexFour, hexFive, hexSix, hexSeven, hexZero //vga_sync,
				//text_light,
				//state_ssd, level_ssd, level_num_ssd, LEDR
);

	wire [15:0] coefZero, coefOne, coefTwo, coefThree, coefFour, coefFive, coefSix, coefSeven; 
	
	// outputs for nicks module
output [7:0] signs;
output [6:0] hexOne, hexTwo, hexThree, hexFour, hexFive, hexSix, hexSeven, hexZero;
//

// inputs for nicks module
input saveCoef, doneInput, signpick;
input [2:0] coefSelect;
input [3:0] coefInVal;
//

// nicks module instantiated
calculatorOne inputstuffpls(clk, rst, saveCoef, donePulse, signpick, signs, doneInput, coefSelect, coefInVal, hexOne, hexTwo, hexThree, hexFour, hexFive, hexSix, hexSeven, hexZero, coefOne, coefTwo, coefThree, coefFour, coefFive, coefSix, coefSeven, coefZero);		
//

	 
	input clk, rst;
	
	input [3:0] color;
	
	reg [3:0] colorS;
	
	initial colorS = 4'b1111;
	
	// vga sigs
	output hsync, vsync;
	output reg [7:0] vga_R, vga_G, vga_B;
	
	//output reg text_light;
	//output vga_sync;
	output vga_blank;
	output vga_clk;
	output reg [4:0] LEDR;
	
	
	//--------------FSM------------------
	reg [3:0] NS, S; // FSM
	reg [26:0] c; //counter for time
	//reg [3:0] cc = 3'b000; //counter for sequence correct
	reg [2:0] level;
	reg [1:0] state;
	reg match, win;
	reg [3:0]colorStore; 
	//----------------------------------
	
	wire [7:0] gvga_R, gvga_G, gvga_B, tvga_R, tvga_G, tvga_B;
	reg [9:0] pixel_x;
	reg [8:0] pixel_y;
	reg img_on;
	
//------Initialize VGA (modified code from Brandon Hill)------//
	reg vga_HS, vga_VS;
	reg clock25;
	
	wire CounterXmaxed = (pixel_x==799); //799 full width of field including front and back porches and sync
	wire CounterYmaxed = (pixel_y==525); //525 full length of field including front and back porches and sync
 
//-----25 MHz clock-----//
	always @(posedge clk)
		if(clock25)
			begin
				clock25 = 0;
			end
		else
			begin
				clock25 = 1;
			end
//----- end clock -----//


//-----Synchronize VGA Output-----//
	assign vga_clk = clock25;
	assign vga_blank = vsync & hsync;
	//assign vga_sync = 1;
		
	always @(posedge clock25)
		if(CounterXmaxed && ~CounterYmaxed)
			begin
			pixel_x <= 0;
			pixel_y <= pixel_y + 1'b1;
			end 
		else if (~CounterXmaxed)
			pixel_x <= pixel_x + 1'b1;
		else if (CounterXmaxed && CounterYmaxed)
			begin
			pixel_y <= 0;
			pixel_x <= 0;
			end
//	
	always @(posedge clock25)
		begin
			vga_HS <= (pixel_x <= 96);   // active for 16 clocks
			vga_VS <= (pixel_y <= 2);   // active for 800 clocks
		end 

	assign hsync = ~vga_HS;
	assign vsync = ~vga_VS;
//----- end synchronization -----//
	

initial colorStore = 4'b0000;

always@(negedge color[3], negedge color[2], negedge color[1], negedge color[0])
begin
		if (color[3] == 0)
			colorStore <= 4'b1000;
		else if(color[2] == 0)
			colorStore <= 4'b0100;
		else if(color[1] == 0)
			colorStore <= 4'b0010;
		else
			colorStore <= 4'b0001;
		
end 

parameter RESET = 4'b0000,
			START = 4'b0001,
			L1S = 4'b0010,
			L1PR = 4'b0011,
			L1PY = 4'b0100,
			L1PG = 4'b0101,
			L1PB = 4'b0111;
		
			
always@(posedge clk or negedge rst) //reset state transition
begin	
	if(rst == 1'b0)
		S <= RESET;
	else
		S <= NS;
end

always@(*) //state transition // change back to combinational (*)
begin
	case(S) 
		RESET:
		begin
			NS = START;
		end	
		START:
		begin
			if(colorStore == 4'b1000)
			begin
				NS = L1S;
			end
			else
			begin
				NS = START;
			end
		end
	endcase
end		

		
	
always@(posedge clk or negedge rst)
begin
	if (rst == 1'b0)
	begin
		c <= 27'd0;
		match <= 1'b0;
		state <= 2'b00;
		
		
		LEDR[0] <= 1;
		LEDR[1] <= 0;
		LEDR[2] <= 0;
		LEDR[3] <= 0;
		LEDR[4] <= 0;
	end
	else
	begin
		case(S)
			RESET:
				begin
					
					
					LEDR[0] <= 1;
					LEDR[1] <= 0;
					LEDR[2] <= 0;
					LEDR[3] <= 0;
					LEDR[4] <= 0;
				
				end
			START:
				begin
					
					LEDR[0] <= 0;
					LEDR[1] <= 1;
					LEDR[2] <= 0;
					LEDR[3] <= 0;
					LEDR[4] <= 0;
				end
			
			default:
			begin
				match <= 1'b1;
				state <= 2'b00;
				
			end
		endcase
	end
end

	
//------------------------------------------------------------------------------------------------------------		

//------------------------------------------------------------------------
		
		//constant declaration
	localparam Max_X = 788;
	localparam Max_Y = 490;
	

	//status signals
	wire bounding_box;
	
parameter

	TXTPIXEND = 4,	// HEIGHT AND WIDTH OF TXT PIXELS
	
	ROWDOWN = 4, // ROWS DOWN
	
	PIXEND = 12,	// DIM OF PIXEL
	
	RIGHT = 10, // RIGHT SIDE OF X
	
	LEFT = 0, // LEFT SIDE OF X
	
	MID = 5, // MID OF X
	
	XWIDTH = 8, // WIDTH OF X
	
	POWWIDTH = 8, // WIDTH OF POW X
	
	PLUSWIDTH = 16, // WIDTH OF PLUS
	
	ROW1 = 60, // TOP EDGE OF THE ROW
	
	POWROW = 45, // TOP EDGE OF THE POWER ROW
	
	COEFW = 8, // WIDTH OF DRAWN COEF
	
	SPC = 10, // SPACE BTW LETTERS
	
	SET = COEFW + SPC + XWIDTH + SPC + POWWIDTH + PLUSWIDTH + SPC, // ONE FULL 'SET' OF COEFF
	
	STARTTXT = 210; // LEFT BUFFER TO START TEXT

// ( pixel_x >= LEFT_EDGE && pixel_x <= RIGHT_EDGE && pixel_y <= BOT_EDGE && pixel_y >= TOP_EDGE );

	wire [15:0] 	ynx25, ynx24, ynx23, ynx22, ynx21,  
					ynx20, ynx19, ynx18, ynx17, ynx16,  
					ynx15, ynx14, ynx13, ynx12, ynx11,  
					ynx10, ynx09, ynx08, ynx07, ynx06,  
					ynx05, ynx04, ynx03, ynx02, ynx01,  
					yxx00, 
					ypx01, ypx02, ypx03, ypx04, ypx05,  
					ypx06, ypx07, ypx08, ypx09, ypx10,  
					ypx11, ypx12, ypx13, ypx14, ypx15,  
					ypx16, ypx17, ypx18, ypx19, ypx20,
					ypx21, ypx22, ypx23, ypx24, ypx25;

	assign ynx25 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (-16'd25 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (-16'd25 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (-16'd25 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (-16'd25 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (-16'd25 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (-16'd25 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * -16'd25) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ynx24 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (-16'd24 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (-16'd24 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (-16'd24 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (-16'd24 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (-16'd24 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (-16'd24 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * -16'd24) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ynx23 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (-16'd23 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (-16'd23 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (-16'd23 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (-16'd23 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (-16'd23 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (-16'd23 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * -16'd23) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ynx22 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (-16'd22 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (-16'd22 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (-16'd22 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (-16'd22 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (-16'd22 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (-16'd22 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * -16'd22) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ynx21 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (-16'd21 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (-16'd21 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (-16'd21 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (-16'd21 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (-16'd21 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (-16'd21 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * -16'd21) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ynx20 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (-16'd20 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (-16'd20 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (-16'd20 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (-16'd20 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (-16'd20 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (-16'd20 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * -16'd20) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ynx19 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (-16'd19 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (-16'd19 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (-16'd19 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (-16'd19 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (-16'd19 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (-16'd19 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * -16'd19) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ynx18 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (-16'd18 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (-16'd18 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (-16'd18 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (-16'd18 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (-16'd18 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (-16'd18 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * -16'd18) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ynx17 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (-16'd17 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (-16'd17 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (-16'd17 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (-16'd17 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (-16'd17 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (-16'd17 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * -16'd17) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ynx16 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (-16'd16 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (-16'd16 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (-16'd16 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (-16'd16 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (-16'd16 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (-16'd16 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * -16'd16) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ynx15 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (-16'd15 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (-16'd15 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (-16'd15 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (-16'd15 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (-16'd15 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (-16'd15 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * -16'd15) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ynx14 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (-16'd14 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (-16'd14 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (-16'd14 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (-16'd14 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (-16'd14 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (-16'd14 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * -16'd14) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ynx13 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (-16'd13 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (-16'd13 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (-16'd13 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (-16'd13 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (-16'd13 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (-16'd13 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * -16'd13) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ynx12 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (-16'd12 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (-16'd12 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (-16'd12 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (-16'd12 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (-16'd12 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (-16'd12 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * -16'd12) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ynx11 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (-16'd11 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (-16'd11 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (-16'd11 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (-16'd11 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (-16'd11 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (-16'd11 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * -16'd11) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ynx10 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (-16'd10 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (-16'd10 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (-16'd10 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (-16'd10 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (-16'd10 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (-16'd10 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * -16'd10) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ynx09 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (-16'd09 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (-16'd09 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (-16'd09 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (-16'd09 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (-16'd09 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (-16'd09 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * -16'd09) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ynx08 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (-16'd08 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (-16'd08 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (-16'd08 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (-16'd08 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (-16'd08 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (-16'd08 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * -16'd08) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ynx07 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (-16'd07 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (-16'd07 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (-16'd07 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (-16'd07 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (-16'd07 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (-16'd07 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * -16'd07) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ynx06 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (-16'd06 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (-16'd06 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (-16'd06 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (-16'd06 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (-16'd06 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (-16'd06 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * -16'd06) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ynx05 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (-16'd05 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (-16'd05 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (-16'd05 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (-16'd05 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (-16'd05 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (-16'd05 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * -16'd05) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ynx04 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (-16'd04 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (-16'd04 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (-16'd04 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (-16'd04 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (-16'd04 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (-16'd04 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * -16'd04) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ynx03 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (-16'd03 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (-16'd03 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (-16'd03 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (-16'd03 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (-16'd03 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (-16'd03 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * -16'd03) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ynx02 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (-16'd02 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (-16'd02 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (-16'd02 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (-16'd02 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (-16'd02 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (-16'd02 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * -16'd02) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ynx01 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (-16'd01 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (-16'd01 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (-16'd01 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (-16'd01 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (-16'd01 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (-16'd01 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * -16'd01) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign yxx00 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (-16'd00 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (-16'd00 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (-16'd00 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (-16'd00 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (-16'd00 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (-16'd00 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * -16'd00) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ypx01 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (16'd01 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (16'd01 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (16'd01 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (16'd01 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (16'd01 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (16'd01 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * 16'd01) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ypx02 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (16'd02 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (16'd02 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (16'd02 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (16'd02 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (16'd02 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (16'd02 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * 16'd02) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ypx03 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (16'd03 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (16'd03 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (16'd03 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (16'd03 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (16'd03 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (16'd03 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * 16'd03) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ypx04 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (16'd04 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (16'd04 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (16'd04 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (16'd04 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (16'd04 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (16'd04 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * 16'd04) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ypx05 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (16'd05 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (16'd05 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (16'd05 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (16'd05 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (16'd05 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (16'd05 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * 16'd05) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ypx06 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (16'd06 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (16'd06 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (16'd06 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (16'd06 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (16'd06 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (16'd06 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * 16'd06) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ypx07 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (16'd07 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (16'd07 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (16'd07 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (16'd07 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (16'd07 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (16'd07 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * 16'd07) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ypx08 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (16'd08 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (16'd08 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (16'd08 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (16'd08 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (16'd08 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (16'd08 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * 16'd08) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ypx09 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (16'd09 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (16'd09 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (16'd09 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (16'd09 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (16'd09 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (16'd09 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * 16'd09) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ypx10 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (16'd10 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (16'd10 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (16'd10 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (16'd10 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (16'd10 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (16'd10 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * 16'd10) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ypx11 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (16'd11 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (16'd11 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (16'd11 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (16'd11 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (16'd11 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (16'd11 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * 16'd11) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ypx12 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (16'd12 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (16'd12 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (16'd12 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (16'd12 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (16'd12 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (16'd12 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * 16'd12) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ypx13 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (16'd13 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (16'd13 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (16'd13 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (16'd13 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (16'd13 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (16'd13 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * 16'd13) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ypx14 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (16'd14 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (16'd14 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (16'd14 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (16'd14 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (16'd14 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (16'd14 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * 16'd14) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ypx15 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (16'd15 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (16'd15 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (16'd15 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (16'd15 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (16'd15 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (16'd15 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * 16'd15) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ypx16 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (16'd16 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (16'd16 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (16'd16 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (16'd16 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (16'd16 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (16'd16 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * 16'd16) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ypx17 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (16'd17 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (16'd17 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (16'd17 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (16'd17 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (16'd17 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (16'd17 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * 16'd17) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ypx18 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (16'd18 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (16'd18 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (16'd18 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (16'd18 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (16'd18 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (16'd18 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * 16'd18) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ypx19 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (16'd19 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (16'd19 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (16'd19 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (16'd19 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (16'd19 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (16'd19 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * 16'd19) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ypx20 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (16'd20 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (16'd20 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (16'd20 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (16'd20 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (16'd20 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (16'd20 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * 16'd20) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ypx21 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (16'd21 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (16'd21 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (16'd21 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (16'd21 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (16'd21 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (16'd21 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * 16'd21) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ypx22 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (16'd22 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (16'd22 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (16'd22 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (16'd22 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (16'd22 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (16'd22 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * 16'd22) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ypx23 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (16'd23 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (16'd23 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (16'd23 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (16'd23 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (16'd23 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (16'd23 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * 16'd23) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ypx24 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (16'd24 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (16'd24 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (16'd24 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (16'd24 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (16'd24 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (16'd24 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * 16'd24) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	assign ypx25 = ((signs[7]? (-16'd1 * coefSeven) : coefSeven) * (16'd25 ** 16'd7)) + ((signs[6]? (-16'd1 * coefSix) : coefSix)  * (16'd25 ** 16'd6)) + ((signs[5]? (-16'd1 * coefFive) : coefFive)  * (16'd25 ** 16'd5)) + ((signs[4]? (-16'd1 * coefFour) : coefFour)  * (16'd25 ** 16'd4)) + ((signs[3]? (-16'd1 * coefThree) : coefThree)  * (16'd25 ** 16'd3)) + ((signs[2]? (-16'd1 * coefTwo) : coefTwo)  * (16'd25 ** 16'd2)) + ((signs[1]? (-16'd1 * coefOne) : coefOne)  * 16'd25) + (signs[0]? (-16'd1 * coefZero) : coefZero);
	
	assign isN25 = ((ynx25 >= 16'd25 || ynx25 <= -16'd25) ? 0 : 1);
	assign isN24 = ((ynx24 >= 16'd25 || ynx24 <= -16'd25) ? 0 : 1);
	assign isN23 = ((ynx23 >= 16'd25 || ynx23 <= -16'd25) ? 0 : 1);
	assign isN22 = ((ynx22 >= 16'd25 || ynx22 <= -16'd25) ? 0 : 1);
	assign isN21 = ((ynx21 >= 16'd25 || ynx21 <= -16'd25) ? 0 : 1);
	assign isN20 = ((ynx20 >= 16'd25 || ynx20 <= -16'd25) ? 0 : 1);
	assign isN19 = ((ynx19 >= 16'd25 || ynx19 <= -16'd25) ? 0 : 1);
	assign isN18 = ((ynx18 >= 16'd25 || ynx18 <= -16'd25) ? 0 : 1);
	assign isN17 = ((ynx17 >= 16'd25 || ynx17 <= -16'd25) ? 0 : 1);
	assign isN16 = ((ynx16 >= 16'd25 || ynx16 <= -16'd25) ? 0 : 1);
	assign isN15 = ((ynx15 >= 16'd25 || ynx15 <= -16'd25) ? 0 : 1);
	assign isN14 = ((ynx14 >= 16'd25 || ynx14 <= -16'd25) ? 0 : 1);
	assign isN13 = ((ynx13 >= 16'd25 || ynx13 <= -16'd25) ? 0 : 1);
	assign isN12 = ((ynx12 >= 16'd25 || ynx12 <= -16'd25) ? 0 : 1);
	assign isN11 = ((ynx11 >= 16'd25 || ynx11 <= -16'd25) ? 0 : 1);
	assign isN10 = ((ynx10 >= 16'd25 || ynx10 <= -16'd25) ? 0 : 1);
	assign isN09 = ((ynx09 >= 16'd25 || ynx09 <= -16'd25) ? 0 : 1);
	assign isN08 = ((ynx08 >= 16'd25 || ynx08 <= -16'd25) ? 0 : 1);
	assign isN07 = ((ynx07 >= 16'd25 || ynx07 <= -16'd25) ? 0 : 1);
	assign isN06 = ((ynx06 >= 16'd25 || ynx06 <= -16'd25) ? 0 : 1);
	assign isN05 = ((ynx05 >= 16'd25 || ynx05 <= -16'd25) ? 0 : 1);
	assign isN04 = ((ynx04 >= 16'd25 || ynx04 <= -16'd25) ? 0 : 1);
	assign isN03 = ((ynx03 >= 16'd25 || ynx03 <= -16'd25) ? 0 : 1);
	assign isN02 = ((ynx02 >= 16'd25 || ynx02 <= -16'd25) ? 0 : 1);
	assign isN01 = ((ynx01 >= 16'd25 || ynx01 <= -16'd25) ? 0 : 1);
	assign isX00 = ((yxx00 >= 16'd25 || yxx00 <= -16'd25) ? 0 : 1);
	assign isP01 = ((ypx01 >= 16'd25 || ypx01 <= -16'd25) ? 0 : 1);
	assign isP02 = ((ypx02 >= 16'd25 || ypx02 <= -16'd25) ? 0 : 1);
	assign isP03 = ((ypx03 >= 16'd25 || ypx03 <= -16'd25) ? 0 : 1);
	assign isP04 = ((ypx04 >= 16'd25 || ypx04 <= -16'd25) ? 0 : 1);
	assign isP05 = ((ypx05 >= 16'd25 || ypx05 <= -16'd25) ? 0 : 1);
	assign isP06 = ((ypx06 >= 16'd25 || ypx06 <= -16'd25) ? 0 : 1);
	assign isP07 = ((ypx07 >= 16'd25 || ypx07 <= -16'd25) ? 0 : 1);
	assign isP08 = ((ypx08 >= 16'd25 || ypx08 <= -16'd25) ? 0 : 1);
	assign isP09 = ((ypx09 >= 16'd25 || ypx09 <= -16'd25) ? 0 : 1);
	assign isP10 = ((ypx10 >= 16'd25 || ypx10 <= -16'd25) ? 0 : 1);
	assign isP11 = ((ypx11 >= 16'd25 || ypx11 <= -16'd25) ? 0 : 1);
	assign isP12 = ((ypx12 >= 16'd25 || ypx12 <= -16'd25) ? 0 : 1);
	assign isP13 = ((ypx13 >= 16'd25 || ypx13 <= -16'd25) ? 0 : 1);
	assign isP14 = ((ypx14 >= 16'd25 || ypx14 <= -16'd25) ? 0 : 1);
	assign isP15 = ((ypx15 >= 16'd25 || ypx15 <= -16'd25) ? 0 : 1);
	assign isP16 = ((ypx16 >= 16'd25 || ypx16 <= -16'd25) ? 0 : 1);
	assign isP17 = ((ypx17 >= 16'd25 || ypx17 <= -16'd25) ? 0 : 1);
	assign isP18 = ((ypx18 >= 16'd25 || ypx18 <= -16'd25) ? 0 : 1);
	assign isP19 = ((ypx19 >= 16'd25 || ypx19 <= -16'd25) ? 0 : 1);
	assign isP20 = ((ypx20 >= 16'd25 || ypx20 <= -16'd25) ? 0 : 1);
	assign isP21 = ((ypx21 >= 16'd25 || ypx21 <= -16'd25) ? 0 : 1);
	assign isP22 = ((ypx22 >= 16'd25 || ypx22 <= -16'd25) ? 0 : 1);
	assign isP23 = ((ypx23 >= 16'd25 || ypx23 <= -16'd25) ? 0 : 1);
	assign isP24 = ((ypx24 >= 16'd25 || ypx24 <= -16'd25) ? 0 : 1);
	assign isP25 = ((ypx25 >= 16'd25 || ypx25 <= -16'd25) ? 0 : 1); 
	
reg graphv1;

always@(*)
begin
	graphv1 =  ((pixel_x == 225 && pixel_y == 275 + (-7 * ynx25))|
					(pixel_x == 234 && pixel_y == 275 + (-7 * ynx24))|
					(pixel_x == 243 && pixel_y == 275 + (-7 * ynx23))|
					(pixel_x == 252 && pixel_y == 275 + (-7 * ynx22))|
					(pixel_x == 261 && pixel_y == 275 + (-7 * ynx21))|
					(pixel_x == 270 && pixel_y == 275 + (-7 * ynx20))|
					(pixel_x == 279 && pixel_y == 275 + (-7 * ynx19))|
					(pixel_x == 288 && pixel_y == 275 + (-7 * ynx18))|
					(pixel_x == 297 && pixel_y == 275 + (-7 * ynx17))|
					(pixel_x == 306 && pixel_y == 275 + (-7 * ynx16))|
					(pixel_x == 315 && pixel_y == 275 + (-7 * ynx15))|
					(pixel_x == 324 && pixel_y == 275 + (-7 * ynx14))|
					(pixel_x == 333 && pixel_y == 275 + (-7 * ynx13))|
					(pixel_x == 342 && pixel_y == 275 + (-7 * ynx12))|
					(pixel_x == 351 && pixel_y == 275 + (-7 * ynx11))|
					(pixel_x == 360 && pixel_y == 275 + (-7 * ynx10))|
					(pixel_x == 369 && pixel_y == 275 + (-7 * ynx09))|
					(pixel_x == 378 && pixel_y == 275 + (-7 * ynx08))|
					(pixel_x == 387 && pixel_y == 275 + (-7 * ynx07))|
					(pixel_x == 396 && pixel_y == 275 + (-7 * ynx06))|
					(pixel_x == 405 && pixel_y == 275 + (-7 * ynx05))|
					(pixel_x == 414 && pixel_y == 275 + (-7 * ynx04))|
					(pixel_x == 423 && pixel_y == 275 + (-7 * ynx03))|
					(pixel_x == 432 && pixel_y == 275 + (-7 * ynx02))|
					(pixel_x == 441 && pixel_y == 275 + (-7 * ynx01))|
					(pixel_x == 450 && pixel_y == 275 + (-7 * yxx00))|
					(pixel_x == 459 && pixel_y == 275 + (-7 * ypx01))|
					(pixel_x == 468 && pixel_y == 275 + (-7 * ypx02))|
					(pixel_x == 477 && pixel_y == 275 + (-7 * ypx03))|
					(pixel_x == 486 && pixel_y == 275 + (-7 * ypx04))|
					(pixel_x == 495 && pixel_y == 275 + (-7 * ypx05))|
					(pixel_x == 504 && pixel_y == 275 + (-7 * ypx06))|
					(pixel_x == 513 && pixel_y == 275 + (-7 * ypx07))|
					(pixel_x == 522 && pixel_y == 275 + (-7 * ypx08))|
					(pixel_x == 531 && pixel_y == 275 + (-7 * ypx09))|
					(pixel_x == 540 && pixel_y == 275 + (-7 * ypx10))|
					(pixel_x == 549 && pixel_y == 275 + (-7 * ypx11))|
					(pixel_x == 558 && pixel_y == 275 + (-7 * ypx12))|
					(pixel_x == 567 && pixel_y == 275 + (-7 * ypx13))|
					(pixel_x == 576 && pixel_y == 275 + (-7 * ypx14))|
					(pixel_x == 585 && pixel_y == 275 + (-7 * ypx15))|
					(pixel_x == 594 && pixel_y == 275 + (-7 * ypx16))|
					(pixel_x == 603 && pixel_y == 275 + (-7 * ypx17))|
					(pixel_x == 612 && pixel_y == 275 + (-7 * ypx18))|
					(pixel_x == 621 && pixel_y == 275 + (-7 * ypx19))|
					(pixel_x == 639 && pixel_y == 275 + (-7 * ypx20))|
					(pixel_x == 648 && pixel_y == 275 + (-7 * ypx21))|
					(pixel_x == 657 && pixel_y == 275 + (-7 * ypx22))|
					(pixel_x == 666 && pixel_y == 275 + (-7 * ypx23))|
					(pixel_x == 675 && pixel_y == 275 + (-7 * ypx24))|
					(pixel_x == 684 && pixel_y == 275 + (-7 * ypx25))
					);
end

assign X_7 = ( ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-7)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-7)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   );
			   
assign X_6 = ( ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-6)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-6)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   );
			   
assign X_5 = ( ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-5)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-5)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   );
			   
assign X_4 = ( ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-4)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-4)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   );
			   
assign X_3 = ( ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-3)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-3)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   );
			   
assign X_2 = ( ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-2)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-2)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   );
			   
assign X_1 = ( ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-1)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-1)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   ( pixel_x >= STARTTXT + COEFW + SPC + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   );
		
			   
assign POW_X_7 =  ( ( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= POWROW + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-7)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-7)) + TXTPIXEND + MID   && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= POWROW + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= POWROW + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= POWROW + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= POWROW + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= POWROW + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= POWROW + (ROWDOWN*(5-1)) ) 
			   		);
			   	
assign POW_X_6 =  ( ( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-6)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-6)) + TXTPIXEND + MID   && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= POWROW + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= POWROW + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= POWROW + (ROWDOWN*(5-4)) ) | 
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= POWROW + (ROWDOWN*(5-3)) ) | 
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= POWROW + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= POWROW + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-6)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-6)) + TXTPIXEND + MID   && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= POWROW + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-6)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-6)) + TXTPIXEND + MID   && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= POWROW + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= POWROW + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= POWROW + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= POWROW + (ROWDOWN*(5-1)) ) 
			   		);
			   		
assign POW_X_5 =  ( ( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= POWROW + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-5)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-5)) + TXTPIXEND + MID   && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= POWROW + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= POWROW + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= POWROW + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= POWROW + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-5)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-5)) + TXTPIXEND + MID   && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= POWROW + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= POWROW + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= POWROW + (ROWDOWN*(5-2)) ) |
					( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= POWROW + (ROWDOWN*(5-1)) ) |
					( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-5)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-5)) + TXTPIXEND + MID   && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= POWROW + (ROWDOWN*(5-1)) ) |
					( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= POWROW + (ROWDOWN*(5-1)) ) 
			   		);
			   		
assign POW_X_4 =  ( ( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= POWROW + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= POWROW + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= POWROW + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-4)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-4)) + TXTPIXEND + MID   && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= POWROW + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= POWROW + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= POWROW + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= POWROW + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= POWROW + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= POWROW + (ROWDOWN*(5-1)) ) 
			   		);
			   		
assign POW_X_3 =  ( ( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= POWROW + (ROWDOWN*(5-5)) ) | 
			 		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-3)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-3)) + TXTPIXEND + MID   && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= POWROW + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= POWROW + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= POWROW + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= POWROW + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= POWROW + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= POWROW + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-3)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-3)) + TXTPIXEND + MID   && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= POWROW + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= POWROW + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-3)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-3)) + TXTPIXEND + MID   && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= POWROW + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= POWROW + (ROWDOWN*(5-1)) ) 
			   		);
			   		
assign POW_X_2 =  ( ( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= POWROW + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-2)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-2)) + TXTPIXEND + MID   && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= POWROW + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= POWROW + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= POWROW + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= POWROW + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-2)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-2)) + TXTPIXEND + MID   && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= POWROW + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= POWROW + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= POWROW + (ROWDOWN*(5-2)) ) |
					( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= POWROW + (ROWDOWN*(5-1)) ) |
					( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-2)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-2)) + TXTPIXEND + MID   && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= POWROW + (ROWDOWN*(5-1)) ) |
					( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= POWROW + (ROWDOWN*(5-1)) ) 
			   		);
			   		
assign POW_X_1 =  ( ( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-1)) + MID && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-1)) + TXTPIXEND + MID && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= POWROW + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-1)) + MID && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-1)) + TXTPIXEND + MID && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= POWROW + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-1)) + MID && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-1)) + TXTPIXEND + MID && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= POWROW + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-1)) + MID && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-1)) + TXTPIXEND + MID && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= POWROW + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-1)) + MID && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + (SET*(7-1)) + TXTPIXEND + MID && pixel_y <= POWROW + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= POWROW + (ROWDOWN*(5-1)) ) 
			   		);
			   		
assign PLUS_7 =   ( ( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) | 
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-7)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-7)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-7)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-7)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-7)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-7)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) 
			   		);
			   		
assign PLUS_6 =   ( ( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) | 
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-6)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-6)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-6)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-6)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-6)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-6)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) 
			   		);

assign PLUS_5 =   ( ( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) | 
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-5)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-5)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-5)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-5)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-5)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-5)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) 
			   		);

assign PLUS_4 =   ( ( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) | 
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-4)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-4)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-4)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-4)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-4)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-4)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) 
			   		);

assign PLUS_3 =   ( ( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) | 
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-3)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-3)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-3)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-3)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-3)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-3)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) 
			   		);

assign PLUS_2 =   ( ( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) | 
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-2)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-2)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-2)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-2)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-2)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-2)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) 
			   		);

assign PLUS_1 =   ( ( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) | 
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-1)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-1)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-1)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-1)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-1)) + MID   && pixel_x <= STARTTXT + COEFW + SPC + XWIDTH + SPC + POWWIDTH + SPC + (SET*(7-1)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) 
			   		);
			
reg coef7;
			
always @(*)
begin
	if (coefSeven == 9)
	begin
		coef7 =   ( ( pixel_x >= STARTTXT + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + MID   && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + MID   && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) 
					);
			   		end
	
	else if (coefSeven == 8)
	begin
	
		coef7  =  ( ( pixel_x >= STARTTXT + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + MID   && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + MID   && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + MID   && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) )  
			   		);
					end
					
	else if (coefSeven == 7)
	begin
	
		coef7 =   ( ( pixel_x >= STARTTXT + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + MID   && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   			   		
	else if (coefSeven == 6)	
	begin	   		
		coef7 =   ( ( pixel_x >= STARTTXT + (SET*(7-7)) + MID   && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + MID   && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + MID   && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefSeven == 5)
	begin
		coef7  =  ( ( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + MID   && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + MID   && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
					( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
					( pixel_x >= STARTTXT + (SET*(7-7)) + MID   && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
					( pixel_x >= STARTTXT + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefSeven == 4)
	begin
		coef7  =  ( ( pixel_x >= STARTTXT + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + MID   && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefSeven == 3)
	begin
		coef7  =  ( ( pixel_x >= STARTTXT + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			 		( pixel_x >= STARTTXT + (SET*(7-7)) + MID   && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + MID   && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + MID   && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefSeven == 2)
	begin
		coef7  =  ( ( pixel_x >= STARTTXT + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + MID   && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + MID   && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
					( pixel_x >= STARTTXT + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
					( pixel_x >= STARTTXT + (SET*(7-7)) + MID   && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
					( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefSeven == 1)
	begin
		coef7  =  ( ( pixel_x >= STARTTXT + (SET*(7-7)) + MID && pixel_x <= STARTTXT + (SET*(7-7)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + MID && pixel_x <= STARTTXT + (SET*(7-7)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + MID && pixel_x <= STARTTXT + (SET*(7-7)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + MID && pixel_x <= STARTTXT + (SET*(7-7)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + MID && pixel_x <= STARTTXT + (SET*(7-7)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else 
	begin
		coef7  =  ( ( pixel_x >= STARTTXT + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + MID   && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + MID   && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-7)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-7)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) )  
			   		);
					end
end

reg coef6;

always @(*)
begin
	if (coefSix == 9)
	begin
		coef6 =   ( ( pixel_x >= STARTTXT + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + MID   && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + MID   && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) 
					);
			   		end
	
	else if (coefSix == 8)
	begin
	
		coef6  =  ( ( pixel_x >= STARTTXT + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + MID   && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + MID   && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + MID   && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) )  
			   		);
					end
					
	else if (coefSix == 7)
	begin
	
		coef6 =   ( ( pixel_x >= STARTTXT + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + MID   && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   			   		
	
	else if (coefSix == 6)	
	begin	   		
		coef6 =   ( ( pixel_x >= STARTTXT + (SET*(7-6)) + MID   && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + MID   && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + MID   && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefSix == 5)
	begin
		coef6  =  ( ( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + MID   && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + MID   && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
					( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
					( pixel_x >= STARTTXT + (SET*(7-6)) + MID   && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
					( pixel_x >= STARTTXT + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefSix == 4)
	begin
		coef6  =  ( ( pixel_x >= STARTTXT + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + MID   && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefSix == 3)
	begin
		coef6  =  ( ( pixel_x >= STARTTXT + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			 		( pixel_x >= STARTTXT + (SET*(7-6)) + MID   && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + MID   && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + MID   && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefSix == 2)
	begin
		coef6  =  ( ( pixel_x >= STARTTXT + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + MID   && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + MID   && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
					( pixel_x >= STARTTXT + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
					( pixel_x >= STARTTXT + (SET*(7-6)) + MID   && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
					( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefSix == 1)
	begin
		coef6  =  ( ( pixel_x >= STARTTXT + (SET*(7-6)) + MID && pixel_x <= STARTTXT + (SET*(7-6)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + MID && pixel_x <= STARTTXT + (SET*(7-6)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + MID && pixel_x <= STARTTXT + (SET*(7-6)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + MID && pixel_x <= STARTTXT + (SET*(7-6)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + MID && pixel_x <= STARTTXT + (SET*(7-6)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else 
	begin
		coef6  =  ( ( pixel_x >= STARTTXT + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + MID   && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + MID   && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-6)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-6)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) )  
			   		);
					end
end

reg coef5;

always @(*)
begin
	if (coefFive == 9)
	begin
		coef5 =   ( ( pixel_x >= STARTTXT + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + MID   && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + MID   && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) 
					);
			   		end
	
	else if (coefFive == 8)
	begin
	
		coef5  =  ( ( pixel_x >= STARTTXT + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + MID   && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + MID   && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + MID   && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) )  
			   		);
					end
					
	else if (coefFive == 7)
	begin
	
		coef5 =   ( ( pixel_x >= STARTTXT + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + MID   && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   			   		
	
	else if (coefFive == 6)	
	begin	   		
		coef5 =   ( ( pixel_x >= STARTTXT + (SET*(7-5)) + MID   && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + MID   && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + MID   && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefFive == 5)
	begin
		coef5  =  ( ( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + MID   && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + MID   && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
					( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
					( pixel_x >= STARTTXT + (SET*(7-5)) + MID   && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
					( pixel_x >= STARTTXT + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefFive == 4)
	begin
		coef5  =  ( ( pixel_x >= STARTTXT + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + MID   && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefFive == 3)
	begin
		coef5  =  ( ( pixel_x >= STARTTXT + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			 		( pixel_x >= STARTTXT + (SET*(7-5)) + MID   && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + MID   && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + MID   && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefFive == 2)
	begin
		coef5  =  ( ( pixel_x >= STARTTXT + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + MID   && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + MID   && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
					( pixel_x >= STARTTXT + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
					( pixel_x >= STARTTXT + (SET*(7-5)) + MID   && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
					( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefFive == 1)
	begin
		coef5  =  ( ( pixel_x >= STARTTXT + (SET*(7-5)) + MID && pixel_x <= STARTTXT + (SET*(7-5)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + MID && pixel_x <= STARTTXT + (SET*(7-5)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + MID && pixel_x <= STARTTXT + (SET*(7-5)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + MID && pixel_x <= STARTTXT + (SET*(7-5)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + MID && pixel_x <= STARTTXT + (SET*(7-5)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else 
	begin
		coef5  =  ( ( pixel_x >= STARTTXT + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + MID   && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + MID   && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-5)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-5)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) )  
			   		);
					end
end

reg coef4;

always @(*)
begin
	if (coefFour == 9)
	begin
		coef4 =   ( ( pixel_x >= STARTTXT + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + MID   && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + MID   && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) 
					);
			   		end
	
	else if (coefFour == 8)
	begin
	
		coef4  =  ( ( pixel_x >= STARTTXT + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + MID   && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + MID   && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + MID   && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) )  
			   		);
					end
					
	else if (coefFour == 7)
	begin
	
		coef4 =   ( ( pixel_x >= STARTTXT + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + MID   && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   			   		
	
	else if (coefFour == 6)	
	begin	   		
		coef4 =   ( ( pixel_x >= STARTTXT + (SET*(7-4)) + MID   && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + MID   && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + MID   && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefFour == 5)
	begin
		coef4  =  ( ( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + MID   && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + MID   && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
					( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
					( pixel_x >= STARTTXT + (SET*(7-4)) + MID   && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
					( pixel_x >= STARTTXT + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefFour == 4)
	begin
		coef4  =  ( ( pixel_x >= STARTTXT + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + MID   && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefFour == 3)
	begin
		coef4  =  ( ( pixel_x >= STARTTXT + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			 		( pixel_x >= STARTTXT + (SET*(7-4)) + MID   && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + MID   && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + MID   && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefFour == 2)
	begin
		coef4  =  ( ( pixel_x >= STARTTXT + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + MID   && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + MID   && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
					( pixel_x >= STARTTXT + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
					( pixel_x >= STARTTXT + (SET*(7-4)) + MID   && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
					( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefFour == 1)
	begin
		coef4  =  ( ( pixel_x >= STARTTXT + (SET*(7-4)) + MID && pixel_x <= STARTTXT + (SET*(7-4)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + MID && pixel_x <= STARTTXT + (SET*(7-4)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + MID && pixel_x <= STARTTXT + (SET*(7-4)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + MID && pixel_x <= STARTTXT + (SET*(7-4)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + MID && pixel_x <= STARTTXT + (SET*(7-4)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else 
	begin
		coef4  =  ( ( pixel_x >= STARTTXT + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + MID   && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + MID   && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-4)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-4)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) )  
			   		);
					end
end

reg coef3;

always @(*)
begin
	if (coefThree == 9)
	begin
		coef3 =   ( ( pixel_x >= STARTTXT + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + MID   && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + MID   && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) 
					);
			   		end
	
	else if (coefThree == 8)
	begin
	
		coef3  =  ( ( pixel_x >= STARTTXT + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + MID   && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + MID   && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + MID   && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) )  
			   		);
					end
					
	else if (coefThree == 7)
	begin
	
		coef3 =   ( ( pixel_x >= STARTTXT + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + MID   && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   			   		
	
	else if (coefThree == 6)	
	begin	   		
		coef3 =   ( ( pixel_x >= STARTTXT + (SET*(7-3)) + MID   && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + MID   && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + MID   && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefThree == 5)
	begin
		coef3  =  ( ( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + MID   && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + MID   && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
					( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
					( pixel_x >= STARTTXT + (SET*(7-3)) + MID   && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
					( pixel_x >= STARTTXT + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefThree == 4)
	begin
		coef3  =  ( ( pixel_x >= STARTTXT + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + MID   && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefThree == 3)
	begin
		coef3  =  ( ( pixel_x >= STARTTXT + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			 		( pixel_x >= STARTTXT + (SET*(7-3)) + MID   && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + MID   && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + MID   && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefThree == 2)
	begin
		coef3  =  ( ( pixel_x >= STARTTXT + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + MID   && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + MID   && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
					( pixel_x >= STARTTXT + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
					( pixel_x >= STARTTXT + (SET*(7-3)) + MID   && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
					( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefThree == 1)
	begin
		coef3  =  ( ( pixel_x >= STARTTXT + (SET*(7-3)) + MID && pixel_x <= STARTTXT + (SET*(7-3)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + MID && pixel_x <= STARTTXT + (SET*(7-3)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + MID && pixel_x <= STARTTXT + (SET*(7-3)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + MID && pixel_x <= STARTTXT + (SET*(7-3)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + MID && pixel_x <= STARTTXT + (SET*(7-3)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else 
	begin
		coef3  =  ( ( pixel_x >= STARTTXT + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + MID   && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + MID   && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-3)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-3)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) )  
			   		);
					end
end

reg coef2;

always @(*)
begin
	if (coefTwo == 9)
	begin
		coef2 =   ( ( pixel_x >= STARTTXT + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + MID   && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + MID   && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) 
					);
			   		end
	
	else if (coefTwo == 8)
	begin
	
		coef2  =  ( ( pixel_x >= STARTTXT + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + MID   && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + MID   && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + MID   && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) )  
			   		);
					end
					
	else if (coefTwo == 7)
	begin
	
		coef2 =   ( ( pixel_x >= STARTTXT + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + MID   && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   			   		
	
	else if (coefTwo == 6)	
	begin	   		
		coef2 =   ( ( pixel_x >= STARTTXT + (SET*(7-2)) + MID   && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + MID   && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + MID   && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefTwo == 5)
	begin
		coef2  =  ( ( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + MID   && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + MID   && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
					( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
					( pixel_x >= STARTTXT + (SET*(7-2)) + MID   && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
					( pixel_x >= STARTTXT + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefTwo == 4)
	begin
		coef2  =  ( ( pixel_x >= STARTTXT + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + MID   && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefTwo == 3)
	begin
		coef2  =  ( ( pixel_x >= STARTTXT + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			 		( pixel_x >= STARTTXT + (SET*(7-2)) + MID   && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + MID   && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + MID   && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefTwo == 2)
	begin
		coef2  =  ( ( pixel_x >= STARTTXT + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + MID   && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + MID   && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
					( pixel_x >= STARTTXT + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
					( pixel_x >= STARTTXT + (SET*(7-2)) + MID   && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
					( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefTwo == 1)
	begin
		coef2  =  ( ( pixel_x >= STARTTXT + (SET*(7-2)) + MID && pixel_x <= STARTTXT + (SET*(7-2)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + MID && pixel_x <= STARTTXT + (SET*(7-2)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + MID && pixel_x <= STARTTXT + (SET*(7-2)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + MID && pixel_x <= STARTTXT + (SET*(7-2)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + MID && pixel_x <= STARTTXT + (SET*(7-2)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else 
	begin
		coef2  =  ( ( pixel_x >= STARTTXT + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + MID   && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + MID   && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-2)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-2)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) )  
			   		);
					end
end

reg coef1;

always @(*)
begin
	if (coefOne == 9)
	begin
		coef1 =   ( ( pixel_x >= STARTTXT + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + MID   && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + MID   && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) 
					);
			   		end
	
	else if (coefOne == 8)
	begin
	
		coef1  =  ( ( pixel_x >= STARTTXT + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + MID   && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + MID   && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + MID   && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) )  
			   		);
					end
					
	else if (coefOne == 7)
	begin
	
		coef1 =   ( ( pixel_x >= STARTTXT + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + MID   && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   			   		
	
	else if (coefOne == 6)	
	begin	   		
		coef1 =   ( ( pixel_x >= STARTTXT + (SET*(7-1)) + MID   && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + MID   && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + MID   && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefOne == 5)
	begin
		coef1  =  ( ( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + MID   && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + MID   && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
					( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
					( pixel_x >= STARTTXT + (SET*(7-1)) + MID   && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
					( pixel_x >= STARTTXT + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefOne == 4)
	begin
		coef1  =  ( ( pixel_x >= STARTTXT + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + MID   && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefOne == 3)
	begin
		coef1  =  ( ( pixel_x >= STARTTXT + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			 		( pixel_x >= STARTTXT + (SET*(7-1)) + MID   && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + MID   && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + MID   && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefOne == 2)
	begin
		coef1  =  ( ( pixel_x >= STARTTXT + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + MID   && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + MID   && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
					( pixel_x >= STARTTXT + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
					( pixel_x >= STARTTXT + (SET*(7-1)) + MID   && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
					( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefOne == 1)
	begin
		coef1  =  ( ( pixel_x >= STARTTXT + (SET*(7-1)) + MID && pixel_x <= STARTTXT + (SET*(7-1)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + MID && pixel_x <= STARTTXT + (SET*(7-1)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + MID && pixel_x <= STARTTXT + (SET*(7-1)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + MID && pixel_x <= STARTTXT + (SET*(7-1)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + MID && pixel_x <= STARTTXT + (SET*(7-1)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else 
	begin
		coef1  =  ( ( pixel_x >= STARTTXT + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + MID   && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + MID   && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-1)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-1)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) )  
			   		);
					end
end

reg coef0;

always @(*)
begin
	if (coefZero == 9)
	begin
		coef0 =   ( ( pixel_x >= STARTTXT + (SET*(7-0)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + MID   && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + MID   && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) 
					);
			   		end
	
	else if (coefZero == 8)
	begin
	
		coef0  =  ( ( pixel_x >= STARTTXT + (SET*(7-0)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + MID   && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + MID   && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + MID   && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) )  
			   		);
					end
					
	else if (coefZero == 7)
	begin
	
		coef0 =   ( ( pixel_x >= STARTTXT + (SET*(7-0)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + MID   && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   			   		
	
	else if (coefZero == 6)	
	begin	   		
		coef0 =   ( ( pixel_x >= STARTTXT + (SET*(7-0)) + MID   && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + MID   && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + MID   && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefZero == 5)
	begin
		coef0  =  ( ( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + MID   && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + MID   && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
					( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
					( pixel_x >= STARTTXT + (SET*(7-0)) + MID   && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
					( pixel_x >= STARTTXT + (SET*(7-0)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefZero == 4)
	begin
		coef0  =  ( ( pixel_x >= STARTTXT + (SET*(7-0)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + MID   && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefZero == 3)
	begin
		coef0  =  ( ( pixel_x >= STARTTXT + (SET*(7-0)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			 		( pixel_x >= STARTTXT + (SET*(7-0)) + MID   && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + MID   && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + MID   && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefZero == 2)
	begin
		coef0  =  ( ( pixel_x >= STARTTXT + (SET*(7-0)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + MID   && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + MID   && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
					( pixel_x >= STARTTXT + (SET*(7-0)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
					( pixel_x >= STARTTXT + (SET*(7-0)) + MID   && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
					( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else if (coefZero == 1)
	begin
		coef0  =  ( ( pixel_x >= STARTTXT + (SET*(7-0)) + MID && pixel_x <= STARTTXT + (SET*(7-0)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + MID && pixel_x <= STARTTXT + (SET*(7-0)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + MID && pixel_x <= STARTTXT + (SET*(7-0)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + MID && pixel_x <= STARTTXT + (SET*(7-0)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + MID && pixel_x <= STARTTXT + (SET*(7-0)) + TXTPIXEND + MID && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) 
			   		);
			   		end
			   		
	else 
	begin
		coef0  =  ( ( pixel_x >= STARTTXT + (SET*(7-0)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + MID   && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-5)) && pixel_y >= ROW1 + (ROWDOWN*(5-5)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + RIGHT && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + RIGHT && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) |
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + MID   && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + MID   && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-1)) && pixel_y >= ROW1 + (ROWDOWN*(5-1)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-2)) && pixel_y >= ROW1 + (ROWDOWN*(5-2)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-3)) && pixel_y >= ROW1 + (ROWDOWN*(5-3)) ) | 
			   		( pixel_x >= STARTTXT + (SET*(7-0)) + LEFT  && pixel_x <= STARTTXT+ (SET*(7-0)) + TXTPIXEND + LEFT  && pixel_y <= ROW1 + TXTPIXEND + (ROWDOWN*(5-4)) && pixel_y >= ROW1 + (ROWDOWN*(5-4)) )  
			   		);
					end
end

//// THE NEW SHIT //////
			   		

//assign derivativeZero = ()
// COPY PASTE FROM HERE UP TO TOP
							
	//pixel is in bounding box
	assign bounding_box = (pixel_x == 450 && pixel_y <= 450 && 100 <= pixel_y) | 
									(pixel_x == 650 && pixel_y <= 450 && 100 <= pixel_y) | 
										(pixel_y == 100 && pixel_x <= 650 && 250 <= pixel_x) |
											(pixel_y == 450 && pixel_x <= 650 && 250 <= pixel_x) |
												(pixel_y == 275 && pixel_x <= 650 && 250 <= pixel_x) |
													(pixel_x == 250 && pixel_y <= 450 && 100 <= pixel_y) | X_7 | X_6 | X_5 | X_4 | X_3 | X_2 | X_1 | POW_X_1 | POW_X_2 | POW_X_3 | POW_X_4 | POW_X_5 | POW_X_6 | POW_X_7 |
				PLUS_1 | PLUS_2 | PLUS_3 | PLUS_4 | PLUS_5 | PLUS_6 | PLUS_7 | coef7	| graphv1 | coef6	| coef5	| coef4	| coef3	| coef2	| coef1	| coef0	
														
												;
 // assign bright = 1;	
	//Produce color when the pixel is in the range of the button.
	always@*
	begin 
		if (bounding_box )
		begin
			img_on = 1;
			vga_R = 8'b11111111; // this is white boundary line
			vga_G = 8'b11111111;
			vga_B = 8'b11111111;
		end 
			// based on input verus rest: assign lit versus unlit color to each button.
		else
		begin
			vga_R = 8'b00000000; //BACKGROUND TRY MAKING 8'1
			vga_G = 8'b00000000;
			vga_B = 8'b00000000;
			end
	end
endmodule

module calculatorOne(clk, rst, saveCoef, donePulse, signpick, signs, doneInput, coefSelect, coefInVal, hexOne, hexTwo, hexThree, hexFour, hexFive, hexSix, hexSeven, hexZero, coefOne, coefTwo, coefThree, coefFour, coefFive, coefSix, coefSeven, coefZero);
input clk, rst, saveCoef, doneInput, signpick;
output [7:0] signs;
input [2:0] coefSelect;
input [3:0] coefInVal;
output donePulse;
output [6:0] hexOne, hexTwo, hexThree, hexFour, hexFive, hexSix, hexSeven, hexZero;
output [15:0] coefOne, coefTwo, coefThree, coefFour, coefFive, coefSix, coefSeven, coefZero;

reg [15:0] coefOne, coefTwo, coefThree, coefFour, coefFive, coefSix, coefSeven, coefZero, coefOned1, coefTwod1, coefThreed1, coefFourd1, coefFived1, coefSixd1, coefSevend1, coefZerod1, coefOned2, coefTwod2, coefThreed2, coefFourd2, coefFived2, coefSixd2, coefSevend2, coefZerod2;

reg [3:0] toHexOne, toHexTwo, toHexThree, toHexFour, toHexFive, toHexSix, toHexSeven, toHexZero; 

reg [1:0] S, NS;

reg [7:0] signs;

reg donePulse;

parameter 	CHANGE  = 2'b00,
				SAVING  = 2'b01,
				DONE 	  = 2'b10;
				

tohex H1(toHexOne[0], 	toHexOne[1], 	toHexOne[2], 	toHexOne[3],	hexOne[0], 		hexOne[1], 		hexOne[2], 		hexOne[3], 		hexOne[4], 		hexOne[5], 		hexOne[6]);
tohex H2(toHexTwo[0], 	toHexTwo[1], 	toHexTwo[2], 	toHexTwo[3], 	hexTwo[0], 		hexTwo[1], 		hexTwo[2], 		hexTwo[3], 		hexTwo[4], 		hexTwo[5], 		hexTwo[6]);
tohex H3(toHexThree[0], toHexThree[1], toHexThree[2], toHexThree[3], hexThree[0], 	hexThree[1], 	hexThree[2],	hexThree[3], 	hexThree[4],	hexThree[5], 	hexThree[6]);
tohex H4(toHexFour[0], 	toHexFour[1], 	toHexFour[2], 	toHexFour[3], 	hexFour[0], 	hexFour[1], 	hexFour[2], 	hexFour[3], 	hexFour[4], 	hexFour[5], 	hexFour[6]);
tohex H5(toHexFive[0], 	toHexFive[1], 	toHexFive[2], 	toHexFive[3], 	hexFive[0], 	hexFive[1], 	hexFive[2], 	hexFive[3], 	hexFive[4], 	hexFive[5], 	hexFive[6]);
tohex H6(toHexSix[0], 	toHexSix[1], 	toHexSix[2], 	toHexSix[3], 	hexSix[0], 		hexSix[1], 		hexSix[2], 		hexSix[3], 		hexSix[4], 		hexSix[5], 		hexSix[6]);
tohex H7(toHexSeven[0], toHexSeven[1], toHexSeven[2], toHexSeven[3], hexSeven[0], 	hexSeven[1], 	hexSeven[2], 	hexSeven[3], 	hexSeven[4], 	hexSeven[5], 	hexSeven[6]);
tohex H0(toHexZero[0], 	toHexZero[1], 	toHexZero[2], 	toHexZero[3], 	hexZero[0], 	hexZero[1], 	hexZero[2], 	hexZero[3], 	hexZero[4], 	hexZero[5], 	hexZero[6]);

always@(posedge clk)
begin
	if(rst == 1'b1)
	begin
		S <= CHANGE;
	end
	else
	begin
		S <= NS;
	end
end

always@(*)
begin
	case(S)
		CHANGE:
		begin
			if(doneInput == 1'd1)
				NS = DONE;
			else if(saveCoef == 1'd1)
				NS = SAVING;
			else
				NS = CHANGE;
		end
		SAVING:
		begin
			NS = CHANGE;
		end
		DONE:
		begin
			NS = CHANGE;
		end
		default:
		begin
			NS = CHANGE;
		end
	endcase
end

always@(posedge clk)
begin
	case(S)
		CHANGE:
		begin
			donePulse <= 1'b0;
		end
		SAVING:
		begin
			case(coefSelect)
				3'b000:
				begin
					signs[0] <= signpick;
					if(coefInVal >= 4'd9)
						toHexZero <= 4'd9;
					else
						toHexZero <= coefInVal;
				end
				3'b001:
				begin
					signs[1] <= signpick;
					if(coefInVal >= 4'd9)
						toHexOne <= 4'd9;
					else
						toHexOne <= coefInVal;
				end
				3'b010:
				begin
					signs[2] <= signpick;
					if(coefInVal >= 4'd9)
						toHexTwo <= 4'd9;
					else
						toHexTwo <= coefInVal;
				end
				3'b011:
				begin
					signs[3] <= signpick;
					if(coefInVal >= 4'd9)
						toHexThree <= 4'd9;
					else
						toHexThree <= coefInVal;
				end
				3'b100:
				begin
					signs[4] <= signpick;
					if(coefInVal >= 4'd9)
						toHexFour <= 4'd9;
					else
						toHexFour <= coefInVal;
				end
				3'b101:
				begin
					signs[5] <= signpick;
					if(coefInVal >= 4'd9)
						toHexFive <= 4'd9;
					else
						toHexFive <= coefInVal;
				end
				3'b110:
				begin
					signs[6] <= signpick;
					if(coefInVal >= 4'd9)
						toHexSix <= 4'd9;
					else
						toHexSix <= coefInVal;
				end
				3'b111:
				begin
					signs[7] <= signpick;
					if(coefInVal >= 4'd9)
						toHexSeven <= 4'd9;
					else
						toHexSeven <= coefInVal;
				end
			endcase
		end
		DONE:
		begin
			donePulse = 1'b1;
			
			coefOne 			<= toHexOne;
			coefTwo 			<= toHexTwo;
			coefThree 		<= toHexThree;
			coefFour 		<= toHexFour;
			coefFive 		<= toHexFive;
			coefSix 			<= toHexSix;
			coefSeven 		<= toHexSeven;
			coefZero 		<= toHexZero;
			coefOned1 		<= toHexOne;
			coefTwod1 		<= toHexTwo   * 2;
			coefThreed1		<= toHexThree * 3;
			coefFourd1 		<= toHexFour  * 4;
			coefFived1 		<= toHexFive  * 5;
			coefSixd1		<= toHexSix   * 6;
			coefSevend1 	<= toHexSeven * 7;
			coefZerod1 		<= 16'd0;
			coefOned2 		<= 16'd0;
			coefTwod2 		<= toHexTwo   * 2;
			coefThreed2		<= toHexThree * 6;
			coefFourd2 		<= toHexFour  * 12;
			coefFived2 		<= toHexFive  * 20;
			coefSixd2		<= toHexSix   * 30;
			coefSevend2 	<= toHexSeven * 42;
			coefZerod2 		<= 16'd0;
		end
			
		default:
		begin
			toHexOne 	<= 4'd0;
			toHexTwo 	<= 4'd0;
			toHexThree 	<= 4'd0;
			toHexFour 	<= 4'd0;
			toHexFive 	<= 4'd0;
			toHexSix 	<= 4'd0;
			toHexSeven 	<= 4'd0;
			toHexZero 	<= 4'd0;
		end
	endcase
end


endmodule

module tohex(
	in_00,
	in_01,
	in_02,
	in_03,
	pin_name1,
	pin_name2,
	pin_name3,
	pin_name4,
	pin_name5,
	pin_name6,
	pin_name7
);


input wire	in_00;
input wire	in_01;
input wire	in_02;
input wire	in_03;
output wire	pin_name1;
output wire	pin_name2;
output wire	pin_name3;
output wire	pin_name4;
output wire	pin_name5;
output wire	pin_name6;
output wire	pin_name7;

wire	SYNTHESIZED_WIRE_133;
wire	SYNTHESIZED_WIRE_134;
wire	SYNTHESIZED_WIRE_135;
wire	SYNTHESIZED_WIRE_136;
wire	SYNTHESIZED_WIRE_137;
wire	SYNTHESIZED_WIRE_138;
wire	SYNTHESIZED_WIRE_139;
wire	SYNTHESIZED_WIRE_140;
wire	SYNTHESIZED_WIRE_141;
wire	SYNTHESIZED_WIRE_142;
wire	SYNTHESIZED_WIRE_143;
wire	SYNTHESIZED_WIRE_144;
wire	SYNTHESIZED_WIRE_145;
wire	SYNTHESIZED_WIRE_146;
wire	SYNTHESIZED_WIRE_147;
wire	SYNTHESIZED_WIRE_148;
wire	SYNTHESIZED_WIRE_149;
wire	SYNTHESIZED_WIRE_150;
wire	SYNTHESIZED_WIRE_151;
wire	SYNTHESIZED_WIRE_152;
wire	SYNTHESIZED_WIRE_105;
wire	SYNTHESIZED_WIRE_106;
wire	SYNTHESIZED_WIRE_107;
wire	SYNTHESIZED_WIRE_108;
wire	SYNTHESIZED_WIRE_109;
wire	SYNTHESIZED_WIRE_110;
wire	SYNTHESIZED_WIRE_111;
wire	SYNTHESIZED_WIRE_112;
wire	SYNTHESIZED_WIRE_113;
wire	SYNTHESIZED_WIRE_114;
wire	SYNTHESIZED_WIRE_115;
wire	SYNTHESIZED_WIRE_116;
wire	SYNTHESIZED_WIRE_117;
wire	SYNTHESIZED_WIRE_118;
wire	SYNTHESIZED_WIRE_119;
wire	SYNTHESIZED_WIRE_120;
wire	SYNTHESIZED_WIRE_121;
wire	SYNTHESIZED_WIRE_122;
wire	SYNTHESIZED_WIRE_123;
wire	SYNTHESIZED_WIRE_124;
wire	SYNTHESIZED_WIRE_125;




assign	SYNTHESIZED_WIRE_134 =  ~in_01;

assign	SYNTHESIZED_WIRE_133 =  ~in_00;

assign	SYNTHESIZED_WIRE_143 = SYNTHESIZED_WIRE_133 & SYNTHESIZED_WIRE_134 & SYNTHESIZED_WIRE_135 & in_03;

assign	SYNTHESIZED_WIRE_144 = in_00 & SYNTHESIZED_WIRE_134 & SYNTHESIZED_WIRE_135 & in_03;

assign	SYNTHESIZED_WIRE_150 = SYNTHESIZED_WIRE_133 & SYNTHESIZED_WIRE_134 & in_02 & SYNTHESIZED_WIRE_136;

assign	SYNTHESIZED_WIRE_140 = in_00 & SYNTHESIZED_WIRE_134 & in_02 & SYNTHESIZED_WIRE_136;

assign	SYNTHESIZED_WIRE_149 = in_00 & SYNTHESIZED_WIRE_134 & SYNTHESIZED_WIRE_135 & SYNTHESIZED_WIRE_136;

assign	SYNTHESIZED_WIRE_138 = in_00 & in_01 & SYNTHESIZED_WIRE_135 & SYNTHESIZED_WIRE_136;

assign	SYNTHESIZED_WIRE_139 = SYNTHESIZED_WIRE_133 & in_01 & SYNTHESIZED_WIRE_135 & SYNTHESIZED_WIRE_136;

assign	SYNTHESIZED_WIRE_137 = SYNTHESIZED_WIRE_133 & SYNTHESIZED_WIRE_134 & SYNTHESIZED_WIRE_135 & SYNTHESIZED_WIRE_136;

assign	SYNTHESIZED_WIRE_152 = in_00 & in_01 & SYNTHESIZED_WIRE_135 & in_03;

assign	SYNTHESIZED_WIRE_145 = SYNTHESIZED_WIRE_133 & in_01 & SYNTHESIZED_WIRE_135 & in_03;

assign	SYNTHESIZED_WIRE_135 =  ~in_02;

assign	SYNTHESIZED_WIRE_106 = SYNTHESIZED_WIRE_137 | SYNTHESIZED_WIRE_138 | SYNTHESIZED_WIRE_139 | SYNTHESIZED_WIRE_140 | SYNTHESIZED_WIRE_141 | SYNTHESIZED_WIRE_142 | SYNTHESIZED_WIRE_143 | SYNTHESIZED_WIRE_144;

assign	SYNTHESIZED_WIRE_105 = SYNTHESIZED_WIRE_145 | SYNTHESIZED_WIRE_146 | SYNTHESIZED_WIRE_147 | SYNTHESIZED_WIRE_148;

assign	SYNTHESIZED_WIRE_108 = SYNTHESIZED_WIRE_137 | SYNTHESIZED_WIRE_139 | SYNTHESIZED_WIRE_149 | SYNTHESIZED_WIRE_138 | SYNTHESIZED_WIRE_150 | SYNTHESIZED_WIRE_141;

assign	SYNTHESIZED_WIRE_107 = SYNTHESIZED_WIRE_143 | SYNTHESIZED_WIRE_145 | SYNTHESIZED_WIRE_151 | SYNTHESIZED_WIRE_144;

assign	SYNTHESIZED_WIRE_110 = SYNTHESIZED_WIRE_137 | SYNTHESIZED_WIRE_138 | SYNTHESIZED_WIRE_149 | SYNTHESIZED_WIRE_150 | SYNTHESIZED_WIRE_140 | SYNTHESIZED_WIRE_142;

assign	SYNTHESIZED_WIRE_109 = SYNTHESIZED_WIRE_141 | SYNTHESIZED_WIRE_144 | SYNTHESIZED_WIRE_143 | SYNTHESIZED_WIRE_145 | SYNTHESIZED_WIRE_152 | SYNTHESIZED_WIRE_151;

assign	SYNTHESIZED_WIRE_112 = SYNTHESIZED_WIRE_137 | SYNTHESIZED_WIRE_138 | SYNTHESIZED_WIRE_139 | SYNTHESIZED_WIRE_140 | SYNTHESIZED_WIRE_142 | SYNTHESIZED_WIRE_143;

assign	SYNTHESIZED_WIRE_111 = SYNTHESIZED_WIRE_144 | SYNTHESIZED_WIRE_148 | SYNTHESIZED_WIRE_152 | SYNTHESIZED_WIRE_151 | SYNTHESIZED_WIRE_146 | SYNTHESIZED_WIRE_137;

assign	SYNTHESIZED_WIRE_114 = SYNTHESIZED_WIRE_137 | SYNTHESIZED_WIRE_142 | SYNTHESIZED_WIRE_139 | SYNTHESIZED_WIRE_143 | SYNTHESIZED_WIRE_145 | SYNTHESIZED_WIRE_152;

assign	SYNTHESIZED_WIRE_113 = SYNTHESIZED_WIRE_148 | SYNTHESIZED_WIRE_146 | SYNTHESIZED_WIRE_147 | SYNTHESIZED_WIRE_151;

assign	SYNTHESIZED_WIRE_136 =  ~in_03;

assign	SYNTHESIZED_WIRE_116 = SYNTHESIZED_WIRE_137 | SYNTHESIZED_WIRE_140 | SYNTHESIZED_WIRE_150 | SYNTHESIZED_WIRE_142 | SYNTHESIZED_WIRE_143 | SYNTHESIZED_WIRE_144;

assign	SYNTHESIZED_WIRE_115 = SYNTHESIZED_WIRE_145 | SYNTHESIZED_WIRE_148 | SYNTHESIZED_WIRE_152 | SYNTHESIZED_WIRE_146 | SYNTHESIZED_WIRE_147 | SYNTHESIZED_WIRE_137;

assign	SYNTHESIZED_WIRE_118 = SYNTHESIZED_WIRE_139 | SYNTHESIZED_WIRE_150 | SYNTHESIZED_WIRE_138 | SYNTHESIZED_WIRE_140 | SYNTHESIZED_WIRE_142 | SYNTHESIZED_WIRE_143;

assign	SYNTHESIZED_WIRE_117 = SYNTHESIZED_WIRE_144 | SYNTHESIZED_WIRE_152 | SYNTHESIZED_WIRE_145 | SYNTHESIZED_WIRE_151 | SYNTHESIZED_WIRE_146 | SYNTHESIZED_WIRE_147;

assign	SYNTHESIZED_WIRE_119 = SYNTHESIZED_WIRE_105 | SYNTHESIZED_WIRE_106;

assign	SYNTHESIZED_WIRE_120 = SYNTHESIZED_WIRE_107 | SYNTHESIZED_WIRE_108;

assign	SYNTHESIZED_WIRE_121 = SYNTHESIZED_WIRE_109 | SYNTHESIZED_WIRE_110;

assign	SYNTHESIZED_WIRE_122 = SYNTHESIZED_WIRE_111 | SYNTHESIZED_WIRE_112;

assign	SYNTHESIZED_WIRE_123 = SYNTHESIZED_WIRE_113 | SYNTHESIZED_WIRE_114;

assign	SYNTHESIZED_WIRE_124 = SYNTHESIZED_WIRE_115 | SYNTHESIZED_WIRE_116;

assign	SYNTHESIZED_WIRE_147 = in_00 & in_01 & in_02 & in_03;

assign	SYNTHESIZED_WIRE_125 = SYNTHESIZED_WIRE_117 | SYNTHESIZED_WIRE_118;

assign	pin_name1 =  ~SYNTHESIZED_WIRE_119;

assign	pin_name2 =  ~SYNTHESIZED_WIRE_120;

assign	pin_name3 =  ~SYNTHESIZED_WIRE_121;

assign	pin_name4 =  ~SYNTHESIZED_WIRE_122;

assign	pin_name5 =  ~SYNTHESIZED_WIRE_123;

assign	pin_name6 =  ~SYNTHESIZED_WIRE_124;

assign	pin_name7 =  ~SYNTHESIZED_WIRE_125;

assign	SYNTHESIZED_WIRE_146 = SYNTHESIZED_WIRE_133 & in_01 & in_02 & in_03;

assign	SYNTHESIZED_WIRE_151 = in_00 & SYNTHESIZED_WIRE_134 & in_02 & in_03;

assign	SYNTHESIZED_WIRE_148 = SYNTHESIZED_WIRE_133 & SYNTHESIZED_WIRE_134 & in_02 & in_03;

assign	SYNTHESIZED_WIRE_142 = SYNTHESIZED_WIRE_133 & in_01 & in_02 & SYNTHESIZED_WIRE_136;

assign	SYNTHESIZED_WIRE_141 = in_00 & in_01 & in_02 & SYNTHESIZED_WIRE_136;


endmodule
