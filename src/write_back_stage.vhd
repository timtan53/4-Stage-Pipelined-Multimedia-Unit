library ieee;
use ieee.std_logic_1164.all;
use work.all;

entity write_back_stage is
	port(
	--Gets info from EX/WB reg
		ex_wb_rd_data : in std_logic_vector(127 downto 0);
		ex_wb_rd_address : in std_logic_vector(4 downto 0);
		--Output data and address to reg file
		reg_file_data : out std_logic_vector(127 downto 0);
		reg_file_address : out std_logic_vector(4 downto 0)
	);
end write_back_stage;

architecture behavioral of write_back_stage is 
begin
	--Register file gets info from EX/WB stage
	reg_file_data <= ex_wb_rd_data;
	reg_file_address <= ex_wb_rd_address;
end behavioral;
	
	
	
