library ieee;
use ieee.std_logic_1164.all;
use work.all;

entity mux_2to1 is
	port(
	--Two input one from ID/EXE reg other from EX/WB reg
	--Sel is the selector for the MUX
		sel : in std_logic;
		input_id_ex : in std_logic_vector(127 downto 0);
		input_ex_wb : in std_logic_vector(127 downto 0);
		output : out std_logic_vector(127 downto 0)
	);
end mux_2to1;

architecture behavioral of mux_2to1 is
begin
	with sel select
		--When sel is 1 that means there is forwarding and mux outputs data from EX/WB reg instead of ID/EXE
		output <= input_ex_wb when '1',
		--Output from ID/EXE when there is no forwarding
		input_id_ex when others;
end behavioral;
	




