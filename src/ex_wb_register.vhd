library ieee;
use ieee.std_logic_1164.all;
use work.all;

entity ex_wb_register is
	port(
	--Gets input from end of execute stage and outputs it for write back stage
	clk : in std_logic;
	reset : in std_logic;
	input_rd_data : in std_logic_vector(127 downto 0);
	input_rd_address : in std_logic_vector(4 downto 0);
	input_rd_wb : in std_logic;
	output_rd_data : out std_logic_vector(127 downto 0);
	output_rd_address : out std_logic_vector(4 downto 0);
	output_rd_wb : out std_logic
	);
end ex_wb_register;

architecture behavioral of ex_wb_register is
begin
	process(clk, reset)
	begin 
		--Checks for reset first, if there is then reset all info to 0
		if reset = '1' then
			output_rd_data <= (others => '0');
			output_rd_address <= (others => '0');
			output_rd_wb <= '0';
		elsif rising_edge(clk) then
			--else rising edge of clk and transfers EXE/WB reg to WB stage
			output_rd_data <= input_rd_data;
			output_rd_address <= input_rd_address;
			output_rd_wb <= input_rd_wb;
		end if;
	end process;
end behavioral;
