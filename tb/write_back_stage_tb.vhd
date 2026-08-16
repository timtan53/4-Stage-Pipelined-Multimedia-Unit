library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.all;

entity write_back_stage_tb is
end write_back_stage_tb;

architecture behavioral of write_back_stage_tb is
	signal ex_wb_rd_data : std_logic_vector(127 downto 0);
	signal ex_wb_rd_address : std_logic_vector(4 downto 0);
	signal reg_file_data : std_logic_vector(127 downto 0);
	signal reg_file_address : std_logic_vector(4 downto 0);
begin
	UUT : entity write_back_stage
		port map(
			ex_wb_rd_data => ex_wb_rd_data,
			ex_wb_rd_address => ex_wb_rd_address,
			reg_file_data => reg_file_data,
			reg_file_address => reg_file_address
		);
	process
		begin
			--Test 1: Checking if data and address passed through correctly
			ex_wb_rd_data <= x"11111111111111111111111111111111";
			ex_wb_rd_address <= "00001";
			wait for 20 ns;
			assert reg_file_data = x"11111111111111111111111111111111" and ex_wb_rd_address = "00001";
				report "WB stage Test 1 failed: Data and Address not passed correctly" severity error;

			--Test 2: Recheck with different values
			ex_wb_rd_data <= x"11111111111111111111111111111112";
			ex_wb_rd_address <= "00010";
			wait for 20 ns;
			assert reg_file_data = x"11111111111111111111111111111112" and ex_wb_rd_address = "00010";
				report "WB stage Test 2 failed: Data and Address not passed correctly" severity error;
			report "WB stage all test finished" severity note;
			wait;
		end process;
end behavioral;
		 
