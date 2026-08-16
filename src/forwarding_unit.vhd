library ieee;
use ieee.std_logic_1164.all;
use work.all;

entity forwarding_unit is
	port(
		--Info from ID/EXE register
		id_ex_rs1_address : in std_logic_vector(4 downto 0);
		id_ex_rs2_address : in std_logic_vector(4 downto 0);
		id_ex_rs3_address : in std_logic_vector(4 downto 0); 
		--Checks if it is an opcode that contains 3 regs 
		id_ex_opcode : in std_logic_vector(1 downto 0);
		--Info from EX/WB register
		ex_wb_rd_address : in std_logic_vector(4 downto 0);
		ex_wb_rd_wb : in std_logic;
		--Outputs the sel for the MUXs
		fwd_sel_rs1 : out std_logic;
		fwd_sel_rs2 : out std_logic;
		fwd_sel_rs3 : out std_logic
	);
end forwarding_unit;

architecture behavioral of forwarding_unit is
	--Internal signal for opcodes with 3 regs
	signal is_3reg : std_logic;
begin
	--1 when instruction[24:23] is 10 which contains 3 regs in the instruction, 0 otherwise
is_3reg <= '1' when id_ex_opcode = "10" else '0';
	--Forwarding for rs1
	process(id_ex_rs1_address, ex_wb_rd_address, ex_wb_rd_wb)
	begin
		--'0' means no hazard so get it from ID/EXE reg
		fwd_sel_rs1 <= '0';
		--Check if EX/WB have write back then check address isn't reg 0 and then compare the two rd's 
		if ex_wb_rd_wb = '1' and ex_wb_rd_address /= "00000" and ex_wb_rd_address = id_ex_rs1_address then
			fwd_sel_rs1 <= '1';
		end if;
	end process;
	--Forwarding for rs2
	process(id_ex_rs2_address, ex_wb_rd_address, ex_wb_rd_wb)
	begin
		fwd_sel_rs2 <= '0';
		if ex_wb_rd_wb = '1' and ex_wb_rd_address /= "00000" and ex_wb_rd_address = id_ex_rs2_address then
			fwd_sel_rs2 <= '1';
		end if;
	end process;
	--Forwarding for rs3
	process(id_ex_rs2_address, ex_wb_rd_address, ex_wb_rd_wb, is_3reg)
	begin
		fwd_sel_rs3 <= '0';
		--RS3 also checks if rs3 is being used in execute stage first then checks for the rest 
		if is_3reg  = '1' and ex_wb_rd_wb = '1' and ex_wb_rd_address /= "00000" and ex_wb_rd_address = id_ex_rs3_address then
			fwd_sel_rs3 <= '1';
		end if;
	end process;
end behavioral;
	
