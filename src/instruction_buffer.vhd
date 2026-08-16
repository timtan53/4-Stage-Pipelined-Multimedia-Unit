library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity instruction_buffer is
    port (
        clk            : in  std_logic;
        reset          : in  std_logic;

        -- load interface from testbench
        load_en        : in  std_logic;
        load_addr      : in  std_logic_vector(5 downto 0);
        load_data      : in  std_logic_vector(24 downto 0);

        -- fetch control
        fetch_en       : in  std_logic;

        current_instr  : out std_logic_vector(24 downto 0);
        pc_out         : out std_logic_vector(5 downto 0)
    );
end instruction_buffer;

architecture behavioral of instruction_buffer is
    type instr_mem_t is array (0 to 63) of std_logic_vector(24 downto 0);
    signal mem : instr_mem_t := (others => (others => '0'));

    signal pc  : unsigned(5 downto 0) := (others => '0');
begin

    current_instr <= mem(to_integer(pc));
    pc_out <= std_logic_vector(pc);

    process(clk, reset)
    begin
        if reset = '1' then
            pc <= (others => '0');
        elsif rising_edge(clk) then
            -- load instructions from TB
            if load_en = '1' then
                mem(to_integer(unsigned(load_addr))) <= load_data;
            end if;

            -- fetch next instruction
            if fetch_en = '1' then
                pc <= pc + 1;
            end if;
        end if;
    end process;

end behavioral;
