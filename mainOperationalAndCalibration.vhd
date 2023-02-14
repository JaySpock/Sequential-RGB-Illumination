library IEEE;
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.NUMERIC_STD.ALL; 
use IEEE.std_logic_unsigned.all; 

LIBRARY altera; 
USE altera.altera_primitives_components.all;
  

entity mainOperationalAndCalibration is 

    port(   clk    			: in std_logic; 										-- Clock signal

            KEY    			: in std_logic;										-- Startup switch
				
				Button			: in std_logic_vector(2 downto 0);				-- Calibration buttons 
				
				DATA 	 			: in std_logic;										-- Current bit from Camera
				
				END_OF_FRAME	: out std_logic;										-- Rising edge indicates end of frame (EOF)
				
				LED_OUT			: out std_logic_vector(2 downto 0);				-- LED output for the pins (LEDs near camera)
				
            LED    			: out std_logic_vector(2 downto 0)); 			-- LED output for development board LEDs

end entity; 

  

architecture mainOperationalAndCalibration_arch of mainOperationalAndCalibration is 
	
	-- MATLAB created component for interfacing with the host computer
	component datacapture
	port(
		 clk: in std_logic;
		 clk_enable: in std_logic;
		 ready_to_capture: out std_logic;
		 Data_out: in std_logic_vector(4 downto 0); 
		 Calibration: in std_logic; 
		 New_Frame: in std_logic); 
	end component;

	-- holding register for LVDS (contains the last 62 bits of LVDS the camera has sent)
	signal FIFO_reg		: std_logic_vector(61 downto 0) := "11111111111111111111111111111111111111111111111111111111111111";

	-- LED output register that will go to both LED_OUT and LED
	signal LED_output 	: std_logic_vector(2 downto 0) := "110"; 
	
	-- EOF signal
	signal NEW_FRAME		: std_logic := '0'; 
	
	-- Positive logic signal indicating if you're in calibration
	signal Calibration	: std_logic := '0'; 
	
	-- Indicates when counting should commence to prevent redetection of same frame
	signal DATA_BUFFER	: std_logic;

	-- Counter variable to prevent same frame retrigger
	signal cnt         	: INTEGER RANGE 0 TO 25000000;

	-- Indicates what operation is happening (calibration, etc)
	signal startup_frame	: INTEGER RANGE 0 to 4 := 4;
	
	-- Makes it so the calibration sequence is LED on, LED off, LED off
	signal cal_cnt			: INTEGER RANGE 0 to 2;
	
	-- Indicator signal to host computer telling what stage is currently occuring
	signal DATA_OUT		: std_logic_vector(4 downto 0) := "00000";

	begin 
	
	-- Instantiate Datacapture
		u0: datacapture
			port map(clk=>clk,
						clk_enable=>'1',
						Data_out=>DATA_OUT,
						Calibration=>Calibration,
						New_Frame=>NEW_FRAME);
	
	-- END_OF_FRAME is the same as NEW_FRAME, but NEW_FRAME can be read
		END_OF_FRAME <= NEW_FRAME;

	-- LED_output is the LED code that can be read
		LED <= LED_output; 

	-- The LEDs near the camera operate using positive logic (LED_output uses negative logic)
		LED_out <= not LED_output;
		
	 process (clk)															-- Execute every clock cycle
			begin
			
				if (rising_edge(clk)) then	
				
					if (DATA_BUFFER = '1') then						-- Immediately after a EOF is detected, don't let it detect again
				
						cnt <= cnt + 1;
						
					end if;
					
					for address in 61 downto 1 loop					-- Move all the bits in the FIFO register over one
						
						FIFO_reg(address) <= FIFO_reg(address - 1);
							
					end loop;
							
					FIFO_reg(0) <= DATA;									-- Push the newest bit into the FIFO register
					
					if(KEY = '0') then									-- If the FPGA is turned off, turn the LEDs off
							startup_frame <= 0;
					end if;
					
					if(Button = "110") then								-- Button control for manual calibration
						startup_frame <= 1;
					elsif (Button = "101") then
						startup_frame <= 2;
					elsif (Button = "011") then
						startup_frame <= 3;
					end if;

				-- EOF is marked by 48 bits set to '0' in a row, because we are over sampling, this should result in 192 zeros in a row
					if (FIFO_reg = "00000000000000000000000000000000000000000000000000000000000000" and DATA_BUFFER = '0') then
					
						NEW_FRAME <= '1';									-- Mark the EOF
						DATA_BUFFER <= '1';
						cnt <= 0;											-- Reset counter to prevent multiple triggers off one EOF
						
						case startup_frame is							-- Actual LED operation
							when 0	=> 
								Calibration <= '1';
								LED_output <= "111";						-- NO LIGHT startup frame
								DATA_OUT <= "00000";						-- Send no light cal to host
								if(cal_cnt = 2) then
									startup_frame <= 1;
									cal_cnt <= 0;
								else
									cal_cnt <= cal_cnt + 1;
								end if;
								
							when 1	=>										-- RED startup frame
								if(cal_cnt = 0) then
									LED_output <= "110";					-- Red LEDs on
									cal_cnt <= cal_cnt + 1;	
									DATA_OUT <= "00001";					-- Send red cal to host
								elsif(cal_cnt = 1) then
									LED_output <= "111";					-- No LEDs on
									cal_cnt <= cal_cnt + 1;
									DATA_OUT <= "00010";					-- Send no light cal to host
								else
									LED_output <= "111";					-- No LEDs on
									startup_frame <= 2;					-- Move onto Green startup frame
									cal_cnt <= 0;
									DATA_OUT <= "00010";					-- Send no light cal to host
								end if;
	
							when 2	=>									   -- GREEN startup frame
								if(cal_cnt = 0) then
									LED_output <= "101";					-- Green LEDs on
									cal_cnt <= cal_cnt + 1;
									DATA_OUT <= "00011";					-- Send green cal to host
								elsif(cal_cnt = 1) then
									LED_output <= "111";					-- No LEDs on
									cal_cnt <= cal_cnt + 1;
									DATA_OUT <= "00100";					-- Send no light cal to host
								else
									LED_output <= "111";					-- No LEDs on
									startup_frame <= 3;					-- Move onto Blue startup frame
									cal_cnt <= 0;
									DATA_OUT <= "00100";					-- Send no light cal to host
								end if;
								
							when 3 	=>										-- BLUE startup frame
								if(cal_cnt = 0) then
									LED_output <= "011";					-- Blue LEDs on
									cal_cnt <= cal_cnt + 1;
									DATA_OUT <= "00101";					-- Send blue cal to host
								elsif(cal_cnt = 1) then						
									LED_output <= "111";					-- No LEDs on
									cal_cnt <= cal_cnt + 1;	
									DATA_OUT <= "00110";					-- Send no light cal to host
								else
									LED_output <= "111";					-- No LEDs on
									startup_frame <= 4;					-- Move on to normal operation
									cal_cnt <= 0;
									DATA_OUT <= "00110";					-- Send no light cal to host
								end if;
								
							
							when others =>									-- Normal operation
								Calibration <= '0';
								case LED_output is
									when "110" =>							-- When red
										LED_output <= "101";				-- Change to green
										DATA_OUT <= "01000";				-- Send green normal operation to host
									when "101" =>							-- When green
										LED_output <= "011";				-- Change to blue
										DATA_OUT <= "01001";				-- Send blue normal operation to host
									when "011" =>							-- When blue
										LED_output <= "110";				-- Change to red
										DATA_OUT <= "00111";				-- Send red normal operation to host
									when "111" =>							-- When turned off
										LED_output <= "110";				-- Change to red
										DATA_OUT <= "00111";				-- Send red normal operation to host
									when others =>							-- When the LEDs aren't any of these
										LED_output <= "111";				-- Turn them off
										DATA_OUT <= "01010";				-- Send the host an error code
								end case;						
						end case;
					elsif (DATA_BUFFER = '1' and cnt >250000) then
																				-- Immediately after a EOF is detected, don't let it detect again
						NEW_FRAME <= '0';
						DATA_BUFFER <= '0';
						cnt <= 0;
					end if;
				end if;
			end process;
	end architecture; 