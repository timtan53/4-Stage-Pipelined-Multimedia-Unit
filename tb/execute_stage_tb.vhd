library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.all;

entity execute_stage_tb is
end execute_stage_tb;

architecture behavioral of execute_stage_tb is
	signal id_ex_instruction : std_logic_vector(24 downto 0);
	signal id_ex_rs1_data : std_logic_vector(127 downto 0);
	signal id_ex_rs2_data : std_logic_vector(127 downto 0);
	signal id_ex_rs3_data : std_logic_vector(127 downto 0);
	signal id_ex_rs1_address : std_logic_vector(4 downto 0);
	signal id_ex_rs2_address : std_logic_vector(4 downto 0);
	signal id_ex_rs3_address : std_logic_vector(4 downto 0);
	signal ex_wb_fwd_data : std_logic_vector(127 downto 0);
	signal ex_wb_fwd_address : std_logic_vector(4 downto 0);
	signal ex_wb_fwd_wb : std_logic;
	signal output_rd_data : std_logic_vector(127 downto 0);
    	signal output_rd_address : std_logic_vector(4 downto 0);
    	signal output_rd_wb : std_logic;
    	signal sel_rs1, sel_rs2, sel_rs3 : std_logic;
    	signal data_rs1, data_rs2, data_rs3 : std_logic_vector(127 downto 0);
    	signal alu_result : std_logic_vector(127 downto 0);
	
	constant rs1_val : std_logic_vector(127 downto 0) := x"11111111111111111111111111111111";
	constant rs2_val : std_logic_vector(127 downto 0) := x"00000000000000000000000000000000";
	constant rs3_val : std_logic_vector(127 downto 0) := x"33333333333333333333333333333333";
	constant fwd_val : std_logic_vector(127 downto 0) := x"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";
begin
	UUT : entity execute_stage
	port map(
		id_ex_instruction => id_ex_instruction,
            	id_ex_rs1_data => id_ex_rs1_data,
            	id_ex_rs2_data => id_ex_rs2_data,
            	id_ex_rs3_data => id_ex_rs3_data,
            	id_ex_rs1_address => id_ex_rs1_address,
            	id_ex_rs2_address => id_ex_rs2_address,
            	id_ex_rs3_address => id_ex_rs3_address,
            	ex_wb_fwd_data => ex_wb_fwd_data,
            	ex_wb_fwd_address => ex_wb_fwd_address,
            	ex_wb_fwd_wb => ex_wb_fwd_wb,
            	output_rd_data => output_rd_data,
            	output_rd_address => output_rd_address,
            	output_rd_wb => output_rd_wb,
            	sel_rs1 => sel_rs1,
            	sel_rs2 => sel_rs2,
            	sel_rs3 => sel_rs3,
            	data_rs1 => data_rs1,
            	data_rs2 => data_rs2,
            	data_rs3 => data_rs3,
            	alu_result => alu_result
        );
	process
	begin
		--Added to fix U signal in test 4 since rs3 is first intialized there causing errors
		id_ex_rs3_address <= "00000";
		id_ex_rs3_data <= rs3_val;
		--Test 1 Data forwarding is present 
		id_ex_instruction <= "1100000101000010001000001"; --OR opcode'
		id_ex_rs1_address <= "00001";
		id_ex_rs2_address <= "00010";
		id_ex_rs1_data <= rs1_val;
		id_ex_rs2_data <= rs2_val;
		ex_wb_fwd_address <= "00001";
		ex_wb_fwd_data  <= fwd_val;
		ex_wb_fwd_wb <= '1';
		wait for 20 ns;
		assert sel_rs1 = '1' and sel_rs2 = '0'
			report "EX Stage Test 1a failed: MUX for rs1 did not set to 1 when forwarding" severity error;
		assert data_rs1 = fwd_val
			report "EX Stage Test 1b failed: Forwarded data was not selected by MUX" severity error;
		assert output_rd_data = x"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF" and 
						output_rd_address = "00001" and
						output_rd_wb = '1' and 
						alu_result = x"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF" and
						data_rs1 = x"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF" and 
						data_rs2 = x"00000000000000000000000000000000"
			report "EX Stage Test 1c failed: Output was not calculated and transferred properly" severity error;

		--Test 2 Data forwarding isn't present
		ex_wb_fwd_address <= "00100";
		wait for 20 ns;
		assert sel_rs1 = '0' and sel_rs2 = '0'
			report "EX Stage Test 2a failed: MUX for rs1 did not set to 0 when not forwarding" severity error;
		assert data_rs1 = rs1_val
			report "EX Stage Test 2b failed: RS1 data was not selected by MUX" severity error;
		assert output_rd_data = x"11111111111111111111111111111111" and 
						output_rd_address = "00001" and
						output_rd_wb = '1' and 
						alu_result = x"11111111111111111111111111111111" and
						data_rs1 = x"11111111111111111111111111111111" and 
						data_rs2 = x"00000000000000000000000000000000"
			report "EX Stage Test 2c failed: Output was not calculated and transferred properly" severity error;
			
		--Test 3 NOP instruction
		id_ex_instruction <= "1100000000111111111111111"; --NOP opcode
		id_ex_rs1_address <= "11111";
		id_ex_rs2_address <= "11111";
		wait for 20 ns;
		assert output_rd_wb = '0'
			report "EX Stage Test 3 failed: write back set to 1 during NOP instruction" severity error;

		--Test 4 R4 instruction
		id_ex_instruction <= "1000000001000100010001000"; --Signed Integer Multiply-Add Low with Saturation opcode
		id_ex_rs1_data <= x"0000000A0000000A0000000A0000000A";
		id_ex_rs2_data <= x"10000002100000021000000210000002";
		id_ex_rs3_data <= x"10000003100000031000000310000003";
		id_ex_rs1_address <= "00001";
		id_ex_rs2_address <= "00010";
		id_ex_rs3_address <= "00100";
		ex_wb_fwd_wb <= '0';
		wait for 20 ns;
		assert sel_rs1 = '0' and sel_rs2 = '0' and sel_rs3 = '0' and 
			data_rs1 = x"0000000A0000000A0000000A0000000A" and 
			data_rs2 = x"10000002100000021000000210000002" and 
			data_rs3 = x"10000003100000031000000310000003" and 
			alu_result = x"00000010000000100000001000000010" and 
			output_rd_data = x"00000010000000100000001000000010" and 
			output_rd_address = "01000" and 
			output_rd_wb = '1' and 
			sel_rs1 = '0' and sel_rs2 = '0' and sel_rs3 = '0'
				report "EX Stage Test 4 failed: Output was not calculated and transferred properly" severity error;
		report "EX Stage all test finished" severity note;
		wait;
	end process;
end behavioral;


		
		
	