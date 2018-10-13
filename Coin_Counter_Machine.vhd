-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:50:59 05/16/2015 
-- Design Name: 
-- Module Name:    lcd - Behavior 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created.
-- Additional Comments: 
--
-------------------------------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity lcd is
    Port ( clk : in  bit;
           reset : in  bit;
           PushButton :in std_logic;
			  PushButton2 :in std_logic;
			  sensor : in std_logic;
           SF_D : out  std_logic_vector (3 downto 0);
           LCD_E : out  bit;
           LCD_RS : out  bit;
           LCD_RW : out  bit;
           SF_CE0 : out  bit
			  );
			  
end lcd;

-------------------------------------------------------------------------------------------------------------------------------
architecture Behavior of lcd is

type tx_sequence is (high_setup, high_hold, oneus, low_setup, low_hold, fortyus, done);
signal tx_state : tx_sequence := done;
signal tx_byte : std_logic_vector(7 downto 0);
signal tx_init : bit := '0';
type init_sequence is (idle, fifteenms, one, two, three, four, five, six, seven, eight, done);
signal init_state : init_sequence := idle;
signal init_init, init_done : bit := '0';
signal i : integer range 0 to 750000 := 0;
signal i2 : integer range 0 to 2000 := 0;
signal i3 : integer range 0 to 82000 := 0;
signal i4 : integer range 0 to 50000000:= 0;
signal i5 : integer range 0 to 50000000:= 0;
signal SF_D0, SF_D1 : std_logic_vector(3 downto 0);
signal LCD_E0, LCD_E1 : bit;
signal mux : bit;
signal con2 : std_logic_vector(3 downto 0);

signal counter_value : std_logic_vector (3 downto 0):="0000";
signal counter_value2 : std_logic_vector (3 downto 0):="0000";

type display_state is (init, function_set, entry_set, set_display, clr_display, pause, set_addr, char_R, char_P, char_titik, char_ribuan, char_ratusan, char_nol_pertama, char_nol_kedua, done);
signal cur_state : display_state := init;

begin
	
	--LED <= tx_byte; --for diagnostic purposes
	SF_CE0 <= '1'; --disable intel strataflash
	LCD_RW <= '0'; --write only
	--The following "with" statements simplify the process of adding and removing states.
	--when to transmit a command/data and when not to
	with cur_state select
		tx_init <= '0' when init | pause | done,
		'1' when others;
	--control the bus
	with cur_state select
		mux <= '1' when init,
		'0' when others;
	--control the initialization sequence
	with cur_state select
		init_init <= '1' when init,
		'0' when others;
	--register select
	with cur_state select
		LCD_RS <= '0' when function_set|entry_set|set_display|clr_display|set_addr,
		'1' when others;
	--what byte to transmit to lcd
	--refer to datasheet for an explanation of these values	
	with cur_state select
		tx_byte <= "00101000" when function_set,
		"00000110" when entry_set,
		"00001100" when set_display,
		"00000001" when clr_display,
		"10000000" when set_addr,
		"01010010" when char_R, 
		"01010000" when char_P, 
		"00101110" when char_titik, 
		"0011" &counter_value when char_ribuan,
		"0011" &counter_value2 when char_ratusan,
		"00110000" when char_nol_pertama,
		"00110000" when char_nol_kedua,
		"00000000" when others;

-------------------------------------------------------------------------------------------------------------------------------
-------- Push Button --------
		--main state machine
counter: process(clk, reset)
begin
	if(reset = '1') then
		i4 <= 0;
		counter_value <= "0000";
	elsif(clk='1' and clk'event) then
		if(i4 = 50000000) then
			if(PushButton = '1') then
				i4 <= 0;
					if(counter_value = "1001") then
						counter_value <= "0000";
					else
						counter_value <= counter_value + '1';
					end if;
			end if;
		else
			i4 <= i4 + 1;
		end if;
	end if;
end process counter;

counter2: process(clk, reset)
begin
	if(reset = '1') then
		i5 <= 0;
		counter_value2 <= "0000";
	elsif(clk='1' and clk'event) then
		if(i5 = 50000000) then
			if(PushButton2 = '1') then
				i5 <= 0;
					if(counter_value2 = "1001") then
						counter_value2<= "0000";
					else
						counter_value2 <= counter_value2 + '1';
					end if;
			end if;
		else
			i5 <= i5 + 1;
		end if;
	end if;
end process counter2;
		
-------------------------------------------------------------------------------------------------------------------------------
-------- Tampil ke LCD --------
	
	display: process(clk, reset)
	
	begin

		if(reset='1') then
			cur_state <= function_set;
		elsif(clk='1' and clk'event) then
		case cur_state is
	--refer to intialize state machine below
			when init =>
				if(init_done = '1') then
					cur_state <= function_set;
				else
					cur_state <= init;
				end if;
	--every other state but pause uses the transmit state machine
			when function_set =>
				if(i2 = 2000) then
					cur_state <= entry_set;
				else
					cur_state <= function_set;
				end if;
			when entry_set =>
				if(i2 = 2000) then
					cur_state <= set_display;
				else
					cur_state <= entry_set;
				end if;
			when set_display =>
				if(i2 = 2000) then
					cur_state <= clr_display;
				else
					cur_state <= set_display;
				end if;
			when clr_display =>
				i3 <= 0;
				if(i2 = 2000) then
					cur_state <= pause;
				else
					cur_state <= clr_display;
				end if;
			when pause =>
				if(i3 = 82000) then
					cur_state <= set_addr;
					i3 <= 0;
				else
					cur_state <= pause;
					i3 <= i3 + 1;
				end if;
			when set_addr =>
				if(i2 = 2000) then
					cur_state <= char_R;
				else
					cur_state <= set_addr;
				end if;
			when char_R =>
				if i2 = 2000 then
					cur_state <= char_P;
				else
					cur_state <= char_R;
				end if;
			when char_P =>
				if i2 = 2000 then
					cur_state <= char_titik;
				else
					cur_state <= char_P;
				end if;
			when char_titik =>
				if (i2 = 2000) then
					cur_state <= char_ribuan;
				else
					cur_state <= char_titik;
				end if;
			when char_ribuan =>
				if (i2 = 2000) then
					cur_state <= char_ratusan;	
					con2 <= "0010";
				else
					cur_state <= char_ribuan;
				end if;
			when char_ratusan =>
				if(i2 = 2000) then
					cur_state <= char_nol_pertama;
				else
					cur_state <= char_ratusan;
				end if;
			when char_nol_pertama =>
				if i2 = 2000 then
					cur_state <= char_nol_kedua;
				else
					cur_state <= char_nol_pertama;
				end if;				
			
--			when update =>
--				cur_state <= char_skorb;
			
			when char_nol_kedua =>
				if (i2 = 2000) then
					cur_state <= set_addr;					
				else
					cur_state <= char_nol_kedua;
				end if;
			when done =>
				cur_state <= done;
		end case;
		end if;
	end process display;

-------------------------------------------------------------------------------------------------------------------------------

with mux select
	SF_D <= SF_D0 when '0', --transmit
	SF_D1 when others; --initialize
with mux select
	LCD_E <= LCD_E0 when '0', --transmit
	LCD_E1 when others; --initialize
	--specified by datasheet
transmit : process(clk, reset, tx_init)
begin
	if(reset='1') then
		tx_state <= done;
	elsif(clk='1' and clk'event) then
		case tx_state is
			when high_setup => --40ns
				LCD_E0 <= '0';
				SF_D0 <= tx_byte(7 downto 4);
				if(i2 = 2) then
					tx_state <= high_hold;
					i2 <= 0;
				else
					tx_state <= high_setup;
					i2 <= i2 + 1;
				end if;
			when high_hold => --230ns
				LCD_E0 <= '1';
				SF_D0 <= tx_byte(7 downto 4);
				if(i2 = 12) then
					tx_state <= oneus;
					i2 <= 0;
				else
					tx_state <= high_hold;
					i2 <= i2 + 1;
				end if;															
			when oneus =>
				LCD_E0 <= '0';
				if(i2 = 50) then
					tx_state <= low_setup;
					i2 <= 0;
				else
					tx_state <= oneus;
					i2 <= i2 + 1;
				end if;
			when low_setup =>
				LCD_E0 <= '0';
				SF_D0 <= tx_byte(3 downto 0);
				if(i2 = 2) then
					tx_state <= low_hold;
					i2 <= 0;
				else
					tx_state <= low_setup;
					i2 <= i2 + 1;
				end if;
			when low_hold =>
				LCD_E0 <= '1';
				SF_D0 <= tx_byte(3 downto 0);
				if(i2 = 12) then
					tx_state <= fortyus;
					i2 <= 0;
				else
					tx_state <= low_hold;
					i2 <= i2 + 1;
				end if;
			when fortyus =>
				LCD_E0 <= '0';
				if(i2 = 2000) then
					tx_state <= done;
					i2 <= 0;
				else
					tx_state <= fortyus;
					i2 <= i2 + 1;
				end if;
			when done =>
				LCD_E0 <= '0';
				if(tx_init = '1') then
					tx_state <= high_setup;
					i2 <= 0;
				else
					tx_state <= done;
					i2 <= 0;
				end if;
		end case;
	end if;
end process transmit;

-------------------------------------------------------------------------------------------------------------------------------

--specified by datasheet
power_on_initialize: process(clk, reset, init_init) --power on initialization sequence
begin
	if(reset='1') then
		init_state <= idle;
		init_done <= '0';
	elsif(clk='1' and clk'event) then
		case init_state is
			when idle =>
				init_done <= '0';
				if(init_init = '1') then
					init_state <= fifteenms;
					i <= 0;
				else
					init_state <= idle;
					i <= i + 1;
				end if;
			when fifteenms =>
				init_done <= '0';
				if(i = 750000) then
					init_state <= one;
					i <= 0;
				else
					init_state <= fifteenms;
					i <= i + 1;
				end if;
			when one =>
				SF_D1 <= "0011";
				LCD_E1 <= '1';
				init_done <= '0';
				if(i = 11) then
					init_state<=two;
					i <= 0;
				else
					init_state<=one;
					i <= i + 1;
				end if;
			when two =>
				LCD_E1 <= '0';
				init_done <= '0';
				if(i = 205000) then
					init_state<=three;
					i <= 0;
				else
					init_state<=two;
					i <= i + 1;
				end if;
			when three =>
				SF_D1 <= "0011";
				LCD_E1 <= '1';
				init_done <= '0';
				if(i = 11) then
					init_state<=four;
					i <= 0;
				else
					init_state<=three;
					i <= i + 1;
				end if;
			when four =>
				LCD_E1 <= '0';
				init_done <= '0';
				if(i = 5000) then
					init_state<=five;
					i <= 0;
				else
					init_state<=four;
					i <= i + 1;
				end if;
			when five =>
				SF_D1 <= "0011";
				LCD_E1 <= '1';
				init_done <= '0';
				if(i = 11) then
					init_state<=six;
					i <= 0;
				else
					init_state<=five;
					i <= i + 1;
				end if;
			when six =>
				LCD_E1 <= '0';
				init_done <= '0';
				if(i = 2000) then
					init_state<=seven;
					i <= 0;
				else
					init_state<=six;
					i <= i + 1;
				end if;
			when seven =>
				SF_D1 <= "0010";
				LCD_E1 <= '1';
				init_done <= '0';
				if(i = 11) then
					init_state<=eight;
					i <= 0;
				else
					init_state<=seven;
					i <= i + 1;
				end if;
			when eight =>
				LCD_E1 <= '0';
				init_done <= '0';
				if(i = 2000) then
				init_state<=done;
					i <= 0;
				else
				init_state<=eight;
					i <= i + 1;
				end if;
			when done =>
				init_state <= done;
				init_done <= '1';
		end case;
	end if;
	end process power_on_initialize;

end Behavior;
