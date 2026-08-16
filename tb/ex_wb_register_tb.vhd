library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.all;

entity ex_wb_register_tb is
end ex_wb_register_tb;

architecture behavioral of ex_wb_register_tb is
	signal clk : std_logic := '0';
	signal reset : std_logic := '0';
 	signal input_rd_data :  std_logic_vector(127 downto 0);
	signal input_rd_address : std_logic_vector(4 downto 0);
	signal input_rd_wb : std_logic;
	signal output_rd_data : std_logic_vector(127 downto 0);
	signal output_rd_address : std_logic_vector(4 downto 0);
	signal output_rd_wb : std_logic;

	constant clk_period : time := 20 ns;
begin
	UUT : entity ex_wb_register
		port map(
			clk => clk,
			reset => reset,
			input_rd_data => input_rd_data,
			input_rd_address => input_rd_address,
			input_rd_wb => input_rd_wb,
			output_rd_data => output_rd_data,
			output_rd_address => output_rd_address,
			output_rd_wb => output_rd_wb
		);
	clk_gen : process
	begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
	end process;
	
	process 
		begin
			--Test 1 Reset
			reset <= '1';
			input_rd_data <= x"11111111111111111111111111111111";
			input_rd_address <= "00001";
			input_rd_wb <= '1';
			wait for 20 ns;
			assert (output_rd_data = x"00000000000000000000000000000000" and output_rd_address = "00000" and output_rd_wb = '0')
				report "EX/WB reg Test 1 failed: Reset didn't clear output" severity error;
			
			--Test 2 Output gets input on rising edge
			reset <= '0';
			wait for 20 ns; --Wait 1 cycle so there was a rising edge
			assert output_rd_data = x"11111111111111111111111111111111" and output_rd_address = "00001" and output_rd_wb = '1'
				report "EX/WB reg Test 2 failed: Output didn't get input during rising edge" severity error;

			--Test 3 Change input but check output holds previous since no rising edge and check after rising edge
			input_rd_data <= x"11111111111111111111111111111110";
			input_rd_address <= "00010";
			input_rd_wb <= '0';
			assert output_rd_data = x"11111111111111111111111111111111" and output_rd_address  = "00001" and output_rd_wb = '1'
				report "EX/WB reg Test 3a failed: Output changed before clock edge" severity error;
			wait for 20 ns;
			assert output_rd_data = x"11111111111111111111111111111110" and output_rd_address  = "00010" and output_rd_wb = '0'
				report "EX/WB reg Test 3b failed: Output didn't change after clock edge" severity error;
			
			report "EX/WB reg all test finished" severity note;
			wait;
		end process;
end behavioral;


		
			
