library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_file is
    port (
        clk         : in  std_logic;
        write_en    : in  std_logic;

        read_addr1  : in  std_logic_vector(4 downto 0);
        read_addr2  : in  std_logic_vector(4 downto 0);
        read_addr3  : in  std_logic_vector(4 downto 0);
        write_addr  : in  std_logic_vector(4 downto 0);

        write_data  : in  std_logic_vector(127 downto 0);

        read_data1  : out std_logic_vector(127 downto 0);
        read_data2  : out std_logic_vector(127 downto 0);
        read_data3  : out std_logic_vector(127 downto 0)
    );
end register_file;

architecture behavioral of register_file is

    type reg_array_t is array (0 to 31) of std_logic_vector(127 downto 0);
    signal regs : reg_array_t := (others => (others => '0'));

begin

    -- R0 is always forced to zero

    read_data1 <= (others => '0') when read_addr1 = "00000"
                  else regs(to_integer(unsigned(read_addr1)));

    read_data2 <= (others => '0') when read_addr2 = "00000"
                  else regs(to_integer(unsigned(read_addr2)));

    read_data3 <= (others => '0') when read_addr3 = "00000"
                  else regs(to_integer(unsigned(read_addr3)));

    -- Synchronous write

    process(clk)
    begin
        if rising_edge(clk) then
            if write_en = '1' then

                -- writes to everything but r0
                if write_addr /= "00000" then
                    regs(to_integer(unsigned(write_addr))) <= write_data;
                end if;

            end if;
        end if;
    end process;

end behavioral;