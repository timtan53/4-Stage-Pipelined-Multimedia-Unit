library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.all;

entity mux_2to1_tb is
end mux_2to1_tb;

architecture behavioral of mux_2to1_tb is
	signal sel : std_logic;
	signal input_id_ex : std_logic_vector(127 downto 0);
	signal input_ex_wb : std_logic_vector(127 downto 0);
	signal output : std_logic_vector(127 downto 0);
begin
	UUT : entity mux_2to1
		port map(
			sel => sel,
			input_id_ex => input_id_ex,
			input_ex_wb => input_ex_wb,
			output => output
		);
	process
	begin
		sel <= '0';
		input_id_ex <= x"11111111111111111111111111111111";
		input_ex_wb <= x"22222222222222222222222222222222";
		wait for 20 ns;
		assert output = input_id_ex 
			report "Mux_2to1 test 1 failed: sel = 0 did not output ID/EX value" severity error;
		
		sel <= '1';
		wait for 20 ns;
		assert output = input_ex_wb 
			report "Mux_2to1 test 2 failed: sel = 1 did not output EX/WB value" severity error;
		report "Mux_2to1 all test finished" severity note;
		wait;
	end process;
end behavioral;
