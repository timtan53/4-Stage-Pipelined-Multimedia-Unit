library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity if_stage is
    port (
        clk           : in  std_logic;
        reset         : in  std_logic;

        load_en       : in  std_logic;
        load_addr     : in  std_logic_vector(5 downto 0);
        load_data     : in  std_logic_vector(24 downto 0);

        fetch_en      : in  std_logic;

        if_instruction: out std_logic_vector(24 downto 0);
        pc_out        : out std_logic_vector(5 downto 0)
    );
end if_stage;

architecture structural of if_stage is
begin

    U_INSTR_BUFFER: entity work.instruction_buffer
        port map (
            clk           => clk,
            reset         => reset,
            load_en       => load_en,
            load_addr     => load_addr,
            load_data     => load_data,
            fetch_en      => fetch_en,
            current_instr => if_instruction,
            pc_out        => pc_out
        );

end structural;
