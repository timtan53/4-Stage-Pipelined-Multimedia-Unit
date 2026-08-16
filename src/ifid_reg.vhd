library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity if_id_register is
    port (
        clk                : in  std_logic;
        reset              : in  std_logic;
        enable             : in  std_logic;

        if_instruction_in  : in  std_logic_vector(24 downto 0);
        if_pc_in           : in  std_logic_vector(5 downto 0);

        id_instruction_out : out std_logic_vector(24 downto 0);
        id_pc_out          : out std_logic_vector(5 downto 0)
    );
end if_id_register;

architecture behavioral of if_id_register is

    constant NOP_INSTR : std_logic_vector(24 downto 0) :=
        "1100000000000000000000000";

begin

    process(clk, reset)
    begin
        if reset = '1' then
            id_instruction_out <= NOP_INSTR;
            id_pc_out          <= (others => '0');

        elsif rising_edge(clk) then
            if enable = '1' then
                id_instruction_out <= if_instruction_in;
                id_pc_out          <= if_pc_in;
            end if;
        end if;
    end process;

end behavioral;
