library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.all;

entity forwarding_unit_tb is
end forwarding_unit_tb;

architecture behavioral of forwarding_unit_tb is
	signal id_ex_rs1_address : std_logic_vector(4 downto 0);
	signal id_ex_rs2_address : std_logic_vector(4 downto 0);
	signal id_ex_rs3_address : std_logic_vector(4 downto 0);
	signal id_ex_opcode : std_logic_vector(1 downto 0);
	signal ex_wb_rd_address : std_logic_vector(4 downto 0);
	signal ex_wb_rd_wb : std_logic;
	signal fwd_sel_rs1, fwd_sel_rs2, fwd_sel_rs3 : std_logic;
begin
	UUT : entity forwarding_unit
		port map(
			id_ex_rs1_address => id_ex_rs1_address,
			id_ex_rs2_address => id_ex_rs2_address,
			id_ex_rs3_address => id_ex_rs3_address,
			id_ex_opcode => id_ex_opcode,
			ex_wb_rd_address => ex_wb_rd_address,
			ex_wb_rd_wb => ex_wb_rd_wb,
			fwd_sel_rs1 => fwd_sel_rs1,
			fwd_sel_rs2 => fwd_sel_rs2,
			fwd_sel_rs3 => fwd_sel_rs3
		);
		process
			begin
				--Test 1 No hazard
				id_ex_rs1_address <= "00001";
				id_ex_rs2_address <= "00010";
				id_ex_rs3_address <= "00100";
				id_ex_opcode <= "10";
				ex_wb_rd_address <= "01000";
				ex_wb_rd_wb <= '1';
				wait for 20 ns;
				assert(fwd_sel_rs1 = '0' and fwd_sel_rs2 = '0' and fwd_sel_rs3 = '0')
					report "Fowarding Unit Test 1 failed: False Hazard Detected" severity error;

				--Test 2 Rs1 Hazard
				id_ex_rs1_address <= "01000";
				id_ex_rs2_address <= "00010";
				id_ex_rs3_address <= "00100";
				wait for 20 ns;
				assert(fwd_sel_rs1 = '1' and fwd_sel_rs2 = '0' and fwd_sel_rs3 = '0')
					report "Fowarding Unit Test 2 failed: Rs1 hazard not detected" severity error;

				--Test 3 Rs2 Hazard
				id_ex_rs1_address <= "00001";
				id_ex_rs2_address <= "01000";
				id_ex_rs3_address <= "00100";
				wait for 20 ns;
				assert(fwd_sel_rs1 = '0' and fwd_sel_rs2 = '1' and fwd_sel_rs3 = '0')
					report "Fowarding Unit Test 3 failed: Rs2 hazard not detected" severity error;

				--Test 4 Rs3 Hazard
				id_ex_rs1_address <= "00001";
				id_ex_rs2_address <= "00010";
				id_ex_rs3_address <= "01000";
				wait for 20 ns;
				assert(fwd_sel_rs1 = '0' and fwd_sel_rs2 = '0' and fwd_sel_rs3 = '1')
					report "Fowarding Unit Test 4 failed: Rs3 hazard not detected" severity error;

				--Test 5 NOP no write back hazard
				id_ex_rs1_address <= "01000";
				id_ex_rs2_address <= "00010";
				id_ex_rs3_address <= "00100";
				ex_wb_rd_wb <= '0';
				wait for 20 ns;
				assert(fwd_sel_rs1 = '0' and fwd_sel_rs2 = '0' and fwd_sel_rs3 = '0')
					report "Fowarding Unit Test 5 failed: Forwarding with no writeback detected" severity error;

				--Test 6 Reg 0 hazard
				id_ex_rs1_address <= "00000";
				id_ex_rs2_address <= "00010";
				id_ex_rs3_address <= "00100";
				ex_wb_rd_address <= "00000";
				ex_wb_rd_wb <= '1';
				wait for 20 ns;
				assert(fwd_sel_rs1 = '0' and fwd_sel_rs2 = '0' and fwd_sel_rs3 = '0')
					report "Fowarding Unit Test 6 failed: Fowarding from reg 0 detected" severity error;

				--Test 7 No register 3 usage
				id_ex_rs1_address <= "00000";
				id_ex_rs2_address <= "00010";
				id_ex_rs3_address <= "00100";
				ex_wb_rd_address <= "00100";
				id_ex_opcode <= "00";
				wait for 20 ns;
				assert(fwd_sel_rs1 = '0' and fwd_sel_rs2 = '0' and fwd_sel_rs3 = '0')
					report "Fowarding Unit Test 7 failed: Rs3 forwarding when rs3 isn't used" severity error;
				
				--Test 8 Multiple hazard
				id_ex_rs1_address <= "00100";
				id_ex_rs2_address <= "00100";
				id_ex_rs3_address <= "00100";
				id_ex_opcode <= "10";
				wait for 20 ns;
				assert(fwd_sel_rs1 = '1' and fwd_sel_rs2 = '1' and fwd_sel_rs3 = '1')
					report "Fowarding Unit Test 8 failed: Multiple hazards not detected" severity error;

				report "Fowarding Unit all test finished" severity note;
				wait;
		end process;
end behavioral;
		
				
				
			
			